## Domain Registry Interface, AFNIC EPP extension for poll messages
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC_GTLD::RegistryMessage;

use strict;
use warnings;
use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          retrieve => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $msgid=$mes->msg_id();
 return unless defined $rinfo->{message};
 return if defined $rinfo->{message}->{$msgid}->{lp}; # if they have a sent a proper lp extension in the message then use that
 # try to match LP related text in content
 my $content = $rinfo->{message}->{$msgid}->{content};
 if ($content =~ m!Application switches to "(\w+)?" state!) {
  $rinfo->{message}->{$msgid}->{lp}->{status} = $1;
 }
 return;
}

####################################################################################################
1;
