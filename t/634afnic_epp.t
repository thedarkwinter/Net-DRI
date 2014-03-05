#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Test::More tests => 104;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('AFNIC');
$dri->target('AFNIC')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$cs,$s,$toc);

####################################################################################################
## §2.2.4

my $ZC=<<'EOF';
ZONE : ndd-de-test-0001.fr.
NS    : ns1.nic.fr.
NS    : ns2.nic.fr.
NS    : ns.ndd-de-test-0001.fr. [192.93.0.1, 2001:660:3005:1::1:1]

==> SUCCESS
EOF

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="50001"><qDate>2008-12-25T00:01:00.0Z</qDate><msg><resZC type="plain-text">'.$ZC.'</resZC></msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name paResult="1">ndd-de-test-0001.fr</domain:name><domain:paTRID><clTRID>une-reference-client-par-exemple</clTRID><svTRID>frnic-00000003</svTRID></domain:paTRID><domain:paDate>2008-12-25T00:01:00.0Z</domain:paDate></domain:panData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),50001,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),50001,'message get_info last_id 2');
is($dri->get_info('id','message',50001),50001,'message get_info id');
is(''.$dri->get_info('qdate','message',50001),'2008-12-25T00:01:00','message get_info qdate');
is($dri->get_info('object_type','message',50001),'domain','message get_info object_type');
is($dri->get_info('object_id','message',50001),'ndd-de-test-0001.fr','message get_info id');
is($dri->get_info('action','message',50001),'review_zonecheck','message get_info action'); ## with this, we know what action has triggered this delayed message
is($dri->get_info('result','message',50001),1,'message get_info result');
is($dri->get_info('trid','message',50001),'une-reference-client-par-exemple','message get_info trid');
is($dri->get_info('svtrid','message',50001),'frnic-00000003','message get_info svtrid');
is(''.$dri->get_info('date','message',50001),'2008-12-25T00:01:00','message get_info date');
is($dri->get_info('result','domain','ndd-de-test-0001.fr'),1,'message get_info(result,domain,$DOM)');
is_string($dri->get_info('review_zonecheck','domain','ndd-de-test-0001.fr'),$ZC,'message get_info(review_zonecheck,domain,$DOM)');


####################################################################################################
## §2.5.1
## (clTRID changed from example + added xsiSchemaLocation)

$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('PR1249'),'registrant');
$cs->set($dri->local_object('contact')->srid('VL'),'admin');
$cs->set($dri->local_object('contact')->srid('AI1'),'tech');
$cs->add($dri->local_object('contact')->srid('PR1249'),'tech');
$R2=$E1.'<response>'.r().'<extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:trdData><frnic:domain><frnic:name>ndd-de-test-0001.fr</frnic:name><frnic:trStatus>pending</frnic:trStatus><frnic:reID>BEdemandeurID</frnic:reID><frnic:reDate>2009-01-01T00:00:00.0Z</frnic:reDate><frnic:reHldID>PR1249</frnic:reHldID><frnic:rhDate>2009-01-09T00:00:00.0Z</frnic:rhDate><frnic:acID>BEactuelID</frnic:acID><frnic:acHldID>MM4567</frnic:acHldID><frnic:ahDate>2009-01-09T00:00:00.0Z</frnic:ahDate></frnic:domain></frnic:trdData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_trade_start('ndd-de-test-0001.fr',{contact=>$cs,keep_ds=>0});
is_string($R1,$E1.'<extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:command><frnic:trade op="request"><frnic:domain keepDS="0"><frnic:name>ndd-de-test-0001.fr</frnic:name><frnic:registrant>PR1249</frnic:registrant><frnic:contact type="admin">VL</frnic:contact><frnic:contact type="tech">AI1</frnic:contact><frnic:contact type="tech">PR1249</frnic:contact></frnic:domain></frnic:trade><frnic:clTRID>ABC-12345</frnic:clTRID></frnic:command></frnic:ext></extension>'.$E2,'domain_trade_start build');
is($dri->get_info('trStatus'),'pending','domain_trade_start get_info(trStatus)');
is($dri->get_info('reID'),'BEdemandeurID','domain_trade_start get_info(reID)');
is(''.$dri->get_info('reDate'),'2009-01-01T00:00:00','domain_trade_start get_info(reDate)');
is($dri->get_info('reHldID'),'PR1249','domain_trade_start get_info(reHldID)');
is(''.$dri->get_info('rhDate'),'2009-01-09T00:00:00','domain_trade_start get_info(rhDate)');
is($dri->get_info('acID'),'BEactuelID','domain_trade_start get_info(acID)');
is($dri->get_info('acHldID'),'MM4567','domain_trade_start get_info(acHldID)');
is(''.$dri->get_info('ahDate'),'2009-01-09T00:00:00','domain_trade_start get_info(ahDate)');

####################################################################################################
## §2.5.2

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="50010"><qDate>2009-12-25T00:02:00.0Z</qDate><msg>Trade requested.</msg></msgQ><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:trdData><frnic:domain><frnic:name>ndd-de-test-0001.fr</frnic:name><frnic:trStatus>pending</frnic:trStatus><frnic:reID>BEdemandeurID</frnic:reID><frnic:reDate>2009-01-01T00:00:00.0Z</frnic:reDate><frnic:rhDate>2009-01-09T00:00:00.0Z</frnic:rhDate><frnic:acID>BEactuelID</frnic:acID><frnic:acHldID>MM4567</frnic:acHldID><frnic:ahDate>2009-01-09T00:00:00.0Z</frnic:ahDate></frnic:domain></frnic:trdData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),50010,'message get_info last_id 1');
is($dri->get_info('content','message',50010),'Trade requested.','message get_info message');
is(''.$dri->get_info('qdate','message',50010),'2009-12-25T00:02:00','message get_info qdate');
is($dri->get_info('object_type','message',50010),'domain','retrieve trade get_info object_type');
is($dri->get_info('object_id','message',50010),'ndd-de-test-0001.fr','retrieve trade get_info id');
is($dri->get_info('trStatus','domain','ndd-de-test-0001.fr'),'pending','retrieve trade get_info(trStatus)');
is($dri->get_info('reID','domain','ndd-de-test-0001.fr'),'BEdemandeurID','retrieve trade get_info(reID)');
is(''.$dri->get_info('reDate','domain','ndd-de-test-0001.fr'),'2009-01-01T00:00:00','retrieve trade get_info(reDate)');
is(''.$dri->get_info('rhDate','domain','ndd-de-test-0001.fr'),'2009-01-09T00:00:00','retrieve trade get_info(rhDate)');
is($dri->get_info('acID','domain','ndd-de-test-0001.fr'),'BEactuelID','retrieve trade get_info(acID)');
is($dri->get_info('acHldID','domain','ndd-de-test-0001.fr'),'MM4567','retrieve trade get_info(acHldID)');
is(''.$dri->get_info('ahDate','domain','ndd-de-test-0001.fr'),'2009-01-09T00:00:00','retrieve trade get_info(ahDate)');

## Other two examples are mostly the same, parsing wise.

####################################################################################################
## §2.5.4
## domain_trade_query : no example

####################################################################################################
## §2.6.1
## (clTRID changed from example + added xsiSchemaLocation)

$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('PR1249'),'registrant');
$cs->set($dri->local_object('contact')->srid('VL'),'admin');
$cs->set($dri->local_object('contact')->srid('AI1'),'tech');
$cs->add($dri->local_object('contact')->srid('PR1249'),'tech');
$R2=$E1.'<response>'.r().'<extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:recData><frnic:domain><frnic:name>ndd-de-test-0001.fr</frnic:name><frnic:reID>BEdemandeurID</frnic:reID><frnic:reDate>2009-01-01T00:00:00.0Z</frnic:reDate><frnic:reHldID>PR1249</frnic:reHldID><frnic:acID>BEactuelID</frnic:acID><frnic:acHldID>MM4567</frnic:acHldID></frnic:domain></frnic:recData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_recover_start('ndd-de-test-0001.fr',{contact=>$cs,auth=>{pw=>'NDCR20080229T173000.123456789'},keep_ds=>1});
is_string($R1,$E1.'<extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:command><frnic:recover op="request"><frnic:domain keepDS="1"><frnic:name>ndd-de-test-0001.fr</frnic:name><frnic:authInfo><domain:pw xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">NDCR20080229T173000.123456789</domain:pw></frnic:authInfo><frnic:registrant>PR1249</frnic:registrant><frnic:contact type="admin">VL</frnic:contact><frnic:contact type="tech">AI1</frnic:contact><frnic:contact type="tech">PR1249</frnic:contact></frnic:domain></frnic:recover><frnic:clTRID>ABC-12345</frnic:clTRID></frnic:command></frnic:ext></extension>'.$E2,'domain_recover_start build');
is($dri->get_info('reID'),'BEdemandeurID','domain_recover_start get_info(reID)');
is(''.$dri->get_info('reDate'),'2009-01-01T00:00:00','domain_recover_start get_info(reDate)');
is($dri->get_info('reHldID'),'PR1249','domain_recover_start get_info(reHldID)');
is($dri->get_info('acID'),'BEactuelID','domain_recover_start get_info(acID)');
is($dri->get_info('acHldID'),'MM4567','domain_recover_start get_info(acHldID)');

####################################################################################################
## §2.7

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">afnic.fr</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="1">af-1234-nic.fr</domain:name></domain:cd><domain:cd><domain:name avail="1">bois-guillaume.fr</domain:name></domain:cd><domain:cd><domain:name avail="0">paris.fr</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="0">trafiquants.fr</domain:name><domain:reason>Forbidden name</domain:reason></domain:cd><domain:cd><domain:name avail="0">toto.wf</domain:name><domain:reason>Zone not opened</domain:reason></domain:cd></domain:chkData></resData><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:chkData><frnic:domain><frnic:cd><frnic:name reserved="0" forbidden="0">afnic.fr</frnic:name></frnic:cd><frnic:cd><frnic:name reserved="0" forbidden="0">af-1234-nic.fr</frnic:name></frnic:cd><frnic:cd><frnic:name reserved="1" forbidden="0">bois-guillaume.fr</frnic:name><frnic:rsvReason>City name</frnic:rsvReason></frnic:cd><frnic:cd><frnic:name reserved="1" forbidden="0">paris.fr</frnic:name><frnic:rsvReason>City name</frnic:rsvReason></frnic:cd><frnic:cd><frnic:name reserved="0" forbidden="1">trafiquants.fr</frnic:name><frnic:fbdReason>Legal issue</frnic:fbdReason></frnic:cd><frnic:cd><frnic:name reserved="0" forbidden="0">toto.wf</frnic:name></frnic:cd></frnic:domain></frnic:chkData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check(qw/afnic.fr af-1234-nic.fr bois-guillaume.fr paris.fr trafiquants.fr toto.wf/);
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>afnic.fr</domain:name><domain:name>af-1234-nic.fr</domain:name><domain:name>bois-guillaume.fr</domain:name><domain:name>paris.fr</domain:name><domain:name>trafiquants.fr</domain:name><domain:name>toto.wf</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','afnic.fr'),1,'domain_check multi get_info(exist,domain1)');
is($dri->get_info('exist_reason','domain','afnic.fr'),'In use','domain_check multi get_info(exist_reason,domain1)');
is($dri->get_info('exist','domain','af-1234-nic.fr'),0,'domain_check multi get_info(exist,domain2)');
is($dri->get_info('exist','domain','bois-guillaume.fr'),0,'domain_check multi get_info(exist,domain3)');
is($dri->get_info('exist','domain','paris.fr'),1,'domain_check multi get_info(exist,domain4)');
is($dri->get_info('exist_reason','domain','paris.fr'),'In use','domain_check multi get_info(exist_reason,domain4)');
is($dri->get_info('exist','domain','trafiquants.fr'),1,'domain_check multi get_info(exist,domain5)');
is($dri->get_info('exist_reason','domain','trafiquants.fr'),'Forbidden name','domain_check multi get_info(exist_reason,domain5)');
is($dri->get_info('exist','domain','toto.wf'),1,'domain_check multi get_info(exist,domain6)');
is($dri->get_info('exist_reason','domain','toto.wf'),'Zone not opened','domain_check multi get_info(exist_reason,domain6)');
is($dri->get_info('reserved_reason','domain','bois-guillaume.fr'),'City name','domain_check multi get_info(reserved_reason,domain3)');
is($dri->get_info('reserved_reason','domain','paris.fr'),'City name','domain_check multi get_info(reserved_reason,domain4)');
is($dri->get_info('forbidden_reason','domain','trafiquants.fr'),'Legal issue','domain_check multi get_info(forbidden_reason,domain5)');
is($dri->get_info('forbidden','domain','afnic.fr'),0,'domain_check multi get_info(forbidden,domain1)');
is($dri->get_info('reserved','domain','afnic.fr'),0,'domain_check multi get_info(reserved,domain1)');
is($dri->get_info('reserved','domain','bois-guillaume.fr'),1,'domain_check multi get_info(reserved,domain3)');
is($dri->get_info('forbidden','domain','trafiquants.fr'),1,'domain_check multi get_info(forbidden,domain5)');

####################################################################################################
## §2.8.2

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>ndd-de-test-0001.fr</domain:name><domain:roid>DOM000000456987-FRNIC</domain:roid><domain:status s="ok"/><domain:registrant>MM4567</domain:registrant><domain:contact type="admin">NFC1</domain:contact><domain:contact type="tech">NFC1</domain:contact><domain:contact type="tech">VL</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.nic.fr</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.nic.fr</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.ndd-de-test-0001.fr</domain:hostName><domain:hostAddr ip="v4">192.93.0.1</domain:hostAddr><domain:hostAddr ip="v6">2001:660:3005:1::1:1</domain:hostAddr></domain:hostAttr></domain:ns><domain:host>ns.ndd-de-test-0001.fr</domain:host><domain:host>ns1234.ndd-de-test-0001.fr</domain:host><domain:clID>BEactuelID</domain:clID><domain:crDate>2008-12-25T00:00:00.0Z</domain:crDate><domain:exDate>2009-12-25T00:00:00.0Z</domain:exDate><domain:update>2009-01-10T00:00:00.0Z</domain:update><domain:authInfo><domain:pw>WarlordZ666</domain:pw></domain:authInfo></domain:infData></resData><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:infData><frnic:domain><frnic:status s="serverTradeProhibited"/><frnic:status s="serverRecoverProhibited"/></frnic:domain></frnic:infData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('ndd-de-test-0001.fr');
is($rc->is_success(),1,'domain_info is_success');
$s=$dri->get_info('status');
is_deeply([$s->list_status()],[qw/serverRecoverProhibited serverTradeProhibited/],'domain_info get_info(status) list_status');

####################################################################################################
## §3.1
## corrected misplacement of contact:id

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>VL99999</contact:id><contact:crDate>2008-11-20T00:00:00.0Z</contact:crDate></contact:creData></resData><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:creData><frnic:nhStatus new="1"/><frnic:idStatus>no</frnic:idStatus></frnic:creData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
my $co=$dri->local_object('contact');
$co->name('Levigneron');
$co->firstname('Vincent');
$co->org('AFNIC');
$co->street(['immeuble international','2, rue Stephenson','Montigny le Bretonneux']);
$co->city('Saint Quentin en Yvelines Cedex');
$co->pc('78181');
$co->cc('FR');
$co->voice('+33.0139308333');
$co->fax('+33.0139308301');
$co->email('vincent.levigneron@nic.fr');
$co->auth({pw=>'UnusedPassword'});
$co->disclose('N');
$co->birth({date=>'1968-07-20',place=>'76000, Rouen'});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AUTO</contact:id><contact:postalInfo type="loc"><contact:name>Levigneron</contact:name><contact:org>AFNIC</contact:org><contact:addr><contact:street>immeuble international</contact:street><contact:street>2, rue Stephenson</contact:street><contact:street>Montigny le Bretonneux</contact:street><contact:city>Saint Quentin en Yvelines Cedex</contact:city><contact:pc>78181</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.0139308333</contact:voice><contact:fax>+33.0139308301</contact:fax><contact:email>vincent.levigneron@nic.fr</contact:email><contact:authInfo><contact:pw>UnusedPassword</contact:pw></contact:authInfo></contact:create></create><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:create><frnic:contact><frnic:list>restrictedPublication</frnic:list><frnic:individualInfos><frnic:birthDate>1968-07-20</frnic:birthDate><frnic:birthCity>Rouen</frnic:birthCity><frnic:birthPc>76000</frnic:birthPc><frnic:birthCc>FR</frnic:birthCc></frnic:individualInfos><frnic:firstName>Vincent</frnic:firstName></frnic:contact></frnic:create></frnic:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create PP build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('id'),'VL99999','contact_create get_info(id)');
is($dri->get_info('action','contact','VL99999'),'create','contact_create get_info(action)');
is($dri->get_info('exist','contact','VL99999'),1,'contact_create get_info(exist)');
is($dri->get_info('new_handle','contact','VL99999'),1,'contact_create get_info(new_handle)');
is_deeply($dri->get_info('qualification','contact','VL99999'),{identification=>{value=>'no'}},'contact_create get_info(identification)');

$R2='';
$co=$dri->local_object('contact');
$co->name('Service des Réclamations');
$co->org('AFNIC Corp');
$co->street(['immeuble international','2, rue Stephenson','Montigny le Bretonneux']);
$co->city('Saint Quentin en Yvelines Cedex');
$co->pc('78181');
$co->cc('FR');
$co->voice('+33.0139308333');
$co->fax('+33.0139308301');
$co->email('vincent.levigneron@nic.fr');
$co->auth({pw=>'UnusedPassword'});
$co->legal_form('company');
$co->legal_id(123456789);
$co->legal_id_type('siren');
$co->trademark('27YOUPLA2345678');
$co->jo({date_declaration=>'1999-05-19',number=>5, page=>2, date_publication=>'1999-06-01'});

$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AUTO</contact:id><contact:postalInfo type="loc"><contact:name>Service des Réclamations</contact:name><contact:org>AFNIC Corp</contact:org><contact:addr><contact:street>immeuble international</contact:street><contact:street>2, rue Stephenson</contact:street><contact:street>Montigny le Bretonneux</contact:street><contact:city>Saint Quentin en Yvelines Cedex</contact:city><contact:pc>78181</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.0139308333</contact:voice><contact:fax>+33.0139308301</contact:fax><contact:email>vincent.levigneron@nic.fr</contact:email><contact:authInfo><contact:pw>UnusedPassword</contact:pw></contact:authInfo></contact:create></create><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:create><frnic:contact><frnic:legalEntityInfos><frnic:legalStatus s="company"/><frnic:siren>123456789</frnic:siren><frnic:trademark>27YOUPLA2345678</frnic:trademark><frnic:asso><frnic:decl>1999-05-19</frnic:decl><frnic:publ announce="5" page="2">1999-06-01</frnic:publ></frnic:asso></frnic:legalEntityInfos></frnic:contact></frnic:create></frnic:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create PM build');


$co=$dri->local_object('contact');
$co->name('Levigneron');
$co->org('AFNIC');
$co->street(['immeuble international','2, rue Stephenson','Montigny le Bretonneux']);
$co->city('Saint Quentin en Yvelines Cedex');
$co->pc('78181');
$co->cc('FR');
$co->voice('+33.0139308333');
$co->fax('+33.0139308301');
$co->email('vincent.levigneron@nic.fr');
$co->auth({pw=>'UnusedPassword'});
$co->legal_form('company');
$co->legal_id(123456789);
$co->legal_id_type('siren');
$co->qualification({identification=>{status=>'ok'},reachable=>{media=>'email',value=>1}});

$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AUTO</contact:id><contact:postalInfo type="loc"><contact:name>Levigneron</contact:name><contact:org>AFNIC</contact:org><contact:addr><contact:street>immeuble international</contact:street><contact:street>2, rue Stephenson</contact:street><contact:street>Montigny le Bretonneux</contact:street><contact:city>Saint Quentin en Yvelines Cedex</contact:city><contact:pc>78181</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.0139308333</contact:voice><contact:fax>+33.0139308301</contact:fax><contact:email>vincent.levigneron@nic.fr</contact:email><contact:authInfo><contact:pw>UnusedPassword</contact:pw></contact:authInfo></contact:create></create><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:create><frnic:contact><frnic:legalEntityInfos><frnic:idStatus>ok</frnic:idStatus><frnic:legalStatus s="company"/><frnic:siren>123456789</frnic:siren></frnic:legalEntityInfos><frnic:reachable media="email">1</frnic:reachable></frnic:contact></frnic:create></frnic:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create PM build qualification');

####################################################################################################
## §3.2

$co=$dri->local_object('contact')->srid('VL99999');
$toc=$dri->local_object('changes');
$toc->del('disclose','restrictedPublication');
$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>VL99999</contact:id></contact:update></update><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:update><frnic:contact><frnic:rem><frnic:list>restrictedPublication</frnic:list></frnic:rem></frnic:contact></frnic:update></frnic:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');


$co=$dri->local_object('contact')->srid('VL99999');
$toc=$dri->local_object('changes');
$toc->add('qualification',{identification=>{status=>'ok'},reachable=>{media=>'email',value=>1}});
$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>VL99999</contact:id></contact:update></update><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2" xsi:schemaLocation="http://www.afnic.fr/xml/epp/frnic-1.2 frnic-1.2.xsd"><frnic:update><frnic:contact><frnic:add><frnic:idStatus>ok</frnic:idStatus><frnic:reachable media="email">1</frnic:reachable></frnic:add></frnic:contact></frnic:update></frnic:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build qualification');


####################################################################################################
## §3.5

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>VL99999</contact:id><contact:roid>VL9999-FRNIC</contact:roid><contact:status s="linked"/><contact:postalInfo type="loc"><contact:name>Levigneron</contact:name><contact:org>AFNIC</contact:org><contact:addr><contact:street>immeuble international</contact:street><contact:street>2, rue Stephenson</contact:street><contact:street>Montigny le Bretonneux</contact:street><contact:city>Saint Quentin en Yvelines Cedex</contact:city><contact:pc>78181</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.0139308333</contact:voice><contact:fax>+33.0139308301</contact:fax><contact:email>vincent.levigneron@nic.fr</contact:email><contact:clID>BEactuelID</contact:clID><contact:crID>BEcreateurID</contact:crID><contact:crDate>2008-11-20T00:00:00.0Z</contact:crDate><contact:update>2008-12-25T00:00:00.0Z</contact:update></contact:infData></resData><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:infData><frnic:contact><frnic:firstName>Vincent</frnic:firstName><frnic:list>restrictedPublication</frnic:list><frnic:individualInfos><frnic:idStatus>ok</frnic:idStatus><frnic:birthDate>1968-07-20</frnic:birthDate><frnic:birthCity>Rouen</frnic:birthCity><frnic:birthPc>76000</frnic:birthPc><frnic:birthCc>FR</frnic:birthCc></frnic:individualInfos></frnic:contact></frnic:infData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$dri->contact_info($co);
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact::AFNIC','contact_info get_info(self)');
is($co->name(),'Levigneron','contact_info get_info(self) name');
is($co->firstname(),'Vincent','contact_info get_info(self) firstname');
is($co->disclose(),'N','contact_info get_info(self) disclose'); ## means <frnic:list>restrictedPublication</frnic:list>
my $b=$co->birth();
is($b->{date},'1968-07-20','contact_info get_info(self) birth date');
is($b->{place},'76000, Rouen','contact_info get_info(self) birth place');


$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>MO666</contact:id><contact:roid>MO666-FRNIC</contact:roid><contact:status s="linked"/><contact:postalInfo type="loc"><contact:name>Mobibus Outlaws</contact:name><contact:addr><contact:street>7, avenue monchignon</contact:street><contact:city>la Baule Escoublac</contact:city><contact:pc>44500</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.987654321</contact:voice><contact:email>toto@nic.fr</contact:email><contact:clID>>-wuhgejav499-.fr</contact:clID><contact:crID>>-wuhgejav499-.fr</contact:crID><contact:crDate>2010-10-12T07:49:45.0Z</contact:crDate><contact:upDate>2011-07-08T16:41:17.0Z</contact:upDate></contact:infData></resData><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:infData><frnic:contact><frnic:legalEntityInfos><frnic:idStatus when="2011-06-21T05:30:36" source="registry">ok</frnic:idStatus><frnic:legalStatus s="company"/><frnic:siren>444158265</frnic:siren></frnic:legalEntityInfos><frnic:obsoleted>0</frnic:obsoleted><frnic:reachable when="2011-06-21T05:30:36" media="email" source="registry">1</frnic:reachable></frnic:contact></frnic:infData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$dri->contact_info($dri->local_object('contact')->srid('MO666'));
$co=$dri->get_info('self');
my $q=$co->qualification();
is($q->{identification}->{value},'ok','contact_info qualification.identification.value');
is($q->{identification}->{source},'registry','contact_info qualification.identification.source');
is(''.$q->{identification}->{when},'2011-06-21T05:30:36','contact_info qualification.identification.when');
is_deeply($co->obsoleted(),{value => 0},'contact_info obsoleted.value');
is($q->{reachable}->{value},1,'contact_info qualification.reachable.value');
is($q->{reachable}->{media},'email','contact_info qualification.reachable.media');
is($q->{reachable}->{source},'registry','contact_info qualification.reachable.source');
is(''.$q->{reachable}->{when},'2011-06-21T05:30:36','contact_info qualification.reachable.when');

####################################################################################################
## Qualification

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="2849"><qDate>2009-05-05T07:52:50.0Z</qDate><msg>Holder identification prevents DNS announcement.</msg></msgQ><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:idtData><frnic:domain><frnic:name>nic.fr</frnic:name><frnic:status s="serverHold"/><frnic:registrant>XXX1234</frnic:registrant></frnic:domain></frnic:idtData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
my $msgid=$rc->get_data('message','session','last_id');
is($rc->get_data('message',$msgid,'object_type'),'domain','message object_type');
my $oid=$rc->get_data('message',$msgid,'object_id');
is($oid,'nic.fr','domain name');
$s=$rc->get_data('domain',$oid,'status');
isa_ok($s,'Net::DRI::Protocol::EPP::Core::Status','domain status');
is_deeply([$s->list_status()],['serverHold'],'domain status list_status()');
$cs=$rc->get_data('domain',$oid,'contact');
isa_ok($cs,'Net::DRI::Data::ContactSet','domain contact');
is_deeply([$cs->types()],['registrant'],'domain contact types');
my $c=$cs->get('registrant');
isa_ok($c,'Net::DRI::Data::Contact::AFNIC','domain contact registrant');
is($c->srid(),'XXX1234','domain contact srid()');



$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="100" id="3006545"><qDate>2011-08-29T15:13:00.0Z</qDate><msg>Qualification process begins.</msg></msgQ><extension><frnic:ext xmlns:frnic="http://www.afnic.fr/xml/epp/frnic-1.2"><frnic:resData><frnic:quaData><frnic:contact><frnic:id>ZNE51</frnic:id><frnic:qualificationProcess s="start"/><frnic:legalEntityInfos><frnic:idStatus>pending</frnic:idStatus><frnic:legalStatus s="association"/><frnic:siren>493020995</frnic:siren></frnic:legalEntityInfos><frnic:reachability><frnic:reStatus>pending</frnic:reStatus><frnic:voice>+33.123456789</frnic:voice><frnic:email>toto@nic.fr</frnic:email></frnic:reachability></frnic:contact></frnic:quaData></frnic:resData></frnic:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
$co=$rc->get_data('self');
is($co->srid(),'ZNE51','qualification notification contact srid');
$q=$co->qualification();
is($q->{process_status},'start','qualification notification contact qualification process_status');
is($q->{identification}->{value},'pending','qualification notification contact qualification identification value');
is($co->legal_form(),'association','qualification notification contact legal_form');
is($co->legal_id_type(),'siren','qualification notification contact legal_id_type');
is($co->legal_id(),'493020995','qualification notification contact legal_id');
is_deeply($q->{reachable},{status=>'pending',voice=>'+33.123456789',email=>'toto@nic.fr'},'qualification notification contact qualification reachable');


exit 0;
