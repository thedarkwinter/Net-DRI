#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 84;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,$e,@c,@d);

########################################################################################################

## Process greetings to select namespace versions
# We need secDNS and domain-ext to select correct versions in the test file
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2014-09-13T09:31:14.123Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrar-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.1</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dynUpdate-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'domain-ext'}->[0],'http://www.eurid.eu/xml/epp/domain-ext-1.1','domain-ext 1.1 for server announcing 1.1');

########################################################################################################
### DOMAIN_CHECK

## 2.1.09/domains/domain-check/domain-check01-resp.xml
# Example of domain check command of multiple domain names
# Response edited, long domain removed, and we need to check availableDate and idn extensions
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="true">some-domain-info-0000000000.eu</domain:name></domain:cd><domain:cd><domain:name avail="false">some-domain-info-1349951245.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">some-domain-info-1349951246.eu</domain:name><domain:reason lang="en">quarantine</domain:reason></domain:cd><domain:cd><domain:name avail="false">andalucia.eu</domain:name><domain:reason lang="en">reserved</domain:reason></domain:cd><domain:cd><domain:name avail="false">andalucía.eu</domain:name><domain:reason lang="en">reserved</domain:reason></domain:cd><domain:cd><domain:name avail="false">agias.eu</domain:name><domain:reason lang="en">blocked</domain:reason></domain:cd><domain:cd><domain:name avail="false">rey-españa.eu</domain:name><domain:reason lang="en">blocked</domain:reason></domain:cd><domain:cd><domain:name avail="false">20karat.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">crédit-suisse.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">bandit-corp.eu</domain:name><domain:reason lang="en">suspended</domain:reason></domain:cd><domain:cd><domain:name avail="false">court-order-seized.eu</domain:name><domain:reason lang="en">seized</domain:reason></domain:cd></domain:chkData></resData><extension><domain-ext:chkData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1"><domain-ext:domain><domain-ext:name>some-domain-info-1349951246.eu</domain-ext:name><domain-ext:availableDate>2014-10-23T13:52:13.392Z</domain-ext:availableDate></domain-ext:domain></domain-ext:chkData><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--andaluca-i2a.eu</idn:ace><idn:unicode>andalucía.eu</idn:unicode></idn:name><idn:name><idn:ace>xn--crdit-suisse-ceb.eu</idn:ace><idn:unicode>crédit-suisse.eu</idn:unicode></idn:name><idn:name><idn:ace>xn--rey-espaa-s6a.eu</idn:ace><idn:unicode>rey-españa.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('some-domain-info-0000000000.eu','some-domain-info-1349951245.eu','some-domain-info-1349951246.eu','andalucia.eu','andalucía.eu','agias.eu','rey-españa.eu','20karat.eu','crédit-suisse.eu','bandit-corp.eu','court-order-seized.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>some-domain-info-0000000000.eu</domain:name><domain:name>some-domain-info-1349951245.eu</domain:name><domain:name>some-domain-info-1349951246.eu</domain:name><domain:name>andalucia.eu</domain:name><domain:name>andalucía.eu</domain:name><domain:name>agias.eu</domain:name><domain:name>rey-españa.eu</domain:name><domain:name>20karat.eu</domain:name><domain:name>crédit-suisse.eu</domain:name><domain:name>bandit-corp.eu</domain:name><domain:name>court-order-seized.eu</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist','domain','some-domain-info-0000000000.eu'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','some-domain-info-1349951245.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','some-domain-info-1349951245.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','some-domain-info-1349951246.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','some-domain-info-1349951246.eu'),'quarantine','domain_check get_info(exist_reason)');
$d=$dri->get_info('availableDate','domain','some-domain-info-1349951246.eu');
SKIP: { ## TODO
  skip 'TODO: availableDate (domain-ext) not yet parsed on domain_check',2;
  isa_ok($d,'DateTime','domain_check get_info(availableDate)');
  is(''.$d,'2014-10-23T16:11:55','domain_check get_info(availableDate) value');
};
is($dri->get_info('exist','domain','andalucia.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','andalucia.eu'),'reserved','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','andalucía.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','andalucía.eu'),'reserved','domain_check get_info(exist_reason)');
is($dri->get_info('name_ace','domain','andalucía.eu'),'xn--andaluca-i2a.eu','domain_check get_info(name_ace)');
SKIP: { ## TODO
  skip 'TODO: ace (idn) not yet parsed on domain_check',1;
  is($dri->get_info('ace','domain','andalucía.eu'),'xn--andaluca-i2a.eu','domain_check get_info(ace)');
};
is($dri->get_info('exist','domain','agias.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','agias.eu'),'blocked','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','rey-españa.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','rey-españa.eu'),'blocked','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','20karat.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','20karat.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','crédit-suisse.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','crédit-suisse.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','bandit-corp.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','bandit-corp.eu'),'suspended','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','court-order-seized.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','court-order-seized.eu'),'seized','domain_check get_info(exist_reason)');

## 2.1.09/domains/domain-check/domain-check02-resp.xml
# Querying the availability of a locked domain name
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="false">europa.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd></domain:chkData></resData><extension><domain-ext:chkData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1"><domain-ext:domain><domain-ext:name>europa.eu</domain-ext:name><domain-ext:status s="serverTransferProhibited"/></domain-ext:domain></domain-ext:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('europa.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>europa.eu</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
$s=$dri->get_info('status');
SKIP: { ## TODO
  skip 'TODO: status (domain-ext) not yet parsed on domain_check',2;
  isa_ok($s,'Net::DRI::Data::StatusList','domain_check get_info(status)');
  is_deeply([$s->list_status()],['serverTransferProhibited'],'domain_check get_info(status) list');
};


########################################################################################################
### DOMAIN_INFO

## 2.1.09/domains/domain-info/domain-info01-resp.xml 
# Status in use and not locked/1 onsite & 1 tech contact/2 name servers with glues (IPv4 and IPv6)/no DNSSEC
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0006.eu</domain:name><domain:roid>domain_0006_eu-EURID</domain:roid><domain:status s="ok" /><domain:registrant>c160</domain:registrant><domain:contact type="billing">c10</domain:contact><domain:contact type="tech">c159</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.domain-0006.eu</domain:hostName><domain:hostAddr ip="v6">2001:db8:85a3:0:0:8a2e:370:7333</domain:hostAddr><domain:hostAddr ip="v4">192.11.11.11</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.other-domain.pt</domain:hostName></domain:hostAttr></domain:ns><domain:clID>a987654</domain:clID><domain:crID>a987654</domain:crID><domain:crDate>2014-09-13T15:57:54.223Z</domain:crDate><domain:upID>a987654</domain:upID><domain:upDate>2014-09-13T15:57:54.000Z</domain:upDate><domain:exDate>2015-09-13T21:59:59.999Z</domain:exDate></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>false</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:contact type="onsite">c163</domain-ext:contact></domain-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0006.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0006.eu</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'domain_0006_eu-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['billing','onsite','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'c160','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c10','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'c159','domain_info get_info(contact) tech srid');
is($s->get('onsite')->srid(),'c163','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.domain-0006.eu','ns1.other-domain.pt'],'domain_info get_info(ns) get_names');
@d=$dh->get_details(1);
is_deeply(\@d,['ns1.domain-0006.eu',['192.11.11.11'],['2001:db8:85a3:0:0:8a2e:370:7333'],undef],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'a987654','domain_info get_info(clID)');
is($dri->get_info('crID'),'a987654','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2014-09-13T15:57:54','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'a987654','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'2014-09-13T15:57:54','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2015-09-13T21:59:59','domain_info get_info(exDate) value');

## 2.1.09/domains/domain-info/domain-info02-cmd.xml
# Example with request for authcode: status in use and not locked/1 tech contact and no onsite contact/no DNS and no DNSSSEC Status in use and not locked/1 onsite & 1 tech contact/2 name servers with glues (IPv4 and IPv6)/no DNSSEC
# Response edited, checking received authInfo
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{authinfo_request => 1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0007.eu</domain:name></domain:info></info><extension><authInfo:info xmlns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/authInfo-1.0 authInfo-1.0.xsd"><authInfo:request/></authInfo:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is_deeply($dri->get_info('auth'),{'pw' => 'XXXX-2MRN-MRAP-MXVR'},'domain_info get_info(authInfo) value');

## 2.1.09/domains/domain-info/domain-info04-cmd.xml
# Status in use and not locked/in other registrar's portfolio and using authcode on request/2 onsite contacts and no tech contacts/2 name servers with no glue/no DNSSEC
# Response edited, checking building and received clid
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:roid>domain_0007_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant><domain:clID>#non-disclosed#</domain:clID></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('clID'),'#non-disclosed#','domain_info get_info(clID)');


## 2.1.09/domains/domain-info/domain-info05-resp.xml
# Status in quarantine/IDN Latin/1 tech & 1 onsite contact/1 name server and no glue/1 DNSSEC key
# Response edited, checking status and dnssec
# I have enabled force_native_idn in the DRD, so checking name_ace and name_idn too
# -- on top of that we will also check the old school implementation from eurids IDN implementation
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domínio-qq.eu</domain:name><domain:roid>xn__domnio_qq_i5a_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>true</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:availableDate>2014-10-23T16:11:55.109Z</domain-ext:availableDate><domain-ext:deletionDate>2014-09-13T16:11:55.109Z</domain-ext:deletionDate><domain-ext:contact type="onsite">c163</domain-ext:contact></domain-ext:infData><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>AwEAAc8mj6eqspwxX/E+OVoA/+MTawDce72K8UOgFmDAvilVqWKsXv9a6HQVPW/feDGHQ3cvGAisb1tv4/DFJBqWniLVr77S20JhhpB+MtuJkKSmb59basCItUo/B9MohZ4hFWsgWtL8HnIuJq1jMwXzmAO236EsUjXVzAdxhqsVX7v1</secDNS:pubKey></secDNS:keyData></secDNS:infData><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--domnio-qq-i5a.eu</idn:ace><idn:unicode>domínio-qq.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domínio-qq.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domínio-qq.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('name'), 'domínio-qq.eu', 'domain get_info(name)');
is($dri->get_info('name_ace'), 'xn--domnio-qq-i5a.eu', 'domain get_info(name_ace)');
is($dri->get_info('name_idn'), 'domínio-qq.eu', 'domain get_info(name_idn)');
is($dri->get_info('ace'), 'xn--domnio-qq-i5a.eu', 'domain get_info(name_ace)');
is($dri->get_info('unicode'), 'domínio-qq.eu', 'domain get_info(name_idn)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok','quarantined'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active'); # hmm, this shout probably not be active? but lets not break old implementation [yet?]
$e=$dri->get_info('secdns');
is_deeply($e,[{key_flags=>'257',key_protocol=>3,key_alg=>5,key_pubKey=>'AwEAAc8mj6eqspwxX/E+OVoA/+MTawDce72K8UOgFmDAvilVqWKsXv9a6HQVPW/feDGHQ3cvGAisb1tv4/DFJBqWniLVr77S20JhhpB+MtuJkKSmb59basCItUo/B9MohZ4hFWsgWtL8HnIuJq1jMwXzmAO236EsUjXVzAdxhqsVX7v1'}],'domain_info get_info(secdns)');
$d=$dri->get_info('availableDate');
isa_ok($d,'DateTime','domain_info get_info(availableDate)');
is(''.$d,'2014-10-23T16:11:55','domain_info get_info(availableDate) value');
$d=$dri->get_info('deletionDate');
isa_ok($d,'DateTime','domain_info get_info(deletionDate)');
is(''.$d,'2014-09-13T16:11:55','domain_info get_info(deletionDate) value');


## 2.1.09/domains/domain-info/domain-info06-cmd.xml
# Domain name in own portfolio with a deletion date, nsgroup and 1 keygroup
# Response edited, checking nsgroup and keygroup only
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>nomen-hawg3nwn.eu</domain:name><domain:roid>nomen_hawg3nwn_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>false</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:deletionDate>2015-01-01T00:00:00.000Z</domain-ext:deletionDate><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:nsgroup>nsg-a-1349684934</domain-ext:nsgroup><domain-ext:keygroup>keygroup-1350898304165</domain-ext:keygroup></domain-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('nomen-hawg3nwn.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">nomen-hawg3nwn.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('name'), 'nomen-hawg3nwn.eu', 'domain get_info(name)');
#is($dri->get_info('nsgroup'), 'nsg-a-1349684934', 'domain get_info(name)');
$dh=$dri->get_info('nsgroup');
isa_ok($dh->[0],'Net::DRI::Data::Hosts','domain_info get_info(nsgroup)');
is($dri->get_info('keygroup'), 'keygroup-1350898304165', 'domain get_info(name)');

#### TODO: when dynUpdate is implemented, these two domain_info's should be tested

## 2.1.09/domains/domain-info/domain-info10-resp.xml
# Domain info without authcode with a successful DYNUPDATE reply section

## domains/domain-info/domain-info11-resp.xml
# Domain info without authcode with a failed DYNUPDATE reply section

########################################################################################################
### DOMAIN_CREATE

########################################################################################################
### DOMAIN_UPDATE

########################################################################################################
### DOMAIN_RENEW

########################################################################################################
### DOMAIN_DELETE

## 2.1.09/domains/domain-delete/domain-delete01-cmd.xml
# Delete domain with a deletion date
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683848.eu',{pure_delete=>1,deleteDate=>DateTime->new(year=>2015,month=>1,day=>1,hour=>0,minute=>0,second=>0)});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683848.eu</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-1.1 domain-ext-1.1.xsd"><domain-ext:schedule><domain-ext:delDate>2015-01-01T00:00:00.000000000Z</domain-ext:delDate></domain-ext:schedule></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

## 2.1.09/domains/domain-delete/domain-delete02-cmd.xml
# Delete domain immediately
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683850.eu',{pure_delete=>1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683850.eu</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

## 2.1.09/domains/domain-delete/domain-undelete01-cmd.xml
# Cancel scheduled deletion
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683848.eu',{pure_delete=>1,cancel=>1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683848.eu</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-1.1 domain-ext-1.1.xsd"><domain-ext:cancel/></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

########################################################################################################
### DOMAIN_TRANSFER





exit 0;
