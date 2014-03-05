## Domain Registry Interface, Whois commands for .WS (RFC3912)
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

package Net::DRI::Protocol::Whois::Domain::WS;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::WS - .WS Whois commands (RFC3912) for Net::DRI

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
 $domain=lc($oname) unless defined($domain);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 parse_registrar($po,$domain,$rr,$rinfo);
 parse_contacts($po,$domain,$rr,$rinfo);
 parse_dates($po,$domain,$rd,$rinfo);
 parse_ns($po,$domain,$rd,$rinfo);
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
 } else ## may also be invalid domain name or reserved domain name
 {
  $e=0;
 }
 return ($dom,$e);
}

## Does not seem to be always there ! (present for whatever.ws, not present for website.ws)
sub parse_registrar
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Registrar Name'}->[0] if (exists($rr->{'Registrar Name'}) && $rr->{'Registrar Name'}->[0]) ;
 $rinfo->{domain}->{$domain}->{clEmail}=$rr->{'Registrar Email'}->[0] if (exists($rr->{'Registrar Email'}) && $rr->{'Registrar Email'}->[0]);
 $rinfo->{domain}->{$domain}->{clVoice}=$rr->{'Registrar Telephone'}->[0] if (exists($rr->{'Registrar Telephone'}) && $rr->{'Registrar Telephone'}->[0]);
 $rinfo->{domain}->{$domain}->{clWhois}=$rr->{'Registrar Whois'}->[0] if (exists($rr->{'Registrar Whois'}) &&$rr->{'Registrar Whois'}->[0]) ;
 return;
}

## Does not seem to be always there (see previous example, opposite case)
sub parse_contacts
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $cs=$po->create_local_object('contactset');

 if (exists($rr->{'Registrant Name'}) && $rr->{'Registrant Name'}->[0])
 {
  my $c=$po->create_local_object('contact');
  $c->name($rr->{'Registrant Name'}->[0]);
  $c->email($rr->{'Registrant Email'}->[0]);
  $cs->add($c,'registrant');
 }
  if (exists($rr->{'Administrative Contact Email'}) && $rr->{'Administrative Contact Email'}->[0])
 {
  my $c=$po->create_local_object('contact');
  $c->email($rr->{'Administrative Contact Email'}->[0]);
  $c->voice($rr->{'Administrative Contact Telephone'}->[0]);
  $cs->add($c,'admin');
 }
 $rinfo->{domain}->{$domain}->{contact}=$cs;
 return;
}

sub parse_dates
{
 my ($po,$domain,$rd,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%Y-%m-%d %T', time_zone => 'America/Los_Angeles');
 my @tmp;
 @tmp=grep { m/Domain created on/ } @$rd;
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime(($tmp[0]=~m/^\s+Domain created on (\S+ \S+)\s*$/)[0]) if @tmp;
 @tmp=grep { m/Domain last updated on/ } @$rd;
 $rinfo->{domain}->{$domain}->{upDate}=$strp->parse_datetime(($tmp[0]=~m/^\s+Domain last updated on (\S+ \S+)\s*$/)[0]) if @tmp;
 return;
}

sub parse_ns
{
 my ($po,$domain,$rd,$rinfo)=@_;
 my @ns;
 foreach my $l (@$rd)
 {
  next unless (($l=~m/^\s+ Current Nameservers:/)..1);
  push @ns,$1 if ($l=~m/^\s*(\S+[^\.])\.?\s*$/);
 }
 $rinfo->{domain}->{$domain}->{ns}=$po->create_local_object('hosts')->set(@ns) if @ns;
 return;
}

####################################################################################################
1;
