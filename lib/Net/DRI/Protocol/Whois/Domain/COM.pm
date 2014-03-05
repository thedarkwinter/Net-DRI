## Domain Registry Interface, Whois commands for .COM/.NET (RFC3912)
##
## Copyright (c) 2007,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::COM;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Core::Status;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::COM - .COM/.NET Whois commands (RFC3912) for Net::DRI

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

Copyright (c) 2007,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 parse_status($po,$domain,$rr,$rinfo);
 parse_ns($po,$domain,$rr,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my ($dom,$e);
 if (exists($rr->{'Domain Name'}))
 {
  $e=1;
  $dom=$rr->{'Domain Name'}->[0];
 } else
 {
  $e=0;
  ($dom)=grep { m/^No match for domain "\S+"\./ } @$rd;
  $dom=~s/^.+"(\S+)".+$/$1/;
 }
 return (lc($dom),$e);
}

sub parse_registrars
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Registrar'}->[0];
 $rinfo->{domain}->{$domain}->{clWhois}=$rr->{'Whois Server'}->[0];
 $rinfo->{domain}->{$domain}->{clWebsite}=$rr->{'Referral URL'}->[0];
 return;
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%d-%b-%Y', locale => 'en_US', time_zone => 'America/New_York');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Creation Date'}->[0]);
 $rinfo->{domain}->{$domain}->{upDate}=$strp->parse_datetime($rr->{'Updated Date'}->[0]);
 $rinfo->{domain}->{$domain}->{exDate}=$strp->parse_datetime($rr->{'Expiration Date'}->[0]);

 my ($l)=($rr->{'>>> Last update of whois database'}->[0]=~m/^(.+) <<<$/);
 $strp=$po->build_strptime_parser(pattern => '%a, %d %b %Y %T UTC', locale => 'en_US', time_zone => 'UTC');
 $rinfo->{domain}->{$domain}->{wuDate}=$strp->parse_datetime($l);
 return;
}

sub parse_status
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new($rr->{'Status'}); #####
 return;
}

sub parse_ns
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{ns}=$po->create_local_object('hosts')->set(@{$rr->{'Name Server'}}) if exists($rr->{'Name Server'});
 return;
}

####################################################################################################
1;
