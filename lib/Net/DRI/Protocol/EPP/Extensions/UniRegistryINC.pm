## Domain Registry Interface, UniRegistryINC EPP extensions
##
## Copyright (c) 2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2019 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::UniRegistryINC;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

# FIXME: even if centric-1.0 is announced is causing some issues so decided to remove from default_extensions. Not critical since the extension is: OPTIONAL!
sub default_extensions { return qw/GracePeriod SecDNS IDN LaunchPhase UniRegistry::RegistryMessage UniRegistry::Market VeriSign::Sync CentralNic::Fee/; }

####################################################################################################
1;
