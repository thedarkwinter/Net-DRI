## Domain Registry Interface, UniRegistry EPP extension for poll messages
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

package Net::DRI::Protocol::EPP::Extensions::UNIREG::RegistryMessage;

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
 return unless my $content = $rinfo->{message}->{$msgid}->{content}; # depending on order we may not have parsed this yet, defer for later
 return if defined $rinfo->{message}->{$msgid}->{lp}; # if they have a sent a proper lp extension in the message then use that
 
 # try to match LP related text in content
 if ($content =~ m!^Launch Application ([\w-]+) is now in status "(\w+)?"/"(\w+)?": (.*)?!) {
  $rinfo->{message}->{$msgid}->{lp}->{application_id} = $1;
  $rinfo->{message}->{$msgid}->{lp}->{status} = $2; # FIXME: this could have multiple statuses, but requires the main LaunchPhase extension to support it
 }

 # market object get info from market_info but we need to define name and object_id
 foreach my $res($mes->get_response('market','infData'))
 {
  next unless $res;
  foreach my $el (Net::DRI::Util::xml_list_children($res))
  {
   next unless $el;
   my ($name,$content)=@$el;
   $rinfo->{message}->{$msgid}->{'object_id'} = $content->textContent() if $name eq 'orderID';
   $rinfo->{message}->{$msgid}->{'name'} = $content->textContent() if $name eq 'name';
  }
 }
 return;
}

####################################################################################################
1;
