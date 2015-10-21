#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use Test::More tests => 75;
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

my ($rc,$s,$d,$dh,@c,$c1,$co,$co2,$toc);


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
is($dri->get_info('contact'),110101190001010001,'contact_info get_info(contact)');
is($dri->get_info('contact_type'),'ORG','contact_info get_info(contact_type)');
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
$co->contact('110101190001010001');
$co->contact_type('ORG');
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
$co2->contact('110101190001010006');
$co2->contact_type('SFZ');
$toc->set('info',$co2);
#$toc->add('mobile',$dri->local_object('contact')->mobile('+44.12348'));
#$toc->del('purveyor',$dri->local_object('contact')->purveyor('blah'));
#$toc->del('contact',$dri->local_object('contact')->contact('foobar'));
#$toc->del('contact_type',$dri->local_object('contact')->contact_type('SFZ'));
#$toc->del('mobile',$dri->local_object('contact')->mobile('foobar2'));
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

exit 0;