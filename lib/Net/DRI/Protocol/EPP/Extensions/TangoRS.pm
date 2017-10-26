## Domain Registry Interface, TANGO (Knipp) EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::TangoRS;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup
{
 my ($self,$rp) = @_;
 $self->ns({ map { $_ => ['http://xmlns.tango-rs.net/epp/'.$_.'-1.0',$_.'-1.0.xsd'] } qw/idn auction/ });
 $self->capabilities('domain_update','idn',['add','del']);
 $self->capabilities('domain_update','auction',['set']);
}

sub default_extensions {
 my ($self,$pp) = @_;
 my @ext = qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction/;
 $self->{fee_version} = $self->{brown_fee_version} = $pp->{brown_fee_version} // $pp->{fee_version};
 push @ext, 'Fee' if $self->{fee_version} && $self->{fee_version} >= '0.21';

 return @ext;
}

####################################################################################################
1;
