## Domain Registry Interface, Nominet Message Parsing
##
## Copyright (c) 2005-2010,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Message;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;


####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'message' => { 'result' => [ undef, \&parse ] } };
}

# To get warning fields from std-warning-1.1
sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 ## Parse warnings
 my $result = $mes->node_extension();
 return unless $result;
 my $warnTypes = {
  'credit-limit'                => 'remaining',
  'glue-removed'                => 'nameserverName',
  'glue-ignored'                => 'ip',
  'deprecated-field'            => ['field-name','processed'],
  'reg-type-set'	        => 'setTo',
  'account-id-ignored'          => undef,
  'contact-moved'               => ['original','final'],
  'ignored-field'               => 'field-name',
  'ignored-attribute'           => 'attribute-name',
  'postalInfo-ignored'          => 'type',
  'truncated-field'             => 'field-name',
  'host-ignored'                => 'host-name',
  'registrar-account-forked'    => 'registrant',
 };
 foreach my $wt (keys %$warnTypes)
 {
  ## We add it to the extra_info.. for now ?
  foreach my $el ($result->getChildrenByTagName('warning:'.$wt))
  {
   my $str = "$wt: ";
   foreach my $attr ($warnTypes->{$wt}) { $str .= "[$attr:" . $el->getAttribute($attr) . "] "; }
   $str .= $el->textContent();
   $mes->add_to_extra_info({from => 'nominet', type => 'text', message => $str});
  }
 }
 return;
}

1;
