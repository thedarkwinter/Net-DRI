## Domain Registry Interface, Whois common parse subroutines
##
## Copyright (c) 2007-2009,2012-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::common;

use strict;
use warnings;

use Net::DRI::Protocol::EPP::Core::Status;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::common - Whois commands (RFC3912) for Net::DRI

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

Copyright (c) 2007-2009,2012-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub epp_parse_registrars
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my %t=('Sponsoring Registrar' => 'cl',
        'Created By'           => 'cr',
        'Created by Registrar' => 'cr',
        'Updated By'           => 'up',
        'Last Updated by Registrar' => 'up',
       );

 while(my ($whois,$epp)=each(%t))
 {
  next unless exists($rr->{$whois});
  my $s=$rr->{$whois}->[0];
  if ($s=~m/^\s*(\S.+\S)\s+\((\S+)\)\s*$/)
  {
   $rinfo->{domain}->{$domain}->{$epp.'ID'}=$2;
   $rinfo->{domain}->{$domain}->{$epp.'Name'}=$1;
  } else
  {
   $rinfo->{domain}->{$domain}->{$epp.'ID'}=$s;
  }
 }
 return;
}

sub epp_parse_dates
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my $strp=$po->build_strptime_parser(pattern => '%d-%b-%Y %T UTC', locale => 'en_US', time_zone => 'UTC');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Created On'}->[0]);

 foreach my $k ('Updated On','Last Updated On')
 {
  next unless exists($rr->{$k});
  $rinfo->{domain}->{$domain}->{upDate}=$strp->parse_datetime($rr->{$k}->[0]);
  last;
 }
 foreach my $k ('Expires On','Expiration Date')
 {
  next unless exists($rr->{$k});
  $rinfo->{domain}->{$domain}->{exDate}=$strp->parse_datetime($rr->{$k}->[0]);
  last;
 }
 return;
}

sub epp_parse_status
{
 my ($po,$domain,$rr,$rinfo)=@_;
 my @s;
 if (exists($rr->{'Domain Status'}))
 {
  @s=map { my $s=$_; $s=~s/OK/ok/; $s; } @{$rr->{'Domain Status'}};
 } elsif (exists($rr->{'Status'})) ## .ORG/.INFO/.MOBI/.CAT variation
 {
  @s=map { my $t=lc($_); $t=~s/ (.)/uc($1)/eg; $t; } @{$rr->{'Status'}};
 }
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s) if @s;
 return;
}

sub epp_parse_contacts
{
 my ($po,$domain,$rr,$rinfo,$rh)=@_;
 my $cs=$po->create_local_object('contactset');
 while(my ($type,$whois)=each %$rh)
 {
  my $c=$po->create_local_object('contact');
  $c->srid($rr->{$whois.' ID'}->[0]) if (exists $rr->{$whois.' ID'} && length $rr->{$whois.' ID'}->[0]);
  $c->name($rr->{$whois.' Name'}->[0]) if (exists $rr->{$whois.' Name'} && length $rr->{$whois.' Name'}->[0]);
  $c->org($rr->{$whois.' Organization'}->[0]) if (exists $rr->{$whois.' Organization'} && length $rr->{$whois.' Organization'}->[0]);
  my @s;
  foreach my $st (qw/Street Address/) ## 2nd form needed for .BIZ
  {
   my $k=$whois.' '.$st;
   @s=map { $rr->{$k.$_}->[0] } grep { exists $rr->{$k.$_} && length $rr->{$k.$_}->[0] } (1..3);
   next unless @s;
   $c->street(\@s);
   last;
  }
  $c->city($rr->{$whois.' City'}->[0]) if (exists $rr->{$whois.' City'} && length $rr->{$whois.' City'}->[0]);
  $c->sp($rr->{$whois.' State/Province'}->[0]) if (exists $rr->{$whois.' State/Province'} && length $rr->{$whois.' State/Province'}->[0]);
  $c->pc($rr->{$whois.' Postal Code'}->[0]) if (exists $rr->{$whois.' Postal Code'} && length $rr->{$whois.' Postal Code'}->[0]);
  $c->cc($rr->{$whois.' Country'}->[0]) if (exists $rr->{$whois.' Country'} && length $rr->{$whois.' Country'}->[0]);
  my $t;
  foreach my $st ('Phone','Phone Number') ## 2nd form needed for .BIZ
  {
   $t=epp_parse_tel($po,$rr,$whois.' '.$st);
   next unless $t;
   $c->voice($t);
   last;
  }
  foreach my $st ('FAX','Facsimile Number') ## 2nd form needed for .BIZ
  {
   $t=epp_parse_tel($po,$rr,$whois.' '.$st);
   next unless $t;
   $c->fax($t);
   last;
  }
  $c->email($rr->{$whois.' Email'}->[0]) if (exists $rr->{$whois.' Email'} && length $rr->{$whois.' Email'}->[0]);
  $cs->add($c,$type) if grep { length } ($c->srid(),$c->name(),$c->city(),$c->cc(),$c->email());
 }
 $rinfo->{domain}->{$domain}->{contact}=$cs;
 return;
}

sub epp_parse_tel
{
 my ($po,$rr,$key)=@_;
 return '' unless (exists($rr->{$key}) && $rr->{$key}->[0]);
 my $r=$rr->{$key}->[0];
 $r.='x'.$rr->{$key.' Ext.'}->[0] if (exists($rr->{$key.' Ext.'}) && $rr->{$key.' Ext.'}->[0]);
 return $r;
}

sub epp_parse_ns
{
 my ($po,$domain,$rr,$rinfo)=@_;
 return unless (exists($rr->{'Name Server'}));
 my @ns=grep { defined($_) && $_ } @{$rr->{'Name Server'}};
 $rinfo->{domain}->{$domain}->{ns}=$po->create_local_object('hosts')->set(@ns) if @ns;
 return;
}

####################################################################################################
1;
