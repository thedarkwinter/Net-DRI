## Domain Registry Interface, Key Relay Mapping for EPP
##
## Copyright (c) 2013,2015,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::KeyRelay;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::SecDNS;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %d=(
        keyrelay     => [ \&command, undef ],
        notification => [ undef, \&notification_parse ],
       );

 return { 'domain' => \%d };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({
           'keyrelay' => [ 'urn:ietf:params:xml:ns:keyrelay-1.0','keyrelay-1.0.xsd' ],
           'secDNS'   => [ 'urn:ietf:params:xml:ns:secDNS-1.1','secDNS-1.1.xsd' ], ## force 1.1 here
         });
 return;
}

sub implements { return 'http://tools.ietf.org/html/draft-ietf-eppext-keyrelay-11'; }

####################################################################################################

sub format_duration
{
 my ($d)=@_;

 return 'P0D' if $d->is_zero();

 my $duration='P';
 my $tmp='';

 state $ru=[qw/years months weeks days hours minutes seconds/];
 my @d=$d->in_units(@$ru[0..3]);
 foreach my $wi (0..$#d)
 {
  next unless $d[$wi] > 0;
  $tmp.=$d[$wi].uc(substr($ru->[$wi],0,1));
 }
 $duration.=$tmp if length $tmp;
 $tmp='';

 @d=$d->in_units(@$ru[4..6]);
 foreach my $wi (0..$#d)
 {
  next unless $d[$wi] > 0;
  $tmp.=$d[$wi].uc(substr($ru->[4+$wi],0,1));
 }
 $duration.='T'.$tmp if length $tmp;
 $duration='-'.$duration if $d->is_negative();
 return $duration;
}

sub command
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('One domain name must be specified for keyrelay operation') unless defined $domain && length $domain;
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for domain name: '.$domain) unless Net::DRI::Util::xml_is_token($domain,1,255);

 my @d;
 push @d,['keyrelay:name',$domain];

 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 push @d,['keyrelay:authInfo',['domain:pw',$rd->{auth}->{pw},exists $rd->{auth}->{roid} ? { 'roid' => $rd->{auth}->{roid} } : undef]];

 Net::DRI::Exception::usererr_insufficient_parameters('key is mandatory') unless Net::DRI::Util::has_key($rd,'key');
 Net::DRI::Exception::usererr_invalid_parameters('key must be a single ref hash or a ref array of ref hashes') unless ref $rd->{key} eq 'ARRAY' || ref $rd->{key} eq 'HASH';
 my @keys = ref $rd->{key} eq 'ARRAY' ? @{$rd->{key}} : ($rd->{key});
 Net::DRI::Exception::usererr_invalid_parameters('key must be a single ref hash or a ref array of ref hashes') if grep { ref $_ ne 'HASH' } @keys;
 foreach my $kd (@keys)
 {
  my @dd;
  Net::DRI::Exception::usererr_insufficient_parameters('secdns is mandatory') unless Net::DRI::Util::has_key($kd,'secdns');
  Net::DRI::Exception::usererr_invalid_parameters('secdns value must be a single ref hash') unless ref $kd->{secdns} eq 'HASH';
  push @dd,['keyrelay:keyData',Net::DRI::Protocol::EPP::Extensions::SecDNS::format_keydata($kd->{secdns})];

  ## Now optional parameters
  if (Net::DRI::Util::has_key($kd,'expiry'))
  {
   my $exp=$kd->{expiry};
   if (Net::DRI::Util::is_class($exp,'DateTime'))
   {
    push @dd,['keyrelay:expiry',['keyrelay:absolute',$exp->strftime('%FT%T.%6N%z')]];
   } elsif (Net::DRI::Util::is_class($exp,'DateTime::Duration'))
   {
    push @dd,['keyrelay:expiry',['keyrelay:relative',format_duration($exp)]];
   } else {
    Net::DRI::Exception::usererr_invalid_parameters('expiry value must be a DateTime or a DateTime::Duration object');
   }
  }
  push @d,['keyrelay:keyRelayData',@dd];
 }

 $mes->command(['create','keyrelay:create',sprintf('xmlns:keyrelay="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('keyrelay'))]);
 $mes->command_body(\@d);

 return;
}

sub parse_duration
{
 my ($po,$dur)=@_;
 state $rm1={ qw/Y years M months W weeks D days/ };
 state $rm2={ qw/H hours M minutes S seconds/ };
 my $rm=$rm1;
 my $tmp=$dur;
 my @d;
 Net::DRI::Exception::err_assert('Unknown duration format: '.$tmp) unless $tmp=~s/^P//;
 while($tmp=~m/(\d+\S|T)/g)
 {
  my $token=$1;
  if ($token eq 'T')
  {
   $rm=$rm2;
   next;
  }
  my ($v,$t)=($token=~m/^(\d+)(\S)$/);
  Net::DRI::Exception::err_assert('Unknown duration token: '.$token.' in '.$dur) unless exists $rm->{$t};
  push @d,$rm->{$t},$v;
 }
 return $po->create_local_object('duration',@d);
}

sub notification_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response($mes->ns('keyrelay'),'infData');
 return unless defined $data;

 my %r = ( type => 'keyrelay' );
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'name')
  {
   $r{name} = $oname = $node->textContent();
  } elsif ($name eq 'authInfo')
  {
   $r{auth}={pw => Net::DRI::Util::xml_child_content($node,$mes->ns('domain'),'pw')};
  } elsif ($name eq 'keyRelayData')
  {
   push @{$r{key}}, _parse_keyrelay($po,$node);
  } elsif ($name eq 'crDate')
  {
   $r{date}=$po->parse_iso8601($node->textContent());
  } elsif ($name=~m/^(?:reID|acID)$/)
  {
   $r{$name}=$node->textContent();
  }
 }

 $rinfo->{domain}->{$oname}->{relay}=\%r;

 return;
}

sub _parse_keyrelay
{
 my ($po, $data)=@_;

 my $mes=$po->message();
 my $ns=$mes->ns('keyrelay');

 my %r;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'keyData')
  {
   my %n;
   Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_keydata($node,\%n);
   $r{secdns}=\%n;
  } elsif ($name eq 'expiry')
  {
   my $exp;
   if (defined($exp=Net::DRI::Util::xml_child_content($node,$ns,'absolute')))
   {
    $r{expiry}=$po->parse_iso8601($exp);
   } elsif (defined($exp=Net::DRI::Util::xml_child_content($node,$ns,'relative')))
   {
    $r{expiry}=parse_duration($po,$exp);
   }
  }
 }

 return \%r;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::KeyRelay - EPP Key Relay mapping (draft-ietf-eppext-keyrelay-11) for Net::DRI

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

Copyright (c) 2013,2015,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
