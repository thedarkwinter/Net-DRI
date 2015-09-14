#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 53;
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

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c,@d);

########################################################################################################

## namespaces
=cut
xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-1.1
xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1
xmlsns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.0"
=cut

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
# Response edited!
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{authinfo_request => 1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0007.eu</domain:name></domain:info></info><extension><authInfo:info xmlns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/authInfo-1.0 authInfo-1.0.xsd"><authInfo:request/></authInfo:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is_deeply($dri->get_info('auth'),{'pw' => 'XXXX-2MRN-MRAP-MXVR'},'domain_info get_info(authInfo) value');

## 2.1.09/domains/domain-info/domain-info04-cmd.xml
# Status in use and not locked/in other registrar's portfolio and using authcode on request/2 onsite contacts and no tech contacts/2 name servers with no glue/no DNSSEC
# Response edited!
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');

## 2.1.09/domains/domain-info/domain-info05-resp.xml
# Status in quarantine/IDN Latin/1 tech & 1 onsite contact/1 name server and no glue/1 DNSSEC key
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domínio-qq.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');

exit 0;
