## Domain Registry Interface, Whois commands for .TRAVEL (RFC3912)
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::TRAVEL;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::Whois::Domain::common;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::TRAVEL - .TRAVEL Whois commands (RFC3912) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'domain' => { info   => [ \&info, \&info_parse ] } };
}

sub info
{
 my ($po,$domain,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/whois',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 $mes->command('domain '.lc($domain));
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 my $rd=$mes->response_raw();
 my ($domain,$exist)=parse_domain($po,$rr,$rd,$rinfo);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 parse_registrars($po,$domain,$rr,$rinfo);
 parse_dates($po,$domain,$rr,$rinfo);
 Net::DRI::Protocol::Whois::Domain::common::epp_parse_status($po,$domain,$rr,$rinfo);
 Net::DRI::Protocol::Whois::Domain::common::epp_parse_contacts($po,$domain,$rr,$rinfo,{registrant => 'Registrant',admin => 'Administrative Contact', billing => 'Billing Contact', tech => 'Technical Contact'});
 Net::DRI::Protocol::Whois::Domain::common::epp_parse_ns($po,$domain,$rr,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my ($dom,$e);
 if (exists($rr->{'Domain Name'}))
 {
  $e=1;
  $dom=lc($rr->{'Domain Name'}->[0]);
  $rinfo->{domain}->{$dom}->{roid}=$rr->{'Domain ID'}->[0];
 } else
 {
  $e=0;
  ($dom)=grep { m/^Not found: domain (\S+)\s*$/ } @$rd;
  $dom=~s/domain (\S+)\s*$/$1/;
  $dom=lc($dom);
 }
 return ($dom,$e);
}

sub parse_registrars
{
 my ($po,$domain,$rr,$rinfo)=@_;

 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Sponsoring Registrar'}->[0];
 $rinfo->{domain}->{$domain}->{clID}=$rr->{'Sponsoring Registrar IANA ID'}->[0] if exists($rr->{'Sponsoring Registrar IANA ID'});
 $rinfo->{domain}->{$domain}->{crName}=$rr->{'Created by Registrar'}->[0];
 $rinfo->{domain}->{$domain}->{upName}=$rr->{'Last Updated by Registrar'}->[0];
 return;
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%a %b %d %T GMT %Y', locale => 'en_US', time_zone => 'UTC');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Domain Registration Date'}->[0]);
 $rinfo->{domain}->{$domain}->{exDate}=$strp->parse_datetime($rr->{'Domain Expiration Date'}->[0]);
 $rinfo->{domain}->{$domain}->{upDate}=$strp->parse_datetime($rr->{'Domain Last Updated Date'}->[0]);
 return;
}

####################################################################################################
1;
