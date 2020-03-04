#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 25;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };

$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['SecDNS','-VeriSign::NameStore']});

my ($rc,$e,$toc);

#########################################################################################################
## Extension: SecDNS

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example2.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.com');
is($dri->get_info('exist'),1,'domain_info get_info(exist) +SecDNS 1');
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC'}],'domain_info get_info(secdns) +SecDNS 1');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.com');
is($dri->get_info('exist'),1,'domain_info get_info(exist) +SecDNS 2');
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',maxSigLife=>604800,key_flags=>256,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}],'domain_info get_info(secdns) +SecDNS 2');

$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('example4.com',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']),contact=>$cs,auth=>{pw=>'2fooBAR'},secdns=>[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC'}]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build +SecDNS 1');

$rc=$dri->domain_create('example5.com',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']),contact=>$cs,auth=>{pw=>'2fooBAR'},secdns=>[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',maxSigLife=>604800,key_flags=>256,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example5.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build +SecDNS 2');


$R2='';
$toc=$dri->local_object('changes');
$toc->add('secdns',[{keyTag=>'12346',alg=>3,digestType=>1,digest=>'38EC35D5B3A34B44C39B'}]);
$rc=$dri->domain_update('example10.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example10.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:add><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +SecDNS 1');


$toc=$dri->local_object('changes');
$toc->del('secdns',[{keyTag=>'12345'}]);
$rc=$dri->domain_update('example11.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example11.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:rem><secDNS:keyTag>12345</secDNS:keyTag></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +SecDNS 2');


$toc=$dri->local_object('changes');
$toc->set('secdns',[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC'}]);
$toc->set('secdns_urgent',1);
$rc=$dri->domain_update('example12.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example12.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0" urgent="1"><secDNS:chg><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:chg></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +SecDNS 3');



$toc=$dri->local_object('changes');
$toc->set('secdns',[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',maxSigLife=>604800,key_flags=>256,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}]);
$rc=$dri->domain_update('example13.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example13.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0"><secDNS:chg><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:chg></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +SecDNS 4');

####################################################################################################
## SecDNS 1.1 support from RFC5910

## Version 1.1 is selected over 1.0 if both are there.

$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{secDNS},'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');

$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{secDNS},'urn:ietf:params:xml:ns:secDNS-1.0','secDNS 1.0 for server announcing 1.0 only');

$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{secDNS},'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1 only');

## SecDNS 1.1 operations

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example100.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc=$dri->domain_info('example100.com');
is_deeply($rc->get_data('secdns'),[{keyTag=>12345,alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC'}],'domain_info parse secDNS-1.1 dsData without keyData');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example101.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc=$dri->domain_info('example101.com');
is_deeply($rc->get_data('secdns'),[{maxSigLife=>604800,keyTag=>12345,alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}],'domain_info parse secDNS-1.1 dsData with keyData');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example102.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response></epp>';
$rc=$dri->domain_info('example102.com');
is_deeply($rc->get_data('secdns'),[{key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}],'domain_info parse secDNS-1.1 keyData');



my %rd=(pure_create=>1,duration=>$dri->local_object('duration',years => 2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']),
        contact => $dri->local_object('contactset')->set($dri->local_object('contact')->srid('jd1234'),'registrant')->set($dri->local_object('contact')->srid('sh8013'),'admin')->set($dri->local_object('contact')->srid('sh8013'),'tech'),
        auth=>{pw=>'2fooBAR'});

$R2='';
$rc=$dri->domain_create('example200.com',{%rd,secdns=>[{maxSigLife=>604800,keyTag=>12345,alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC'}]});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example200.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create secDNS 1.1 dsData without keyData build');

$rc=$dri->domain_create('example201.com',{%rd,secdns=>[{maxSigLife=>604800,keyTag=>12345,alg=>3,digestType=>1,digest=>'49FD46E6C4B45C55D4AC',key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}]});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example201.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create secDNS 1.1 dsData with keyData build');

$rc=$dri->domain_create('example202.com',{%rd,secdns=>[{key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='}]});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example202.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create secDNS 1.1 keyData build');



$rc=$dri->domain_update('example300.com',$dri->local_object('changes')->del('secdns',{keyTag=>12345,alg=>3,digestType=>1,digest=>'38EC35D5B3A34B33C99B'})->add('secdns',{keyTag=>12346,alg=>3,digestType=>1,digest=>'38EC35D5B3A34B44C39B'}));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example300.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:rem><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B33C99B</secDNS:digest></secDNS:dsData></secDNS:rem><secDNS:add><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 add dsData + rem dsData build');

$rc=$dri->domain_update('example301.com',$dri->local_object('changes')->set('secdns',{maxSigLife=>605900}));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example301.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:chg><secDNS:maxSigLife>605900</secDNS:maxSigLife></secDNS:chg></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 chg maxSigLife build');

$rc=$dri->domain_update('example302.com',$dri->local_object('changes')->del('secdns',{key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4QQQ'})->add('secdns',{key_flags=>257,key_protocol=>3,key_alg=>1,key_pubKey=>'AQPJ////4Q=='})->set('secdns',{maxSigLife=>605900}));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example302.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:rem><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4QQQ</secDNS:pubKey></secDNS:keyData></secDNS:rem><secDNS:add><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>1</secDNS:alg><secDNS:pubKey>AQPJ////4Q==</secDNS:pubKey></secDNS:keyData></secDNS:add><secDNS:chg><secDNS:maxSigLife>605900</secDNS:maxSigLife></secDNS:chg></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 add keyData + del keyData + chg maxSigLife build');

$rc=$dri->domain_update('example303.com',$dri->local_object('changes')->del('secdns',{keyTag=>12346,alg=>3,digestType=>1,digest=>'38EC35D5B3A34B44C39B'}));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example303.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:rem><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 del dsData build');

$rc=$dri->domain_update('example304.com',$dri->local_object('changes')->del('secdns','all')->set('secdns_urgent',1));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example304.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" urgent="1"><secDNS:rem><secDNS:all>true</secDNS:all></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 rem all + urgent build');

$rc=$dri->domain_update('example305.com',$dri->local_object('changes')->del('secdns','all')->add('secdns',{keyTag=>12346,alg=>3,digestType=>1,digest=>'38EC35D5B3A34B44C39B'})->set('secdns_urgent',1));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example305.com</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" urgent="1"><secDNS:rem><secDNS:all>true</secDNS:all></secDNS:rem><secDNS:add><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update secDNS 1.1 rem all + add dsData + urgent build');


exit 0;
