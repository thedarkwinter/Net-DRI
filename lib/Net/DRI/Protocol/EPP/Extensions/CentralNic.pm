## Domain Registry Interface, CentralNic EPP extensions (http://labs.centralnic.com/epp/ext/)
##
##
## Copyright (c) 2007-2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub default_extensions { return qw/SecDNS GracePeriod IDN LaunchPhase CentralNic::Fee/; }

####################################################################################################
1;
