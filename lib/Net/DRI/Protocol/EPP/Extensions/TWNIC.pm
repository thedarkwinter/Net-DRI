## Domain Registry Interface, TWNIC EPP extensions
##
## Copyright (c) 2018 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TWNIC;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TWNIC - TWNIC EPP Extensions for Net::DRI

=head1 DESCRIPTION

Additional extensions for TWNIC - based on Neustar Legacy System and their Greeting on OT&E!

=cut

####################################################################################################

sub default_extensions { return qw/IDN SecDNS NeuLevel::Message/; }

####################################################################################################
1;
