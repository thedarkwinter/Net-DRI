## Domain Registry Interface, Whois commands for .LU (RFC3912)
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

package Net::DRI::Protocol::Whois::Domain::LU;

use strict;
use warnings;

use Carp;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Core::Status;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::LU - .LU Whois commands (RFC3912) for Net::DRI

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
 my ($domain,$exist)=parse_domain($po,$rr,$rd,$rinfo);
 $domain=lc($oname) unless defined($domain);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 parse_status($po,$domain,$rr,$rinfo);
 parse_ns($po,$domain,$rr,$rinfo);
 parse_dates($po,$domain,$rr,$rinfo);
 parse_contacts($po,$domain,$rr,$rinfo);
 parse_registrars($po,$domain,$rr,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my ($dom,$e);
 if ($rd=~m/\n% WHOIS (\S+)\n% No such domain$/s)
 {
   $dom=$1.'.lu';
   $e=0;
 } else
 {
   $e=1;
   $dom=lc($rr->{'domainname'}->[0]);
 }
 return ($dom,$e);
}

sub parse_status
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my @s=map { my $s=$_; $s=~s/ACTIVE/ok/; $s; } @{$rr->{'domaintype'}};
 carp('For '.$domain.' new status found, please report: '.join(' ',@s)) if (grep { $_ ne 'ok' } @s);
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s) if @s;
 return;
}

sub parse_ns
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $h=$po->create_local_object('hosts');
 foreach my $ns (grep { defined($_) && $_ } @{$rr->{'nserver'}})
 {
  if (my ($name,$ips)=($ns=~m/^(\S+) \[(\S+)\]$/))
  {
   my @ips=split(/,/,$ips);
   $h->add($name,\@ips);
  } else
  {
   $h->add($ns);
  }
 }
 $rinfo->{domain}->{$domain}->{ns}=$h unless $h->is_empty();
 return;
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%d/%m/%Y', time_zone => 'Europe/Luxembourg');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'registered'}->[0]);
 return;
}

sub parse_contacts
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $cs=$po->create_local_object('contactset');
 my %t=('org' => 'registrant', 'adm' => 'admin', 'tec' => 'tech');
 foreach my $t (keys(%t))
 {
  my $c=$po->create_local_object('contact');
  $c->type('contact');
  $c->name($rr->{$t.'-name'}->[0]) if (exists($rr->{$t.'-name'}) && $rr->{$t.'-name'}->[0]);
  $c->street($rr->{$t.'-address'}) if (exists($rr->{$t.'-address'}) && @{$rr->{$t.'-address'}});
  $c->pc($rr->{$t.'-zipcode'}->[0]) if (exists($rr->{$t.'-zipcode'}) && $rr->{$t.'-zipcode'}->[0]);
  $c->city($rr->{$t.'-city'}->[0]) if (exists($rr->{$t.'-city'}) && $rr->{$t.'-city'}->[0]);
  $c->cc($rr->{$t.'-country'}->[0]) if (exists($rr->{$t.'-country'}) && $rr->{$t.'-country'}->[0]);
  $c->email($rr->{$t.'-email'}->[0]) if (exists($rr->{$t.'-email'}) && $rr->{$t.'-email'}->[0]);
  $cs->add($c,$t{$t});
 }

 my %ot=('ORGANISATION' => 'holder_org', 'PRIVATE' => 'holder_pers');
 my $type=$rr->{'ownertype'}->[0];
 carp('For '.$domain.' new ownertype found, please report: '.$type) if ($type ne 'ORGANISATION' && $type ne 'PRIVATE');
 $cs->get('registrant')->type($ot{$type});

 $rinfo->{domain}->{$domain}->{contact}=$cs;
 return;
}

sub parse_registrars
{
 my ($po,$domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'registrar-name'}->[0];
 $rinfo->{domain}->{$domain}->{clEmail}=$rr->{'registrar-email'}->[0];
 $rinfo->{domain}->{$domain}->{clWebsite}=$rr->{'registrar-url'}->[0];
 $rinfo->{domain}->{$domain}->{clCountry}=$rr->{'registrar-country'}->[0];
 return;
}

####################################################################################################
1;
