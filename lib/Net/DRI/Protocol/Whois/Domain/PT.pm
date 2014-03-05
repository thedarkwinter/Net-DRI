## Domain Registry Interface, Whois commands for .SE (RFC3912)
##
## Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::PT;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::PT - .PT Whois commands (RFC3912) for Net::DRI

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

Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 parse_dates($po,$domain,$rr,$rinfo);
 parse_contacts($po,$domain,$rr,$rd,$rinfo);
 parse_ns($po,$domain,$rr,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my ($dom,$e);

 if (exists($rr->{"Nome de dom\x{ED}nio / Domain Name"}))
 {
  $e=1;
  $dom=lc($rr->{"Nome de dom\x{ED}nio / Domain Name"}->[0]);
 } else
 {
  $e=0;
 }
 return ($dom,$e);
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%d/%m/%Y', time_zone => 'Europe/Lisbon');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Data de registo / Creation Date (dd/mm/yyyy)'}->[0]);
 return;
}

sub parse_contacts
{
 my ($po,$domain,$rr,$rd,$rinfo)=@_;
 my $cs=$po->create_local_object('contactset');
 my @m=qw/name street city pc cc email/;
 my @t=qw/billing admin tech/;
 my $c;

 foreach my $l (@$rd)
 {
  $l=~s/^\s+//;
  $l=~s/\s+$//;

  if (($l=~m!Titular / Registrant!)..($l=~m/^\s*$/))
  {
   next if ($l eq 'Titular / Registrant');
   if ($l=~m/^\s*$/)
   {
    $cs->add($c,'registrant');
    $c=undef;
    next;
   }
   $l=~s/^Email:\s+//;
   $c=$po->create_local_object('contact') unless defined $c;
   my $m=shift(@m);
   $c->$m($m eq 'street'? [$l] : $l);
  }
  if (($l=~m!^(Entidade Gestora / Billing Contact|Respons\x{E1}vel Administrativo / Admin Contact|Respons\x{E1}vel T\x{E9}cnico / Tech Contact)$!)..($l=~m/^\s*$/))
  {
   next if $l=~m! / \S+ Contact$!;
   if ($l=~m/^\s*$/)
   {
    $cs->add($c,shift(@t));
    $c=undef;
    next;
   }
   if ($l=~s/^Email:\s+//)
   {
    $c->email($l);
   } else
   {
    $c=$po->create_local_object('contact');
    $c->name($l);
   }
  }
 }
 $rinfo->{domain}->{$domain}->{contact}=$cs;
 return;
}

sub parse_ns
{
 my ($po,$domain,$rr,$rinfo)=@_;
 return unless (exists($rr->{Nameserver}));
 my $h=$po->create_local_object('hosts');
 foreach my $ns (grep { defined($_) && $_ } @{$rr->{Nameserver}})
 {
  $h->add($ns);
 }
 $rinfo->{domain}->{$domain}->{ns}=$h unless $h->is_empty();
 return;
}

####################################################################################################
1;
