## Domain Registry Interface, Protocol superclass
##
## Copyright (c) 2005-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_accessors(qw(name version commands message default_parameters logging));

use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Changes;
use Net::DRI::Data::Contact;
use Net::DRI::Data::ContactSet;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::StatusList;

=pod

=head1 NAME

Net::DRI::Protocol - Superclass of all Net::DRI Protocols

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,$ctx)=@_;

 my $self={	capabilities => {},
		factories => { 	datetime	=> sub { return DateTime->new(@_); },
				duration	=> sub { return DateTime::Duration->new(@_); },
				changes  	=> sub { return Net::DRI::Data::Changes->new(@_); },
				contact  	=> sub { return Net::DRI::Data::Contact->new(); },
				contactset 	=> sub { return Net::DRI::Data::ContactSet->new(@_); },
				hosts		=> sub { return Net::DRI::Data::Hosts->new(@_); },
				status		=> sub { return Net::DRI::Data::StatusList->new(@_); },
				},
		logging   => $ctx->{registry}->logging(),
		logging_ctx => { registry => $ctx->{registry}->name(), profile => $ctx->{profile}, transport_class => $ctx->{transport_class} },
	};

 bless($self,$class);
 $self->message(undef);
 $self->default_parameters({});

 $self->log_setup_channel($class,'protocol',$self->{logging_ctx});
 $self->log_output('debug','core',sprintf('Added profile %s for registry %s',$class,$ctx->{registry}->name()));
 return $self;
}

sub log_output
{
 my ($self,$level,$type,$data1)=@_;
 $self->{logging_ctx}->{protocol}=$self->name().'/'.$self->version() if (! exists $self->{logging_ctx}->{protocol} && defined $self->name());
 return $self->logging()->output($level,$type,ref $data1 ? +{ %{$self->{logging_ctx}}, %$data1 } : $data1);
}


sub parse_iso8601
{
 my ($self,$d)=@_;
 $self->{iso8601_parser}=DateTime::Format::ISO8601->new() unless exists $self->{iso8601_parser};
 return $self->{iso8601_parser}->parse_datetime($d);
}

sub build_strptime_parser
{
 my ($self,@args)=@_;
 my $key=join("\x{001E}",@args);
 $self->{strptime_parser}->{$key}=DateTime::Format::Strptime->new(@args) unless exists $self->{strptime_parser}->{$key};
 return $self->{strptime_parser}->{$key};
}

sub create_local_object
{
 my ($self,$what,@args)=@_;
 return unless defined $self && defined $what;
 my $fn=$self->factories();
 return unless (defined($fn) && ref($fn) && exists($fn->{$what}) && (ref($fn->{$what}) eq 'CODE'));
 return $fn->{$what}->(@args);
}

## This should not be called multiple times for a given Protocol class (as it will erase the loaded_modules slot)
sub _load
{
 my ($self,@classes)=@_;
 my $etype='protocol/'.$self->name();
 my $version=$self->version();

 my (%c,%done,@done);
 foreach my $class (@classes)
 {
  next if exists($done{$class});
  Net::DRI::Util::load_module($class,$etype);
  Net::DRI::Exception::method_not_implemented('register_commands',$class) unless $class->can('register_commands');
  my $rh=$class->register_commands($version);
  $self->{commands_by_class}->{$class}=$rh;
  Net::DRI::Util::hash_merge(\%c,$rh); ## { object type => { action type => [ build action, parse action ]+ } }
  if ($class->can('capabilities_add'))
  {
   my @a=$class->capabilities_add();
   if (ref($a[0]))
   {
    foreach my $a (@a) { $self->capabilities(@$a); }
   } else
   {
    $self->capabilities(@a);
   }
  }
  $class->setup($self,$version) if $class->can('setup');
  $done{$class}=1;
  push @done,$class;
 }

 $self->{loaded_modules}=\@done;
 $self->commands(\%c);
 return;
}

## has_module + find_action_in_class should instead better be based on some ID, like the XML namespace in EPP,
## instead of the Perl module names
sub has_module
{
 my ($self,$mod)=@_;
 return 0 unless defined $mod && length $mod;
 return (grep { $_ eq $mod } @{$self->{loaded_modules}})? 1 : 0;
}

sub find_action_in_class
{
 my ($self,$class,$otype,$oaction)=@_;
 return unless defined $class && length $class && exists $self->{commands_by_class}->{$class} && exists $self->{commands_by_class}->{$class}->{$otype} && exists $self->{commands_by_class}->{$class}->{$otype}->{$oaction};
 return wantarray ? @{$self->{commands_by_class}->{$class}->{$otype}->{$oaction}} : $self->{commands_by_class}->{$class}->{$otype}->{$oaction}->[0];
}

sub _load_commands
{
 my ($self,$otype,$oaction)=@_;

 my $etype='protocol/'.$self->name();
 Net::DRI::Exception->die(1,$etype,7,'Object type and/or action not defined') unless (defined $otype && length $otype && defined $oaction && length $oaction);
 my $h=$self->commands();
 Net::DRI::Exception->die(1,$etype,8,'No actions defined for object of type <'.$otype.'>') unless exists($h->{$otype});
 Net::DRI::Exception->die(1,$etype,9,'No action name <'.$oaction.'> defined for object of type <'.$otype.'> in '.ref($self)) unless exists($h->{$otype}->{$oaction});
 return $h;
}

sub has_action
{
 my ($self,$otype,$oaction)=@_;
 return eval { my $h=$self->_load_commands($otype,$oaction); 1; } ? 1 : 0;
}

sub action
{
 my ($self,$otype,$oaction,$trid,@params)=@_;
 my $h=$self->_load_commands($otype,$oaction);

 ## Create a new message from scratch and loop through all functions registered for given action & type
 my $msg=$self->create_local_object('message',$trid,$otype,$oaction);
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref $msg && $msg->isa('Net::DRI::Protocol::Message'));
 $self->message($msg); ## store it for later use (in loop below)

 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[0];
  next unless (defined($pf) && (ref($pf) eq 'CODE'));
  $pf->($self,@params);
 }

 $self->message(undef); ## needed ? useful ?
 return $msg;
}

sub reaction
{
 my ($self,$otype,$oaction,$dr,$sent,$oname,$trid)=@_;
 my $h=$self->_load_commands($otype,$oaction);
 my $msg=$self->create_local_object('message');
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref($msg) && $msg->isa('Net::DRI::Protocol::Message'));

 my %info;
 ## TODO is $sent needed here really ? if not remove from API above also !
 $msg->parse($dr,\%info,$otype,$oaction,$sent); ## will trigger an Exception by itself if problem ## TODO : add  later the whole LocalStorage stuff done when sending ? (instead of otype/oaction/message sent)
 $self->message($msg); ## store it for later use (in loop below)
 $info{$otype}->{$oname}->{name}=$oname if ($otype eq 'domain' || $otype eq 'host' || $otype eq 'nsgroup' || $otype eq 'keygroup'); ## TODO : abstract this ?

 if (exists $h->{message} && exists $h->{message}->{result})
 {
  foreach my $t (@{$h->{message}->{result}})
  {
   my $pf=$t->[1];
   next unless (defined $pf && ref $pf eq 'CODE');
   $pf->($self,$otype,$oaction,$oname,\%info);
  }
 }

 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[1];
  next unless (defined $pf && ref $pf eq 'CODE');
  $pf->($self,$otype,$oaction,$oname,\%info);
 }

 my $rc=$msg->result_status();
 if (defined $rc)
 {
  $rc->_set_trid([ $trid ]) unless $rc->trid(); ## if not done inside Protocol::*::Message::result_status, make sure we save at least our transaction id
  foreach my $v1 (values %info)
  {
   next unless ref $v1 eq 'HASH' && keys %$v1;
   foreach my $v2 (values %{$v1})
   {
    next unless ref $v2 eq 'HASH' && keys %$v2; ## yes, this can happen, with must_reconnect for example
    next if exists $v2->{result_status};
    $v2->{result_status}=$rc;
   }
  }
 }
 $self->message(undef); ## needed ? useful ?

 $info{session}->{exchange}->{result_from_cache}=0;
 $info{session}->{exchange}->{protocol}=$self->nameversion();
 $info{session}->{exchange}->{trid}=$trid;
 return ($rc,\%info);
}

sub nameversion
{
 my $self=shift;
 return $self->name().'/'.$self->version();
}

sub factories
{
 my ($self,$object,$code)=@_;
 if (defined $object && defined $code)
 {
  $self->{factories}->{$object}=$code;
  return $self;
 }
 return $self->{factories};
}

sub capabilities
{
 my ($self,$action,$object,$cap)=@_;
 if (defined($action) && defined($object))
 {
  $self->{capabilities}->{$action}={} unless exists($self->{capabilities}->{$action});
  if (defined($cap))
  {
   $self->{capabilities}->{$action}->{$object}=$cap;
  } else
  {
   delete($self->{capabilities}->{$action}->{$object});
  }
 }
 return $self->{capabilities};
}

####################################################################################################
1;
