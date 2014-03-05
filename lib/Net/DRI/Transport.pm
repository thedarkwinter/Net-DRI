## Domain Registry Interface, Superclass of all Transport/* modules (hence virtual class, never used directly)
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

package Net::DRI::Transport;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_accessors(qw/name version retry pause trace timeout defer current_state has_state is_sync time_creation time_open time_used trid_factory logging/);

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Transport - Superclass of all Transport Modules in Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This is a superclass that should never be used directly, but only through its subclasses.

=head1 METHODS

During the new() call, subclasses will call this new() method, which expects a ref hash with some
keys (other are handled by the subclasses), among which:

=head2 defer

do we open the connection right now (0) or later (1)

=head2 timeout

time to wait (in seconds) for server reply (default 60)

=head2 retry

number of times we try to send the message to the registry (default 2)

=head2 trid

(optional) code reference of a subroutine generating a transaction id when passed a name ; 
if not defined, $dri->trid_factory() is used, which is Net::DRI::Util::create_trid_1 by default

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
 my ($class,$ctx,$ropts)=@_;
 my $ndr=$ctx->{registry};
 my $pname=$ctx->{profile};

 my $self={
           is_sync   => exists($ropts->{is_sync})? $ropts->{is_sync} : 1, ## do we need to wait for reply as soon as command sent ?
           retry     => exists($ropts->{retry})?   $ropts->{retry}   : 2,  ## by default, we will try once only
           pause     => exists($ropts->{pause})?   $ropts->{pause}   : 10, ## time in seconds to wait between two retries
           timeout   => exists($ropts->{timeout})? $ropts->{timeout} : 60,
           defer     => exists($ropts->{defer})?   $ropts->{defer}   : 0, ## defer opening connection as long as possible (irrelevant if stateless) ## XX maybe not here, too low
           logging   => $ndr->logging(),
           trid_factory => (exists($ropts->{trid}) && (ref($ropts->{trid}) eq 'CODE'))? $ropts->{trid} : $ndr->trid_factory(),
           current_state => undef, ## for stateless transport, otherwise 0=close, 1=open
           has_state     => undef, ## do we need to open a session before sending commands ?
           transport     => undef, ## will be defined in subclasses
           time_creation => time(),
           logging_ctx => { registry => $ndr->name(), profile => $pname, protocol => $ctx->{protocol}->name() },
          };

 bless $self,$class;
 $self->log_setup_channel($class,'transport',$self->{logging_ctx}); ## if we need the transport name here, we will have to put that further below, in another method called after new() ; otherwise we derive it from $class
 $self->log_output('debug','core',sprintf('Added transport %s for registry %s',$class,$ndr->name()));
 return $self;
}

sub transport_data { my ($self,$data)=@_; return defined $data ? $self->{transport}->{$data} : $self->{transport}; }

sub log_output
{
 my ($self,$level,$type,$data1,$data2)=@_;
 return $self->logging()->output($level,$type,$data1) unless defined $data2;
 $self->{logging_ctx}->{transport}=$self->name().'/'.$self->version() unless exists $self->{logging_ctx}->{transport};
 return $self->logging()->output($level,$type,{ %{$self->{logging_ctx}}, %$data1, %$data2 });
}

sub parse_ssl_options
{
 my ($self,$ropts)=@_;

 require IO::Socket::SSL;
 $IO::Socket::SSL::DEBUG=$ropts->{ssl_debug} if exists $ropts->{ssl_debug};

 my %s=();
 $s{SSL_verify_mode}=exists $ropts->{ssl_verify} ? $ropts->{ssl_verify} : 0x00; ## by default, no authentication whatsoever
 $s{SSL_verify_callback}=sub { my $r=$ropts->{ssl_verify_callback}->($self,@_); Net::DRI::Exception->die(1,'transport',6,'SSL certificate user verification failed, aborting connection') unless $r; 1; } if (exists $ropts->{ssl_verify_callback} && defined $ropts->{ssl_verify_callback});

 foreach my $s (qw/key_file cert_file ca_file ca_path version passwd_cb/)
 {
  next unless exists $ropts->{'ssl_'.$s};
  Net::DRI::Exception::usererr_invalid_parameters('File "'.$ropts->{'ssl_'.$s}.'" does not exist or is unreadable by current UID') if ($s=~m/_file$/ && ! -r $ropts->{'ssl_'.$s});
  Net::DRI::Exception::usererr_invalid_parameters('Directory "'.$ropts->{'ssl_'.$s}.'" does not exist')                            if ($s=~m/_path$/ && ! -d $ropts->{'ssl_'.$s});
  $s{'SSL_'.$s}=$ropts->{'ssl_'.$s};
 }

 $s{SSL_cipher_list}=exists $ropts->{ssl_cipher_list} ? $ropts->{ssl_cipher_list} : 'SSLv3:TLSv1:!aNULL:!eNULL';
 $s{SSL_hostname}=$ropts->{ssl_hostname} if exists $ropts->{ssl_hostname}; # defaults to servers hostname, set blank to disable SNI

 return \%s;
}

## WARNING : this is a preliminary implementation of this new feature, it WILL change
## Should it be in Registry.pm ? + tweaking of process_back
sub protocol_parse
{
 my ($to,$po,$otype,$oaction,$dr,$trid,$dur,$sent)=@_;
 my ($rc,$rinfo)=$po->reaction($otype,$oaction,$dr);

 $rinfo->{session}->{exchange}->{transport}=$to->name().'/'.$to->version();

 foreach my $v1 (values(%$rinfo))
 {
  foreach my $v2 (values(%{$v1}))
  {
   delete($v2->{result_status}) if exists $v2->{result_status};
  }
 }

 $rinfo->{session}->{exchange}={ %{$rinfo->{session}->{exchange}}, duration_seconds => $dur, raw_command => defined $sent ? $sent->as_string() : undef, raw_reply => $dr->as_string(), object_type => $otype, object_action => $oaction };
 $rc->_set_data($rinfo);
## die($rc) unless $rc->is_success(); ## was done just after reaction before ## TODO maybe not necessary ? Tweak Registry::add_profile + search for other die in Transport/
 return $rc;
}

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend,$cb1,$cb2,$count)=@_; ## $cb1=how to send, $cb2=how to test if fatal (to break loop) or not (retry once more)
 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));
 my $ok=0;

 ## Try to reconnect if needed
 $self->open_connection($ctx) if ($self->has_state() && !$self->current_state()); ## TODO : grab result !
 ## Here $tosend is a Net::DRI::Protocol::Message object (in fact, a subclass of that), in perl internal encoding, no transport related data (such as EPP 4 bytes header)
 $self->log_output('notice','transport',$ctx,{phase=>'active',direction=>'out',message=>$tosend});
 $ok=$self->$cb1($count,$tosend,$ctx);
 $self->time_used(time());

 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry') unless $ok;
 return;
}

sub receive
{
 my ($self,$ctx,$cb1,$cb2,$count)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));

 my $ans;
 $ans=$self->$cb1($count,$ctx); ## a Net::DRI::Data::Raw object
 Net::DRI::Exception->die(0,'transport',5,'Unable to receive message from registry') unless defined $ans;
 ## $ans should have been properly decoded into a native Perl string
 $self->log_output('notice','transport',$ctx,{phase=>'active',direction=>'in',message=>$ans});
 return $ans;
}

sub try_again ## TO BE SUBCLASSED
{
 my ($self,$ctx,$po,$err,$count,$istimeout,$step,$rpause,$rtimeout)=@_; ## $step is 0 before send, 1 after, and 2 after receive successful
 ## Should return 1 if we try again, or 0 if we should stop processing now
 return ($istimeout && ($count <= $self->{retry}))? 1 : 0;
}

sub open_connection ## no critic (Subroutines::RequireFinalReturn)
{
 my ($self,$ctx)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::method_not_implemented('open_connection',$self);
}

sub end ## no critic (Subroutines::RequireFinalReturn)
{
 my ($self,$ctx)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::method_not_implemented('end',$self);
}

####################################################################################################
## Pass a true value if you want the connection to be automatically redone if the ping failed
sub ping ## no critic (Subroutines::RequireFinalReturn)
{
 my ($self,$autorecon)=@_;
 return unless $self->has_state();
 Net::DRI::Exception::method_not_implemented('ping',$self);
}

####################################################################################################
1;
