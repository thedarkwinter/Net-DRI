## Domain Registry Interface, Neulevel EPP WhoisType (for .TEL and possibly others)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::WhoisType;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           create => [ \&create, undef ],
           update => [ \&update, undef ],
           info =>	[ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub add_whoistype
{
 my $rd = shift;
 Net::DRI::Exception::usererr_insufficient_parameters('whois_type type value must be defined') unless Net::DRI::Util::has_key($rd,'type');
 my $wt = uc $rd->{'type'};
 Net::DRI::Exception::usererr_invalid_parameters('whois_type type value must be either Legal or Natural') unless $wt =~ m/^(?:LEGAL|NATURAL)$/;
 my $pub = (defined $rd->{'publish'} && (lc($rd->{'publish'}) =~ m/(true|yes|1|y)/ ))?'Y':'N';
 return  "WhoisType=$wt" . (($wt eq 'LEGAL')?'': " Publish=$pub");
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('whois_type is required for domain creates') unless Net::DRI::Util::has_key($rd,'whois_type');
 my $unspec = add_whoistype($rd->{'whois_type'});
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $tochg=$todo->set('whois_type');
 return unless defined $tochg;
 my $unspec = add_whoistype($tochg);
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;

 my %t;
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   $rinfo->{$otype}->{$oname}->{whois_type}->{type}=$v    if $k eq 'WhoisType';
   $rinfo->{$otype}->{$oname}->{whois_type}->{publish}=$v if $k eq 'Publish';
  }
 }

 return;
}

####################################################################################################
1;
