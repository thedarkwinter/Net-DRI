## Domain Registry Interface, RegistryObject
##
## Copyright (c) 2005,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Data::RegistryObject;

use strict;
use warnings;

use Net::DRI::Exception;

our $AUTOLOAD;

=pod

=head1 NAME

Net::DRI::Data::RegistryObject - Additional API for Net::DRI operations

=head1 SYNOPSYS

 my $dri=Net::DRI->new();
 my $nsg=$dri->remote_object('nsgroup');
 $nsg->create(...);
 $nsg->update(...);
 $nsg->whatever(...);

 Also:
 my $nsg=$dri->remote_object('nsgroup','name');

=head1 DESCRIPTION

For objects other than domains, hosts, or contacts, Net::DRI::Data::RegistryObject
can be used to apply actions.

Net::DRI::remote_object is used to create a new Net::DRI::Data::RegistryObject
with either only one parameter (the object type) or two parameters (the object
type and the object name)

If the object name is not passed at creation it will need to be passed for all
later actions as first parameter.

All calls are handled by an AUTOLOAD, except target() which is the same as in Net::DRI.

All calls need either two array references (protocol parameters and transport parameters)
or a list (protocol parameters only).

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


###########################################################################################################

sub new
{
 my ($class,$p,$type,$name)=@_; ## $name (object name) not necessarily defined

 Net::DRI::Exception::err_invalid_parameters() unless (defined($p) && ((ref($p) eq 'Net::DRI') || (ref($p) eq 'Net::DRI::Registry')));
 Net::DRI::Exception::err_insufficient_parameters() unless (defined($type) && $type);

 my $self={ 
            p    => $p,
            type => $type,
            name => $name,
          };

 bless($self,$class);
 return $self;
}

sub target
{
 my ($self,@args)=@_;
 $self->{p}->target(@args);
 return $self;
}

sub AUTOLOAD ## no critic (Subroutines::RequireFinalReturn)
{
 my ($self,@args)=@_;
 my $attr=$AUTOLOAD; ## this is the action wanted on the object
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my $name=$self->{name};
 my ($rp,$rt);
 if (@args==2 && (ref $args[0] eq 'ARRAY') && (ref $args[1] eq 'ARRAY'))
 {
  $rp=$args[0];
  $rp=[ $self->{name}, @$rp ] if (defined $name && $name);
  $rt=$args[1];
 } else
 {
  $rp=(defined $name && $name)? [ $name, @args ] : [ @args ];
  $rt=[];
 }

 my $p=$self->{p};
 if (ref $p eq 'Net::DRI::Registry')
 {
  return $p->process($self->{type},$attr,$rp,$rt);
 } elsif (ref $p eq 'Net::DRI')
 {
  my $c=$self->{type}.'_'.$attr;
  return $p->$c->(@$rp);
 } else
 {
  Net::DRI::Exception::err_assert('case not handled: '.ref($p));
 }
}

###########################################################################################################
1;
