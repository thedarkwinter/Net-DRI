## Domain Registry Interface, Whois commands for .AT (RFC3912)
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

package Net::DRI::Protocol::Whois::Domain::AT;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::AT - .AT Whois commands (RFC3912) for Net::DRI

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

 parse_ns($po,$domain,$rr,$rinfo);
 parse_dates($po,$domain,$rr,$rinfo);
 parse_contacts($po,$domain,$rr,$rd,$rinfo);
 return;
}

sub parse_domain
{
 my ($po,$rr,$rd,$rinfo)=@_;
 my ($dom,$e);
 if (exists($rr->{'domain'}))
 {
  $e=1;
  $dom=lc($rr->{'domain'}->[0]);
 } else
 {
  $e=0;
 }
 return ($dom,$e);
}

sub parse_ns
{
 my ($po,$domain,$rr,$rinfo)=@_;
 return unless exists($rr->{'nserver'});

 ## I do not know how multiple IPs for one host are handled, we do the very crude way for now
 my $h=$po->create_local_object('hosts');
 my @n=grep { defined($_) && $_ } @{$rr->{'nserver'}};
 my @i=grep { defined($_) && $_ } @{$rr->{'remarks'}};
 while(@n)
 {
  $h->add(shift(@n),[shift(@i)]);
 }
 $rinfo->{domain}->{$domain}->{ns}=$h unless $h->is_empty();
 return;
}

sub parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%Y%m%d %T', time_zone => 'Europe/Vienna');
 $rinfo->{domain}->{$domain}->{upDate}=$strp->parse_datetime($rr->{'changed'}->[0]);
 return;
}

sub parse_contacts
{
 my ($po,$domain,$rr,$rd,$rinfo)=@_;
 my $cs=$po->create_local_object('contactset');
 my %t=('registrant' => 'registrant', 'admin-c' => 'admin', 'tech-c' => 'tech');
 my %tmp;

 ## First pass, only the IDs
 foreach my $t (keys(%t))
 {
  my $c=$po->create_local_object('contact');
  my $id=$rr->{$t}->[0];
  $tmp{$id}=$c;
  $c->srid($id);
  $cs->add($c,$t{$t});
 }

 ## Now all details
 my ($id,@s);
 foreach my $l (reverse grep { (($_=~m/^personname:/)..($_=~m/^\s*$/)) } @$rd)
 {
  next if ($l=~m/^(?:source|changed):/);
  $id=$1 if ($l=~m/^nic-hdl:\s+(\S+)\s*$/);
  if ($l=~m/^e-mail:\s+(\S+)\s*$/)
  {
   $tmp{$id}->email($1);
  } elsif ($l=~m/^fax-no:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->fax($1);
  } elsif ($l=~m/^phone:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->voice($1);
  } elsif ($l=~m/^country:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->cc($1);
  } elsif ($l=~m/^city:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->city($1);
  } elsif ($l=~m/^postal code:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->pc($1);
  } elsif ($l=~m/^street address:\s+(\S.+\S)\s*$/)
  {
   push @s,$1;
  } elsif ($l=~m/^organization:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->org($1);
   $tmp{$id}->street([reverse(@s)]) if @s;
   @s=();
  } elsif ($l=~m/^personname:\s+(\S.+\S)\s*$/)
  {
   $tmp{$id}->name($1);
   $tmp{$id}->street([reverse(@s)]) if @s;
   @s=();
  }
 }
 $rinfo->{domain}->{$domain}->{contact}=$cs;
 return;
}

####################################################################################################
1;
