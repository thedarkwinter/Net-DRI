## Domain Registry Interface, Whois commands for .EU (RFC3912)
##
## Copyright (c) 2007,2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::EU;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::ResultStatus;

use Net::DRI::Protocol::EPP::Core::Status;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::EU - .EU Whois commands (RFC3912) for Net::DRI

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

Copyright (c) 2007,2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $mes->command(lc $domain);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 my $rd=$mes->response_raw();
 die(Net::DRI::Protocol::ResultStatus->new_error('SESSION_LIMIT_EXCEEDED_CLOSING','Registry rate limiting','en')) if $rd=~m/Still in grace period, wait/;
 my ($domain,$exist)=parse_domain($po,$rr,$rd,$rinfo);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';
 $rinfo->{domain}->{$domain}->{ace}=$rr->{'IDNA Domain'}.'.eu' if exists $rr->{'IDNA Domain'};

 return unless $exist;

 parse_registrars($po,$domain,$rr,$rinfo);
 parse_dates($po,$domain,$rr,$rinfo);
 parse_status($po,$domain,$rr,$rinfo);
 parse_ns($po,$domain,$rr,$rd,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my $dom=lc($rr->{'Domain'}->[0]).'.eu';
 my $e=(exists($rr->{'Status'}) && ($rr->{'Status'}->[0] eq 'AVAILABLE'))? 0 : 1;
 return ($dom,$e);
}

sub parse_registrars
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Name'}->[-1];
 $rinfo->{domain}->{$domain}->{clWebsite}=$rr->{'Website'}->[-1] if exists $rr->{'Website'};
 return;
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 return unless exists $rr->{'Registered'};
 my $strp=$po->build_strptime_parser(pattern => '%a %b%n%d %Y', locale => 'en_US', time_zone => 'Europe/Brussels');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Registered'}->[0]);
 return;
}

sub parse_status
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(['ok']);
 return;
}

sub parse_ns
{
 my ($po,$domain,$rr,$rd,$rinfo)=@_;
 my $ns=$po->create_local_object('hosts');
 foreach my $l (@$rd)
 {
  next unless (($l=~m/^Nameservers:/)..($l=~m/^\s*$/));
  $l=~s/^\s+//;
  $l=~s/[)\s]+$//;
  next unless length($l);
  $ns->add(split(/ \(?/,$l));
 }
 $rinfo->{domain}->{$domain}->{ns}=$ns;
 return;
}

####################################################################################################
1;
