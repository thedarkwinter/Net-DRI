#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 154;
use Test::Exception;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('FICORA');
$dri->target('FICORA')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c,$e);
my ($c,$cs,$c1,$c2,$c3,$ns);

## Hello
$R2=$E1.'<greeting><svID>Ficora EPP Server</svID><svDate>2014-11-11T14:37:11.9720308+02:00</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:nsset-1.2</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:keyset-1.3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:domain-ext-1.0</extURI></svcExtension></svcMenu><dcp><access><personal/></access><statement><purpose><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Ficora EPP Server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2014-11-11T14:37:11','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:nsset-1.2','urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:keyset-1.3'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:domain-ext-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:domain-ext-1.0'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><personal/></access><statement><purpose><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');

## Login
$R2='';
$rc=$dri->process('session','login',['AsiakasX','foo-BAR2',{client_newpassword => 'bar-FOO2'}]);
is($R1,$E1.'<command><login><clID>AsiakasX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:nsset-1.2</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:keyset-1.3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:domain-ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

## Logout
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

## Poll - Req request
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is_string($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrieve build xml');
## Poll - Ack request
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_delete('b4d5ae3f-0014-4087-9a1e-a3a400bb202f');
is($rc->is_success(),1,'message_delete is_success');
is_string($R1,$E1.'<command><poll msgID="b4d5ae3f-0014-4087-9a1e-a3a400bb202f" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_delete build xml');

## Check Balance
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><balanceamount>123</balanceamount><timestamp>1999-04-03T22:00:00.0Z</timestamp></resData><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$rc=$dri->registrar_balance();
is_string($R1,$E1.'<command><check><balance/></check><clTRID>ABC-12345</clTRID></command>'.$E2,'registrar_balance build');
is($rc->is_success(),1,'registrar_balance is_success');
is($dri->get_info('balanceamount'),'123','registrar_balance get_info(balanceamount)');
is($dri->get_info('timestamp'),'1999-04-03T22:00:00.0Z','registrar_balance get_info(timestamp)');

## Auto renew
$R2='';
$rc=$dri->domain_autorenew('example-autorenew.fi',{value=>1});
is($R1,$E1.'<command><renew><domain:autorenew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-autorenew.fi</domain:name><domain:value>1</domain:value></domain:autorenew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_autorenew is_success');
# test for value different than 0,1
throws_ok { $dri->domain_autorenew('example-autorenew.fi',{value=>2}) } qr/Invalid parameters: value must be 0 or 1/, 'domain_autorenew - parse invalid param value: 2';
throws_ok { $dri->domain_autorenew('example-autorenew.fi',{value=>-1}) } qr/Invalid parameters: value must be 0 or 1/, 'domain_autorenew - parse invalid param value: -1';

## Domain check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">foobar1.fi</domain:name></domain:cd><domain:cd><domain:name avail="0">foobar2.fi</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="1">foobar3.fi</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar1.fi','foobar2.fi','foobar3.fi');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>foobar1.fi</domain:name><domain:name>foobar2.fi</domain:name><domain:name>foobar3.fi</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','foobar1.fi'),0,'domain_check multi get_info(exist) 1/3');
is($dri->get_info('exist','domain','foobar2.fi'),1,'domain_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','domain','foobar2.fi'),'In use','domain_check multi get_info(exist_reason)');
is($dri->get_info('exist','domain','foobar3.fi'),0,'domain_check multi get_info(exist) 3/3');

## Domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.fi</domain:name><domain:registrylock>1</domain:registrylock><domain:autorenew>1</domain:autorenew><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo><domain:dsData><domain:keyTag>12345</domain:keyTag><domain:alg>3</domain:alg><domain:digestType>1</domain:digestType><domain:digest>38EC35D5B3A34B33C99B</domain:digest><domain:keyData><domain:flags>257</domain:flags><domain:protocol>233</domain:protocol><domain:alg>1</domain:alg><domain:pubKey>AQPJ////4Q==</domain:pubKey></domain:keyData></domain:dsData><domain:dsData><domain:keyTag>12345</domain:keyTag><domain:alg>3</domain:alg><domain:digestType>1</domain:digestType><domain:digest>38EC35D5B3A34B33C99B</domain:digest><domain:keyData><domain:flags>257</domain:flags><domain:protocol>233</domain:protocol><domain:alg>1</domain:alg><domain:pubKey>AQPJ////4Q==</domain:pubKey></domain:keyData></domain:dsData></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.fi',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">example.fi</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'example.fi','domain_info get_info(name)');
is($dri->get_info('registrylock'),1,'domain_info get_info(registrylock)');
is($dri->get_info('autorenew'),1,'domain_info get_info(autorenew)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
is($s->get('tech')->srid(),'sh8013','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(subordinate_hosts)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns1.example.net'],'domain_info get_info(host) get_names');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns1.example.net'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');
is($dri->get_info('crID'),'ClientY','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_info get_info(exDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','domain_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','domain_info get_info(trDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
is($dri->get_info('exist'),1,'domain_info get_info(exist) +SecDNS 1');
is($dri->protocol()->ns()->{secDNS},'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1 only');


## Domain transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.fi</domain:name><domain:trStatus>Transferred</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('example.fi',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.fi</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'Transferred','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_start get_info(acID)');
##########
##########


## Domain create - test based on recent documentation (their sample use both: hostObj AND hostAttr - by the RFC should be only one! - Net-DRI is using hostAttr only!)
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>esimerkki.fi</domain:name><domain:crDate>2014-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2016-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('haltijantunnus');
$c3=$dri->local_object('contact')->srid('tekninen');
$cs->set($c1,'registrant');
$cs->set($c3,'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns2.example.net',[],[],1);
$rc=$dri->domain_create('esimerkki.fi',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dh,contact=>$cs,auth=>{pw=>'salasana'},secdns=>[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',maxSigLife=>604800}]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>esimerkki.fi</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.net</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>haltijantunnus</domain:registrant><domain:contact type="tech">tekninen</domain:contact><domain:authInfo><domain:pw>salasana</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2014-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2016-04-03T22:00:00','domain_create get_info(exDate) value');

# test => <domain:registrant> is mandatory (check if return notification about insufficient params)
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('haltijantunnus');
$c3=$dri->local_object('contact')->srid('tekninen');
# $cs->set($c1,'registrant');
$cs->set($c3,'tech');
throws_ok { $dri->domain_create('noregisrant.fi',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'foobarnoreg'}} ) } qr/Registrant contact required for FICORA/, 'domain_create - no contact type registrant';

# test => <domain:period> is mandatory (check if return notification about insufficient params)
$cs->set($c1,'registrant');
throws_ok { $dri->domain_create('noregisrant.fi',{pure_create=>1,contact=>$cs,auth=>{pw=>'foobarnoreg'}} ) } qr/Period required for FICORA/, 'domain_create - no period';
##########
##########


## Domain delete

# test with only delete command
$R2='';
$rc=$dri->domain_delete('exampleonlydelete.fi',{pure_delete=>1});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>exampleonlydelete.fi</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete (simple) build');
is($rc->is_success(),1,'domain_delete (simple) is_success');

# test with scheduled delete time
# NOTE: check the response code. they return 1001 for scheduled domain delete command. they only return 1000 for domains deleted or delete is canceled - check next test!
$R2=$E1.'<response><result code="1001"><msg>Command completed successfully; action pending</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ </svTRID></trID></response>'.$E2;
$rc=$dri->domain_delete('example-scheduled-delete.fi',{delDate=>DateTime->new(year=>2015,month=>1,day=>1)});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-scheduled-delete.fi</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="urn:ietf:params:xml:ns:domain-ext-1.0"><domain-ext:schedule><domain-ext:delDate>2015-01-01T00:00:00.0Z</domain-ext:delDate></domain-ext:schedule></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete (scheduled) build');
is($rc->is_success(),1,'domain_delete_schedule is_success');
# lets add a test to check invalid delDate param
throws_ok { $dri->domain_delete('example-scheduled-delete.fi',{delDate=>1}) } qr/must be a DateTime object/, 'domain_delete_schedule - wrong delDate format';

# test domain delete is cancelled
$R2=$E1.'<response>'.r().'</response>'.$E2;
$rc=$dri->domain_delete('example-delete-cancelled.fi',{cancel=>1});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-delete-cancelled.fi</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="urn:ietf:params:xml:ns:domain-ext-1.0"><domain-ext:cancel/></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete (cancelled) build');
is($rc->is_success(),1,'domain_delete_cancel is_success');
##########
##########


## Domain update
$R2='';
my $toc=$dri->local_object('changes');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns2.example.net',[],[],1);
$toc->add('ns',$dh);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mak21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('publish','Payment overdue.'));
$toc->del('ns',$dh);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('C4000'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('update'));
$toc->del('auth',{pw=>'2BARfoo', pwregistranttransfer=>'2BARfoo'});
$toc->set('registrant',$dri->local_object('contact')->srid('C5000'));
$toc->set('auth',{pw=>'2BARfoo', pwregistranttransfer=>'2BARfoo'});
$toc->set('registrylock',
  {
    type            =>  'activate',
    smsnumber       =>  ['+2314s12312','+2314s12316','+2314s12318'],
    numbertosend    =>  ['1423','1424','1425'],
    authkey         =>  '7867896f896sadf9786',
  }
);
$toc->del('secdns',
  [
    {
      keyTag        =>  '12345',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B33C99B',
      key_flags     =>  '257',
      key_protocol  =>  '233',
      key_alg       =>  '1',
      key_pubKey    =>  'AQPJ////4Q=='
    },
    {
      keyTag        =>  '12345',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B33C99B',
      key_flags     =>  '257',
      key_protocol  =>  '233',
      key_alg       =>  '1',
      key_pubKey    =>  'AQPJ////4Q=='
    }
  ]
);
$toc->add('secdns',
  [
    {
      keyTag        =>  '12346',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B44C39B',
      key_flags     =>  '257',
      key_protocol  =>  '233',
      key_alg       =>  '1',
      key_pubKey    =>  'AQPJ////4Q=='
    },
    {
      keyTag        =>  '12346',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B44C39B',
      key_flags     =>  '257',
      key_protocol  =>  '233',
      key_alg       =>  '1',
      key_pubKey    =>  'AQPJ////4Q=='
    }
  ]
);
$rc=$dri->domain_update('example.fi',$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.fi</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.net</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">mak21</domain:contact><domain:status lang="en" s="clientHold">Payment overdue.</domain:status></domain:add><domain:rem><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.net</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">C4000</domain:contact><domain:status s="clientUpdateProhibited"/><domain:authInfo><domain:pw>2BARfoo</domain:pw><domain:pwregistranttransfer>2BARfoo</domain:pwregistranttransfer></domain:authInfo></domain:rem><domain:chg><domain:registrant>C5000</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw><domain:pwregistranttransfer>2BARfoo</domain:pwregistranttransfer></domain:authInfo><domain:registrylock type="activate"><domain:smsnumber>+2314s12312</domain:smsnumber><domain:smsnumber>+2314s12316</domain:smsnumber><domain:smsnumber>+2314s12318</domain:smsnumber><domain:numbertosend>1423</domain:numbertosend><domain:numbertosend>1424</domain:numbertosend><domain:numbertosend>1425</domain:numbertosend><domain:authkey>7867896f896sadf9786</domain:authkey></domain:registrylock></domain:chg></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:rem><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B33C99B</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>233</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B33C99B</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>233</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:rem><secDNS:add><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>233</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>233</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update build');
is($rc->is_success(),1,'domain_update is_success');
# test to send invalid registrylock type attribute
$toc->set('registrylock',{type=>'foobar'});
throws_ok { $dri->domain_update('example.fi',$toc) } qr/registrylock and need to be: activate, deactivate, requestkey/, 'domain_update - parse invalid registrylock type attribute';


# From technical documentation
# Chapter 7.2 - Registrar change
#
# Domain name registrar (ISP) change happens by creating a transfer key, providing it to
# the new registrar and ultimately the new registrar should transfer the domain to itself.
# Registrar transfer key expires in one month after creating the key. In this example, the
# new registrar adds new name servers to the domain that is transferred. If the domain
# had DNSSec in use prior to transfer, they will be removed. Removal of registrar
# transfer key is also depicted below

# creating registrar transfer key
$R2='';
$rc=$dri->domain_update('creating-registrar-transfer-key.fi',$dri->local_object('changes')->set('auth',{pw=>'newPassword1!'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>creating-registrar-transfer-key.fi</domain:name><domain:chg><domain:authInfo><domain:pw>newPassword1!</domain:pw></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>','domain_update create registrar transfer key build');
is($rc->is_success(),1,'domain_update create registrar transfer key is_success');

# new registrar sends transfer request (domain:transfer)
$R2='';
$rc=$dri->domain_transfer_start('example.fi',{auth=>{pw=>'newPassword1!'}});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.fi</domain:name><domain:authInfo><domain:pw>newPassword1!</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');

# registrar removes transfer key
$R2='';
$rc=$dri->domain_update('remove-registrar-transfer-key.fi',$dri->local_object('changes')->del('auth',{pw=>'newPassword1!'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>remove-registrar-transfer-key.fi</domain:name><domain:rem><domain:authInfo><domain:pw>newPassword1!</domain:pw></domain:authInfo></domain:rem></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>','domain_update remove registrar transfer key build');
is($rc->is_success(),1,'domain_update create registrar transfer key is_success');



# From technical documentation
# Chapter 7.3 - Registrant change
#
# Domain registrar may start registrant (previously holder) change process. The process
# requires a transfer key if the register number or holder type of the registrant will
# change. Starting the change process will send an email to the registrant that contains
# the transfer key. The key is generated by the system and is valid for one month.

# requesting registrant change key
$R2='';
$rc=$dri->domain_update('example-request-change-registrant-key.fi',$dri->local_object('changes')->set('auth',{pwregistranttransfer=>'new'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-request-change-registrant-key.fi</domain:name><domain:chg><domain:authInfo><domain:pwregistranttransfer>new</domain:pwregistranttransfer></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>','domain_update request registrant transfer key build');
is($rc->is_success(),1,'domain_update request registrant transfer key is_success');

# registrant change
$R2='';
$toc=$dri->local_object('changes');
$toc->set('registrant',$dri->local_object('contact')->srid('newRegistrantUsername'));
$toc->set('auth',{pwregistranttransfer=>'newregpass'});
$rc=$dri->domain_update('example-change-registrant.fi',$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example-change-registrant.fi</domain:name><domain:chg><domain:registrant>newRegistrantUsername</domain:registrant><domain:authInfo><domain:pwregistranttransfer>newregpass</domain:pwregistranttransfer></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>','domain_update request registrant change build');
is($rc->is_success(),1,'domain_update request registrant change is_success');

##########
##########


## Domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>esimerkki.fi</domain:name><domain:exDate>2016-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('esimerkki.fi',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2014,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>esimerkki.fi</domain:name><domain:curExpDate>2014-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2016-04-03T22:00:00','domain_renew get_info(exDate) value');
##########
##########


## Contact check
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:cd><contact:id avail="1">username1</contact:id></contact:cd><contact:cd><contact:id avail="0">username2</contact:id><contact:reason>In use</contact:reason></contact:cd><contact:cd><contact:id avail="1">username3</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('username1','username2','username3'));
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>username1</contact:id><contact:id>username2</contact:id><contact:id>username3</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');
is($dri->get_info('exist','contact','username1'),0,'contact_check multi get_info(exist) 1/3');
is($dri->get_info('exist','contact','username2'),1,'contact_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','contact','username2'),'In use','contact_check multi get_info(exist_reason)');
is($dri->get_info('exist','contact','username3'),0,'contact_check multi get_info(exist) 3/3');
##########
##########


## Contact info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:firstname>John Doe</contact:firstname><contact:lastname>John Doe</contact:lastname><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+358401231234</contact:voice><contact:email>jdoe@example.com</contact:email><contact:legalemail>jdoe@example.com</contact:legalemail><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:disclose flag="0"><contact:voice/><contact:email/><contact:address/></contact:disclose></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'sh8013','contact_info get_info(self) srid');
is($co->firstname(),'John Doe','contact_info get_info(self) firstname');
is($co->lastname(),'John Doe','contact_info get_info(self) lastname');
is($co->org(),'Example Inc.','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['123 Example Dr.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Dulles','contact_info get_info(self) city');
is($co->sp(),'VA','contact_info get_info(self) sp');
is($co->pc(),'20166-6503','contact_info get_info(self) pc');
is($co->cc(),'US','contact_info get_info(self) cc');
is($co->voice(),'+358401231234x1234','contact_info get_info(self) voice');
is($co->email(),'jdoe@example.com','contact_info get_info(self) email');
is($co->legalemail(),'jdoe@example.com','contact_info get_info(self) legalemail');
is($dri->get_info('clID'),'ClientY','contact_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');
is_deeply($co->disclose(),{voice=>0,email=>0,address=>0},'contact_info get_info(self) disclose');
##########
##########


## Contact create
$R2='';
$co=$dri->local_object('contact');
$co->srid('sha1');
$co->role(5);
$co->type(1);
$co->isfinnish(1);
$co->firstname('Essi');
$co->lastname('Esimerkki Oy');
$co->name('HR');
$co->org('Esimerkki Oy');
$co->birthdate('2005-04-03T22:00:00.0Z');
$co->identity('123423A123F');
$co->registernumber('1234312SFAD-5');
$co->street(['123 Example Dr.','','']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.com');
$co->legalemail('jdoe@example.com');
$co->disclose({addr=>0,email=>0});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sha1</contact:id><contact:role>5</contact:role><contact:type>1</contact:type><contact:postalInfo type="loc"><contact:isfinnish>1</contact:isfinnish><contact:firstname>Essi</contact:firstname><contact:lastname>Esimerkki Oy</contact:lastname><contact:name>HR</contact:name><contact:org>Esimerkki Oy</contact:org><contact:birthDate>2005-04-03T22:00:00.0Z</contact:birthDate><contact:identity>123423A123F</contact:identity><contact:registernumber>1234312SFAD-5</contact:registernumber><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street/><contact:street/><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:legalemail>jdoe@example.com</contact:legalemail><contact:disclose flag="0"><contact:email/><contact:addr/></contact:disclose></contact:create></create><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');


## contact delete
$R2='';
$co=$dri->local_object('contact')->srid('C5000');
$rc=$dri->contact_delete($co);
is($R1,$E1.'<command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>C5000</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');
##########
##########


## contact update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('C5000');
$toc=$dri->local_object('changes');
my $co2=$dri->local_object('contact');
$co2->type('2');
$co2->isfinnish('1');
$co2->firstname('John');
$co2->lastname('Doe');
$co2->name('HR');
$co2->org('Example Inc.');
$co2->birthdate('2005-04-03T22:00:00.0Z');
$co2->identity('123423A123F');
$co2->registernumber('1234312-5');
$co2->street(['123 Example Dr.','Suite 100','Suite 100']);
$co2->city('Dulles');
$co2->sp('VA');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+1.7035555555x1234');
$co2->fax('+1.7035555556');
$co2->email('jdoe@example.com');
$co2->legalemail('jdoe@example.com');
$co2->disclose({addr=>0,email=>0,voice=>0});
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>C5000</contact:id><contact:chg><contact:type>2</contact:type><contact:postalInfo type="loc"><contact:isfinnish>1</contact:isfinnish><contact:firstname>John</contact:firstname><contact:lastname>Doe</contact:lastname><contact:name>HR</contact:name><contact:org>Example Inc.</contact:org><contact:birthDate>2005-04-03T22:00:00.0Z</contact:birthDate><contact:identity>123423A123F</contact:identity><contact:registernumber>1234312-5</contact:registernumber><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:legalemail>jdoe@example.com</contact:legalemail><contact:disclose flag="0"><contact:voice/><contact:email/><contact:addr/></contact:disclose></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');
##########
##########


## test period limit - we can only perform actions for a max period of 5 years!
throws_ok { $dri->domain_renew('example204.fi',{duration => DateTime::Duration->new(years=>6), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)}) } qr/Invalid duration/, 'domain_renew - parse invalid period (bigger than 5 years)';
##########
##########


# poll message extra tests - not on their technical documentation - based on their OT&E
$R2='<?xml version="1.0" encoding="utf-8"?><epp xmlns:host="urn:ietf:params:xml:ns:host-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:obj="urn:ietf:params:xml:ns:obj-1.0" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="76" id="04bf96cb-ab15-44d8-b89c-a7cf00eab81c"><qDate>2017-08-14T14:14:35.183</qDate><msg>Contact deleted</msg></msgQ><resData><obj:trnData><obj:name>C527431</obj:name></obj:trnData></resData><trID><clTRID>NET-DRI-0.12-TDW-FICORA-62-1504106326123136</clTRID><svTRID>wl9mgnu</svTRID></trID></response></epp>';
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'04bf96cb-ab15-44d8-b89c-a7cf00eab81c','message get_info last_id');
is($dri->message_count(),76,'message_count');
is(''.$dri->get_info('qdate','message','04bf96cb-ab15-44d8-b89c-a7cf00eab81c'),'2017-08-14T14:14:35','message get_info qdate');
is($dri->get_info('content','message','04bf96cb-ab15-44d8-b89c-a7cf00eab81c'),'Contact deleted','message get_info msg');
is($dri->get_info('lang','message','04bf96cb-ab15-44d8-b89c-a7cf00eab81c'),'en','message get_info lang');
is($dri->get_info('object_type','message','04bf96cb-ab15-44d8-b89c-a7cf00eab81c'),'contact','message get_info object_type');
is($dri->get_info('name','message','04bf96cb-ab15-44d8-b89c-a7cf00eab81c'),'C527431','message get_info name');

$R2='<?xml version="1.0" encoding="utf-8"?><epp xmlns:host="urn:ietf:params:xml:ns:host-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:obj="urn:ietf:params:xml:ns:obj-1.0" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="53" id="5d5c7f0c-0e13-435d-b340-a7d100d035ba"><qDate>2017-08-16T12:38:04.137</qDate><msg>Domain renewed</msg></msgQ><resData><obj:trnData><obj:name>foobar-test.fi</obj:name></obj:trnData></resData><trID><clTRID>NET-DRI-0.12-TDW-FICORA-17880-1504185627130190</clTRID><svTRID>uzg9va0</svTRID></trID> </response></epp>';
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'5d5c7f0c-0e13-435d-b340-a7d100d035ba','message get_info last_id');
is($dri->message_count(),53,'message_count');
is(''.$dri->get_info('qdate','message','5d5c7f0c-0e13-435d-b340-a7d100d035ba'),'2017-08-16T12:38:04','message get_info qdate');
is($dri->get_info('content','message','5d5c7f0c-0e13-435d-b340-a7d100d035ba'),'Domain renewed','message get_info msg');
is($dri->get_info('lang','message','5d5c7f0c-0e13-435d-b340-a7d100d035ba'),'en','message get_info lang');
is($dri->get_info('object_type','message','5d5c7f0c-0e13-435d-b340-a7d100d035ba'),'domain','message get_info object_type');
is($dri->get_info('name','message','5d5c7f0c-0e13-435d-b340-a7d100d035ba'),'foobar-test.fi','message get_info name');
##########
##########


exit 0;
