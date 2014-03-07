## Domain Registry Interface, Handling of contact data for RegBox new gtlds
##
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Data::Contact::RegBox;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Util;
__PACKAGE__->register_attributes(qw(type));

####################################################################################################

sub init
{
 my ($self,$what,$ndr)=@_;
 $self->auth({pw=>''}) if $what eq 'create'; # not supported
 $self->disclose(undef); # not supported
 return;
}

####################################################################################################
1;
