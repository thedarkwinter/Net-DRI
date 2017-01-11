#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use Test::More tests => 68;
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
$dri->add_registry('CN');
$dri->target('CN')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$dh,@c,$c1,$co,$co2,$cs,$toc);


### Contact commands ###

## contact:check - multi
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">example</contact:id></contact:cd><contact:cd><contact:id avail="0">test</contact:id><contact:reason>In use</contact:reason></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('example','test'));
is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>example</contact:id><contact:id>test</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build');
is($rc->is_success(),1,'contact_check multi is_success');

## contact:info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>cnnic</contact:id><contact:roid>contact8013-cn</contact:roid><contact:status s="ok"/><contact:postalInfo type="int"><contact:name>cnnic</contact:name><contact:org>cnnic</contact:org><contact:addr><contact:street>no.4 of zhongguancun south 4 street</contact:street><contact:street>haidian</contact:street><contact:city>beijing</contact:city><contact:sp>beijing</contact:sp><contact:pc>100190</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="loc"><contact:name>约翰</contact:name><contact:org>例子公司</contact:org><contact:addr><contact:street>no.4 of zhongguancun south 4 street</contact:street><contact:street>haidian</contact:street><contact:city>beijing</contact:city><contact:sp>beijing</contact:sp><contact:pc>100190</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:voice>+86.1058813000</contact:voice><contact:fax>+86.1058813001</contact:fax><contact:email>support@cnnic.cn</contact:email><contact:clID>test</contact:clID><contact:crID>test</contact:crID><contact:crDate>2015-02-06T02:56:17.0Z</contact:crDate><contact:authInfo><contact:pw>foobar</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:name type="loc"/><contact:org type="loc"/><contact:addr type="loc"/><contact:voice/><contact:fax/><contact:email/></contact:disclose></contact:infData></resData><extension><cnnic-contact:infData xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:type>E</cnnic-contact:type><cnnic-contact:contact type="ORG">110101190001010001</cnnic-contact:contact><cnnic-contact:purveyor>mypurveyor</cnnic-contact:purveyor><cnnic-contact:mobile>+86.013811939493</cnnic-contact:mobile></cnnic-contact:infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('cnnic');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>cnnic</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info multi is_success');
is($dri->get_info('type'),'E','contact_info get_info(type)');
is($dri->get_info('orgno'),110101190001010001,'contact_info get_info(orgno)');
is($dri->get_info('orgtype'),'ORG','contact_info get_info(orgtype)');
is($dri->get_info('purveyor'),'mypurveyor','contact_info get_info(purveyor)');
is($dri->get_info('mobile'),'+86.013811939493','contact_info get_info(mobile)');

## contact:create
$co=$dri->local_object('contact')->srid('cnnic');
$co->name('约翰','cnnic');
$co->org('例子公司','cnnic');
$co->street(['No.4 of Zhongguancun South 4 Street','Haidian'],['No.4 of Zhongguancun South 4 Street','Haidian']);
$co->city('Beijing','Beijing');
$co->sp('Beijing','Beijing');
$co->pc('100190','100190');
$co->cc('CN','CN');
$co->voice('+86.1058813000');
$co->fax('+86.1058813001');
$co->email('support@cnnic.cn');
$co->auth({pw=>'fooBAR'});
$co->disclose({voice=>0,fax=>0,email=>0});
# contact extensions
$co->type('E');
$co->orgno('110101190001010001');
$co->orgtype('ORG');
$co->purveyor('mypurveyor');
$co->mobile('+86.013811939493');
$R2='';
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>cnnic</contact:id><contact:postalInfo type="loc"><contact:name>约翰</contact:name><contact:org>例子公司</contact:org><contact:addr><contact:street>No.4 of Zhongguancun South 4 Street</contact:street><contact:street>Haidian</contact:street><contact:city>Beijing</contact:city><contact:sp>Beijing</contact:sp><contact:pc>100190</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>cnnic</contact:name><contact:org>cnnic</contact:org><contact:addr><contact:street>No.4 of Zhongguancun South 4 Street</contact:street><contact:street>Haidian</contact:street><contact:city>Beijing</contact:city><contact:sp>Beijing</contact:sp><contact:pc>100190</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:voice>+86.1058813000</contact:voice><contact:fax>+86.1058813001</contact:fax><contact:email>support@cnnic.cn</contact:email><contact:authInfo><contact:pw>fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:fax/><contact:email/></contact:disclose></contact:create></create><extension><cnnic-contact:create xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:type>E</cnnic-contact:type><cnnic-contact:contact type="ORG">110101190001010001</cnnic-contact:contact><cnnic-contact:purveyor>mypurveyor</cnnic-contact:purveyor><cnnic-contact:mobile>+86.013811939493</cnnic-contact:mobile></cnnic-contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build_xml');
is($rc->is_success(),1,'contact_create is_success');

## contact:update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('cnnic');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->name('lily');
$co2->org('itself');
$co2->street(['Foo','Bar','2']);
$co2->city('Example City');
$co2->pc('20166-6503');
$co2->cc('CN');
$co2->voice('+1.9999999999');
$co2->fax('+1.5555555555');
$co2->email('a56165993@gmail.com');
$co2->orgno('110101190001010006');
$co2->orgtype('SFZ');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>cnnic</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>lily</contact:name><contact:org>itself</contact:org><contact:addr><contact:street>Foo</contact:street><contact:street>Bar</contact:street><contact:street>2</contact:street><contact:city>Example City</contact:city><contact:pc>20166-6503</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>lily</contact:name><contact:org>itself</contact:org><contact:addr><contact:street>Foo</contact:street><contact:street>Bar</contact:street><contact:street>2</contact:street><contact:city>Example City</contact:city><contact:pc>20166-6503</contact:pc><contact:cc>CN</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.9999999999</contact:voice><contact:fax>+1.5555555555</contact:fax><contact:email>a56165993@gmail.com</contact:email></contact:chg></contact:update></update><extension><cnnic-contact:update xmlns:cnnic-contact="urn:ietf:params:xml:ns:cnnic-contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-contact-1.0 cnnic-contact-1.0.xsd"><cnnic-contact:chg><cnnic-contact:contact type="SFZ">110101190001010006</cnnic-contact:contact></cnnic-contact:chg></cnnic-contact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## contact:delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->contact_delete($dri->local_object('contact')->srid('example1'));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>example1</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command></epp>','contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');

## contact:transfer
$co=$dri->local_object('contact')->srid('example1')->auth({pw=>'foo-BAR2'});
$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>example1</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>test</contact:reID><contact:reDate>2015-02-06T03:41:23.0Z</contact:reDate><contact:acID>cns</contact:acID><contact:acDate>2015-02-11T03:41:23.0Z</contact:acDate></contact:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_transfer_start($co);
is($R1,$E1.'<command><transfer op="request"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>example1</contact:id><contact:authInfo><contact:pw>foo-BAR2</contact:pw></contact:authInfo></contact:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_transfer_start build');
is($rc->is_success(),1,'contact_transfer_start is_success');
is($dri->get_info('action'),'transfer','contact_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'contact_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'pending','contact_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'test','contact_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','contact_transfer_start get_info(reDate)');
is("".$d,'2015-02-06T03:41:23','contact_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'cns','contact_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','contact_transfer_start get_info(acDate)');
is("".$d,'2015-02-11T03:41:23','contact_transfer_start get_info(acDate) value');


### Domain commands ###

## domain:info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns="urn:ietf:params:xml:ns:domain-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.cn</domain:name><domain:roid>20150206s10001s72989693-cn</domain:roid><domain:status s="ok"/><domain:registrant>cnnic</domain:registrant><domain:contact type="admin">cnnic</domain:contact><domain:contact type="billing">cnnic</domain:contact><domain:contact type="tech">cnnic</domain:contact><domain:ns><domain:hostObj>ns.m.cn</domain:hostObj></domain:ns><domain:clID>test</domain:clID><domain:crID>test</domain:crID><domain:crDate>2015-02-06T04:01:21.0Z</domain:crDate><domain:exDate>2018-02-06T04:01:21.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:rgpStatus s="addPeriod"/></rgp:infData><cnnic-domain:infData xmlns:cnnic-domain="urn:ietf:params:xml:ns:cnnic-domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-domain-1.0 cnnic-domain-1.0.xsd"><cnnic-domain:purveyor>mypurveyor</cnnic-domain:purveyor></cnnic-domain:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.cn',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.cn</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'20150206s10001s72989693-cn','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['addPeriod','ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'cnnic','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'cnnic','domain_info get_info(contact) admin srid');
is($s->get('billing')->srid(),'cnnic','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'cnnic','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.m.cn'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'test','domain_info get_info(clID)');
is($dri->get_info('crID'),'test','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2015-02-06T04:01:21','domain_info get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2018-02-06T04:01:21','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
# domain extensions
is($dri->get_info('purveyor'),'mypurveyor','domain_info get_info(purveyor)');

## domain:create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns="urn:ietf:params:xml:ns:domain-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.cn</domain:name><domain:crDate>2015-02-06T04:01:21.0Z</domain:crDate><domain:exDate>2018-02-06T04:01:21.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('cnnic');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'billing');
$cs->set($c1,'tech');
$rc=$dri->domain_create('example.cn',{pure_create=>1,duration=>DateTime::Duration->new(years=>3),ns=>$dri->local_object('hosts')->set(['ns.m.cn']),contact=>$cs,auth=>{pw=>'fooBAR'},purveyor=>'mypurveyor',type=>'E'});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.cn</domain:name><domain:period unit="y">3</domain:period><domain:ns><domain:hostObj>ns.m.cn</domain:hostObj></domain:ns><domain:registrant>cnnic</domain:registrant><domain:contact type="admin">cnnic</domain:contact><domain:contact type="billing">cnnic</domain:contact><domain:contact type="tech">cnnic</domain:contact><domain:authInfo><domain:pw>fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><cnnic-domain:create xmlns:cnnic-domain="urn:ietf:params:xml:ns:cnnic-domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-domain-1.0 cnnic-domain-1.0.xsd"><cnnic-domain:type>E</cnnic-domain:type><cnnic-domain:purveyor>mypurveyor</cnnic-domain:purveyor></cnnic-domain:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2015-02-06T04:01:21','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2018-02-06T04:01:21','domain_create get_info(exDate) value');

## domain:update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('a.test.cn'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('cnnic2'),'admin');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('delete'));
$toc->del('ns',$dri->local_object('hosts')->set('ns.m.cn'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('cnnic1'),'admin');
$toc->del('contact',$cs);
$toc->set('registrant',$dri->local_object('contact')->srid('registrant1'));
$toc->set('auth',{pw=>'2BARfoo'});
$toc->set('type','I');
$toc->set('purveyor','mynewpurveyor');
$rc=$dri->domain_update('example.cn',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.cn</domain:name><domain:add><domain:ns><domain:hostObj>a.test.cn</domain:hostObj></domain:ns><domain:contact type="admin">cnnic2</domain:contact><domain:status s="clientDeleteProhibited"/></domain:add><domain:rem><domain:ns><domain:hostObj>ns.m.cn</domain:hostObj></domain:ns><domain:contact type="admin">cnnic1</domain:contact></domain:rem><domain:chg><domain:registrant>registrant1</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><cnnic-domain:update xmlns:cnnic-domain="urn:ietf:params:xml:ns:cnnic-domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-domain-1.0 cnnic-domain-1.0.xsd"><cnnic-domain:chg><cnnic-domain:type>I</cnnic-domain:type><cnnic-domain:purveyor>mynewpurveyor</cnnic-domain:purveyor></cnnic-domain:chg></cnnic-domain:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

# test .xn--fiqs8s TLD
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.xn--fiqs8s</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.xn--fiqs8s');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.xn--fiqs8s</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','example3.xn--fiqs8s'),0,'domain_check get_info(exist) from cache');

### Host commands ###

## host:info
$R2=$E1.'<response>'.r().'<resData><host:infData xmlns="urn:ietf:params:xml:ns:host-1.0" xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.m.cn</host:name><host:roid>host7039266-cn</host:roid><host:status s="clientUpdateProhibited"/><host:addr ip="v6">0000:0000:0000:0000:0000:0000:c0a8:00c7</host:addr><host:addr ip="v4">192.168.0.199</host:addr><host:clID>test</host:clID><host:crID>test</host:crID><host:crDate>2015-02-06T03:23:45.000Z</host:crDate><host:upID>test</host:upID><host:upDate>2015-02-06T03:29:23.0Z</host:upDate></host:infData></resData><extension><cnnic-host:infData xmlns:cnnic-host="urn:ietf:params:xml:ns:cnnic-host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-host-1.0 cnnic-host-1.0.xsd"><cnnic-host:purveyor>my-purveyor</cnnic-host:purveyor></cnnic-host:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('ns1.m.cn');
is($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.m.cn</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('action'),'info','host_info get_info(action)');
is($dri->get_info('exist'),1,'host_info get_info(exist)');
is($dri->get_info('purveyor'),'my-purveyor','host_info get_info(purveyor)');

## host:create
$R2='';
$rc=$dri->host_create($dri->local_object('hosts')->add('ns.bj.cn',['218.241.111.111'],['']),{purveyor=>'mypurveyor'});
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.bj.cn</host:name><host:addr ip="v4">218.241.111.111</host:addr></host:create></create><extension><cnnic-host:create xmlns:cnnic-host="urn:ietf:params:xml:ns:cnnic-host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cnnic-host-1.0 cnnic-host-1.0.xsd"><cnnic-host:purveyor>mypurveyor</cnnic-host:purveyor></cnnic-host:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');

exit 0;
