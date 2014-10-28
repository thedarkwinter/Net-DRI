## Domain Registry Interface, Whois for NGTLDs
##
## Copyright (c) 2007,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::NGTLD;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Core::Status;
use Net::DRI::Protocol::Whois::Domain::common;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::NGTLD - Whois for new gTLDs

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2009,2012-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

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
 my ($po,$oname,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/whois',10,'Invalid domain name: '.$oname) unless Net::DRI::Util::is_hostname($oname);
 $mes->command(lc($oname));
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $rd=$mes->response_raw();
 $rinfo->{domain}->{$oname}->{action}='info';
 $rinfo->{domain}->{$oname}->{whois}=$rd;

 my $rr=standardize_keys($mes->response());
 $rinfo->{domain}->{$oname}->{exist}=exists($rr->{'name'})?1:0;
 return unless $rinfo->{domain}->{$oname}->{exist};
 
 $rinfo->{domain}->{$oname}->{id}=$rr->{'domain_id'}->[0];
 $rinfo->{domain}->{$oname}->{clIANA}=$rr->{'iana_id'}->[0] if $rr->{'iana_id'};
 $rinfo->{domain}->{$oname}->{clName}=$rr->{'registrar'}->[0] if $rr->{'registrar'};
 $rinfo->{domain}->{$oname}->{clWhois}=$rr->{'whois_server'}->[0] if $rr->{'whois_server'};
 $rinfo->{domain}->{$oname}->{clWebsite}=$rr->{'referral_url'}->[0] if $rr->{'referral_url'};
 $rinfo->{domain}->{$oname}->{clID}=$rr->{'registrar_id'}->[0] if $rr->{'registrar_id'};
 $rinfo->{domain}->{$oname}->{clStreet}=$rr->{'registrar_street'}->[0] if $rr->{'registrar_street'};
 $rinfo->{domain}->{$oname}->{clCity}=$rr->{'registrar_city'}->[0] if $rr->{'registrar_city'};
 $rinfo->{domain}->{$oname}->{clPC}=$rr->{'registrar_pc'}->[0] if $rr->{'registrar_pc'};
 $rinfo->{domain}->{$oname}->{clCC}=$rr->{'registrar_cc'}->[0] if $rr->{'registrar_cc'};
 $rinfo->{domain}->{$oname}->{clPhone}=$rr->{'registrar_phone'}->[0] if $rr->{'registrar_phone'};
 $rinfo->{domain}->{$oname}->{clFax}=$rr->{'registrar_fax'}->[0] if $rr->{'registrar_fax'};

 $rinfo->{domain}->{$oname}->{crDate}=$po->parse_iso8601($rr->{'created'}->[0]) if $rr->{'created'};
 $rinfo->{domain}->{$oname}->{upDate}=$po->parse_iso8601($rr->{'updated'}->[0]) if $rr->{'updated'};
 $rinfo->{domain}->{$oname}->{exDate}=$po->parse_iso8601($rr->{'expires'}->[0]) if $rr->{'expires'};
 $rinfo->{domain}->{$oname}->{wuDate}=$po->parse_iso8601($rr->{'last_update'}->[0]) if $rr->{'last_update'};

 $rinfo->{domain}->{$oname}->{status}=Net::DRI::Protocol::EPP::Core::Status->new($rr->{'status'});
 $rinfo->{domain}->{$oname}->{ns}=$po->create_local_object('hosts')->set(@{$rr->{'ns'}}) if exists($rr->{'ns'});
 Net::DRI::Protocol::Whois::Domain::common::epp_parse_contacts($po,$oname,$rr,$rinfo,{registrant => 'Registrant',admin => 'Admin', billing => 'Billing', tech => 'Tech'});

 $rinfo->{domain}->{$oname}->{dnssec}=$rr->{'dnssec'}->[0];

 return;
}

####################################################################################################
sub standardize_keys
{
  my ($in) = @_;
  my $rr;
  while( my($uk,$v) = each %{ $in }) 
  {
   my $k=lc($uk);
   $rr->{'domain_id'} = $v if $k =~ m/^(domain id)/;
   $rr->{'name'} = $v if $k =~ m/^(domain name)/;
   $rr->{'whois_server'} = $v if $k =~ m/^(whois server)/;
   $rr->{'referral_url'} = $v if $k =~ m/^(referral url|registrar url)/;
   $rr->{'registrar'} = $v if $k =~ m/^(sponsoring registrar)( organization)?$/;
   $rr->{'registrar_id'} = $v if $k =~ m/^sponsoring registrar id$/;
   $rr->{'registrar_street'} = $v if $k =~ m/^sponsoring registrar street/;
   $rr->{'registrar_city'} = $v if $k =~ m/^sponsoring registrar city/;
   $rr->{'registrar_pc'} = $v if $k =~ m/^sponsoring registrar postal/;
   $rr->{'registrar_cc'} = $v if $k =~ m/^sponsoring registrar country/;
   $rr->{'registrar_phone'} = $v if $k =~ m/^sponsoring registrar phone/;
   $rr->{'registrar_fax'} = $v if $k =~ m/^sponsoring registrar fax/;
   $rr->{'iana_id'} = $v if $k =~ m/iana/;
   @{$rr->{'status'}} = map { s/\s.*$//; $_ } @{$v} if $k =~ m/status$/;
   
   $rr->{'created'} = $v if $k =~ m/(created|creation|registered|registration) (date|on)?$/;
   $rr->{'updated'} = $v if $k =~ m/(last )?update(d)? (date|on)?$/ && $k !~ /whois/;
   $rr->{'expires'} = $v if $k =~ m/(expiry|expiration) date$/;
   $rr->{'last_update'} = $v if $k =~ m/whois database/ && $k =~/last update/;

   @{$rr->{'ns'}} = map { s/\s.*$//; $_ } @{$v} if $k =~ m/name ?server/;
   $rr->{'dnssec'} = $v if $k =~ m/dnssec/;

   # whois::common is case sensitive, so we need to use case sensive $uk for the keys
   if ($k =~ m/^(registrant|admin|administrative|billing|tech)/)
   {
    $uk =~ s/dministrative/dmin/i;
    $uk =~ s/echnical/ech/i;
    $uk =~ s/ contact//i;
    $rr->{$uk} = $v;
   }
  }
  $rr->{'last_update'}->[0] =~ s/\s.*$// if $rr->{'last_update'};
  #print Dumper $rr; 
  return $rr;
}
####################################################################################################

1;
