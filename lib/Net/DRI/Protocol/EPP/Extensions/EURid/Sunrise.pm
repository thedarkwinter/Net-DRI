## Domain Registry Interface, EURid Sunrise EPP extension for Net::DRI
## (from registration_guidelines_v1_0F-appendix2-sunrise.pdf )
##
## Copyright (c) 2005,2007-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise;

use strict;
use warnings;

use Email::Valid;
use DateTime::Format::ISO8601;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Extensions::EURid::Domain;
use Net::DRI::DRD::EURid;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise - EURid Sunrise EPP extension for Net::DRI

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

Copyright (c) 2005,2007-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=(
           apply  => [ \&apply, \&apply_parse ],
           apply_info   => [ \&info, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'sunrise' => [ 'http://www.eurid.eu/xml/epp/sunrise-1.0','sunrise-1.0.xsd' ] });
 return;
}

####################################################################################################

########### Query commands

sub info
{
 my ($epp,$reference)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('Apply_info action needs a reference') unless defined($reference) && $reference;
 Net::DRI::Exception::usererr_invalid_parameters('reference must be a xml normalizedstring from 1 to 100 characters long') unless Net::DRI::Util::xml_is_normalizedstring($reference,1,100);

 $mes->command(['apply-info','domain:apply-info',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain'))]);
 $mes->command_body([['domain:reference',$reference]]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('domain','appInfoData');
 return unless $infdata;

 my $cs=Net::DRI::Data::ContactSet->new();
 my $pd=DateTime::Format::ISO8601->new();
 my $c=$infdata->firstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->nodeName();
  next unless $name;

  if ($name=~m/^domain:(name|reference|code)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->firstChild->getData();
  } elsif ($name eq 'domain:status')
  {
   $rinfo->{domain}->{$oname}->{application_status}=$c->firstChild->getData();
  } elsif ($name=~m/^domain:(crDate|docsReceivedDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$pd->parse_datetime($c->firstChild->getData());
  } elsif ($name eq 'domain:registrant')
  {
   $cs->set($po->create_local_object('contact')->srid($c->firstChild->getData()),'registrant');
  } elsif ($name eq 'domain:contact')
  {
   $cs->add($po->create_local_object('contact')->srid($c->firstChild->getData()),$c->getAttribute('type'));
  } elsif ($name eq 'domain:ns')
  {
   $rinfo->{domain}->{$oname}->{ns}=Net::DRI::Protocol::EPP::Util::parse_ns($po,$c);
  } elsif ($name eq 'domain:adr')
  {
   $rinfo->{domain}->{$oname}->{adr}=Net::DRI::Util::xml_parse_boolean($c->firstChild->getData());
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{contact}=$cs;
 return;
}

############ Transform commands

sub apply
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'apply',$domain);

 Net::DRI::Exception::usererr_insufficient_parameters('Apply action needs parameters') unless (defined($rd) && (ref($rd) eq 'HASH'));
 my @need=grep { !(exists($rd->{$_}) && $rd->{$_}) } qw/reference right prior-right-on-name prior-right-country documentaryevidence evidence-lang/;
 Net::DRI::Exception::usererr_insufficient_parameters('The following parameters are needed: '.join(' ',@need)) if @need;

 Net::DRI::Exception::usererr_invalid_parameters('reference must be a xml normalizedstring from 1 to 100 characters long') unless Net::DRI::Util::xml_is_normalizedstring($rd->{reference},1,100);
 push @d,['domain:reference',$rd->{reference}];

 Net::DRI::Exception::usererr_invalid_parameters('right must be PUBLICBODY, REG-TM-NAT, REG-TM-COM-INTL, GEO-DOO, COMP-ID, UNREG-TM, TITLES-ART, OTHER') unless ($rd->{right}=~m/^(?:PUBLICBODY|REG-TM-NAT|REG-TM-COM-INTL|GEO-DOO|COMP-ID|UNREG-TM|TITLES-ART|OTHER)/);
 push @d,['domain:right',$rd->{right}];

 Net::DRI::Exception::usererr_invalid_parameters('prior-right-on-name must be a xml token from 1 to 255 characters long') unless Net::DRI::Util::xml_is_token($rd->{'prior-right-on-name'},1,255);
 push @d,['domain:prior-right-on-name',$rd->{'prior-right-on-name'}];

 Net::DRI::Exception::usererr_invalid_parameters('prior-right-country must be a CC of EU member') unless (length($rd->{'prior-right-country'})==2 && exists($Net::DRI::DRD::EURid::CCA2_EU{uc($rd->{'prior-right-country'})})); ####
 push @d,['domain:prior-right-country',uc($rd->{'prior-right-country'})];

 Net::DRI::Exception::usererr_invalid_parameters('documentaryevidence must be applicant, registrar or thirdparty') unless $rd->{documentaryevidence}=~m/^(?:applicant|registrar|thirdparty)$/;
 if ($rd->{documentaryevidence} eq 'thirdparty')
 {
  Net::DRI::Exception::usererr_invalid_parameters('documentaryevidence_email must be a valid email address') unless (defined($rd->{documentaryevidence_email}) && Email::Valid->rfc822($rd->{documentaryevidence_email}));
  push @d,['domain:documentaryevidence',['domain:thirdparty',$rd->{documentaryevidence_email}]];
 } else
 {
  push @d,['domain:documentaryevidence',['domain:'.$rd->{documentaryevidence}]];
 }

 Net::DRI::Exception::usererr_invalid_parameters('evidence-lang must be a lang of EU member') unless (length($rd->{'evidence-lang'})==2 && exists($Net::DRI::DRD::EURid::LANGA2_EU{lc($rd->{'evidence-lang'})})); ####
 push @d,['domain:evidence-lang',lc($rd->{'evidence-lang'})];


 ## Nameservers, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain,'domain') if Net::DRI::Util::has_ns($rd);

 ## Contacts, all OPTIONAL
 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o);
  push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs);
 }

 $mes->command_body(\@d);

 ## Nameserver groups
 if (exists($rd->{nsgroup}))
 {
  my @n=Net::DRI::Protocol::EPP::Extensions::EURid::Domain::add_nsgroup($rd->{nsgroup});
  my $eid=Net::DRI::Protocol::EPP::Extensions::EURid::Domain::build_command_extension($mes,$epp,'eurid:ext');
  $mes->command_extension($eid,['eurid:apply',['eurid:domain',@n]]);
 }
 return;
}

sub apply_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 $rinfo->{_internal}->{must_reconnect}=1; ## All apply commands (successful or not) close the connection
 return unless $mes->is_success();

 my $credata=$mes->get_response('domain','appData');
 return unless $credata;

 $rinfo->{domain}->{$oname}->{exist}=1;

 my $c=$credata->firstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->nodeName();
  next unless $name;

  if ($name=~m/^domain:(name|reference|code)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->firstChild->getData();
  } elsif ($name=~m/^domain:(crDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

####################################################################################################
1;
