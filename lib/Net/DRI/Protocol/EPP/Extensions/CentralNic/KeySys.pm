## Domain Registry Interface, CentralNic EPP Fee extension
##
## Copyright (c) 2020 Ivan Borzenkov <ivan.borenkov@gmail.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwiner.com>. All rights reserved.
##           (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::KeySys;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;
use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::KeySys - CentralNic EPP KeySys extension commands for Net::DRI

=head1 DESCRIPTION

Partially implemented KeySys extension

=cut

####################################################################################################

sub register_commands
{
 my %tmp=(
  info    => [ undef, \&info_parse ],
#  update  => [ \&update, undef ], #.la and am dont use keysys:accept-trade, keeping function for other tlds or other keysys params if needed later 
 );
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'keysys' => [ 'http://www.key-systems.net/epp/keysys-1.0','keysys-1.0.xsd' ] });
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 
 my $mes=$po->message();
 return unless $mes->is_success();
 
 my $resdata=$mes->get_extension('keysys','resData');
 return unless defined $resdata;
 
 my $infdata = ($resdata->getChildrenByTagName('keysys:infData'))[0];
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata)){
  my ($n,$c)=@$el;
  $rinfo->{domain}->{$oname}->{"ks_".$n} = $n =~/date/i
                                           ? eval { $po->parse_iso8601($c->textContent()) } || $c->textContent() 
                                           : $c->textContent();
 }

 return;
}

sub update
{
 my ($epp, $domain, $rd) = @_;

 if (!Net::DRI::Util::check_isa($rd,'Net::DRI::Data::Changes') || !$rd->{'registrant'}) {
  return
 }

 my $mes = $epp->message();
 my $eid=$mes->command_extension_register('keysys:update','xmlns:keysys="http://www.key-systems.net/epp/keysys-1.0"', 'keysys');
 my @kv = ();
 push @kv, ['keysys:domain', ['keysys:accept-trade', 1]];
 $mes->command_extension($eid,\@kv);
 return;
}

####################################################################################################
1;
