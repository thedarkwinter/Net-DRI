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
 $self->ns({ map { $_ => 'http://xmlns.tango-rs.net/epp/'.$_.'-1.0' } qw/idn auction/ });
 $self->capabilities('domain_update','idn',['add','del']);
 $self->capabilities('domain_update','auction',['set']);
}

sub default_extensions {
 my ($self,$pp) = @_;
 my @ext;

 # tweak to fix mess with multiple (and non existent) fees
 # .ruhr: no fee; .nrw: standard 1.0 fee (rfc8748); .whoswho: draft fee version 0.21
 # no idea about the other TLDs: gmx and ifm - simply add, and share please, if needed :)
 if ($self && ($self->{logging_ctx}->{profile} =~ m/nrw/ || $self->{logging_ctx}->{registry} =~ m/nrw/)) {
  $pp->{fee_version} = '1.0';
  @ext = qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction Fee/;
 } elsif ($self && ($self->{logging_ctx}->{profile} =~ m/whoswho/ || $self->{logging_ctx}->{registry} =~ m/whoswho/)) {
  $pp->{fee_version} = '0.21';
  @ext = qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction CentralNic::Fee/;
 } else {
  $pp->{fee_version} = undef;
  @ext = qw/GracePeriod SecDNS LaunchPhase TangoRS::IDN TangoRS::Auction/;
 }

 return @ext;
}

####################################################################################################
1;
