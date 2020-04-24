## Domain Registry Interface, UniRegistry EPP extensions
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UniRegistry;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

## eps object not extension but yes a core module
sub core_modules
{
 my ($self,$rp)=@_;
 my @c;
 push @c, map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Contact/;
 # need following tweak to use Host properly :p
 if (! $self->{hostasattr})
 {
  push @c, 'Net::DRI::Protocol::EPP::Core::Host';
  $self->ns({host => 'urn:ietf:params:xml:ns:host-1.0'});
 }
 push @c, map { 'Net::DRI::Protocol::EPP::Extensions::UniRegistry::'.$_ } qw/EPS/ if exists $rp->{default_product} && defined $rp->{default_product} && $rp->{default_product} eq 'ICM_EPS';

 return @c;
}

## icm profile use 2x extra extensions - afilias association and ipr - related with migration from Afilias to Uniregistry::ICM platform
sub default_extensions
{
 my ($self,$rp)=@_;
 my @c=qw/GracePeriod SecDNS IDN LaunchPhase UniRegistry::Centric UniRegistry::RegistryMessage UniRegistry::Market VeriSign::Sync CentralNic::Fee/;
 push @c,qw/Afilias::Association Afilias::IPR/ if exists $rp->{default_product} && defined $rp->{default_product} && $rp->{default_product} eq 'ICM';

 return @c;
}

####################################################################################################
1;
