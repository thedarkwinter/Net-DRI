## Domain Registry Interface, SKNIC EPP extensions
##
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2018 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2018 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SKNIC;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub default_extensions {
 my ($self,$pp) = @_;
 $self->{brown_fee_version} = $pp->{brown_fee_version} if exists $pp->{brown_fee_version};
 my @extensions = qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee CentralNic::RegType CentralNic::AuxContact CentralNic::SkContactIdent/;
 return @extensions;
}

####################################################################################################
1;
