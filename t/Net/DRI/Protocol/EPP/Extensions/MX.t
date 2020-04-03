#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 91;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('NICMexico');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$co,$d,$toc,$co2,$cs);

####################################################################################################
## Examples taken from 'EPP Manual 2.0 MX.PDF'

## 2.4 Service Discovery (epp:hello)
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

### 2.5 Service Messages (epp:poll)
## req
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
# delete / ack
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_delete('2659297');
is($rc->is_success(),1,'message_delete is_success');
is_string($R1,$E1.'<command><poll msgID="2659297" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_delete build xml');

## 3.2 Epp:logout
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');


## 4.2 Contact:create
$R2='';
$co=$dri->local_object('contact')->srid('sh8013');
$co->name('Example Contact');
#$co->org('Example Inc.');
$co->street(['Example Street 1','Example Street 2','']);
$co->city('Example City');
$co->sp('Example State');
$co->pc('012345');
$co->cc('MX');
$co->voice('+52.123456789');
$co->fax('');
$co->email('example@example.mx');
$co->auth({pw=>'2fooBAR'});
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:name>Example Contact</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:street/><contact:city>Example City</contact:city><contact:sp>Example State</contact:sp><contact:pc>012345</contact:pc><contact:cc>MX</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.123456789</contact:voice><contact:fax/><contact:email>example@example.mx</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');

## 4.3 Contact:check
# single
$R2='';
$rc=$dri->contact_check($dri->local_object('contact')->srid('sh8013'));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command></epp>','contact_check build');
is($rc->is_success(),1,'contact_check is_success');
# multi - NOTE: max of 100 contact_check...
$R2='';
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('sh8001','sh8002','sh8003'));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8001</contact:id><contact:id>sh8002</contact:id><contact:id>sh8003</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command></epp>','contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');

## 4.4 Contact:info
$R2='';
$rc=$dri->contact_info($dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command></epp>','contact_info build');
is($rc->is_success(),1,'contact_info is_success');

## 4.5 Contact:update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->name('Example Name');
$co2->street(['Example Street 1','Example Street 2','']);
$co2->city('Example City');
$co2->sp('Example State');
$co2->pc('012345');
$co2->cc('MX');
$co2->voice('+52.0123456789');
$co2->email('example@example.mx');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Example Name</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:street/><contact:city>Example City</contact:city><contact:sp>Example State</contact:sp><contact:pc>012345</contact:pc><contact:cc>MX</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.0123456789</contact:voice><contact:email>example@example.mx</contact:email></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');


## 5.1 Host:create
$R2='';
$rc=$dri->host_create($dri->local_object('hosts')->add('ns.example.mx',['192.0.2.2'],[],1));
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.example.mx</host:name><host:addr ip="v4">192.0.2.2</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($rc->is_success(),1,'host_create is_success');
# external host
$rc=$dri->host_create('ns.google.com');
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.google.com</host:name></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create (external) build');
is($rc->is_success(),1,'host_create (external) is_success');

## 5.2 Host:check
$R2='';
$rc=$dri->host_check('ns.example.mx');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.example.mx</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($rc->is_success(),1,'host_check is_success');
# multi
$rc=$dri->host_check('ns1.example.mx','ns2.example.mx','ns3.example.mx');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns1.example.mx</host:name><host:name>ns2.example.mx</host:name><host:name>ns3.example.mx</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check multi build');
is($rc->is_success(),1,'host_check multi is_success');

## 5.3 Host:info
$R2='';
$rc=$dri->host_info('ns.example.mx');
is_string($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.example.mx</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($rc->is_success(),1,'host_info is_success');

## 5.4 Host:update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ip',$dri->local_object('hosts')->add('ns.example.mx',['192.168.100.2'],[],1));
$toc->del('ip',$dri->local_object('hosts')->add('ns.example.mx',['192.168.100.3'],[],1));
$rc=$dri->host_update('ns.example.mx',$toc);
is_string($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.example.mx</host:name><host:add><host:addr ip="v4">192.168.100.2</host:addr></host:add><host:rem><host:addr ip="v4">192.168.100.3</host:addr></host:rem></host:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

## 5.5 Host:delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->host_delete('ns.example.mx');
is_string($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns.example.mx</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'host_delete build');
is($rc->is_success(),1,'host_delete is_success');


## 6.1 Domain:create
# TODO: check the problem when creating with months instead of years :(
$R2='';
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('reg1'),'registrant');
$cs->set($dri->local_object('contact')->srid('adm1'),'admin');
$cs->set($dri->local_object('contact')->srid('bil1'),'billing');
$cs->set($dri->local_object('contact')->srid('tec1'),'tech');
$rc=$dri->domain_create('example.mx',{pure_create=>1,duration=>DateTime::Duration->new(years=>5),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name><domain:period unit="y">5</domain:period><domain:registrant>reg1</domain:registrant><domain:contact type="admin">adm1</domain:contact><domain:contact type="billing">bil1</domain:contact><domain:contact type="tech">tec1</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');

## 6.2 Domain:check
$R2='';
$rc=$dri->domain_check('example.mx');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
# multi
$rc=$dri->domain_check('example-available.mx','example-reserved.mx','example-in-use.mx');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-available.mx</domain:name><domain:name>example-reserved.mx</domain:name><domain:name>example-in-use.mx</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');

## 6.3 Domain:info
$R2='';
$rc=$dri->domain_info('example.mx');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">example.mx</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');

## 6.4 Domain:delete
$R2='';
$rc=$dri->domain_delete('example.mx');
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

## 6.5 Domain:renew
$R2='';
$rc=$dri->domain_renew('example.mx',{current_expiration => DateTime->new(year=>2011,month=>8,day=>27),duration=>DateTime::Duration->new(years=>1)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name><domain:curExpDate>2011-08-27</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_renew is_success');

## 6.6 Domain:update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('publish'));
$rc=$dri->domain_update('example.mx',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name><domain:add><domain:status s="clientHold"/></domain:add></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

## 6.7 Domain:restore
$R2='';
$rc=$dri->domain_restore(qw/example.mx/);
is_string($R1,$E1.'<command><renew><nicmx-domrst:restore xmlns:nicmx-domrst="http://www.nic.mx/nicmx-domrst-1.0"><nicmx-domrst:name>example.mx</nicmx-domrst:name></nicmx-domrst:restore></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_restore build');
is($rc->is_success(),1,'domain_restore is_success');

## 6.8 Domain:transfer
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('example.mx',{auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.mx</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');

## 6.9 Domain:transfer query
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('example.com.mx',{auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com.mx</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($rc->is_success(),1,'domain_transfer_query is_success');

## 7.1 Rar:info (check the balance through EPP)
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="34" id="3418"/><resData><rar:infData xmlns:rar="http://www.nic.mx/rar-1.0"><rar:id>12345</rar:id><rar:roid>12345-MX</rar:roid><rar:name>reg-mx_example</rar:name><rar:balance>81.10</rar:balance></rar:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_balance();
is_string($R1,$E1.'<command><info><rar:info xmlns:rar="http://www.nic.mx/rar-1.0"/></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registrar_balance build');
is($rc->is_success(),1,'registrar_balance is_success');
is($dri->get_info('id'),'12345','registrar_balance get_info(id)');
is($dri->get_info('roid'),'12345-MX','registrar_balance get_info(roid)');
is($dri->get_info('name'),'reg-mx_example','registrar_balance get_info(name)');
is($dri->get_info('balance'),'81.10','registrar_balance get_info(balance)');


## 8.1 Domain Name Transfer Request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>2000-06-08T22:00:00.0Z</qDate><msg>Transfer requested.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com.mx</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),12345,'message get_info last_id 2');
is($dri->get_info('id','message',12345),12345,'message get_info id');
is(''.$dri->get_info('qdate','message',12345),'2000-06-08T22:00:00','message get_info qdate');
is($dri->get_info('content','message',12345),'Transfer requested.','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('name','message',12345),'example.com.mx','message get_info name');
is($dri->get_info('trStatus','message',12345),'pending','message get_info status');
is($dri->get_info('reID','message',12345),'ClientX','message get_info reID');
is(''.$dri->get_info('reDate','message',12345),'2000-06-08T22:00:00','message get_info reDate');
is($dri->get_info('acID','message',12345),'ClientY','message get_info acID');
is(''.$dri->get_info('acDate','message',12345),'2000-06-13T22:00:00','message get_info acDate');

## 8.2 Response of Pending Domain Transfer Request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="316"><qDate>2008-02-21T16:08:01.0Z</qDate><msg>Pending transfer completed successfully.</msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name paResult="1">transfer-in-02.com.mx</domain:name><domain:paTRID><svTRID>OPL-688540</svTRID></domain:paTRID><domain:paDate>2008-02-21T16:08:01.0Z</domain:paDate></domain:panData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),316,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),316,'message get_info last_id 2');
is($dri->get_info('id','message',316),316,'message get_info id');
is(''.$dri->get_info('qdate','message',316),'2008-02-21T16:08:01','message get_info qdate');
is($dri->get_info('content','message',316),'Pending transfer completed successfully.','message get_info msg');
is($dri->get_info('lang','message',316),'en','message get_info lang');
is($dri->get_info('name','message',316),'transfer-in-02.com.mx','message get_info paResult');
is($dri->get_info('result','message',316),1,'message get_info name');
is($dri->get_info('svtrid','message',316),'OPL-688540','message get_info svTRID');
is(''.$dri->get_info('date','message',316),'2008-02-21T16:08:01','message get_info paDate');

## 8.3 Messages defined by Registry .MX
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="45" id="31"><qDate>2008-02-18T17:15:54.0Z</qDate><msg>Domain creation pending, waiting for documents.</msg></msgQ><extension><nicmx-msg:nicmx xmlns:nicmx-msg="http://www.nic.mx/nicmx-msg-1.0"><nicmx-msg:msgTypeID>4</nicmx-msg:msgTypeID><nicmx-msg:object>transfer-01.edu.mx</nicmx-msg:object><nicmx-msg:msDate>2008-02-18T17:15:54.0Z</nicmx-msg:msDate></nicmx-msg:nicmx></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),31,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),31,'message get_info last_id 2');
is($dri->get_info('id','message',31),31,'message get_info id');
is(''.$dri->get_info('qdate','message',31),'2008-02-18T17:15:54','message get_info qdate');
is($dri->get_info('content','message',31),'Domain creation pending, waiting for documents.','message get_info msg');
is($dri->get_info('lang','message',31),'en','message get_info lang');
is($dri->get_info('msg_type_id','message',31),4,'message get_info msgTypeID');
is($dri->get_info('object','message',31),'transfer-01.edu.mx','message get_info object');
is($dri->get_info('name','message',31),'transfer-01.edu.mx','message get_info name');
is($dri->get_info('object_id','message',31),'transfer-01.edu.mx','message get_info object_id');
is(''.$dri->get_info('msDate','message',31),'2008-02-18T17:15:54','message get_info msDate');

####################################################################################################
exit 0;
