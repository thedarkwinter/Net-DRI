#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 85;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider => 'sidn',name=>'sidn_gtld'});
$dri->target('sidn_gtld')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$co2,$cs,$c1,$c2,$toc,$d);

## hello / greeting
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

## poll (op="req")
## host:update transaction successful
$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="9" id="100000"><qDate>2009-10-27T10:34:32.000Z</qDate><msg>1202 Change to name server ns1.bol.amsterdam processed</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>host:update</sidn-ext-epp:command><sidn-ext-epp:data><result code="1000"><msg>The name server has been changed after consideration.</msg></result><trID><clTRID>TestWZNMC10T50</clTRID><svTRID>100012</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
is($rc->get_data('message',100000,'command'),'host_update','notification host:update command');
is($rc->get_data('message',100000,'object_type'),'host','notification host:update object_type');
is($rc->get_data('message',100000,'result_code'),'1000','notification host:update result_code');
is($rc->get_data('message',100000,'result_msg'),'The name server has been changed after consideration.','notification host:update result_msg');
is($rc->get_data('message',100000,'trid'),'TestWZNMC10T50','notification host:update cltrid');
is($rc->get_data('message',100000,'svtrid'),'100012','notification host:update svtrid');
## contact:update transaction successful
$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="8" id="100001"><qDate>2009-10-27T10:35:32.000Z</qDate><msg>1100 Details of contact person TEA000031-GOEDA updated</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>contact:update</sidn-ext-epp:command><sidn-ext-epp:data><result code="1000"><msg>The contact person has been changed after consideration.</msg></result><trID><clTRID>TestWZNMC10T50</clTRID><svTRID>100006</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
is($rc->get_data('message',100001,'command'),'contact_update','notification contact:update command');
is($rc->get_data('message',100001,'object_type'),'contact','notification contact:update object_type');
is($rc->get_data('message',100001,'result_code'),'1000','notification contact:update result_code');
is($rc->get_data('message',100001,'result_msg'),'The contact person has been changed after consideration.','notification contact:update result_msg');
is($rc->get_data('message',100001,'trid'),'TestWZNMC10T50','notification contact:update cltrid');
is($rc->get_data('message',100001,'svtrid'),'100006','notification contact:update svtrid');
## domain:delete transaction successful
$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="6" id="100003"><qDate>2009-10-27T10:37:32.000Z</qDate><msg>2018 ’Delete domain name’ transaction for doris.amsterdam rejected</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>domain:delete</sidn-ext-epp:command><sidn-ext-epp:data><result code="2308"><msg>Deletion of the domain name has been considered and rejected because a constraint applies.</msg></result><trID><clTRID>TestVWDNC10T30</clTRID><svTRID>100045</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
is($rc->get_data('message',100003,'command'),'domain_delete','notification domain:delete command');
is($rc->get_data('message',100003,'object_type'),'domain','notification domain:delete object_type');
is($rc->get_data('message',100003,'result_code'),'2308','notification domain:delete result_code');
is($rc->get_data('message',100003,'result_msg'),'Deletion of the domain name has been considered and rejected because a constraint applies.','notification domain:delete result_msg');
is($rc->get_data('message',100003,'trid'),'TestVWDNC10T30','notification domain:delete cltrid');
is($rc->get_data('message',100003,'svtrid'),'100045','notification domain:delete svtrid');
## domain:transfer transaction successful
$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="4" id="100005"><qDate>2009-10-27T10:39:32.000Z</qDate><msg>1015 Transfer domain name domaintransfer31.amsterdam processed</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>domain:transfer</sidn-ext-epp:command><sidn-ext-epp:data><result code="1000"><msg>The domain name has been transferred.</msg></result><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domaintransfer31.amsterdam</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>104000</domain:reID><domain:reDate>2009-10-29T13:06:34.935Z</domain:reDate><domain:acID>102000</domain:acID><domain:acDate>2009-11-03T13:06:34.935Z</domain:acDate></domain:trnData></resData><trID><clTRID>C0101C10T10</clTRID><svTRID>100027</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
is($rc->get_data('message',100005,'command'),'domain_transfer','notification domain:transfer command');
is($rc->get_data('message',100005,'object_type'),'domain','notification domain:transfer object_type');
is($rc->get_data('message',100005,'result_code'),'1000','notification domain:transfer result_code');
is($rc->get_data('message',100005,'result_msg'),'The domain name has been transferred.','notification domain:transfer result_msg');
is($rc->get_data('message',100005,'name'),'domaintransfer31.amsterdam','notification domain:transfer name');
is($rc->get_data('message',100005,'trStatus'),'pending','notification domain:transfer trStatus');
is($rc->get_data('message',100005,'reID'),'104000','notification domain:transfer reID');
$d=$rc->get_data('message',100005,'reDate');
isa_ok($d,'DateTime','notification domain:transfer reDate');
is("".$d,'2009-10-29T13:06:34','notification domain:transfer reDate value');
is($rc->get_data('message',100005,'acID'),'102000','notification domain:transfer acID');
$d=$rc->get_data('message',100005,'acDate');
isa_ok($d,'DateTime','notification domain:transfer acDate');
is("".$d,'2009-11-03T13:06:34','notification domain:transfer acDate value');
is($rc->get_data('message',100005,'trid'),'C0101C10T10','notification domain:transfer cltrid');
is($rc->get_data('message',100005,'svtrid'),'100027','notification domain:transfer svtrid');
## domain:transfer-start transaction successful
$R2=$E1.'<response>'.r(1301,'The message has been picked up. Please confirm receipt to remove the message from the queue.').'<msgQ count="3" id="100006"><qDate>2009-10-27T10:40:32.000Z</qDate><msg>1014 Transfer domain name domaintransfer31.amsterdam is being processed</msg></msgQ><resData><sidn-ext-epp:pollData xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><sidn-ext-epp:command>domain:transfer-start</sidn-ext-epp:command><sidn-ext-epp:data><result code="1000"><msg>Transfer of the domain name has begun.</msg></result><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domaintransfer31.amsterdam</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>104000</domain:reID><domain:reDate>2009-10-29T13:06:34.935Z</domain:reDate><domain:acID>102000</domain:acID><domain:acDate>2009-11-03T13:06:34.935Z</domain:acDate></domain:trnData></resData><trID><svTRID>100027</svTRID></trID></sidn-ext-epp:data></sidn-ext-epp:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
is($rc->get_data('message',100006,'command'),'domain_transfer_start','notification domain:transfer-start command');
is($rc->get_data('message',100006,'object_type'),'domain','notification domain:transfer-start object_type');
is($rc->get_data('message',100006,'result_code'),'1000','notification domain:transfer-start result_code');
is($rc->get_data('message',100006,'result_msg'),'Transfer of the domain name has begun.','notification domain:transfer-start result_msg');
is($rc->get_data('message',100006,'name'),'domaintransfer31.amsterdam','notification domain:transfer-start name');
is($rc->get_data('message',100006,'trStatus'),'pending','notification domain:transfer-start trStatus');
is($rc->get_data('message',100006,'reID'),'104000','notification domain:transfer-start reID');
$d=$rc->get_data('message',100006,'reDate');
isa_ok($d,'DateTime','notification domain:transfer-start reDate');
is("".$d,'2009-10-29T13:06:34','notification domain:transfer-start reDate value');
is($rc->get_data('message',100006,'acID'),'102000','notification domain:transfer-start acID');
$d=$rc->get_data('message',100006,'acDate');
isa_ok($d,'DateTime','notification domain:transfer-start acDate');
is("".$d,'2009-11-03T13:06:34','notification domain:transfer-start acDate value');
is($rc->get_data('message',100006,'svtrid'),'100027','notification domain:transfer-start svtrid');

## poll (op="ack")
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_delete('100000');
is($rc->is_success(),1,'message_delete is_success');
is_string($R1,$E1.'<command><poll msgID="100000" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_delete build xml');

# domain check (multi) transaction successful
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="false">doris.amsterdam</domain:name></domain:cd><domain:cd><domain:name avail="true">dyris.amsterdam</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('doris.amsterdam','dyris.amsterdam');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>doris.amsterdam</domain:name><domain:name>dyris.amsterdam</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','doris.amsterdam'),1,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','dyris.amsterdam'),0,'domain_check multi get_info(exist) 2/2');
# domain info transaction successful
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>doris.amsterdam</domain:name><domain:roid>DNM_100028-SIDN</domain:roid><domain:status s="inactive"/><domain:registrant>CON009003-DEEL1</domain:registrant><domain:contact type="admin">CON009003-DEEL1</domain:contact><domain:contact type="tech">CON009003-DEEL1</domain:contact><domain:clID>DEEL1</domain:clID><domain:crID>DEEL1</domain:crID><domain:crDate>2013-06-19T08:17:56.000Z</domain:crDate><domain:exDate>2014-06-19T08:17:56.000Z</domain:exDate><domain:authInfo><domain:pw>token011</domain:pw></domain:authInfo></domain:infData></resData><extension><sidn-ext-epp:ext><sidn-ext-epp:infData><sidn-ext-epp:domain><sidn-ext-epp:limited>false</sidn-ext-epp:limited><sidn-ext-epp:optOut>false</sidn-ext-epp:optOut></sidn-ext-epp:domain></sidn-ext-epp:infData></sidn-ext-epp:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('doris.amsterdam');
is($rc->get_data('opt_out'),0,'domain_info opt_out');
is($rc->get_data('limited'),0,'domain_info limited');

# domain check transaction unsuccessful
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><response><result code="2308"><msg>Validation of the transaction failed.</msg></result><extension><sidn-ext-epp:ext><sidn-ext-epp:response><sidn-ext-epp:msg code="F0018" field="Domain name">A domain name must end with ?.amsterdam?.</sidn-ext-epp:msg></sidn-ext-epp:response></sidn-ext-epp:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar.amsterdam');
my $ext_info = $rc->{'info'}[0];
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>foobar.amsterdam</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($ext_info->{'field'},'Domain name','domain_check extension field');
is($ext_info->{'from'},'sidn','domain_check extension from');
is($ext_info->{'code'},'F0018','domain_check extension code');
is($ext_info->{'type'},'text','domain_check extension type');
is($ext_info->{'message'},'A domain name must end with ?.amsterdam?.','domain_check extension message');
# domain info transaction unsuccessful
$R2='<?xml version="1.0" encoding="utf-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:sidn-ext-epp="http://rxsd.domain-registry.nl/sidn-ext-epp-1.0"><response><result code="2303"><msg>The specified domain name is unknown.</msg></result><extension><sidn-ext-epp:ext><sidn-ext-epp:response><sidn-ext-epp:msg field="" code="T0001">De opgegeven domeinnaam is onbekend.</sidn-ext-epp:msg></sidn-ext-epp:response></sidn-ext-epp:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('foobar.amsterdam');
$ext_info = $rc->{'info'}[0];
is($ext_info->{'field'},'','domain_info extension field');
is($ext_info->{'from'},'sidn','domain_info extension from');
is($ext_info->{'code'},'T0001','domain_info extension code');
is($ext_info->{'type'},'text','domain_info extension type');
is($ext_info->{'message'},'De opgegeven domeinnaam is onbekend.','domain_info extension message');

# no tests for domain: create, update and delete (like the standard). The SIDN extension is the same format has was tested before (field, from, code, type, message)

# domain update (op=restore)
$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'report', report => {predata=>'Pre-delete registration data goes here. Both XML and free text are allowed.', postdata=>'Post-restore registration data goes here. Both XML and free text are allowed.',deltime=>DateTime->new(year=>2003,month=>7,day=>10,hour=>22),restime=>DateTime->new(year=>2003,month=>7,day=>20,hour=>22),reason=>'Registrant error.',statement1=>'This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.',statement2=>'The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.',other=>'Supporting information goes here.' }});
$rc=$dri->domain_update('doris.amsterdam',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>doris.amsterdam</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:restore op="report"><rgp:report><rgp:preData>Pre-delete registration data goes here. Both XML and free text are allowed.</rgp:preData><rgp:postData>Post-restore registration data goes here. Both XML and free text are allowed.</rgp:postData><rgp:delTime>2003-07-10T22:00:00.0Z</rgp:delTime><rgp:resTime>2003-07-20T22:00:00.0Z</rgp:resTime><rgp:resReason>Registrant error.</rgp:resReason><rgp:statement>This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.</rgp:statement><rgp:statement>The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.</rgp:statement><rgp:other>Supporting information goes here.</rgp:other></rgp:report></rgp:restore></rgp:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_report');
is($rc->is_success(),1,'domain_update is_success +RGP');

# domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example202.amsterdam</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('example202.amsterdam',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example202.amsterdam</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');

exit 0;
