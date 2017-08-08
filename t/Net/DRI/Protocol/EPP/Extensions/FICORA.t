#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 100;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
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

## Domain check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">foobar1.fi</domain:name></domain:cd><domain:cd><domain:name avail="0">foobar2.fi</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="1">foobar3.fi</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobar1.fi','foobar2.fi','foobar3.fi');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar1.fi</domain:name><domain:name>foobar2.fi</domain:name><domain:name>foobar3.fi</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','foobar1.fi'),0,'domain_check multi get_info(exist) 1/3');
is($dri->get_info('exist','domain','foobar2.fi'),1,'domain_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','domain','foobar2.fi'),'In use','domain_check multi get_info(exist_reason)');
is($dri->get_info('exist','domain','foobar3.fi'),0,'domain_check multi get_info(exist) 3/3');

## Domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.fi</domain:name><domain:registrylock>1</domain:registrylock><domain:autorenew>1</domain:autorenew><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo><domain:dsData><domain:keyTag>12345</domain:keyTag><domain:alg>3</domain:alg><domain:digestType>1</domain:digestType><domain:digest>38EC35D5B3A34B33C99B</domain:digest><domain:keyData><domain:flags>257</domain:flags><domain:protocol>233</domain:protocol><domain:alg>1</domain:alg><domain:pubKey>AQPJ////4Q==</domain:pubKey></domain:keyData></domain:dsData><domain:dsData><domain:keyTag>12345</domain:keyTag><domain:alg>3</domain:alg><domain:digestType>1</domain:digestType><domain:digest>38EC35D5B3A34B33C99B</domain:digest><domain:keyData><domain:flags>257</domain:flags><domain:protocol>233</domain:protocol><domain:alg>1</domain:alg><domain:pubKey>AQPJ////4Q==</domain:pubKey></domain:keyData></domain:dsData></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.fi',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.fi</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
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
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1 only');
##########
##########
# FIXME: the sample from the technical documentation looks wrong. secDNS-1 should be an extension? :(
# print Dumper($dri->get_info('secDNS-1'));
# is_deeply($rc->get_data('secdns'),[{maxSigLife=>604800,keyTag=>12345,alg=>3,digestType=>1,digest=>'38EC35D5B3A34B33C99B',key_flags=>257,key_protocol=>233,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}],'domain_info parse secDNS-1.1 dsData with keyData');
# $e=$dri->get_info('secdns');
# print Dumper($e);
# is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'38EC35D5B3A34B33C99B'}],'domain_info get_info(secdns) +SecDNS 1');
##########
##########

# ##########
# ##########
# # TODO: FIXME => check chapter 4.3 Transfer
# # - Do we need to update the info_parse to get dsData - the XSD is not using the standards :(
# # - Double check new field on info_parse: registrylock, autorenew, autorenewDate (check Schemas.zip: DomainInfoResponse2.xsd)
# ##########
# ## Domain transfer
# $R2=$E1.'<response>'.r().'<resData><obj:trnData xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:name>foobartransfer.fi</obj:name><obj:trStatus>Transferred</obj:trStatus><obj:reID>ClientX</obj:reID><obj:reDate>2000-06-08T22:00:00.0Z</obj:reDate><obj:acID>ClientY</obj:acID></obj:trnData></resData>'.$TRID.'</response>'.$E2;
# $rc=$dri->domain_transfer_start('foobartransfer.fi',{auth=>{pw=>'2fooBAR'}});
# # TODO: FIXME
# # is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobartransfer.fi</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns></domain:transfer></transfer><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></command>'.$E2,'domain_transfer_request build');
# is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobartransfer.fi</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
# is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
# is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
# is($dri->get_info('trStatus'),'pending','domain_transfer_start get_info(trStatus)');
# is($dri->get_info('reID'),'ClientX','domain_transfer_start get_info(reID)');
# $d=$dri->get_info('reDate');
# isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
# is("".$d,'2000-06-08T22:00:00','domain_transfer_start get_info(reDate) value');
# is($dri->get_info('acID'),'ClientY','domain_transfer_start get_info(acID)');
# $d=$dri->get_info('acDate');
# isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
# is("".$d,'2000-06-13T22:00:00','domain_transfer_start get_info(acDate) value');
# $d=$dri->get_info('exDate');
# isa_ok($d,'DateTime','domain_transfer_start get_info(exDate)');
# is("".$d,'2002-09-08T22:00:00','domain_transfer_start get_info(exDate) value');
# ##########
# ##########

## Domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esimerkki.fi</domain:name><domain:crDate>2014-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2016-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('registrantusername');
$c2=$dri->local_object('contact')->srid('admin');
$c3=$dri->local_object('contact')->srid('technical');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c3,'tech');
$rc=$dri->domain_create('esimerkki.fi',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.esimerkki.fi'],['ns2.esimerkki.fi']),contact=>$cs,auth=>{pw=>'password'},secdns=>[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',maxSigLife=>604800}]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esimerkki.fi</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.esimerkki.fi</domain:hostObj><domain:hostObj>ns2.esimerkki.fi</domain:hostObj></domain:ns><domain:registrant>registrantusername</domain:registrant><domain:contact type="admin">admin</domain:contact><domain:contact type="tech">technical</domain:contact><domain:authInfo><domain:pw>password</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2014-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2016-04-03T22:00:00','domain_create get_info(exDate) value');

# ##########
# ##########
# # TODO: FIXME
# # - Do we need to always send <obj:delete> element?
# ##########
# ## Domain delete
# $R2='';
# $rc=$dri->domain_delete('example203.com',{pure_delete=>1});
# is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example203.com</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
# is($rc->is_success(),1,'domain_delete is_success');
# ##########
# ##########

# ##########
# ##########
# # TODO: FIXME
# # - Do we need to always send <obj:delete> element?
# ## Domain update
# $R2='';
# $rc=$dri->domain_delete('example203.com',{pure_delete=>1});
# is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example203.com</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
# is($rc->is_success(),1,'domain_delete is_success');
# ##########
# ##########

## Domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esimerkki.fi</domain:name><domain:exDate>2016-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('esimerkki.fi',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2014,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esimerkki.fi</domain:name><domain:curExpDate>2014-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2016-04-03T22:00:00','domain_renew get_info(exDate) value');

## Contact check
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">username1</contact:id></contact:cd><contact:cd><contact:id avail="0">username2</contact:id><contact:reason>In use</contact:reason></contact:cd><contact:cd><contact:id avail="1">username3</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('username1','username2','username3'));
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>username1</contact:id><contact:id>username2</contact:id><contact:id>username3</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');
is($dri->get_info('exist','contact','username1'),0,'contact_check multi get_info(exist) 1/3');
is($dri->get_info('exist','contact','username2'),1,'contact_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','contact','username2'),'In use','contact_check multi get_info(exist_reason)');
is($dri->get_info('exist','contact','username3'),0,'contact_check multi get_info(exist) 3/3');

## Contact info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:firstname>John Doe</contact:firstname><contact:lastname>John Doe</contact:lastname><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+358401231234</contact:voice><contact:email>jdoe@example.com</contact:email><contact:legalemail>jdoe@example.com</contact:legalemail><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:disclose flag="0"><contact:voice/><contact:email/><contact:address/></contact:disclose></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
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
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sha1</contact:id><contact:role>5</contact:role><contact:type>1</contact:type><contact:postalInfo type="loc"><contact:isfinnish>1</contact:isfinnish><contact:firstname>Essi</contact:firstname><contact:lastname>Esimerkki Oy</contact:lastname><contact:name>HR</contact:name><contact:org>Esimerkki Oy</contact:org><contact:birthDate>2005-04-03T22:00:00.0Z</contact:birthDate><contact:identity>123423A123F</contact:identity><contact:registernumber>1234312SFAD-5</contact:registernumber><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street/><contact:street/><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:legalemail>jdoe@example.com</contact:legalemail><contact:disclose flag="0"><contact:email/><contact:addr/></contact:disclose></contact:create></create><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');


exit 0;
