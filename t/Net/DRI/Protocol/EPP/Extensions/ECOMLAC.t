#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 106;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('ECOMLAC');
$dri->target('ECOMLAC')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$co2,$cs,$toc,$s);

## epp:hello
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

### epp:poll
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

## epp:logout
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

## contact:create
$R2='';
$co=$dri->local_object('contact')->srid('conexample');
$co->name('Example Contact');
$co->street(['Example Street 1','Example Street 2','']);
$co->city('Example City');
$co->sp('Example State');
$co->pc('012345');
$co->cc('MX');
$co->voice('+52.123456789');
$co->fax('');
$co->email('example@example.lat');
$co->auth({pw=>'2fooBAR'});
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample</contact:id><contact:postalInfo type="loc"><contact:name>Example Contact</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:street/><contact:city>Example City</contact:city><contact:sp>Example State</contact:sp><contact:pc>012345</contact:pc><contact:cc>MX</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.123456789</contact:voice><contact:fax/><contact:email>example@example.lat</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:create></create><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');

## contact:check
# single
$R2='';
$rc=$dri->contact_check($dri->local_object('contact')->srid('conexample'));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command></epp>','contact_check build');
is($rc->is_success(),1,'contact_check is_success');
# multi - NOTE: max of 100 contact_check...
$R2='';
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('conexample001','conexample002','conexample003'));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample001</contact:id><contact:id>conexample002</contact:id><contact:id>conexample003</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command></epp>','contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');

## contact:info
$R2='';
$rc=$dri->contact_info($dri->local_object('contact')->srid('conexample')->auth({pw=>'2fooBAR'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command></epp>','contact_info build');
is($rc->is_success(),1,'contact_info is_success');

## contact:update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('conexample');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->name('Example Name');
$co2->street(['Example Street 1','Example Street 2','']);
$co2->city('Example City');
$co2->sp('Example State');
$co2->pc('012345');
$co2->cc('MX');
$co2->voice('+52.0123456789');
$co2->email('example@example.lat');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Example Name</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:street/><contact:city>Example City</contact:city><contact:sp>Example State</contact:sp><contact:pc>012345</contact:pc><contact:cc>MX</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.0123456789</contact:voice><contact:email>example@example.lat</contact:email></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## contact:delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->contact_delete($dri->local_object('contact')->srid('conexample'));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>conexample</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command></epp>','contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');

## host:create
$R2='';
$rc=$dri->host_create($dri->local_object('hosts')->add('ns.example.lat',['192.0.2.2'],[],1));
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.example.lat</host:name><host:addr ip="v4">192.0.2.2</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($rc->is_success(),1,'host_create is_success');
# external host
$rc=$dri->host_create('ns.google.com');
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.google.com</host:name></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create (external) build');
is($rc->is_success(),1,'host_create (external) is_success');

## host:check
$R2='';
$rc=$dri->host_check('ns.example.lat');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.example.lat</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($rc->is_success(),1,'host_check is_success');
# multi
$rc=$dri->host_check('ns1.example.lat','ns2.example.lat','ns3.example.lat');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.example.lat</host:name><host:name>ns2.example.lat</host:name><host:name>ns3.example.lat</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check multi build');
is($rc->is_success(),1,'host_check multi is_success');

## host:info
$R2='';
$rc=$dri->host_info('ns.example.com');
is_string($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.example.com</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($rc->is_success(),1,'host_info is_success');

## host:update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ip',$dri->local_object('hosts')->add('ns.example.lat',['192.168.100.2'],[],1));
$toc->del('ip',$dri->local_object('hosts')->add('ns.example.lat',['192.168.100.3'],[],1));
$rc=$dri->host_update('ns.example.lat',$toc);
is_string($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.example.lat</host:name><host:add><host:addr ip="v4">192.168.100.2</host:addr></host:add><host:rem><host:addr ip="v4">192.168.100.3</host:addr></host:rem></host:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

## host:delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->host_delete('ns.example.com');
is_string($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.example.com</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'host_delete build');
is($rc->is_success(),1,'host_delete is_success');

## domain:create
$R2='';
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('conexample'),'registrant');
$cs->set($dri->local_object('contact')->srid('conexample'),'admin');
$cs->set($dri->local_object('contact')->srid('conexample'),'billing');
$cs->set($dri->local_object('contact')->srid('conexample'),'tech');
$rc=$dri->domain_create('example.lat',{pure_create=>1,duration=>DateTime::Duration->new(years=>5),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name><domain:period unit="y">5</domain:period><domain:registrant>conexample</domain:registrant><domain:contact type="admin">conexample</domain:contact><domain:contact type="billing">conexample</domain:contact><domain:contact type="tech">conexample</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');

## domain:check
$R2='';
$rc=$dri->domain_check('example.lat');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
# multi
$rc=$dri->domain_check('example-available.lat','example-reserved.lat','example-in-use.lat');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example-available.lat</domain:name><domain:name>example-reserved.lat</domain:name><domain:name>example-in-use.lat</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');

## domain:info
$R2='';
$rc=$dri->domain_info('example.lat');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.lat</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');

## domain:update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('publish'));
$rc=$dri->domain_update('example.lat',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name><domain:add><domain:status s="clientHold"/></domain:add></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

## domain:delete
$R2='';
$rc=$dri->domain_delete('example.lat');
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

## domain:renew
$R2='';
$rc=$dri->domain_renew('example.lat',{current_expiration => DateTime->new(year=>2011,month=>8,day=>27),duration=>DateTime::Duration->new(years=>1)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name><domain:curExpDate>2011-08-27</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_renew is_success');

## domain:transfer (request)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('example.lat',{auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');

## domain:transfer (query)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('example.lat',{auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.lat</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($rc->is_success(),1,'domain_transfer_query is_success');

## rar:info (check the balance through EPP)
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="34" id="3418"/><resData><rar:infData xmlns:rar="http://www.nic.mx/rar-1.0" xsi:schemaLocation="http://www.nic.mx/rar-1.0 rar-1.0.xsd"><rar:id>rar_registrar</rar:id><rar:roid>RAR_REGISTRAR-LAT</rar:roid><rar:name>Registrar</rar:name><rar:balance>81.10</rar:balance></rar:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_balance();
#print Dumper($rc);
is_string($R1,$E1.'<command><info><rar:info xmlns:rar="http://www.nic.mx/rar-1.0" xsi:schemaLocation="http://www.nic.mx/rar-1.0 rar-1.0.xsd"/></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registrar_balance build');
is($rc->is_success(),1,'registrar_balance is_success');
is($dri->get_info('id'),'rar_registrar','registrar_balance get_info(id)');
is($dri->get_info('roid'),'RAR_REGISTRAR-LAT','registrar_balance get_info(roid)');
is($dri->get_info('name'),'Registrar','registrar_balance get_info(name)');
is($dri->get_info('balance'),'81.10','registrar_balance get_info(balance)');

## Domain Name Transfer Request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>2000-06-08T22:00:00.0Z</qDate><msg>Transfer requested.</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.lat</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),12345,'message get_info last_id 2');
is($dri->get_info('id','message',12345),12345,'message get_info id');
is(''.$dri->get_info('qdate','message',12345),'2000-06-08T22:00:00','message get_info qdate');
is($dri->get_info('content','message',12345),'Transfer requested.','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('name','message',12345),'example.lat','message get_info name');
is($dri->get_info('trStatus','message',12345),'pending','message get_info status');
is($dri->get_info('reID','message',12345),'ClientX','message get_info reID');
is(''.$dri->get_info('reDate','message',12345),'2000-06-08T22:00:00','message get_info reDate');
is($dri->get_info('acID','message',12345),'ClientY','message get_info acID');
is(''.$dri->get_info('acDate','message',12345),'2000-06-13T22:00:00','message get_info acDate');

## Response of Pending Domain Transfer Request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="316"><qDate>2008-02-21T16:08:01.0Z</qDate><msg>Pending transfer completed successfully.</msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name paResult="1">transfer-in-02.lat</domain:name><domain:paTRID><svTRID>OPL-688540</svTRID></domain:paTRID><domain:paDate>2008-02-21T16:08:01.0Z</domain:paDate></domain:panData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),316,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),316,'message get_info last_id 2');
is($dri->get_info('id','message',316),316,'message get_info id');
is(''.$dri->get_info('qdate','message',316),'2008-02-21T16:08:01','message get_info qdate');
is($dri->get_info('content','message',316),'Pending transfer completed successfully.','message get_info msg');
is($dri->get_info('lang','message',316),'en','message get_info lang');
is($dri->get_info('name','message',316),'transfer-in-02.lat','message get_info paResult');
is($dri->get_info('result','message',316),1,'message get_info name');
is($dri->get_info('svtrid','message',316),'OPL-688540','message get_info svTRID');
is(''.$dri->get_info('date','message',316),'2008-02-21T16:08:01','message get_info paDate');

## Messages defined by Registry .LAT
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="45" id="31"><qDate>2012-02-18T17:15:54.0Z</qDate><msg>Domain has been renewed.</msg></msgQ><extension><niclat-msg:niclat xmlns:niclat-msg="http://www.nic.mx/niclat-msg-1.0"><niclat-msg:msgTypeID>5</niclat-msg:msgTypeID><niclat-msg:object>suspended-01.lat</niclat-msg:object><niclat-msg:msDate>2012-02-18T17:15:54.0Z</niclat-msg:msDate><niclat-msg:exDate>2014-02-18T17:15:54.0Z</niclat-msg:exDate></niclat-msg:niclat></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),31,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),31,'message get_info last_id 2');
is($dri->get_info('id','message',31),31,'message get_info id');
is(''.$dri->get_info('qdate','message',31),'2012-02-18T17:15:54','message get_info qdate');
is($dri->get_info('content','message',31),'Domain has been renewed.','message get_info msg');
is($dri->get_info('msg_type_id','message',31),5,'message get_info msgTypeID');
is($dri->get_info('object','message',31),'suspended-01.lat','message get_info object');
is(''.$dri->get_info('msDate','message',31),'2012-02-18T17:15:54','message get_info msDate');
is(''.$dri->get_info('exDate','message',31),'2014-02-18T17:15:54','message get_info exDate');

## Administrative Status extension
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>extexample.lat</domain:name><domain:roid>foobar</domain:roid><domain:status s="ok"/><domain:registrant>latreg</domain:registrant><domain:contact type="admin">latadmin</domain:contact><domain:contact type="billing">latbilling</domain:contact><domain:contact type="tech">latech</domain:contact><domain:ns><domain:hostObj>ns1.extexample.lat</domain:hostObj><domain:hostObj>ns2.extexample.lat</domain:hostObj></domain:ns><domain:clID>rar_foobar</domain:clID><domain:crDate>2015-05-11T21:43:58.0Z</domain:crDate></domain:infData></resData><extension><nicmx-as:adminStatus xmlns:nicmx-as="http://www.nic.mx/nicmx-admstatus-1.1"><nicmx-as:value>suspendedByExternalAuthority</nicmx-as:value><nicmx-as:msg lang="en">The domain has been suspended by an URS determination.</nicmx-as:msg></nicmx-as:adminStatus></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('extexample.lat');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">extexample.lat</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('value'),'suspendedByExternalAuthority','domain_info get_info(value)');
is($dri->get_info('msg'),'The domain has been suspended by an URS determination.','domain_info get_info(msg)');
is($dri->get_info('lang'),'en','domain_info get_info(lang)');

# IDNs
## domain_create
my $idn = $dri->local_object('idn')->autodetect('idnexample.lat','es');
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>idnexample.lat</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('idnexample.lat',{pure_create=>1,auth=>{pw=>'2fooBAR'},'idn' => $idn});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>idnexample.lat</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="http://www.nic.lat/nicmx-idn-1.0" xsi:schemaLocation="http://www.nic.lat/nicmx-idn-1.0 nicmx-idn-1.0.xsd"><idn:lang>ES</idn:lang></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');
## domain_check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">idn-check-example.lat</domain:name></domain:cd></domain:chkData></resData><extension><idn:checkResData xmlns:idn="http://www.nic.lat/nicmx-idn-1.0" xsi:schemaLocation="http://www.nic.lat/nicmx-idn-1.0 nicmx-idn-1.0.xsd"><idn:name>foobar_name</idn:name><idn:base>foobar_base</idn:base><idn:lang>es</idn:lang></idn:checkResData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('idn-check-example.lat');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>idn-check-example.lat</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build_xml');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('idn_name'),'foobar_name','domain_check get_info(name)');
is($dri->get_info('idn_base'),'foobar_base','domain_check get_info(base)');
is($dri->get_info('idn_lang'),'es','domain_check get_info(lang)');
## domain_info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>idn-info-example.lat</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infoResData xmlns:idn="http://www.nic.lat/nicmx-idn-1.0" xsi:schemaLocation="http://www.nic.lat/nicmx-idn-1.0 nicmx-idn-1.0.xsd"><idn:lang>fr</idn:lang></idn:infoResData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('idn-info-example.lat');
is($dri->get_info('idn_lang'),'fr','domain_check get_info(lang)');
## domain_info - with ASCII format
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--tst-bma.lat</domain:name><domain:roid>DOMAIN_119-LAT</domain:roid><domain:status s="inactive"/><domain:registrant>monitoreonicmxr</domain:registrant><domain:contact type="admin">monitoreonicmxr</domain:contact><domain:contact type="billing">monitoreonicmxr</domain:contact><domain:contact type="tech">monitoreonicmxr</domain:contact><domain:clID>rar_monit</domain:clID><domain:crDate>2015-06-09T17:23:01.0Z</domain:crDate></domain:infData></resData><extension><rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:rgpStatus s="addPeriod"/></rgp:infData><idn:infoResData xmlns:idn="http://www.nic.lat/nicmx-idn-1.0"><idn:lang>ES</idn:lang></idn:infoResData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('xn--tst-bma.lat');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status) +RGP');
is($dri->get_info('idn_lang'),'ES','domain_check get_info(lang) idn');

exit 0;
