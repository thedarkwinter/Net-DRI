## Domain Registry Interface, United TLD EPP extensions
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UnitedTLD;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::DRD::MAM - United TLD (Demand Media) Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension United TLD New Generic TLDs.  This extension set is used by Donuts and Rightside

=cut

####################################################################################################

sub default_extensions { return qw/GracePeriod SecDNS LaunchPhase IDN AllocationToken UnitedTLD::Charge UnitedTLD::Finance ARI::KeyValue/; }

####################################################################################################
1;
