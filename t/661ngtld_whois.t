#!/usr/bin/perl

use strict;
use warnings;
use Net::DRI;
use Data::Dumper;

use Test::More tests => 506;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : ''); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
my ($rc,$s,$h,@hs,$c,$r);

####################################################################################################
# Afnic
$R2='Domain Name: nic.paris
Domain ID: DOM000000000002-PARIS
WHOIS Server: whois.nic.paris
Referral URL: http://mondomaine.paris.fr
Updated Date: 2014-02-13T16:45:56Z
Creation Date: 2014-02-13T16:45:56Z
Registry Expiry Date: 2015-02-13T16:45:56Z
Sponsoring Registrar: Registry Operations
Sponsoring Registrar IANA ID: 9999
Domain Status: ok
Registrant ID: NP101-PARIS
Registrant Name: Ville de Paris
Registrant Street: 4, rue Lobau
Registrant City: Paris
Registrant Postal Code: 75004
Registrant Country: FR
Registrant Phone: +33.143476538
Registrant Email: support@afnic.fr
Admin ID: NP101-PARIS
Admin Name: Ville de Paris
Admin Street: 4, rue Lobau
Admin City: Paris
Admin Postal Code: 75004
Admin Country: FR
Admin Phone: +33.143476538
Admin Email: support@afnic.fr
Tech ID: NP101-PARIS
Tech Name: Ville de Paris
Tech Street: 4, rue Lobau
Tech City: Paris
Tech Postal Code: 75004
Tech Country: FR
Tech Phone: +33.143476538
Tech Email: support@afnic.fr
Name Server: ns1.nic.fr
Name Server: ns2.nic.fr
Name Server: ns3.nic.fr
DNSSEC: signedDelegation

Rights restricted by copyright.
See http://www.afnic.fr/afnic/web/mentions-legales-whois_en';

$dri->add_registry('NGTLD',{provider=>'afnic','name'=>'paris'});
$dri->target('paris')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.paris');
is($rc->is_success(),1,'AFNIC domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.paris','domain_info get_info (name)');
is($dri->get_info('id'),'DOM000000000002-PARIS','domain_info get_info (id)');
is($dri->get_info('clName'),'Registry Operations','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.nic.paris','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://mondomaine.paris.fr','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2014-02-13T16:45:56','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-02-13T16:45:56','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-02-13T16:45:56','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),undef,'domain_info get_info (wuDate)'); # They don't seem to give this?
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.nic.fr','ns2.nic.fr','ns3.nic.fr'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'NP101-PARIS','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'NP101-PARIS','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'NP101-PARIS','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Ville de Paris','domain_info get_info (contact) registrant name');
is($r->org(),undef,'domain_info get_info (contact) registrant org');

####################################################################################################
# Afilias
$R2='Domain Name:NIC.PINK
Domain ID: D51961279-LRMS
Creation Date: 2014-03-14T16:20:28Z
Updated Date: 2014-05-13T20:31:49Z
Registry Expiry Date: 2015-03-14T16:20:28Z
Sponsoring Registrar:Afilias (R719-LRMS)
Sponsoring Registrar IANA ID: 800219
WHOIS Server: whois.afilias.net
Referral URL: http://www.afilias.net/
Domain Status: ok
Registrant ID:800218-Reserved
Registrant Name:Afilias Ltd.
Registrant Organization:Afilias Ltd.
Registrant Street: 2 La Touche House
Registrant City:Dublin
Registrant State/Province:
Registrant Postal Code:1
Registrant Country:IE
Registrant Phone:+353.18541100
Registrant Phone Ext: 
Registrant Fax: +1.2157065701
Registrant Fax Ext: 
Registrant Email:support@afilias.info
Admin ID:800218-Reserved
Admin Name:Afilias Ltd.
Admin Organization:Afilias Ltd.
Admin Street: 2 La Touche House
Admin City:Dublin
Admin State/Province:
Admin Postal Code:1
Admin Country:IE
Admin Phone:+353.18541100
Admin Phone Ext: 
Admin Fax: +1.2157065701
Admin Fax Ext: 
Admin Email:support@afilias.info
Tech ID:800218-Reserved
Tech Name:Afilias Ltd.
Tech Organization:Afilias Ltd.
Tech Street: 2 La Touche House
Tech City:Dublin
Tech State/Province:
Tech Postal Code:1
Tech Country:IE
Tech Phone:+353.18541100
Tech Phone Ext: 
Tech Fax: +1.2157065701
Tech Fax Ext: 
Tech Email:support@afilias.info
Name Server:A0.NIC.PINK
Name Server:A2.NIC.PINK
Name Server:B0.NIC.PINK
Name Server:C0.NIC.PINK
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
DNSSEC:Unsigned

Access to AFILIAS WHOIS information is provided to assist persons in determining the contents of a domain name registration record in the Afilias registry database. The data in this record is provided by Afilias Limited for informational purposes only, and Afilias does not guarantee its accuracy.  This service is intended only for query-based access. You agree that you will use this data only for lawful purposes and that, under no circumstances will you use this data to(a) allow, enable, or otherwise support the transmission by e-mail, telephone, or facsimile of mass unsolicited, commercial advertising or solicitations to entities other than the data recipient\'s own existing customers; or (b) enable high volume, automated, electronic processes that send queries or data to the systems of Registry Operator, a Registrar, or Afilias except as reasonably necessary to register domain names or modify existing registrations. All rights reserved. Afilias reserves the right to modify these terms at any time. By submitting this query, you agree to abide by this policy.';

$dri->add_registry('NGTLD',{provider=>'afilias'});
$dri->target('afilias')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.pink');
is($rc->is_success(),1,'AFILIAS domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.pink','domain_info get_info (name)');
is($dri->get_info('id'),'D51961279-LRMS','domain_info get_info (id)');
is($dri->get_info('clName'),'Afilias (R719-LRMS)','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'800219','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.afilias.net','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.afilias.net/','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2014-03-14T16:20:28','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-05-13T20:31:49','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-03-14T16:20:28','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),undef,'domain_info get_info (wuDate)'); # They don't seem to give this?
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a0.nic.pink','a2.nic.pink','b0.nic.pink','c0.nic.pink'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'800218-Reserved','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'800218-Reserved','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'800218-Reserved','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Afilias Ltd.','domain_info get_info (contact) registrant name');
is($r->org(),'Afilias Ltd.','domain_info get_info (contact) registrant org');


####################################################################################################
# ARI

$R2='Domain Name: nic.build
Domain ID: D215DA75E3E0A4133AE5DD1B3BE26C3E6-ARI
WHOIS Server: whois.aridnrs.net.au
Referral URL: http://www.aridnrs.net.au/
Updated Date: 2013-11-21T04:33:41Z
Creation Date: 2013-11-19T02:41:04Z
Registry Expiry Date: 2023-11-19T02:41:04Z
Sponsoring Registrar: Plan Bee LLC
Sponsoring Registrar IANA ID: 9999
Domain Status: ok
Registrant ID: C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI
Registrant Name: Plan Bee LLC
Registrant Organization: 
Registrant Street: 2800 28th St. Suite 170
Registrant Street: 
Registrant Street: 
Registrant City: Santa Monica
Registrant State/Province: 
Registrant Postal Code: 
Registrant Country: us
Registrant Phone: 
Registrant Phone Ext: 
Registrant Fax: 
Registrant Fax Ext: 
Registrant Email: George@dotbuild.co
Admin ID: C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI
Admin Name: Plan Bee LLC
Admin Organization: 
Admin Street: 2800 28th St. Suite 170
Admin Street: 
Admin Street: 
Admin City: Santa Monica
Admin State/Province: 
Admin Postal Code: 
Admin Country: us
Admin Phone: 
Admin Phone Ext: 
Admin Fax: 
Admin Fax Ext: 
Admin Email: George@dotbuild.co
Tech ID: C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI
Tech Name: Plan Bee LLC
Tech Organization: 
Tech Street: 2800 28th St. Suite 170
Tech Street: 
Tech Street: 
Tech City: Santa Monica
Tech State/Province: 
Tech Postal Code: 
Tech Country: us
Tech Phone: 
Tech Phone Ext: 
Tech Fax: 
Tech Fax Ext: 
Tech Email: George@dotbuild.co
Name Server: a.nic.build
Name Server: b.nic.build
Name Server: c.nic.build
Name Server: d.nic.build
DNSSEC: signedDelegation
>>> Last update of WHOIS database: 2014-05-27T09:29:20Z <<<

The Service is provided so that you may look up certain information in relation to domain names that we store in our database.

Use of the Service is subject to our policies, in particular you should familiarise yourself with our Acceptable Use Policy and our Privacy Policy.

The information provided by this Service is \'as is\' and we make no guarantee of it its accuracy.

You agree that by your use of the Service you will not use the information provided by us in a way which is:
* inconsistent with any applicable laws, 
* inconsistent with any policy issued by us, 
* to generate, distribute, or facilitate unsolicited mass email, promotions, advertisings or other solicitations, or 
* to enable high volume, automated, electronic processes that apply to the Service.

You acknowledge that:
* a response from the Service that a domain name is \'available\', does not guarantee that is able to be registered, 
* we may restrict, suspend or terminate your access to the Service at any time, and 
* the copying, compilation, repackaging, dissemination or other use of the information provided by the Service is not permitted, without our express written consent.

This information has been prepared and published in order to represent administrative and technical management of the TLD.

We may discontinue or amend any part or the whole of these Terms of Service from time to time at our absolute discretion.';

$dri->add_registry('NGTLD',{provider=>'ari'});
$dri->target('ari')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.build');
is($rc->is_success(),1,'ARI domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.build','domain_info get_info (name)');
is($dri->get_info('id'),'D215DA75E3E0A4133AE5DD1B3BE26C3E6-ARI','domain_info get_info (id)');
is($dri->get_info('clName'),'Plan Bee LLC','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.aridnrs.net.au','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.aridnrs.net.au/','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-11-19T02:41:04','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2013-11-21T04:33:41','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2023-11-19T02:41:04','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-27T09:29:20','domain_info get_info (wuDate)'); # They don't seem to give this?
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a.nic.build','b.nic.build','c.nic.build','d.nic.build'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'C5BB57F68FC594A56A7ABB5573DF2FE1C-ARI','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Plan Bee LLC','domain_info get_info (contact) registrant name');
is($r->org(),undef,'domain_info get_info (contact) registrant org');


####################################################################################################
# Centralnic
$R2='Domain ID:CNIC-DO1465579
Domain Name:NIC.WIKI
Created On:2013-09-11T11:57:19.0Z
Last Updated On:2014-03-28T15:17:00.0Z
Expiration Date:2014-09-11T23:59:59.0Z
Status:serverTransferProhibited
Status:serverUpdateProhibited
Status:serverDeleteProhibited
Status:serverRenewProhibited
Registrant ID:C11480
Registrant Name:Domain Administrator
Registrant Organization:CentralNic Ltd
Registrant Street1:35-39 Moorgate
Registrant City:London
Registrant Postal Code:EC2R 6AR
Registrant Country:GB
Registrant Phone:+44.8700170900
Registrant Fax:+44.8700170901
Registrant Email:domains@centralnic.com
Admin ID:C11480
Admin Name:Domain Administrator
Admin Organization:CentralNic Ltd
Admin Street1:35-39 Moorgate
Admin City:London
Admin Postal Code:EC2R 6AR
Admin Country:GB
Admin Phone:+44.8700170900
Admin Fax:+44.8700170901
Admin Email:domains@centralnic.com
Tech ID:C11480
Tech Name:Domain Administrator
Tech Organization:CentralNic Ltd
Tech Street1:35-39 Moorgate
Tech City:London
Tech Postal Code:EC2R 6AR
Tech Country:GB
Tech Phone:+44.8700170900
Tech Fax:+44.8700170901
Tech Email:domains@centralnic.com
Billing ID:C11480
Billing Name:Domain Administrator
Billing Organization:CentralNic Ltd
Billing Street1:35-39 Moorgate
Billing City:London
Billing Postal Code:EC2R 6AR
Billing Country:GB
Billing Phone:+44.8700170900
Billing Fax:+44.8700170901
Billing Email:domains@centralnic.com
Sponsoring Registrar ID:C11480
Sponsoring Registrar IANA ID:9999
Sponsoring Registrar Organization:CentralNic Ltd
Sponsoring Registrar Street1:35-39 Moorgate
Sponsoring Registrar City:London
Sponsoring Registrar Postal Code:EC2R 6AR
Sponsoring Registrar Country:GB
Sponsoring Registrar Phone:+44.8700170900
Sponsoring Registrar Fax:+44.8700170901
Sponsoring Registrar Website:http://www.centralnic.com/
Referral URL:http://www.centralnic.com/
WHOIS Server:whois.centralnic.com
Name Server:NS0.NIC.WIKI
Name Server:NS1.NIC.WIKI
Name Server:NS2.NIC.WIKI
Name Server:NS3.NIC.WIKI
Name Server:NS4.NIC.WIKI
Name Server:NS5.NIC.WIKI
DNSSEC:Unsigned
>>> Last update of WHOIS database: 2014-05-27T09:37:40.0Z <<<

This whois service is provided by CentralNic Ltd and only contains
information pertaining to Internet domain names we have registered for
our customers. By using this service you are agreeing (1) not to use any
information presented here for any purpose other than determining
ownership of domain names, (2) not to store or reproduce this data in 
any way, (3) not to use any high-volume, automated, electronic processes
to obtain data from this service. Abuse of this service is monitored and
actions in contravention of these terms will result in being permanently
blacklisted. All data is (c) CentralNic Ltd https://www.centralnic.com/';

$dri->add_registry('NGTLD',{provider=>'centralnic'});
$dri->target('centralnic')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.wiki');
is($rc->is_success(),1,'CENTRALNIC domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.wiki','domain_info get_info (name)');
is($dri->get_info('id'),'CNIC-DO1465579','domain_info get_info (id)');
is($dri->get_info('clName'),'CentralNic Ltd','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.centralnic.com','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.centralnic.com/','domain_info get_info (clWebsite)');
is($dri->get_info('clID'),'C11480','domain_info get_info (clID)');
is($dri->get_info('clStreet'),'35-39 Moorgate','domain_info get_info (clStreet)');
is($dri->get_info('clCity'),'London','domain_info get_info (clCity)');
is($dri->get_info('clPC'),'EC2R 6AR','domain_info get_info (clPC)');
is($dri->get_info('clCC'),'GB','domain_info get_info (clCC)');
is($dri->get_info('clPhone'),'+44.8700170900','domain_info get_info (clPhone)');
is($dri->get_info('clFax'),'+44.8700170901','domain_info get_info (clFax)');

$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverRenewProhibited','serverTransferProhibited','serverUpdateProhibited'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-09-11T11:57:19','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-03-28T15:17:00','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2014-09-11T23:59:59','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-27T09:37:40','domain_info get_info (wuDate)'); # They don't seem to give this?
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns0.nic.wiki','ns1.nic.wiki','ns2.nic.wiki','ns3.nic.wiki','ns4.nic.wiki','ns5.nic.wiki'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'C11480','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'C11480','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'C11480','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'C11480','domain_info get_info (contact) billing srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Domain Administrator','domain_info get_info (contact) registrant name');
is($r->org(),'CentralNic Ltd','domain_info get_info (contact) registrant org');

####################################################################################################
# CoreNIC / Tango-RS
$R2='% Copyright (c) 2014 by CORE Association
% 
% Restricted rights.
%
Domain ID: 8-D
Domain Name: nic.??????
Domain Name ACE: nic.xn--80asehdb
Update Date: 2013-12-18T14:00:51.491Z
Creation Date: 2013-08-02T11:15:21.320Z
Sponsoring Registrar: Registry self-allocated
Sponsoring Registrar IANA ID: 9999
Registrant ID: REG-C10
Registrant Name: CORE DNS
Registrant Organization: CORE Association
Registrant Street: World Trade Center II - 29,
Registrant Street: route de Pre-Bois
Registrant City: Geneva
Registrant Postal Code: CH-1215
Registrant Country: CH
Registrant Email: support@coreregistry.net
Admin ID: REG-C10
Admin Name: CORE DNS
Admin Organization: CORE Association
Admin Street: World Trade Center II - 29,
Admin Street: route de Pre-Bois
Admin City: Geneva
Admin Postal Code: CH-1215
Admin Country: CH
Admin Email: support@coreregistry.net
Tech ID: REG-C10
Tech Name: CORE DNS
Tech Organization: CORE Association
Tech Street: World Trade Center II - 29,
Tech Street: route de Pre-Bois
Tech City: Geneva
Tech Postal Code: CH-1215
Tech Country: CH
Tech Email: support@coreregistry.net
Billing ID: REG-C10
Billing Name: CORE DNS
Billing Organization: CORE Association
Billing Street: World Trade Center II - 29,
Billing Street: route de Pre-Bois
Billing City: Geneva
Billing Postal Code: CH-1215
Billing Country: CH
Billing Email: support@coreregistry.net
Name Server: anycast24.irondns.net
Name Server: anycast23.irondns.net
Name Server: anycast10.irondns.net
Name Server: anycast9.irondns.net
Registry Expiry Date: 2014-08-02T11:15:21.320Z
Domain Status: ok
DNSSEC: signedDelegation
Last update of Whois database: 2014-05-27T12:38:38.659Z
%
% WARNING: Some characters of the response above could not be encoded using
% the current character set. The affected characters have been replaced by
% question marks ("?"). Use the -C query option to specify a character set
% capable of encoding more characters, such as UTF-8.
%
% Terms and Conditions of Use
% 
% The data in this record is provided by CORE for informational purposes
% only. CORE does not guarantee its accuracy and cannot, under any
% circumstances, be held liable in case the stored information would prove
% to be wrong, incomplete or not accurate in any sense.
% 
% All the domain data that is visible in the Whois service is protected by
% law. It is not permitted to use it for any purpose other than technical or
% administrative requirements associated with the operation of the Internet.
% It is explicitly forbidden to extract, copy and/or use or re-utilise in
% any form and by any means (electronically or not) the whole or a
% quantitatively or qualitatively substantial part of the contents of the
% Whois database without prior and explicit written permission by CORE.
% It is prohibited, in particular, to use it for transmission of unsolicited
% and/or commercial and/or advertising by phone, fax, e-mail or for any
% similar purposes.
% 
% By maintaining the connection you assure that you have a legitimate
% interest in the data and that you will only use it for the stated
% purposes. You are aware that CORE maintains the right to initiate legal
% proceedings against you in the event of any breach of this assurance and
% to bar you from using its Whois service.
%
% End of Whois record.
';

$dri->add_registry('NGTLD',{provider=>'corenic',name=>'xn--80asehdb'});
$dri->target('xn--80asehdb')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.xn--80asehdb');
is($rc->is_success(),1,'CORENIC domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.xn--80asehdb','domain_info get_info (name)');
is($dri->get_info('id'),'8-D','domain_info get_info (id)');
is($dri->get_info('clName'),'Registry self-allocated','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),undef,'domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),undef,'domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-08-02T11:15:21','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2013-12-18T14:00:51','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2014-08-02T11:15:21','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-27T12:38:38','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['anycast24.irondns.net','anycast23.irondns.net','anycast10.irondns.net','anycast9.irondns.net'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'REG-C10','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'REG-C10','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'REG-C10','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'REG-C10','domain_info get_info (contact) billing srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'CORE DNS','domain_info get_info (contact) registrant name');
is($r->org(),'CORE Association','domain_info get_info (contact) registrant org');

####################################################################################################
# CNNIC
$R2='Domain Name: nic.佛山
Puny Name: nic.xn--1qqw23a
Domain ID: 3591
WHOIS Server: 218.241.97.61
Referral URL: http://whois.ngtld.cn
Updated Date: 2014-08-20T16:05:02Z
Creation Date: 2014-08-15T04:12:59Z
Registry Expiry Date: 2019-08-15T04:12:59Z
Sponsoring Registrar: IANA9999
Sponsoring Registrar IANA ID: 9999
Domain Status: ok
Registrant ID: 9999-contact-001
Registrant Name: 张黎
Registrant Organization: 广州誉威信息科技有限公司
Registrant Street: 广州市天河区林和西路1号国际贸易中心3302
Registrant City: guangzhou
Registrant State/Province: guangdong
Registrant Postal Code: 510000
Registrant Country: cn
Registrant Phone: +86.1058813170
Registrant Fax: +86.1058812666
Registrant Email: zhangli@cnnic.cn
Admin ID: 9999-contact-001
Admin Name: 张黎
Admin Organization: 广州誉威信息科技有限公司
Admin Street: 广州市天河区林和西路1号国际贸易中心3302
Admin City: guangzhou
Admin State/Province: guangdong
Admin Postal Code: 510000
Admin Country: cn
Admin Phone: +86.1058813170
Admin Fax: +86.1058812666
Admin Email: zhangli@cnnic.cn
Tech ID: 9999-contact-001
Tech Name: 张黎
Tech Organization: 广州誉威信息科技有限公司
Tech Street: 广州市天河区林和西路1号国际贸易中心3302
Tech City: guangzhou
Tech State/Province: guangdong
Tech Postal Code: 510000
Tech Country: cn
Tech Phone: +86.1058813170
Tech Fax: +86.1058812666
Tech Email: zhangli@cnnic.cn
Name Server: ta.ngtld.cn
Name Server: tb.ngtld.cn
Name Server: tc.ngtld.cn
Name Server: td.ngtld.cn
Name Server: te.ngtld.cn
DNSSEC: unsigned
>>> Last update of WHOIS database: 2014-09-08T13:13:12Z <<<

Disclaimer: The data contained in China Internet Network Information Center\'s("CNNIC") WhoIs database is 
provided for the sole purpose of assisting you in obtaining information about or related to a domain name registration record. 
CNNIC provides the data in accordance with the registration record, but does not guarantee its accuracy. 
By submitting a WHOIS query, you agree that you will use this Data only for lawful purposes and that, under no circumstances will you: 
(1) use electronic processes that are automated and high-volume to access or query the Whois database; 
(2)support the transmission of mass unsolicited, commercial advertising or solicitations via facsimile, e-mail and telephone. 
Without the prior written consent of CNNIC, the compilation, repackaging and dissemination of this Data is expressly prohibited.
CNNIC reserves the right to modify these terms at any time. By submitting this query, you agree to abide by this policy.';

$dri->add_registry('NGTLD',{provider=>'cnnic'});
$dri->target('cnnic')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.xn--1qqw23a');
is($rc->is_success(),1,'CNNIC domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.xn--1qqw23a','domain_info get_info (name)');
is($dri->get_info('id'),'3591','domain_info get_info (id)');
is($dri->get_info('clName'),'IANA9999','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'218.241.97.61','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://whois.ngtld.cn','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2014-08-15T04:12:59','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-08-20T16:05:02','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2019-08-15T04:12:59','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-09-08T13:13:12','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ta.ngtld.cn','tb.ngtld.cn','tc.ngtld.cn','td.ngtld.cn','te.ngtld.cn'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'9999-contact-001','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'9999-contact-001','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'9999-contact-001','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'张黎','domain_info get_info (contact) registrant name');
is($r->org(),'广州誉威信息科技有限公司','domain_info get_info (contact) registrant org');

####################################################################################################
# CoCCA
SKIP: {
  skip '*** TODO : CoCCA',1;
};

####################################################################################################
# Charleston Road Registry

$R2='Domain Name: nic.xn--q9jyb4c
Domain ID: cc971-roid
WHOIS Server: whois.nic.xn--q9jyb4c
Referral URL: http://nic.xn--q9jyb4c/
Updated Date: 2013-12-03T18:39:49Z
Creation Date: 2013-12-03T18:39:49Z
Registry Expiry Date: 2014-12-03T18:39:49Z
Sponsoring Registrar: Charleston Road Registry
Sponsoring Registrar IANA ID: 9999
Domain Status: ok
Registrant ID: crr-admin
Registrant Name: CRR Admin
Registrant Organization: Charleston Road Registry, Inc.
Registrant Street: 1600 Amphitheatre Parkway
Registrant Street:
Registrant City: Mountain View
Registrant State/Province: CA
Registrant Postal Code: 94043
Registrant Country: US
Registrant Phone: +1.6502531318
Registrant Phone Ext:
Registrant Fax: +1.6502530001
Registrant Fax Ext:
Registrant Email: legal@charlestonroadregistry.com
Admin ID: crr-admin
Admin Name: CRR Admin
Admin Organization: Charleston Road Registry, Inc.
Admin Street: 1600 Amphitheatre Parkway
Admin Street:
Admin City: Mountain View
Admin State/Province: CA
Admin Postal Code: 94043
Admin Country: US
Admin Phone: +1.6502531318
Admin Phone Ext:
Admin Fax: +1.6502530001
Admin Fax Ext:
Admin Email: legal@charlestonroadregistry.com
Tech ID: crr-tech
Tech Name: CRR Tech
Tech Organization: Charleston Road Registry, Inc.
Tech Street: 1600 Amphitheatre Parkway
Tech Street:
Tech City: Mountain View
Tech State/Province: CA
Tech Postal Code: 94043
Tech Country: US
Tech Phone: +1.6502531318
Tech Phone Ext:
Tech Fax: +1.6502530001
Tech Fax Ext:
Tech Email: crr-tech@google.com
Name Server: ns1.google.com
Name Server: ns2.google.com
Name Server: ns3.google.com
Name Server: ns4.google.com
DNSSEC: unsigned
>>> Last update of WHOIS database: 2014-05-27T14:54:59Z <<<

WHOIS information is provided by Charleston Road Registry Inc. (CRR) solely for
query-based, informational purposes. By querying our WHOIS database, you are
agreeing to comply with these terms
(http://www.google.com/registry/whois-disclaimer.html) so please read them
carefully.  Any information provided is "as is" without any guarantee of
accuracy. You may not use such information to (a) allow, enable, or otherwise
support the transmission of mass unsolicited, commercial advertising or
solicitations; (b) enable high volume, automated, electronic processes that
access the systems of CRR or any ICANN-Accredited Registrar, except as
reasonably necessary to register domain names or modify existing registrations;
or (c) engage in or support unlawful behavior. CRR reserves the right to
restrict or deny your access to the Whois database, and may modify these terms
at any time.';

#$dri->add_registry('NGTLD',{provider=>'crr',tlds=>['xn--q9jyb4c']});
#$dri->target('crr')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->add_registry('CRR'); # For fun we are going to go old school DRD on this
$dri->target('CRR')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});

$rc = $dri->domain_info('nic.xn--q9jyb4c');
is($rc->is_success(),1,'CRR domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.xn--q9jyb4c','domain_info get_info (name)');
is($dri->get_info('id'),'cc971-roid','domain_info get_info (id)');
is($dri->get_info('clName'),'Charleston Road Registry','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.nic.xn--q9jyb4c','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://nic.xn--q9jyb4c/','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-12-03T18:39:49','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2013-12-03T18:39:49','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2014-12-03T18:39:49','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-27T14:54:59','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.google.com','ns2.google.com','ns3.google.com','ns4.google.com'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'crr-admin','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'crr-admin','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'crr-tech','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'CRR Admin','domain_info get_info (contact) registrant name');
is($r->org(),'Charleston Road Registry, Inc.','domain_info get_info (contact) registrant org');


####################################################################################################
# Donuts
$R2='Domain Name: nic.photography
Domain ID: 542caf866e6c4d198b3f2d98bb3554ed-D
WHOIS Server: http://whois.donuts.co
Referral URL: http://www.donuts.co
Updated Date: 2014-04-02T19:04:00Z
Creation Date: 2013-10-02T17:56:35Z
Registry Expiry Date: 2015-10-02T17:56:35Z
Sponsoring Registrar: Donuts Internal (9999)
Sponsoring Registrar IANA ID: 9999
DomainStatus: ok
Registrant ID: id01
Registrant Name: Chris Cowherd
Registrant Organization: Donuts Inc.
Registrant Street: 10500 NE 8th St Suite 350  
Registrant City: Bellevue
Registrant State/Province: WA
Registrant Postal Code: 98004
Registrant Country: US
Registrant Phone: 
Registrant Phone Ext: 
Registrant Fax: 
Registrant Fax Ext: 
Registrant Email: it@donuts.co
Admin ID: id01
Admin Name: Chris Cowherd
Admin Organization: Donuts Inc.
Admin Street: 10500 NE 8th St Suite 350  
Admin City: Bellevue
Admin State/Province: WA
Admin Postal Code: 98004
Admin Country: US
Admin Phone: 
Admin Phone Ext: 
Admin Fax: 
Admin Fax Ext: 
Admin Email: it@donuts.co
Tech ID: id01
Tech Name: Chris Cowherd
Tech Organization: Donuts Inc.
Tech Street: 10500 NE 8th St Suite 350  
Tech City: Bellevue
Tech State/Province: WA
Tech Postal Code: 98004
Tech Country: US
Tech Phone: 
Tech Phone Ext: 
Tech Fax: 
Tech Fax Ext: 
Tech Email: it@donuts.co
Name Server: pdns86.ultradns.com
Name Server: pdns86.ultradns.biz
DNSSEC: unsigned

>>> Last update of WHOIS database: 2014-05-13T13:04:55Z <<<

Terms of Use: Users accessing the Donuts WHOIS service must agree to use the data only for lawful purposes, and under under no circumstances use the data to: Allow, enable, or otherwise support the transmission by e-mail, telephone, or facsimile of mass unsolicited, commercial advertising or solicitations to entities other than the registrar\'s own existing customers. Enable high volume, automated, electronic processes that send queries or data to the systems of Donuts or any ICANN-accredited registrar, except as reasonably necessary to register domain names or modify existing registrations. When using the Donuts Whois service, please consider the following: The Whois service is not a replacement for standard EPP commands to the SRS service. Whois is not considered authoritative for registered domain objects. The Whois service may be scheduled for downtime during production or OT&E maintenance periods. Queries to the Whois services are throttled. If too many queries are received from a single IP address within a specified time, the service will begin to reject further queries for a period of time to prevent disruption of Whois service access.';
$dri->add_registry('NGTLD',{provider=>'donuts'});
$dri->target('donuts')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.photography');
is($rc->is_success(),1,'DONUTS domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.photography','domain_info get_info (name)');
is($dri->get_info('id'),'542caf866e6c4d198b3f2d98bb3554ed-D','domain_info get_info (id)');
is($dri->get_info('clName'),'Donuts Internal (9999)','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'http://whois.donuts.co','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.donuts.co','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-10-02T17:56:35','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-04-02T19:04:00','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-10-02T17:56:35','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-13T13:04:55','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['pdns86.ultradns.com','pdns86.ultradns.biz'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'id01','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'id01','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'id01','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Chris Cowherd','domain_info get_info (contact) registrant name');
is($r->org(),'Donuts Inc.','domain_info get_info (contact) registrant org');

####################################################################################################
# Famous Four / Neustar
$R2='Domain Name:                                 NIC.TRADE
Domain ID:                                   D313-TRADE
Sponsoring Registrar:                        NEUSTAR Organization
Sponsoring Registrar IANA ID:                9999
Registrar URL (registration services):       www.neustar.co
Domain Status:                               serverDeleteProhibited
Domain Status:                               serverTransferProhibited
Domain Status:                               serverUpdateProhibited

Registrant ID:                               NICCONTACT1
Registrant Name:                             Neustar, Inc.
Registrant Address1:                         21575 Ridgetop Cir
Registrant City:                             Sterling
Registrant State/Province:                   VA
Registrant Postal Code:                      20166
Registrant Country:                          United States
Registrant Country Code:                     US
Registrant Phone Number:                     +1.5714345400
Registrant Email:                            support@neustar.biz

Administrative Contact ID:                   NICCONTACT1
Administrative Contact Name:                 Neustar, Inc.
Administrative Contact Address1:             21575 Ridgetop Cir
Administrative Contact City:                 Sterling
Administrative Contact State/Province:       VA
Administrative Contact Postal Code:          20166
Administrative Contact Country:              United States
Administrative Contact Country Code:         US
Administrative Contact Phone Number:         +1.5714345400
Administrative Contact Email:                support@neustar.biz

Billing Contact ID:                          NICCONTACT1
Billing Contact Name:                        Neustar, Inc.
Billing Contact Address1:                    21575 Ridgetop Cir
Billing Contact City:                        Sterling
Billing Contact State/Province:              VA
Billing Contact Postal Code:                 20166
Billing Contact Country:                     United States
Billing Contact Country Code:                US
Billing Contact Phone Number:                +1.5714345400
Billing Contact Email:                       support@neustar.biz

Technical Contact ID:                        NICCONTACT1
Technical Contact Name:                      Neustar, Inc.
Technical Contact Address1:                  21575 Ridgetop Cir
Technical Contact City:                      Sterling
Technical Contact State/Province:            VA
Technical Contact Postal Code:               20166
Technical Contact Country:                   United States
Technical Contact Country Code:              US
Technical Contact Phone Number:              +1.5714345400
Technical Contact Email:                     support@neustar.biz

DNSSEC:                                      unsigned
Name Server:                                 NS1.DNS.NIC.TRADE
Name Server:                                 NS2.DNS.NIC.TRADE
Name Server:                                 NS3.DNS.NIC.TRADE
Name Server:                                 NS4.DNS.NIC.TRADE
Name Server:                                 NS5.DNS.NIC.TRADE
Name Server:                                 NS6.DNS.NIC.TRADE

Created by Registrar:                        NEUSTAR Organization
Last Updated by Registrar:                   NEULEVELCSR
Domain Registration Date:                    2013-08-09T23:03:59Z
Domain Expiration Date:                      2014-08-08T23:59:59Z
Domain Last Updated Date:                    2014-03-07T19:33:58Z
Name Value Pair:                             Variant=NIC.TRADE



>>>> Whois database was last updated on: 2014-05-20T22:16:59Z <<<<


The WHOIS service offered by the Registry Operator, and the access to the records in the Registry Operator WHOIS database, are provided for information purposes only and is designed (i)to assist persons in determining whether a specific domain name registration record is available or not in the Registry Operator database and (ii)to obtain information related to the registration records of existing domain names.  The Registry Operator cannot, under any circumstances, be held liable in such instances where the stored information would prove to be wrong, incomplete, or not accurate in any sense. By submitting a WHOIS query, you, the user, agree that you will not use this data: (i)to allow, enable or otherwise support in any way the transmission of unsolicited, commercial advertising or other solicitations whether via direct mail, email, telephone or otherwise; (ii)to enable high volume, automated, electronic processes that apply to the registry (or its systems); (iii)for target advertising in any possible way; (iv)to cause nuisance in any possible way to the registrants by sending (whether by automated, electronic processes capable of enabling high volumes or other possible means) messages to them; (v)to violate any law, rule, regulation or statute; and/or (vi)in contravention of any applicable data and privacy protection acts. Without prejudice to the above, it is explicitly forbidden to extract, copy and/or use or re-utilize in any form and by any means (electronically or not) the whole or a quantitatively or qualitatively substantial part of the contents of the WHOIS database without prior and explicit permission by Registry Operator, nor in any attempt hereof, or to apply automated, electronic processes to Registry Operator (or its systems or their designated third party Registry Service Provider\'s systems). You agree that any reproduction and/or transmission of data for commercial purposes will always be considered as the extraction of a substantial part of the c
ontent of the WHOIS database. By utilizing this website and/or submitting a query you agree to abide by this policy and accept that Registry Operator can take measures to limit the use of its WHOIS services in order to protect the privacy of its registrants or the integrity of the database. We reserve the right to make changes to these Terms and Conditions at any time without prior notice to you. It is your responsibility to review these Terms and Conditions each time you access or use the WHOIS service and to familiarise yourself with any changes. If you do not agree to the changes implemented by Registry Operator, your sole and exclusive remedy is to terminate your use of the WHOIS service. 

By executing a query, in any manner whatsoever, you agree to abide by these Terms and Conditions. NOTE: FAILURE TO LOCATE A RECORD IN THE WHOIS DATABASE IS NOT INDICATIVE OF THE AVAILABILITY OF A DOMAIN NAME.

All domain names are subject to certain additional domain name registration
rules.  For details, please visit our site at www.whois.trade.';

$dri->add_registry('NGTLD',{provider=>'ffm','name'=>'trade'});
$dri->target('trade')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.trade');
is($rc->is_success(),1,'FFM/Neustar domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.trade','domain_info get_info (name)');
is($dri->get_info('id'),'D313-TRADE','domain_info get_info (id)');
is($dri->get_info('clName'),'NEUSTAR Organization','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),undef,'domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'www.neustar.co','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverTransferProhibited','serverUpdateProhibited'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-08-09T23:03:59','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-03-07T19:33:58','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2014-08-08T23:59:59','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-05-20T22:16:59','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.dns.nic.trade','ns2.dns.nic.trade','ns3.dns.nic.trade','ns4.dns.nic.trade','ns5.dns.nic.trade','ns6.dns.nic.trade'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'NICCONTACT1','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'NICCONTACT1','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'NICCONTACT1','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'NICCONTACT1','domain_info get_info (contact) billing srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Neustar, Inc.','domain_info get_info (contact) registrant name');
is($r->org(),undef,'domain_info get_info (contact) registrant org');

####################################################################################################
# GMO Registry
$R2='Domain ID:GMOREGISTRY-DO31179
Domain Name:NIC.TOKYO
WHOIS Server:whois.nic.tokyo
Referral URL:http://nic.tokyo
Created On:2014-01-31T03:00:21.0Z
Last Updated On:2014-01-31T03:00:21.0Z
Expiration Date:2015-01-31T23:59:59.0Z
Status:ok
Registrant ID:H738825
Registrant Name:Reserved Domain
Registrant Organization:GMO Registry, Inc.
Registrant Street1:Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,
Registrant City:Tokyo
Registrant Postal Code:150-8512
Registrant Country:JP
Registrant Phone:+81.354561601
Registrant Email:system@gmoregistry.com
Admin ID:H738825
Admin Name:Reserved Domain
Admin Organization:GMO Registry, Inc.
Admin Street1:Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,
Admin City:Tokyo
Admin Postal Code:150-8512
Admin Country:JP
Admin Phone:+81.354561601
Admin Email:system@gmoregistry.com
Tech ID:H738825
Tech Name:Reserved Domain
Tech Organization:GMO Registry, Inc.
Tech Street1:Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,
Tech City:Tokyo
Tech Postal Code:150-8512
Tech Country:JP
Tech Phone:+81.354561601
Tech Email:system@gmoregistry.com
Billing ID:H738825
Billing Name:Reserved Domain
Billing Organization:GMO Registry, Inc.
Billing Street1:Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,
Billing City:Tokyo
Billing Postal Code:150-8512
Billing Country:JP
Billing Phone:+81.354561601
Billing Email:system@gmoregistry.com
Sponsoring Registrar ID:H738824
Sponsoring Registrar IANA ID:9999
Sponsoring Registrar Organization:GMO Registry, Inc.
Sponsoring Registrar Street1:Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,
Sponsoring Registrar City:Tokyo
Sponsoring Registrar Postal Code:150-8512
Sponsoring Registrar Country:JP
Sponsoring Registrar Phone:+81.354561601
Sponsoring Registrar Website:http://www.gmoregistry.com
Name Server:NS1.GMOINTERNET.COM
Name Server:NS1.GMOINTERNET.JP
DNSSEC:Unsigned

This whois service is provided by GMO Registry and only contains
information pertaining to Internet domain names we have registered for
our customers. By using this service you are agreeing (1) not to use any
information presented here for any purpose other than determining
ownership of domain names, (2) not to store or reproduce this data in 
any way, (3) not to use any high-volume, automated, electronic processes
to obtain data from this service. Abuse of this service is monitored and
actions in contravention of these terms will result in being permanently
blacklisted. All data is (c) GMO Registry http://www.gmo-registry.com/en/';

$dri->add_registry('NGTLD',{provider=>'gmo'});
$dri->target('gmo')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.tokyo');
is($rc->is_success(),1,'GMO domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.tokyo','domain_info get_info (name)');
is($dri->get_info('id'),'GMOREGISTRY-DO31179','domain_info get_info (id)');
is($dri->get_info('clName'),'GMO Registry, Inc.','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)');
is($dri->get_info('clWhois'),'whois.nic.tokyo','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://nic.tokyo','domain_info get_info (clWebsite)');
is($dri->get_info('clID'),'H738824','domain_info get_info (clID)');
is($dri->get_info('clStreet'),'Cerulean Tower, 26-1 Sakuragaoka-cho, Shibuya-ku,','domain_info get_info (clStreet)');
is($dri->get_info('clCity'),'Tokyo','domain_info get_info (clCity)');
is($dri->get_info('clPC'),'150-8512','domain_info get_info (clPC)');
is($dri->get_info('clCC'),'JP','domain_info get_info (clCC)');
is($dri->get_info('clPhone'),'+81.354561601','domain_info get_info (clPhone)');
is($dri->get_info('clFax'),undef,'domain_info get_info (clFax)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2014-01-31T03:00:21','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-01-31T03:00:21','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-01-31T23:59:59','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),undef,'domain_info get_info (wuDate)'); # They don't seem to give this?
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.gmointernet.com','ns1.gmointernet.jp'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'H738825','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'H738825','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'H738825','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'H738825','domain_info get_info (contact) billing srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Reserved Domain','domain_info get_info (contact) registrant name');
is($r->org(),'GMO Registry, Inc.','domain_info get_info (contact) registrant org');

####################################################################################################
# KNET
$R2='Domain Name: nic.wang
Domain ID: 20140117g10001g-06637179
WHOIS Server: whois.nic.wang
Referral URL: http://nic.wang
Updated Date: 2014-05-22T13:57:34Z
Creation Date: 2014-01-17T11:55:04Z
Registry Expiry Date: 2015-01-17T11:55:04Z
Sponsoring Registrar: Zodiac Registry Limited
Sponsoring Registrar IANA ID: 9999
Domain Status: clientDeleteProhibited
Registrant ID: registry-wang
Registrant Name: Eugene Li
Registrant Organization: Zodiac
Registrant Street: Block B Unit 403Horizon International Tower No. 6 Zhichun Road
Registrant City: Haidian
Registrant State/Province: Beijing
Registrant Postal Code: 
Registrant Country: CN
Registrant Phone: +86.01082961269
Registrant Phone Ext: 
Registrant Fax: +86.01082961219
Registrant Fax Ext: 
Registrant Email: eugene.li@zodiac-corp.com
Admin ID: registry-wang
Admin Name: Eugene Li
Admin Organization: Zodiac
Admin Street: Block B Unit 403Horizon International Tower No. 6 Zhichun Road
Admin City: Haidian
Admin State/Province: Beijing
Admin Postal Code: 
Admin Country: CN
Admin Phone: +86.01082961269
Admin Phone Ext: 
Admin Fax: +86.01082961219
Admin Fax Ext: 
Admin Email: eugene.li@zodiac-corp.com
Tech ID: registry-wang
Tech Name: Eugene Li
Tech Organization: Zodiac
Tech Street: Block B Unit 403Horizon International Tower No. 6 Zhichun Road
Tech City: Haidian
Tech State/Province: Beijing
Tech Postal Code: 
Tech Country: CN
Tech Phone: +86.01082961269
Tech Phone Ext: 
Tech Fax: +86.01082961219
Tech Fax Ext: 
Tech Email: eugene.li@zodiac-corp.com
Name Server: gns2.zdnscloud.net.cn
Name Server: lns1.zdnscloud.info
Name Server: gns1.zdnscloud.net
Name Server: lns2.zdnscloud.biz
DNSSEC: unsigned
>>> Last update of WHOIS database: 2014-06-19T12:12:16Z <<<

NOTICE: The expiration date displayed in this record is the date the
registrar\'s sponsorship of the domain name registration in the registry is
currently set to expire. This date does not necessarily reflect the expiration
date of the domain name registrant\'s agreement with the sponsoring
registrar.  Users may consult the sponsoring registrar\'s Whois database to
view the registrar\'s reported date of expiration for this registration.

TERMS OF USE: The information in the Whois database is collected through ICANN-accredited registrars. Zodiac Holdings Limited and its affiliates （“We”） make this information available to you “as is” and do not guarantee its accuracy or completeness. <br/ >By submitting a Whois query, you agree that you will use this data only for lawful purposes and that, under no circumstances will you use this data： （1） to allow, enable, or otherwise support the transmission of mass unsolicited, commercial advertising or solicitations via direct mail, electronic mail, or by telephone; （2） in contravention of any applicable data and privacy protection laws; or （3） to enable high volume, automated, electronic processes that apply to our registry （or our systems）. Compilation, repackaging, dissemination, or other use of the Whois database in its entirety, or of a substantial portion thereof, is not allowed without our prior written permission.';

$dri->add_registry('NGTLD',{provider=>'knet','name'=>'wang'});
$dri->target('wang')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.wang');
is($rc->is_success(),1,'KNET domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.wang','domain_info get_info (name)');
is($dri->get_info('id'),'20140117g10001g-06637179','domain_info get_info (id)');
is($dri->get_info('clName'),'Zodiac Registry Limited','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois.nic.wang','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://nic.wang','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2014-01-17T11:55:04','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-05-22T13:57:34','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-01-17T11:55:04','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-06-19T12:12:16','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['gns2.zdnscloud.net.cn','lns1.zdnscloud.info','gns1.zdnscloud.net','lns2.zdnscloud.biz'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'registry-wang','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'registry-wang','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'registry-wang','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Eugene Li','domain_info get_info (contact) registrant name');
is($r->org(),'Zodiac','domain_info get_info (contact) registrant org');

####################################################################################################
# Key Systems (KS / StartingDot)
$R2='Domain Name: NIC.DESI
Domain ID: 537911537_DOMAIN-DESI
WHOIS Server: whois.nic.desi
Updated Date: 2013-12-03T13:43:11Z
Creation Date: 2013-12-03T11:25:25Z
Registry Expiry Date: 2023-12-03T11:25:25Z
Sponsoring registrar: Desi Networks LLC
Sponsoring registrar IANA ID: 9999
Domain Status: ok
Registrant ID: P-RNO22
Registrant Title: Mr.
Registrant Name: Ravin Ohri
Registrant Organization: Desi Networks LLC
Registrant Street: 6813 Marbury Road
Registrant City: Bethesda
Registrant State/Province: MD
Registrant Postal Code: 20817
Registrant Country: US
Registrant Phone: +1.3014529028
Registrant Fax: +1.3016567111
Registrant Email: rohri@desinetwork.in
Admin ID: P-RNO22
Admin Title: Mr.
Admin Name: Ravin Ohri
Admin Organization: Desi Networks LLC
Admin Street: 6813 Marbury Road
Admin City: Bethesda
Admin State/Province: MD
Admin Postal Code: 20817
Admin Country: US
Admin Phone: +1.3014529028
Admin Fax: +1.3016567111
Admin Email: rohri@desinetwork.in
Tech ID: P-RNO22
Tech Title: Mr.
Tech Name: Ravin Ohri
Tech Organization: Desi Networks LLC
Tech Street: 6813 Marbury Road
Tech City: Bethesda
Tech State/Province: MD
Tech Postal Code: 20817
Tech Country: US
Tech Phone: +1.3014529028
Tech Fax: +1.3016567111
Tech Email: rohri@desinetwork.in
Billing ID: P-RNO22
Billing Title: Mr.
Billing Name: Ravin Ohri
Billing Organization: Desi Networks LLC
Billing Street: 6813 Marbury Road
Billing City: Bethesda
Billing State/Province: MD
Billing Postal Code: 20817
Billing Country: US
Billing Phone: +1.3014529028
Billing Fax: +1.3016567111
Billing Email: rohri@desinetwork.in
Name Server: ns1.key-systems.net
Name Server: ns2.key-systems.net
Name Server: ns3.key-systems.net
DNSSEC: signedDelegation
>>> Last update of WHOIS database: 2014-06-19T12:26:09Z <<< 

; This data is provided by DESI REGISTRY for information purposes only in
; accordance with the DESI REGISTRY TLD Privacy Policy. It is intended to
; assist persons to obtain information about or related to domain name
; registration records. DESI REGISTRY does not guarantee its accuracy.
; By submitting this query, you agree to abide as follows:
;
; You agree to use this data only for lawful purposes and that under no
; circumstances will you permit this data to
; 1) allow, enable, or otherwise support the transmission of mass
;    unsolicited, commercial advertising or solicitations via e-mail,
;    telephone or fax (spam); nor
; 2) enable high volume, automated, electronic processes to the systems
;    of DESI REGISTRY or Registrars, except as reasonably required to
;    register new domain names or modify existing registrations; nor
; 3) will you generate a database of registered domain names and
;    registrant data.
;
; These terms may be changed without prior notice.
; By submitting this query, you agree to abide by this policy.
';

$dri->add_registry('NGTLD',{provider=>'ks','name'=>'desi'});
$dri->target('desi')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.desi');
is($rc->is_success(),1,'KS/StartingDot domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.desi','domain_info get_info (name)');
is($dri->get_info('id'),'537911537_DOMAIN-DESI','domain_info get_info (id)');
is($dri->get_info('clName'),'Desi Networks LLC','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois.nic.desi','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),undef,'domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-12-03T11:25:25','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2013-12-03T13:43:11','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2023-12-03T11:25:25','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-06-19T12:26:09','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.key-systems.net','ns2.key-systems.net','ns3.key-systems.net'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'P-RNO22','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'P-RNO22','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'P-RNO22','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'P-RNO22','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Ravin Ohri','domain_info get_info (contact) registrant name');
is($r->org(),'Desi Networks LLC','domain_info get_info (contact) registrant org');

####################################################################################################
# Minds And Machines
$R2='Domain ID: 4702-Minds
Domain Name: nic.bayern
WHOIS Server: whois-dub.mm-registry.com
Updated Date: 2014-06-17T12:56:22Z
Creation Date: 2014-04-23T03:05:36Z
Registry Expiry Date: 2024-04-23T03:05:36Z
Sponsoring Registrar: M+M Registry Admin
Sponsoring Registrar IANA ID: 9999
Domain Status: OK

Registrant ID: 26416-Minds
Registrant Name: Caspar Veltheim
Registrant Organization: Bayern Connect GmbH
Registrant Street: Antonienstrasse 3
Registrant City: Munich
Registrant State/Province: 
Registrant Postal Code: 80802
Registrant Country: DE
Registrant Phone: +49.8936035104
Registrant Phone Ext: 
Registrant Fax: 
Registrant Fax Ext: 
Registrant Email: info@bayernconnect.de

Admin ID: 26416-Minds
Admin Name: Caspar Veltheim
Admin Organization: Bayern Connect GmbH
Admin Street: Antonienstrasse 3
Admin City: Munich
Admin State/Province: 
Admin Postal Code: 80802
Admin Country: DE
Admin Phone: +49.8936035104
Admin Phone Ext: 
Admin Fax: 
Admin Fax Ext: 
Admin Email: info@bayernconnect.de

Tech ID: 102-Minds
Tech Name: Support
Tech Organization: Minds + Machines Ltd
Tech Street: 32 Nassau
Tech City: Dublin 2
Tech State/Province: 
Tech Postal Code: 
Tech Country: IE
Tech Phone: 
Tech Phone Ext: 
Tech Fax: 
Tech Fax Ext: 
Tech Email: support@mm-registry.com

Name Server: a.ns.nic.bayern
Name Server: b.ns.nic.bayern

DNSSEC: signedDelegation

>>> Last update of WHOIS database: 2014-06-19T01:20:15Z <<<

TERMS OF USE: The whois information provided on this site is intended to provide you with the relevant contact information for a domain name registrant and the identity of certain administrative and technical contacts associated with that domain name. The data in this record is provided by Minds + Machines Registry, a subsidiary of Minds + Machines Group Limited, formerly Top Level Domain Holdings Limited (“the Company”), for informational purposes only. Accuracy is not guaranteed. The Company is the authoritative source for whois information in top-level domains it operates under contract with the Internet Corporation for Assigned Names and Numbers. This service is intended only for query-based access. By using this service, you agree that you will use any data presented for lawful purposes only and that under no circumstances will you use (a) data acquired for the purpose of allowing, enabling, or otherwise supporting the transmission by email, telephone, facsimile, or other communications mechanisms mass unsolicited, commercial, advertising, or solicitations to entities other than your existing customers; or (b) this service to enable high volume, automated, electronic processes that send queries or data to the systems of any registrar or any registry except as reasonably necessary to register domain names or to modify existing domain name registrations. The Company reserves the right to modify these terms at any time. By submitting this query, you agree to abide by this policy. All rights reserved.';

$dri->add_registry('NGTLD',{provider=>'mam'});
$dri->target('mam')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.bayern');
is($rc->is_success(),1,'Minds And Machines domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.bayern','domain_info get_info (name)');
is($dri->get_info('id'),'4702-Minds','domain_info get_info (id)');
is($dri->get_info('clName'),'M+M Registry Admin','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois-dub.mm-registry.com','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),undef,'domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['OK'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
is($dri->get_info('crDate'),'2014-04-23T03:05:36','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-06-17T12:56:22','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2024-04-23T03:05:36','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-06-19T01:20:15','domain_info get_info (wuDate)');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a.ns.nic.bayern','b.ns.nic.bayern'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'26416-Minds','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'26416-Minds','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'102-Minds','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Caspar Veltheim','domain_info get_info (contact) registrant name');
is($r->org(),'Bayern Connect GmbH','domain_info get_info (contact) registrant org');

####################################################################################################
# NIC.BR
SKIP: {
  skip '*** TODO : NIC.BR',1;
};

####################################################################################################
# Nominet
$R2='Domain Name: NIC.WALES
Domain ID: 141
Creation Date: 2014-08-07T08:44:38Z
Registry Expiry Date: 2015-08-07T08:44:38Z
Sponsoring Registrar: clid-nomi-9999
Sponsoring Registrar IANA ID: 9999
WHOIS Server: whois.nic.wales
Referral URL: http://nic.wales
Domain Status: ok
Registrant ID: Nomi_Contact
Registrant Name: Nominet Internal Nic Contact
Registrant Organization: Nominet
Registrant Street: Edmund Halley Road
Registrant City: Oxford
Registrant State/Province: Oxon
Registrant Postal Code: OX4 4DQ
Registrant Country: GB
Registrant Phone: +44.01234567899
Registrant Email: support@nominet.org.uk
Admin ID: Nomi_Contact
Admin Name: Nominet Internal Nic Contact
Admin Organization: Nominet
Admin Street: Edmund Halley Road
Admin City: Oxford
Admin State/Province: Oxon
Admin Postal Code: OX4 4DQ
Admin Country: GB
Admin Phone: +44.01234567899
Admin Email: support@nominet.org.uk
Tech ID: Nomi_Contact
Tech Name: Nominet Internal Nic Contact
Tech Organization: Nominet
Tech Street: Edmund Halley Road
Tech City: Oxford
Tech State/Province: Oxon
Tech Postal Code: OX4 4DQ
Tech Country: GB
Tech Phone: +44.01234567899
Tech Email: support@nominet.org.uk
Name Server: ns1.nic.uk.
Name Server: ns2.nic.uk.
Name Server: ns4.nic.uk.
Name Server: ns5.nic.uk.
Name Server: ns6.nic.uk.
Name Server: ns7.nic.uk.
DNSSEC: signedDelegation
>>> Last update of WHOIS database: 2014-09-23T11:49:26Z <<<

This WHOIS information is provided for free by Nominet UK, the central registry for .wales domain names. This information and the .wales WHOIS are:

Copyright Nominet UK 2013.

You may not access the .wales WHOIS or use any data from it except as permitted by the terms of use available in full at http://www.nominet.org.uk/whois, which includes restrictions on: (A) use of the data for advertising, or its repackaging, recompilation, redistribution or reuse (B) obscuring, removing or hiding any or all of this notice and (C) exceeding query rate or volume limits. The data is provided on an \'as-is\' basis and may lag behind the register. No guarantee is given as to the accuracy of the data provided. Access may be withdrawn or restricted at any time.';

$dri->add_registry('NGTLD',{provider=>'nominet',name=>'wales'});
$dri->target('wales')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.wales');
is($rc->is_success(),1,'NOMINET domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.wales','domain_info get_info (name)');
is($dri->get_info('id'),'141','domain_info get_info (id)');
is($dri->get_info('clName'),'clid-nomi-9999','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois.nic.wales','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://nic.wales','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
is($dri->get_info('crDate'),'2014-08-07T08:44:38','domain_info get_info (crDate)');
is($dri->get_info('upDate'),undef,'domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-08-07T08:44:38','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-09-23T11:49:26','domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.nic.uk','ns2.nic.uk','ns4.nic.uk','ns5.nic.uk','ns6.nic.uk','ns7.nic.uk'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'Nomi_Contact','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'Nomi_Contact','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'Nomi_Contact','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Nominet Internal Nic Contact','domain_info get_info (contact) registrant name');
is($r->org(),'Nominet','domain_info get_info (contact) registrant org');


####################################################################################################
# OpenRegistry
$R2='Domain Name: nic.gent
Domain ID: d467697-gent
WHOIS Server: fake.whois.server
Referral URL: http://fake.url
Updated Date: 2014-07-14T14:23:35.161Z
Creation Date: 2014-04-18T09:42:38.146Z
Registry Expiry Date: 2024-04-18T09:42:38.146Z
Sponsoring Registrar: .gent Registry Registrar (nb)
Sponsoring Registrar IANA ID: 9999
Domain Status: ok http://www.icann.org/epp#OK
Registrant ID: gent0001
Registrant Name: .gent Registry
Registrant Organization: COMBELL GROUP NV/SA
Registrant Street: Skaldenstraat 121
Registrant City: Gent
Registrant State/Province:
Registrant Postal Code: 9042
Registrant Country: BE
Registrant Phone: +32.92960290
Registrant Phone Ext:
Registrant Fax:
Registrant Fax Ext:
Registrant Email: info@dotgent.com
Admin ID: gent-admin
Admin Name: .gent Registry
Admin Organization: COMBELL GROUP NV/SA
Admin Street: Skaldenstraat 121
Admin City: Gent
Admin State/Province:
Admin Postal Code: 9042
Admin Country: BE
Admin Phone: +32.92960290
Admin Phone Ext:
Admin Fax:
Admin Fax Ext:
Admin Email: info@dotgent.com
Tech ID: gent-tech
Tech Name: .gent Registry Back-end Operator
Tech Organization: OpenRegistry S.A.
Tech Street: 2, rue Leon Laval
Tech City: Leudelange
Tech State/Province:
Tech Postal Code: 3372
Tech Country: LU
Tech Phone: +352.277227
Tech Phone Ext:
Tech Fax:
Tech Fax Ext:
Tech Email: gent@openregistry.com
Name Server: a.ns.nic.gent (89.207.184.98)
Name Server: a.ns.nic.gent (2a02:2790:0:2:0:0:0:53)
Name Server: c.ns.nic.gent (54.247.68.190)
Name Server: x.ns.nic.gent (195.253.64.4)
Name Server: x.ns.nic.gent (2a01:5b0:4:0:0:0:0:4)
Name Server: y.ns.nic.gent (195.253.64.7)
Name Server: y.ns.nic.gent (2a01:5b0:4:0:0:0:0:7)
DNSSEC: signedDelegation
>>> Last update of WHOIS database: 2014-10-28T16:49:29.179Z <<<

For more information on Whois status codes, please visit https://www.icann.org/resources/pages/epp-status-codes-2014-06-16-en.

% WHOIS LEGAL STATEMENT AND TERMS & CONDITIONS
% The WHOIS service offered by OpenRegistry and the access to the
% records in the OpenRegistry WHOIS database are provided for information
% purposes only. It allows persons to check whether a specific domain name
% is still available or not and to obtain information related to the
% registration records of existing domain names. You are not authorized to
% access or query our WHOIS  database through the use of electronic
% processes that are high-volume and  automated except as reasonably
% necessary to register domain names or modify existing registrations.
%
% OpenRegistry cannot, under any circumstances, be held liable should the
% stored information prove to be wrong, incomplete or inaccurate in any sense.
%
% By submitting a WHOIS query you agree not to use the information made
% available to:
%   - Allow, enable or otherwise support the transmission of unsolicited,
%     commercial advertising or other solicitations whether via email, telephone
%     or otherwise;
%   - Target advertising in any possible way;
%   - Cause nuisance in any possible way to the registrants by sending (whether
%     by automated, electronic processes capable of enabling high volumes or
%     other possible means) messages to them.
%
% Without prejudice to the above, it is explicitly forbidden to extract, copy
% and/or use or re-utilise in any form and  by any means (electronically or
% not) the whole or a quantitatively or qualitatively substantial part of the
% contents of the WHOIS database without prior and explicit permission by
% OpenRegistry, nor in any attempt hereof, to apply automated, electronic
% processes to OpenRegistry (or its systems).
%
% By submitting the query you agree that any reproduction and/or transmission
% of data for commercial purposes will always be considered as the extraction
% of a substantial part of the content of the WHOIS database. You also agree
% to abide by this policy and accept that OpenRegistry can take measures to
% limit the use of its WHOIS services in order to protect the privacy of its
% registrants and/or the integrity of the database. OpenRegistry reserves the
% right  to restrict your access to the WHOIS database in its sole discretion
% to ensure operational stability.  OpenRegistry may restrict or terminate your
% access to the WHOIS database for failure to abide by these terms of use.
%
% OpenRegistry reserves the right to modify these terms at any time.
';

$dri->add_registry('NGTLD',{provider=>'openreg',name=>'gent'});
$dri->target('gent')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.gent');
is($rc->is_success(),1,'OPENREGISTRY domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.gent','domain_info get_info (name)');
is($dri->get_info('id'),'d467697-gent','domain_info get_info (id)');
is($dri->get_info('clName'),'.gent Registry Registrar (nb)','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'fake.whois.server','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://fake.url','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
isa_ok($dri->get_info('crDate'),'DateTime','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-07-14T14:23:35','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2024-04-18T09:42:38','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-10-28T16:49:29','domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a.ns.nic.gent','c.ns.nic.gent','x.ns.nic.gent','y.ns.nic.gent'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'gent0001','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'gent-admin','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'gent-tech','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'.gent Registry','domain_info get_info (contact) registrant name');
is($r->org(),'COMBELL GROUP NV/SA','domain_info get_info (contact) registrant org');

####################################################################################################
# PIR
$R2='Domain Name:NIC.XN--NQV7F
Domain ID: D172226524-LROR
Creation Date: 2014-04-21T19:57:06Z
Updated Date: 2014-04-21T19:57:13Z
Registry Expiry Date: 2015-04-21T19:57:06Z
Sponsoring Registrar:Public Interest Registry (R2002-LROR)
Sponsoring Registrar IANA ID: 800224
WHOIS Server: whois.dummy.dumdumb
Referral URL: http://www.dummy.dumdumb
Domain Status: serverTransferProhibited
Registrant ID:PC5001-PR
Registrant Name:100-RO Names
Registrant Organization:Public Interest Registry
Registrant Street: 1775 Wiehle Avenue
Registrant City:Reston
Registrant State/Province:VA
Registrant Postal Code:20190
Registrant Country:US
Registrant Phone:+1.7038895778
Registrant Phone Ext: 
Registrant Fax: +1.7038895779
Registrant Fax Ext: 
Registrant Email:support@pir.org
Admin ID:PC5001-PR
Admin Name:100-RO Names
Admin Organization:Public Interest Registry
Admin Street: 1775 Wiehle Avenue
Admin City:Reston
Admin State/Province:VA
Admin Postal Code:20190
Admin Country:US
Admin Phone:+1.7038895778
Admin Phone Ext: 
Admin Fax: +1.7038895779
Admin Fax Ext: 
Admin Email:support@pir.org
Tech ID:PC5001-PR
Tech Name:100-RO Names
Tech Organization:Public Interest Registry
Tech Street: 1775 Wiehle Avenue
Tech City:Reston
Tech State/Province:VA
Tech Postal Code:20190
Tech Country:US
Tech Phone:+1.7038895778
Tech Phone Ext: 
Tech Fax: +1.7038895779
Tech Fax Ext: 
Tech Email:support@pir.org
Name Server:A0.NIC.XN--NQV7F
Name Server:A2.NIC.XN--NQV7F
Name Server:B0.NIC.XN--NQV7F
Name Server:C0.NIC.XN--NQV7F
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
Name Server: 
DNSSEC:Unsigned

Access to Public Interest Registry WHOIS information is provided to assist persons in determining the contents of a domain name registration record in the Public Interest Registry registry database. The data in this record is provided by Public Interest Registry for informational purposes only, and Public Interest Registry does not guarantee its accuracy. This service is intended only for query-based access. You agree that you will use this data only for lawful purposes and that, under no circumstances will you use this data to(a) allow, enable, or otherwise support the transmission by e-mail, telephone, or facsimile of mass unsolicited, commercial advertising or solicitations to entities other than the data recipient\'s own existing customers; or (b) enable high volume, automated, electronic processes that send queries or data to the systems of Registry Operator, a Registrar, or Afilias except as reasonably necessary to register domain names or modify existing registrations. All rights reserved. Public Interest Registry reserves the right to modify these terms at any time. By submitting this query, you agree to abide by this policy.';

$dri->add_registry('NGTLD',{provider=>'pir'});
$dri->target('pir')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.xn--nqv7f');
is($rc->is_success(),1,'PIR domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.xn--nqv7f','domain_info get_info (name)');
is($dri->get_info('id'),'D172226524-LROR','domain_info get_info (id)');
is($dri->get_info('clName'),'Public Interest Registry (R2002-LROR)','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'800224','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois.dummy.dumdumb','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.dummy.dumdumb','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['serverTransferProhibited'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
is($dri->get_info('crDate'),'2014-04-21T19:57:06','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-04-21T19:57:13','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2015-04-21T19:57:06','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),undef,'domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a0.nic.xn--nqv7f','a2.nic.xn--nqv7f','b0.nic.xn--nqv7f','c0.nic.xn--nqv7f'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'PC5001-PR','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'PC5001-PR','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'PC5001-PR','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'100-RO Names','domain_info get_info (contact) registrant name');
is($r->org(),'Public Interest Registry','domain_info get_info (contact) registrant org');

####################################################################################################
# RegBOX
$R2='Domain ID:                    D0000000007-BERLIN
Domain Name:                  nic.berlin
Creation Date:                2013-12-12T10:02:52Z
Updated Date:                 2014-06-03T12:55:16Z
Registry Expiry Date:         2014-12-12T10:02:52Z
Sponsoring Registrar:         dotBERLIN GmbH u. Co. KG
Sponsoring Registrar IANA ID: 9999
Domain Status:                serverDeleteProhibited
Domain Status:                serverTransferProhibited
Registrant ID:                BERLIN-BERLIN
Registrant Name:              Dirk Krischenowski
Registrant Organization:      dotBERLIN GmbH & Co. KG
Registrant Street:            Gustav-Mueller-Strasse 1
Registrant City:              Berlin
Registrant State/Province:    Berlin
Registrant Postal Code:       10829
Registrant Country:           DE
Registrant Phone:             +49.304978
Registrant Phone Ext:         2345
Registrant Fax:               +49.304978
Registrant Fax Extension:     2356
Registrant Email:             krischenowski@dotberlin.de
Admin ID:                     BERLIN-BERLIN
Admin Name:                   Dirk Krischenowski
Admin Organization:           dotBERLIN GmbH & Co. KG
Admin Street:                 Gustav-Mueller-Strasse 1
Admin City:                   Berlin
Admin State/Province:         Berlin
Admin Postal Code:            10829
Admin Country:                DE
Admin Phone:                  +49.304978
Admin Phone Ext:              2345
Admin Fax:                    +49.304978
Admin Fax Extension:          2356
Admin Email:                  krischenowski@dotberlin.de
Tech ID:                      TLDBOX-BERLIN
Tech Name:                    TLDBOX
Tech Organization:            TLD-BOX Registrydienstleistungen GmbH
Tech Street:                  Jakob-Haringer-Strasse 8
Tech City:                    Salzburg
Tech State/Province:          Salzburg
Tech Postal Code:             5200
Tech Country:                 AT
Tech Phone:                   +43.662234548
Tech Phone Ext:               730
Tech Fax:                     +43.662234548
Tech Fax Extension:           19
Tech Email:                   iana@tld-box.at
Name Server:                  sec1.rcode0.net
Name Server:                  sec2.rcode0.net
DNSSEC:                       Unsigned

% Copyright (c) 2014 by Dotberlin GmbH & Co. KG (1)
% 
% Except for agreed Internet operational purposes, 
% no part of this information may be reproduced, 
% stored in a retrieval system, or transmitted, 
% in any form or by any means, electronic, mechanical, 
% recording, or otherwise, without prior permission 
% of Dotberlin GmbH & Co. KG 
% on behalf of itself and/or the copyright holders. 
% Any use of this material to target advertising or 
% similar activities is explicitly forbidden and 
% can be prosecuted.
% 
% Furthermore, it is strictly forbidden to use the 
% Whois database in such a way that jeopardizes or 
% could jeopardize the stability of the technical systems 
% of Dotberlin GmbH & Co. KG 
% under any circumstances. In particular, this includes 
% any misuse of the Whois database and any use of 
% the Whois database which disturbs its operation.
% 
% Should the user violate these points, 
% Dotberlin GmbH & Co. KG reserves the right 
% to deactivate the Whois database entirely or 
% partly for the user. Moreover, the user shall 
% be held liable for any and all damage arising 
% from a violation of these points.
';

$dri->add_registry('NGTLD',{provider=>'regbox','name'=>'berlin'});
$dri->target('berlin')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.berlin');
is($rc->is_success(),1,'RegBox domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.berlin','domain_info get_info (name)');
is($dri->get_info('id'),'D0000000007-BERLIN','domain_info get_info (id)');
is($dri->get_info('clName'),'dotBERLIN GmbH u. Co. KG','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),undef,'domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),undef,'domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverTransferProhibited'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
is($dri->get_info('crDate'),'2013-12-12T10:02:52','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-06-03T12:55:16','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2014-12-12T10:02:52','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),undef,'domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['sec1.rcode0.net','sec2.rcode0.net'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'BERLIN-BERLIN','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'BERLIN-BERLIN','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'TLDBOX-BERLIN','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Dirk Krischenowski','domain_info get_info (contact) registrant name');
is($r->org(),'dotBERLIN GmbH & Co. KG','domain_info get_info (contact) registrant org');

####################################################################################################
# SIDN
SKIP: {
  skip '*** TODO : SIDN',1;
};

####################################################################################################
# TCI
SKIP: {
  skip '*** TODO : TCI',1;
};

####################################################################################################
# UniRegistry
$R2='Domain Name: nic.tattoo
Domain ID: DO_4810ec9890fdf872f2e23b58df485dc4-ISC
WHOIS Server: whois.uniregistry.net
Referral URL: http://whois.uniregistry.net
Updated Date: 2014-05-08T00:18:32.620Z
Creation Date: 2013-09-16T14:21:26.648Z
Registry Expiry Date: 2023-09-16T14:21:26.648Z
Sponsoring Registrar: Uniregistry, Corp.
Sponsoring Registrar ID: 9999
Sponsoring Registrar IANA ID: 9999
Domain Status: serverDeleteProhibited
Domain Status: serverTransferProhibited
Domain Status: serverUpdateProhibited
Registrant ID: uniregistry
Registrant Name: Uniregistry Registry Internal Resources
Registrant Organization: Uniregistry, Corp
Registrant Street: PO Box 1361
Registrant City: Grand Cayman
Registrant State/Province: George Town
Registrant Postal Code: KY1-1108
Registrant Country: KY
Registrant Phone: +1.3457496263
Registrant Fax: +1.3457496263
Registrant Email: ops+whois@uniregistry.com
Admin ID: tattoo-admin
Admin Name: Uniregistry admin contact
Admin Organization: Uniregistry, Corp
Admin Street: PO Box 1361
Admin City: Grand Cayman
Admin State/Province: George Town
Admin Postal Code: KY1-1108
Admin Country: KY
Admin Phone: +1.3457496263
Admin Fax: +1.3457496263
Admin Email: ops+whois@uniregistry.com
Tech ID: tattoo-tech
Tech Name: Uniregistry tech contact
Tech Organization: Uniregistry, Corp
Tech Street: PO Box 1361
Tech City: Grand Cayman
Tech State/Province: George Town
Tech Postal Code: KY1-1108
Tech Country: KY
Tech Phone: +1.3457496263
Tech Fax: +1.3457496263
Tech Email: ops+whois@uniregistry.com
Billing ID: tattoo-billing
Billing Name: Uniregistry billing contact
Billing Organization: Uniregistry, Corp
Billing Street: PO Box 1361
Billing City: Grand Cayman
Billing State/Province: George Town
Billing Postal Code: KY1-1108
Billing Country: KY
Billing Phone: +1.3457496263
Billing Fax: +1.3457496263
Billing Email: ops+whois@uniregistry.com
Name Server: a.ns.uniregistry.net
Name Server: tld.isc-sns.info
Name Server: tld.isc-sns.com
Name Server: tld.isc-sns.net
DNSSEC: signedDelegation

>>> Last update of WHOIS database: 2014-06-19T14:36:00.381Z <<<


The  WHOIS information provided on this page is intended to provide you
with relevant contact information for a domain name registrant and the
identity of certain administrative and technical contacts associated
with the domain name. 

The data in this record is provided by Uniregistry for informational
purposes only, and it does not guarantee its accuracy. Uniregistry is
authoritative for whois information in top-level domains it operates
under contract with the Internet Corporation for Assigned Names and
Numbers. Whois information from other top-level domains is provided by
a third-party under license to Uniregistry. 

This service is intended only for query-based access. By using this
service, you agree that you will use any data presented only for lawful
purposes and that, under no circumstances will you use (a) data
acquired for the purpose of allowing, enabling, or otherwise supporting
the transmission by e-mail, telephone, facsimile or other
communications mechanism of mass  unsolicited, commercial advertising
or solicitations to entities other than your existing  customers; or
(b) this service to enable high volume, automated, electronic processes
that send queries or data to the systems of any Registrar or any
Registry except as reasonably necessary to register domain names or
modify existing domain name registrations. 

Uniregistry reserves the right to modify these terms at any time. By
submitting this query, you agree to abide by this policy. All rights
reserved.';

$dri->add_registry('NGTLD',{provider=>'unireg'});
$dri->target('unireg')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.tattoo');
is($rc->is_success(),1,'UniRegistry domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.tattoo','domain_info get_info (name)');
is($dri->get_info('id'),'DO_4810ec9890fdf872f2e23b58df485dc4-ISC','domain_info get_info (id)');
is($dri->get_info('clName'),'Uniregistry, Corp.','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'whois.uniregistry.net','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://whois.uniregistry.net','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverTransferProhibited','serverUpdateProhibited'],'domain_info get_info(status) list'); # FIXME, should this not be lower-cased somewhere?
is($dri->get_info('crDate'),'2013-09-16T14:21:26','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-05-08T00:18:32','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2023-09-16T14:21:26','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-06-19T14:36:00','domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['a.ns.uniregistry.net','tld.isc-sns.info','tld.isc-sns.com','tld.isc-sns.net'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'uniregistry','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'tattoo-admin','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'tattoo-tech','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'tattoo-billing','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Uniregistry Registry Internal Resources','domain_info get_info (contact) registrant name');
is($r->org(),'Uniregistry, Corp','domain_info get_info (contact) registrant org');

####################################################################################################
# Verisign
$R2='Whois Server Version 2.0

Domain names can now be registered with many different competing registrars. 
Go to http://registrar.verisign-grs.com/whois/ for detailed information.

   Domain Name: NIC.CAREER
   Domain ID: 106017070
   Whois Server: rs.internic.net
   Referral URL: http://www.networksolutions.com
   Updated Date: 2013-11-14T10:09:07Z
   Creation Date: 2013-05-31T10:16:43Z
   Registry Expiry Date: 2023-05-31T10:16:43Z
   Sponsoring Registrar: TEST REGISTRAR
   Sponsoring Registrar IANA ID: 9999
   Domain Status: ok
   Registrant ID: VRSNCONTACT
   Registrant Name: Verisign Customer Service
   Registrant Organization: Verisign, Inc.
   Registrant Street: 12061 Bluemont Way
   Registrant City: Reston
   Registrant Country: US
   Registrant Phone: +1.7039256999
   Registrant Email: info@verisign-grs.com
   Admin ID: VRSNCONTACT
   Admin Name: Verisign Customer Service
   Admin Organization: Verisign, Inc.
   Admin Street: 12061 Bluemont Way
   Admin City: Reston
   Admin Country: US
   Admin Phone: +1.7039256999
   Admin Email: info@verisign-grs.com
   Tech ID: VRSNCONTACT
   Tech Name: Verisign Customer Service
   Tech Organization: Verisign, Inc.
   Tech Street: 12061 Bluemont Way
   Tech City: Reston
   Tech Country: US
   Tech Phone: +1.7039256999
   Tech Email: info@verisign-grs.com
   Billing ID: VRSNCONTACT
   Billing Name: Verisign Customer Service
   Billing Organization: Verisign, Inc.
   Billing Street: 12061 Bluemont Way
   Billing City: Reston
   Billing Country: US
   Billing Phone: +1.7039256999
   Billing Email: info@verisign-grs.com
   Name Server: NS100.NSTLD.NET
   Name Server: NS101.NSTLD.NET
   Name Server: NS102.NSTLD.NET
   Name Server: NS103.NSTLD.NET
   Name Server: NS104.NSTLD.NET
   Name Server: NS105.NSTLD.NET
   DNSSEC: Unsigned delegation


>>> Last update of whois database: 2014-07-31T11:02:24Z <<<

NOTICE: The expiration date displayed in this record is the date the 
registrar\'s sponsorship of the domain name registration in the registry is 
currently set to expire. This date does not necessarily reflect the 
expiration date of the domain name registrant\'s agreement with the 
sponsoring registrar.  Users may consult the sponsoring registrar\'s 
Whois database to view the registrar\'s reported date of expiration 
for this registration.

TERMS OF USE: You are not authorized to access or query our Whois 
database through the use of electronic processes that are high-volume and 
automated except as reasonably necessary to register domain names or 
modify existing registrations; the Data in VeriSign\'s ("VeriSign") Whois 
database is provided by VeriSign for information purposes only, and to 
assist persons in obtaining information about or related to a domain name 
registration record. VeriSign does not guarantee its accuracy. 
By submitting a Whois query, you agree to abide by the following terms of 
use: You agree that you may use this Data only for lawful purposes and that 
under no circumstances will you use this Data to: (1) allow, enable, or 
otherwise support the transmission of mass unsolicited, commercial 
advertising or solicitations via e-mail, telephone, or facsimile; or 
(2) enable high volume, automated, electronic processes that apply to 
VeriSign (or its computer systems). The compilation, repackaging, 
dissemination or other use of this Data is expressly prohibited without 
the prior written consent of VeriSign. You agree not to use electronic 
processes that are automated and high-volume to access or query the 
Whois database except as reasonably necessary to register domain names 
or modify existing registrations. VeriSign reserves the right to restrict 
your access to the Whois database in its sole discretion to ensure 
operational stability.  VeriSign may restrict or terminate your access to the 
Whois database for failure to abide by these terms of use. VeriSign 
reserves the right to modify these terms at any time. 

The Registry database contains ONLY .cc, .tv, and .jobs domains 
and Registrars.
';

$dri->add_registry('NGTLD',{provider=>'verisign'});
$dri->target('verisign')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.career');
is($rc->is_success(),1,'Verisign domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.career','domain_info get_info (name)');
is($dri->get_info('id'),'106017070','domain_info get_info (id)');
is($dri->get_info('clName'),'TEST REGISTRAR','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); # FIXME, when this is 1 it does not get returned?
is($dri->get_info('clWhois'),'rs.internic.net','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),'http://www.networksolutions.com','domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($dri->get_info('crDate'),'2013-05-31T10:16:43','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2013-11-14T10:09:07','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2023-05-31T10:16:43','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-07-31T11:02:24','domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns100.nstld.net','ns101.nstld.net','ns102.nstld.net','ns103.nstld.net','ns104.nstld.net','ns105.nstld.net'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'VRSNCONTACT','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'VRSNCONTACT','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'VRSNCONTACT','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'VRSNCONTACT','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'Verisign Customer Service','domain_info get_info (contact) registrant name');
is($r->org(),'Verisign, Inc.','domain_info get_info (contact) registrant org');

####################################################################################################
# ZACR
$R2='Domain Name: nic.joburg
Domain ID: dom_C-9999
WHOIS Server: joburg-whois1.registry.net.za

Updated Date: 2014-09-29T11:32:01Z
Creation Date: 2014-06-09T08:18:44Z
Registry Expiry Date: 2998-12-31T22:00:00Z
Sponsoring Registrar: DNServices
Sponsoring Registrar IANA ID: 9999 
Domain Status: Registered until renewal date

Registrant ID: dnservices
Registrant Name: DNServices
Registrant Organization: 
Registrant Street: COZA House Gazelle Close Corporate Park South 
Registrant City: Midrand
Registrant State/Province: Gauteng
Registrant Postal Code: 1685
Registrant Country: ZA
Registrant Phone: Tel: +27.113140077
Registrant Phone Ext: 
Registrant Fax: Fax: None
Registrant Fax Ext: 
Registrant Email: Email: support@dnservices.co.za

Admin ID: dnservices
Admin Name: DNServices
Admin Organization: 
Admin Street: COZA House Gazelle Close Corporate Park South 
Admin City: Midrand
Admin State/Province: Gauteng
Admin Postal Code: 1685
Admin Country: ZA
Admin Phone: +27.113140077
Admin Phone Ext: 
Admin Fax: 
Admin Fax Ext: 
Admin Email: support@dnservices.co.za

Billing ID: dnservices
Billing Name: DNServices
Billing Organization: 
Billing Street: COZA House Gazelle Close Corporate Park South 
Billing City: Midrand
Billing State/Province: Gauteng
Billing Postal Code: 1685
Billing Country: ZA
Billing Phone: +27.113140077
Billing Phone Ext: 
Billing Fax: 
Billing Fax Ext: 
Billing Email: support@dnservices.co.za

Tech ID: dnservices
Tech Name: DNServices
Tech Organization: 
Tech Street: COZA House Gazelle Close Corporate Park South 
Tech City: Midrand
Tech State/Province: Gauteng
Tech Postal Code: 1685
Tech Country: ZA
Tech Phone: +27.113140077
Tech Phone Ext: 
Tech Fax: 
Tech Fax Ext: 
Tech Email: support@dnservices.co.za


Name Server: ns1.dnservices.co.za
Name Server: ns1.nic.joburg
DNSSEC: unsigned
>>> Last update of WHOIS database: 2014-10-28T17:35:44Z <<<

#    WHOIS lookup made at 2014-10-28T17:35:44Z
# --
# The use of this Whois facility is subject to the following terms and
# conditions. https://registry.net.za/whois_terms
# Copyright (c) ZACR 1995-2014
';

$dri->add_registry('NGTLD',{provider=>'zacr',name=>'joburg'});
$dri->target('joburg')->add_current_profile('p1','whois',{f_send=>\&mysend,f_recv=>\&myrecv});
$rc = $dri->domain_info('nic.joburg');
is($rc->is_success(),1,'ZACR domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'nic.joburg','domain_info get_info (name)');
is($dri->get_info('id'),'dom_C-9999','domain_info get_info (id)');
is($dri->get_info('clName'),'DNServices','domain_info get_info (clName)');
is($dri->get_info('clIANA'),'9999','domain_info get_info (clIANA)'); 
is($dri->get_info('clWhois'),'joburg-whois1.registry.net.za','domain_info get_info (clWhois)');
is($dri->get_info('clWebsite'),undef,'domain_info get_info (clWebsite)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['Registered'],'domain_info get_info(status) list'); # FIXME - dodgy response
is($dri->get_info('crDate'),'2014-06-09T08:18:44','domain_info get_info (crDate)');
is($dri->get_info('upDate'),'2014-09-29T11:32:01','domain_info get_info (upDate)');
is($dri->get_info('exDate'),'2998-12-31T22:00:00','domain_info get_info (exDate)');
is($dri->get_info('wuDate'),'2014-10-28T17:35:44','domain_info get_info (wuDate) undef');
$h=$dri->get_info('ns');
isa_ok($h,'Net::DRI::Data::Hosts','domain_info get_info (ns)');
@hs=$h->get_names();
is_deeply(\@hs,['ns1.dnservices.co.za','ns1.nic.joburg'],'domain_info get_info (ns) get_names');
$c=$dri->get_info('contact');
isa_ok($c,'Net::DRI::Data::ContactSet','domain_info get_info (contactSet)');
is_deeply([$c->types()],['admin','billing','registrant','tech'],'domain_info get_info (contactSet) types');
is($c->get('registrant')->srid(),'dnservices','domain_info get_info (contact) registrant srid');
is($c->get('admin')->srid(),'dnservices','domain_info get_info (contact) admin srid');
is($c->get('tech')->srid(),'dnservices','domain_info get_info (contact) tech srid');
is($c->get('billing')->srid(),'dnservices','domain_info get_info (contact) tech srid');
$r = $c->get('registrant');
isa_ok($r,'Net::DRI::Data::Contact','domain_info get_info (contact) registrant contact');
is($r->name(),'DNServices','domain_info get_info (contact) registrant name');
is($r->org(),undef,'domain_info get_info (contact) registrant org');

exit 0;