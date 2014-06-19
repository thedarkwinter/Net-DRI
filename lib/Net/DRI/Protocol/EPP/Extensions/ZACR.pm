## Domain Registry Interface, ZACR (ZA Central Registry) EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::ZACR;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

#1. GracePeriod is not yet active, but I am told it will be. This might well make the autorenew feature COZA::Domain redundant
#2. COZA::Domain and COZA::Contact are optional extensions; at the mo not announced on test server, but again I am told they are being used.
#3. At this point there is no plan for IDNS, however for .africa it may well be implemented after the initial Launch phases

sub default_extensions { return qw/GracePeriod SecDNS LaunchPhase COZA::Domain COZA::Contact/; } # IDN not used

####################################################################################################
1;