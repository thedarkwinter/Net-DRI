## Domain Registry Interface, AFNIC EPP extension for premium domains
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC_GTLD::PremiumDomain;

use strict;
use warnings;
use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          check => [ undef, \&parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 return unless ($otype && $oname);
 my $mes=$po->message();
 return unless $mes->is_success();
 $rinfo->{$otype}->{$oname}->{exist_reason} =~ m!^(.*)? - Reserve Auction Price: (\d+) Create: (\d+) Tranfer:(\d+) Renew:(\d+)$!;
 if ($1) {
  $rinfo->{domain}->{$oname}->{is_premium} = 1;
  $rinfo->{domain}->{$oname}->{price_currency} = 'EUR';
  $rinfo->{domain}->{$oname}->{price_category} = $1;
  $rinfo->{domain}->{$oname}->{price_duration} = DateTime::Duration->new(years=>1);
  $rinfo->{domain}->{$oname}->{create_price} = 0+$2; # hmm, this should probably be $2 + $3
  $rinfo->{domain}->{$oname}->{renew_price} = 0+$5;
  #$rinfo->{domain}->{$oname}->{restore_price} = undef; # not implemented in this extension
  $rinfo->{domain}->{$oname}->{transfer_price} = 0+$4;

 }

 return;
}

####################################################################################################
1;
