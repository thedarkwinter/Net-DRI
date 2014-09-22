## Domain Registry Interface, TMCH messages commands
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::TMCH::Core::RegistryMessage;
use Net::DRI::Protocol::EPP::Core::RegistryMessage;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Switch;

####################################################################################################

# Use Standard EPP::Core::RegistryMessage functions, and add a notifcation : parse for additional
sub register_commands
{
 my ($class,$version)=@_;
 my %msg=(
           retrieve => [ \&Net::DRI::Protocol::EPP::Core::RegistryMessage::pollreq, \&Net::DRI::Protocol::EPP::Core::RegistryMessage::parse_poll ],
           delete   => [ \&Net::DRI::Protocol::EPP::Core::RegistryMessage::pollack ],
         );
  my %nots=(
           parse => [undef,\&parse],
           );

 return { 'message' => \%msg, 'notifications'=>\%nots };
}

####################################################################################################
#### Notifications

# Parse any additional stuff above and beyond the Basic EPP polling.
# At the moment it just changes the action if the content matches a known result
sub parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $msgid=$mes->msg_id();
 my $content=$mes->msg_content();
 return unless (defined($msgid) && $msgid && defined($content)); 

 if ($content =~ m/^Watermark/) # watermark reached
 {
   return;
 }
 
 if ($content =~ m/^Mark mark renewal approved/) # this might be a tmchv1 thing (?)
 {
  $rinfo->{$otype}->{$oname}->{action} = 'renewed';
  $rinfo->{$otype}->{$oname}->{status} = 'verified';
  return;
 }
 
 unless ($content =~ /^([0-9]{3})\s(.*)?/)
 {
  $rinfo->{$otype}->{$oname}->{action} = 'unknown' unless defined $rinfo->{$otype}->{$oname}->{action};
  return;
 }
 
 my ($code,$text) = ($1,$2);
 $rinfo->{$otype}->{$oname}->{action_text} = $text;
 $rinfo->{$otype}->{$oname}->{action_code} = $code;
 
 switch ($code) {
  
  # Proof of use : these are probably wrong status's
  case 102 {
   $rinfo->{$otype}->{$oname}->{action} = 'pou_expired';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 103 {
   $rinfo->{$otype}->{$oname}->{action} = 'pou_verified';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 104 {
   $rinfo->{$otype}->{$oname}->{action} = 'pou_invalid';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 105 {
   $rinfo->{$otype}->{$oname}->{action} = 'pou_incorrect';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }

  # Mark, this should all be correct
  case 123 {
   $rinfo->{$otype}->{$oname}->{action} = $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 124 {
   $rinfo->{$otype}->{$oname}->{action} = $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case [126,127] {
   $rinfo->{$otype}->{$oname}->{action} = $rinfo->{$otype}->{$oname}->{status} = 'invalid';
  }
 case 134 {
   $rinfo->{$otype}->{$oname}->{action} = 'exception';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 137 {
   $rinfo->{$otype}->{$oname}->{action} = $rinfo->{$otype}->{$oname}->{status} = 'expired';
  }
  case 146 {
   $rinfo->{$otype}->{$oname}->{action} = 'correction_period_expired';
   $rinfo->{$otype}->{$oname}->{status} = 'invalid';
  }
  case 154 {
   $rinfo->{$otype}->{$oname}->{action} = 'exception';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 164 {
   $rinfo->{$otype}->{$oname}->{action} = 'exception';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 190 {
   $rinfo->{$otype}->{$oname}->{action} = 'pou_expiring';
   $rinfo->{$otype}->{$oname}->{status} = 'expiring';
  }
  case 191 {
   $rinfo->{$otype}->{$oname}->{action} = 'mark_certificate_expiring';
   $rinfo->{$otype}->{$oname}->{status} = 'expiring';
  }
  case 196 {
   $rinfo->{$otype}->{$oname}->{action} = 'warning';
   $rinfo->{$otype}->{$oname}->{status} = 'incorrect';
  }
  case 197 {
   $rinfo->{$otype}->{$oname}->{action} = 'warning';
   $rinfo->{$otype}->{$oname}->{status} = 'expiring';
  }
  case 198 {
   $rinfo->{$otype}->{$oname}->{action} = $rinfo->{$otype}->{$oname}->{status} = 'deactivated';
  }
  case 199 {
   $rinfo->{$otype}->{$oname}->{action} = 'transfer';
   $rinfo->{$otype}->{$oname}->{status} = 'revoked';
  }
  
  # Think these are notifications that others have registered them ?
  case 210 {
   $rinfo->{$otype}->{$oname}->{action} = 'domain_registered_sunrise';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 220 {
   $rinfo->{$otype}->{$oname}->{action} = 'domain_registered_claims';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 230 {
   $rinfo->{$otype}->{$oname}->{action} = 'domain_activated';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 220 {
   $rinfo->{$otype}->{$oname}->{action} = 'domain_qualified_launch';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  
  # SMD, these messages indicated the mark was already verified
  case 310 {
   $rinfo->{$otype}->{$oname}->{action} = 'smd_created';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 320 {
   $rinfo->{$otype}->{$oname}->{action} = 'smd_generated';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  case 330 {
   $rinfo->{$otype}->{$oname}->{action} = 'smd_revoked';
   $rinfo->{$otype}->{$oname}->{status} = 'verified';
  }
  
  # Watermak
  case 400 {
   $otype = 'message';
   $rinfo->{$otype}->{$oname}->{action} = 'low_balace' ;
  }

  # IDRP
  case 500 {
   $otype = 'message';
   $rinfo->{$otype}->{$oname}->{action} = 'udrp' ;
  }

 }
 return;
}

####################################################################################################
1;
