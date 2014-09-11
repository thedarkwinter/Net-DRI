## Domain Registry Interface, Key Relay Mapping for EPP (draft-gieben-epp-keyrelay-03)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
 $po->ns({ 'keyrelay' => [ 'urn:ietf:params:xml:ns:keyrelay-1.0','keyrelay-1.0.xsd' ],
           'secDNS'   => [ 'urn:ietf:params:xml:ns:secDNS-1.1','secDNS-1.1.xsd' ], ## force 1.1 here
         });
 return;
}

####################################################################################################

sub format_duration
{
 my ($d)=@_;
 my $duration='P';
 my $tmp='';

 my @u=qw/years months weeks days hours minutes seconds/;
 my @d=$d->in_units(@u[0..3]);
 foreach my $wi (0..$#d)
 {
  next unless $d[$wi] > 0;
  $tmp.=$d[$wi].uc(substr($u[$wi],0,1));
 }
 $duration.=$tmp if length $tmp;
 $tmp='';

 @d=$d->in_units(@u[4..6]);
 foreach my $wi (0..$#d)
 {
  next unless $d[$wi] > 0;
  $tmp.=$d[$wi].uc(substr($u[4+$wi],0,1));
 }
 $duration.='T'.$tmp if length $tmp;
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

 Net::DRI::Exception::usererr_insufficient_parameters('secdns is mandatory') unless Net::DRI::Util::has_key($rd,'secdns');
 Net::DRI::Exception::usererr_invalid_parameters('secdns value must be an array reference with key data') unless ref $rd->{secdns} eq 'ARRAY' && @{$rd->{secdns}};
 push @d,map { ['keyrelay:keyData',Net::DRI::Protocol::EPP::Extensions::SecDNS::format_keydata($_)] } @{$rd->{secdns}};

 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 push @d,['keyrelay:authInfo',['domain:pw',$rd->{auth}->{pw},exists $rd->{auth}->{roid} ? { 'roid' => $rd->{auth}->{roid} } : undef]];

 ## Now optional parameters
 if (Net::DRI::Util::has_key($rd,'expiry'))
 {
  my $exp=$rd->{expiry};
  if (Net::DRI::Util::is_class($exp,'DateTime'))
  {
   push @d,['keyrelay:expiry',['keyrelay:absolute',$exp->strftime('%FT%T.%6N%z')]];
  } elsif (Net::DRI::Util::is_class($exp,'DateTime::Duration'))
  {
   push @d,['keyrelay:expiry',['keyrelay:relative',format_duration($exp)]];
  } else {
   Net::DRI::Exception::usererr_invalid_parameters('expiry value must be a DateTime or a DateTime::Duration object');
  }
 }

 my $eid=$mes->command_extension_register(['keyrelay','domain','secDNS'],'command');
 $mes->command_extension($eid,[['keyrelay:keyrelay',@d],['keyrelay:clTRID',$mes->cltrid()]]);

 return;
}

sub parse_duration
{
 my ($po,$dur)=@_;
 my %m1=qw/Y years M months W weeks D days/;
 my %m2=qw/H hours M minutes S seconds/;
 my $rm=\%m1;
 my $tmp=$dur;
 my @d;
 Net::DRI::Exception::err_assert('Unknown duration format: '.$tmp) unless $tmp=~s/^P//;
 while($tmp=~m/(\d+\S|T)/g)
 {
  my $token=$1;
  if ($token eq 'T')
  {
   $rm=\%m2;
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

 my $data=$mes->get_response($mes->ns('keyrelay'),'response');
 return unless defined $data;

 my $ns=$mes->ns('keyrelay');
 $data=Net::DRI::Util::xml_traverse($data,$ns,'panData');
 return unless defined $data;

 my %r;
 my @secdns;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'name')
  {
   $oname=lc $node->textContent();
   $rinfo->{domain}->{$oname}->{action}='review';
   $rinfo->{domain}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($node->getAttribute('paResult'));
  } elsif ($name eq 'paDate')
  {
   $rinfo->{domain}->{$oname}->{date}=$po->parse_iso8601($node->textContent());
  } elsif ($name eq 'keyData')
  {
   my %n;
   Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_keydata($node,\%n);
   push @secdns,\%n;
  } elsif ($name eq 'authInfo')
  {
   $r{auth}={pw => Net::DRI::Util::xml_child_content($node,$mes->ns('domain'),'pw')};
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
  } elsif ($name=~m/^(?:reID|acID)$/)
  {
   $r{$name}=$node->textContent();
  }
 }

 $r{secdns}=\@secdns;
 $rinfo->{domain}->{$oname}->{keyrelay}=\%r;
 
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::KeyRelay - EPP Key Relay mapping (draft-gieben-epp-keyrelay-03) for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
