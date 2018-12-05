#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 55;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::NameStore');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{default_product=>'dotNET',extensions=>['VeriSign::NameStore']});

#########################################################################################################
## Example taken from EPP-NameStoreExt-Mapping.pdf

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.tv</domain:name></domain:cd><domain:cd><domain:name avail="0">example2.career</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotCC</namestoreExt:subProduct></namestoreExt:namestoreExt></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->domain_check('example22.tv','example2.career');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.tv</domain:name><domain:name>example2.career</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotNET</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build with namestore fixed in add_current_profile()');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example22.tv'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.career'),1,'domain_check multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','example2.career'),'In use','domain_check multi get_info(exist_reason)');
is($dri->get_info('subproductid'),'dotCC','domain_check multi get_info(subproductid)');


## if _auto_ it will be computed from first domain
$dri->add_current_profile('p2','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{default_product=>'_auto_',extensions=>['VeriSign::NameStore']});
$rc=$dri->domain_check('example22.tv','example2.career');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.tv</domain:name><domain:name>example2.career</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotTV</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build with namestore=_auto_');

## you can always pass it explicitly, which will override the default set in add_current_profile only for the given call
$dri->add_current_profile('p3','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{default_product=>'_auto_',extensions=>['VeriSign::NameStore']});
$rc=$dri->domain_check('example22.tv','example2.tv',{subproductid=>'dotAA'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.tv</domain:name><domain:name>example2.tv</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotAA</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build with namestore given in call');

## Check some more namestores
$rc=$dri->domain_check('example4.cc');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.cc</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotCC</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build with namestore=_auto_ for .cc');

$rc=$dri->domain_check('example4.tv');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.tv</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotTV</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build with namestore=_auto_ for .tv');

$rc=$dri->domain_check('example4.career');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.career</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build with namestore=_auto_ for .career');

$rc=$dri->domain_check('example4.jobs');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.jobs</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotJOBS</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build with namestore=_auto_ for .jobs');

## Handle errors
$R2=$E1.'<response><result code="2001"><msg>Command syntax error</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>NameStore Extension not provided</reason></extValue></result><extension><namestoreExt:nsExtErrData xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:msg code="1">Specified sub-product does not exist</namestoreExt:msg></namestoreExt:nsExtErrData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('namestore.tv');
is_deeply([$rc->get_extended_results()],[{lang=>'en',from=>'eppcom:extValue',reason=>'NameStore Extension not provided',type=>'text',message=>''},
                                         {from=>'verisign:namestoreExt',type=>'text',code=>1,message=>'Specified sub-product does not exist'}],'namestore error handling');



## Checking that current_product usage
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.career</domain:name></domain:cd></domain:chkData></resData><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.career');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.career</domain:name></domain:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build with namestore fixed in add_current_profile()');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('subproductid'),'CAREER','domain_check multi get_info(subproductid)');

# host check - using previous (current) product
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns2.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns2.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>CAREER</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');
is($dri->get_info('exist'),1,'host_check get_info(exist)');
is($dri->get_info('exist','host','ns2.example2.com'),1,'host_check get_info(exist) from cache');
is($dri->get_info('exist_reason'),'In use','host_check reason');

# host check - manually setting current_product
$dri->protocol()->{current_product} = 'BLAH';
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns3.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns3.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns3.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>BLAH</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');

# host check - manually setting product in RD
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns4.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns4.example2.com',{subproductid=>'FOO'});
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns4.example2.com</host:name></host:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>FOO</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');

# contact check - using previous (current) product
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">sh8000</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
my $co=$dri->local_object('contact')->srid('sh8000'); #->auth({pw=>'2fooBAR'});
$rc=$dri->contact_check($co);
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8000</contact:id></contact:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>FOO</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build');
is($rc->is_success(),1,'contact_check is_success');
is($dri->get_info('action'),'check','contact_check get_info(action)');
is($dri->get_info('exist'),0,'contact_check get_info(exist)');
is($dri->get_info('exist','contact','sh8000'),0,'contact_check get_info(exist) from cache');

# defreg
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:infData xmlns:defReg="http://www.nic.name/epp/defReg-1.0"><defReg:roid>EXAMPLE1-REP</defReg:roid><defReg:name level="premium">doe</defReg:name><defReg:registrant>jd1234</defReg:registrant><defReg:tm>XYZ-123</defReg:tm><defReg:tmCountry>US</defReg:tmCountry><defReg:tmDate>1990-04-03</defReg:tmDate><defReg:adminContact>sh8013</defReg:adminContact><defReg:status s="ok" /><defReg:clID>ClientX</defReg:clID><defReg:crID>ClientY</defReg:crID><defReg:crDate>1999-04-03T22:00:00.0Z</defReg:crDate><defReg:upID>ClientX</defReg:upID><defReg:upDate>1999-12-03T09:00:00.0Z</defReg:upDate><defReg:exDate>2000-04-03T22:00:00.0Z</defReg:exDate><defReg:trDate>2000-01-08T09:00:00.0Z</defReg:trDate><defReg:authInfo><defReg:pw>2fooBAR</defReg:pw></defReg:authInfo></defReg:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_info('EXAMPLE1-REP', { auth => { pw => 'ABC555' } } );
is_string($R1,$E1.'<command><info><defReg:info xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE1-REP</defReg:roid><defReg:authInfo><defReg:pw>ABC555</defReg:pw></defReg:authInfo></defReg:info></info><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>name</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_info build_xml');
is($rc->is_success(),1,'defreg_check is_success');
is($dri->get_info('action','defreg','EXAMPLE1-REP'), 'info', 'defreg_info get_info(action)');
is($dri->get_info('action'), 'info', 'defreg_info get_info(action)');
is($dri->get_info('roid'), 'EXAMPLE1-REP', 'defreg_info get_info(roid)');
is($dri->get_info('name'), 'doe', 'defreg_info get_info(name)');
is($dri->get_info('level'), 'premium', 'defreg_info get_info(level)');
my $cs = $dri->get_info('contact');
isa_ok($cs, 'Net::DRI::Data::ContactSet', 'defreg_info get_info(cs)');
is($cs->get('registrant')->srid(),'jd1234', 'defreg_info get_info(cs registrant)');
is($cs->get('admin')->srid(),'sh8013', 'defreg_info get_info(cs admin)');
is($dri->get_info('tm'), 'XYZ-123', 'defreg_info get_info(tm)');
is($dri->get_info('tmCountry'), 'US', 'defreg_info get_info(tm_country)');
is($dri->get_info('tmDate'), '1990-04-03T00:00:00', 'defreg_info get_info(tmDate)');
my $s = $dri->get_info('status');
isa_ok($s, 'Net::DRI::Protocol::EPP::Core::Status', 'defreg_info get_info(status)');
is($s->is_active(), 1,'defreg_info get_info(status active)');
is($dri->get_info('clID'), 'ClientX', 'defreg_info get_info(clID)');
is($dri->get_info('crID'), 'ClientY', 'defreg_info get_info(crID)');
is($dri->get_info('upID'), 'ClientX', 'defreg_info get_info(upID)');
is($dri->get_info('crDate'), '1999-04-03T22:00:00', 'defreg_info get_info(crDate)');
is($dri->get_info('upDate'), '1999-12-03T09:00:00', 'defreg_info get_info(upDate)');
is($dri->get_info('exDate'), '2000-04-03T22:00:00', 'defreg_info get_info(exDate)');
is($dri->get_info('trDate'), '2000-01-08T09:00:00', 'defreg_info get_info(trDate)');
is_deeply($dri->get_info('auth'), {pw => '2fooBAR'}, 'defreg_info get_info(authInfo)');

$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:chkData xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:cd><defReg:name level="premium" avail="1">fred</defReg:name></defReg:cd><defReg:cd><defReg:name level="standard" avail="0">def.fred</defReg:name><defReg:reason>Conflicting object exists</defReg:reason></defReg:cd></defReg:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_check('fred', 'jed.fred', { level => 'premium' });
is_string($R1,$E1.'<command><check><defReg:check xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:name level="premium">fred</defReg:name><defReg:name level="premium">jed.fred</defReg:name></defReg:check></check><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>name</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_check all premium build_xml');


exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
