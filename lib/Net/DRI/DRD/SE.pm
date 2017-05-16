## NOTE: This module is depricated in favour of the Net::DRI::DRD::IIS driver which supports both .SE and .NU domains

## Domain Registry Interface, .IIS policy on reserved names
## Contributed by Elias Sidenbladh and Ulrich Wisser from NIC SE
## Updated 2014 Michael Holloway to change regerences to IIS for inclusion of .NU
##
## Copyright (c) 2006-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::SE;

use strict;
use warnings;

use base qw/Net::DRI::DRD::IIS/;

=pod

=head1 NAME

Net::DRI::DRD::SE - .SE policies for Net::DRI

=head1 DESCRIPTION

NOTE: This module is depricated in favour of the L<Net::DRI::DRD::IIS> driver which supports both .SE and .NU domains

=cut

####################################################################################################

sub new
{
 my $class=shift;
 warn "DRD::SE.pm is depricated, please use DRD::IIS.pm for .SE and .NU domains!";
 return $class->SUPER::new(@_);
}

sub name { return 'SE'; }

1;
