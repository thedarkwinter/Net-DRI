## Domain Registry Interface, CNNIC EPP extensions
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CNNIC;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CNNIC - CNNIC EPP Extensions for Net::DRI

=head1 DESCRIPTION

Additional domain extensions for CNNIC.

=cut 

####################################################################################################

sub default_extensions { return qw/GracePeriod SecDNS LaunchPhase CNNIC::CDN CNNIC::Registry CNNIC::Contact/; }

####################################################################################################
1;
