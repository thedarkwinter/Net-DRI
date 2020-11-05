## Domain Registry Interface, IE (Titan) EPP extensions
##
##
## Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::IE;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::IE;

####################################################################################################

sub default_extensions {
 my ($self,$pp) = @_;
 $self->{brown_fee_version} = $pp->{brown_fee_version} if exists $pp->{brown_fee_version};
 my @extensions = qw/GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee CIRA::FuryIE/; # TODO: confirm via <greeting>!!!
 return @extensions;
}

####################################################################################################
1;
