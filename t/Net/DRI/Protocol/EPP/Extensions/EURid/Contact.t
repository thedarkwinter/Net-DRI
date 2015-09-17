#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More skip_all => 'EURid/Contact tests need reviewing!';
use Test::More tests => 48;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'TRID-0001'; };
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

########################################################################################################
## Examples taken from EPP_Guidelines_2_1_09

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2014-09-13T09:31:14.123Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrar-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.2</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dynUpdate-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'contact-ext'}->[0],'http://www.eurid.eu/xml/epp/contact-ext-1.1','contact-ext 1.1 for server announcing 1.1');


########################################################################################################
## Contacts - these are old tests but still work

## Contact
## p.38

$R2=$E1.'<response>'.r().'<resData><contact:creData><contact:id>c16212470</contact:id><contact:crDate>2012-10-03T12:14:03.325Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('client_id001');
$co->name('Teki-Sue Porter');
$co->org('Tech Support Unlimited');
$co->street(['Main Street 122']);
$co->city('Nowhere City');
$co->pc('1234');
$co->cc('BE');
$co->voice('+32.123456789');
$co->fax('+32.123456790');
$co->email('nobody@example.eu');
$co->type('tech');
$co->lang('en');
$rc=$dri->contact_create($co);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>client_id001</contact:id><contact:postalInfo type="loc"><contact:name>Teki-Sue Porter</contact:name><contact:org>Tech Support Unlimited</contact:org><contact:addr><contact:street>Main Street 122</contact:street><contact:city>Nowhere City</contact:city><contact:pc>1234</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.123456789</contact:voice><contact:fax>+32.123456790</contact:fax><contact:email>nobody@example.eu</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><contact-ext:create xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.1 contact-ext-1.1.xsd"><contact-ext:type>tech</contact-ext:type><contact-ext:lang>en</contact-ext:lang></contact-ext:create></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 1');
is($rc->is_success(),1,'contact_create 1 is_success');
my $id=$rc->get_data('contact','client_id001','id');
is($rc->get_data('contact',$id,'exist'),1,'contact_create 1 get_info(exist)');
is($rc->get_data('contact',$id,'id'),'c16212470','contact_create 1 get_info(id)');
is(''.$rc->get_data('contact',$id,'crDate'),'2012-10-03T12:14:03','contact_create 1 get_info(crdate)');

## contact create 2 same as 1

$R2=$E1.'<response>'.r().'<resData><contact:creData><contact:id>c16212472</contact:id><contact:crDate>2012-10-03T12:14:04.747Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('client_id003');
$co->name('Ann Ployee');
$co->org('ACME Intercontinental');
$co->street(['Main Street 122','Building 5','P.O. Box 123']);
$co->city('Nowhere City');
$co->pc('1234');
$co->cc('BE');
$co->voice('+32.123456789');
$co->fax('+32.123456790');
$co->email('nobody@example.com');
$co->type('registrant');
$co->vat('VAT1234567890');
$co->lang('en');
$rc=$dri->contact_create($co);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>client_id003</contact:id><contact:postalInfo type="loc"><contact:name>Ann Ployee</contact:name><contact:org>ACME Intercontinental</contact:org><contact:addr><contact:street>Main Street 122</contact:street><contact:street>Building 5</contact:street><contact:street>P.O. Box 123</contact:street><contact:city>Nowhere City</contact:city><contact:pc>1234</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.123456789</contact:voice><contact:fax>+32.123456790</contact:fax><contact:email>nobody@example.com</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><contact-ext:create xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.1 contact-ext-1.1.xsd"><contact-ext:type>registrant</contact-ext:type><contact-ext:vat>VAT1234567890</contact-ext:vat><contact-ext:lang>en</contact-ext:lang></contact-ext:create></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 3');
is($rc->is_success(),1,'contact_create 3 is_success');
$id=$rc->get_data('contact','client_id003','id');
is($rc->get_data('contact',$id,'exist'),1,'contact_create 3 get_info(exist)');
is($rc->get_data('contact',$id,'id'),'c16212472','contact_create 3 get_info(id)');
is(''.$rc->get_data('contact',$id,'crDate'),'2012-10-03T12:14:04','contact_create 3 get_info(crdate)');


## p.39
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->contact_delete($dri->local_object('contact')->srid('c16212481'));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>c16212481</contact:id></contact:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');

## p.28 (old)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sb3249');
$toc=$dri->local_object('changes');
my $co2=$dri->local_object('contact');
$co2->org('Newco');
$co2->street(['Green Tower','City Square']);
$co2->city('London');
$co2->pc('1111');
$co2->cc('GB');
$co2->voice('+44.1865332156');
$co2->fax('+44.1865332157');
$co2->email('noreply@eurid.eu');
$co2->vat('GB12345678');
$co2->lang('en');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org>Newco</contact:org><contact:addr><contact:street>Green Tower</contact:street><contact:street>City Square</contact:street><contact:city>London</contact:city><contact:pc>1111</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865332156</contact:voice><contact:fax>+44.1865332157</contact:fax><contact:email>noreply@eurid.eu</contact:email></contact:chg></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.1 contact-ext-1.1.xsd"><contact-ext:chg><contact-ext:vat>GB12345678</contact-ext:vat><contact-ext:lang>en</contact-ext:lang></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 1');
is($rc->is_success(),1,'contact_update is_success 1');

## p.29 (old)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->voice('+44.1865332156');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:voice>+44.1865332156</contact:voice></contact:chg></contact:update></update><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 2');
is($rc->is_success(),1,'contact_update is_success 2');


## p.30 (old)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->lang('nl');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.1 contact-ext-1.1.xsd"><contact-ext:chg><contact-ext:lang>nl</contact-ext:lang></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 3');
is($rc->is_success(),1,'contact_update is_success 3');

## p.31 (old)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->org('');
$co2->vat('');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org/></contact:postalInfo></contact:chg></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.1 contact-ext-1.1.xsd"><contact-ext:chg><contact-ext:vat/></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 4');
is($rc->is_success(),1,'contact_update is_success 4');

## p.45
$R2=$E1.'<response>'.r().'<resData><contact:infData><contact:id>c16212587</contact:id><contact:roid>16212587-EURID</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Ann Ployee</contact:name><contact:org>ACME Intercontinental</contact:org><contact:addr><contact:street>Main Street 122</contact:street><contact:street>Building 5</contact:street><contact:street>P.O. Box 123</contact:street><contact:city>Nowhere City</contact:city><contact:pc>1234</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.123456789</contact:voice><contact:fax>+32.123456790</contact:fax><contact:email>nobody@example.com</contact:email><contact:clID>a123456</contact:clID><contact:crID>a123456</contact:crID><contact:crDate>2012-10-04T10:11:30.000Z</contact:crDate><contact:upDate>2012-10-04T10:11:30.000Z</contact:upDate></contact:infData></resData><extension><contact-ext:infData><contact-ext:type>registrant</contact-ext:type><contact-ext:vat>VAT1234567890</contact-ext:vat><contact-ext:lang>en</contact-ext:lang></contact-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('c16212587'));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>c16212587</contact:id></contact:info></info><clTRID>TRID-0001</clTRID></command></epp>','contact_info build 3');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact::EURid','contact_info get_info(self)');
is($co->srid(),'c16212587','contact_info get_info(self) srid');
is($co->roid(),'16212587-EURID','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'contact_info get_info(status) list_status');
is($s->can_delete(),1,'contact_info get_info(status) can_delete');
is($co->name(),'Ann Ployee','contact_info get_info(self) name');
is($co->org(),'ACME Intercontinental','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['Main Street 122','Building 5','P.O. Box 123'],'contact_info get_info(self) street');
is($co->city(),'Nowhere City','contact_info get_info(self) city');
is($co->pc(),'1234','contact_info get_info(self) pc');
is($co->cc(),'BE','contact_info get_info(self) cc');
is($co->voice(),'+32.123456789','contact_info get_info(self) voice');
is($co->fax(),'+32.123456790','contact_info get_info(self) fax');
is($co->email(),'nobody@example.com','contact_info get_info(self) email');
is($dri->get_info('clID'),'a123456','contact_info get_info(clID)');
is($dri->get_info('crID'),'a123456','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is(''.$d,'2012-10-04T10:11:30','contact_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is(''.$d,'2012-10-04T10:11:30','contact_info get_info(upDate) value');
is($co->type(),'registrant','contact_info get_info(self) type');
is($co->vat(),'VAT1234567890','contact_info get_info(self) vat');
is($co->lang(),'en','contact_info get_info(self) lang');

exit 0;
