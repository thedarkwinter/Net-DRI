#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More tests => 6;
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
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'idn'}->[0],'http://www.eurid.eu/xml/epp/idn-1.0','idn 1.0 for server announcing 1.0');
SKIP: {
  skip 'TODO: Upgrade to domain-ext-1.2',1;
  is($dri->protocol()->ns()->{'domain-ext'}->[0],'http://www.eurid.eu/xml/epp/domain-ext-1.2','domain-ext 1.2 for server announcing 1.1 + 1.2');
};
is($dri->protocol()->ns()->{'poll'}->[0],'http://www.eurid.eu/xml/epp/poll-1.2','poll 1.2 for server announcing 1.1 + 1.2');
is($dri->protocol()->ns()->{'authInfo'}->[0],'http://www.eurid.eu/xml/epp/authInfo-1.0','authInfo 1.0 for server announcing 1.0');
#is($dri->protocol()->ns()->{'dynUpdate'}->[0],'http://www.eurid.eu/xml/epp/dynUpdate-1.0','dynUpdate1.0 for server announcing 1.0'); # FIXME this extension is missing?


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

#############################################################################################################
## Nsgroup

SKIP: {
    skip 'TODO: These tests are NSGOUP-1.0 instead of 1.1',1;


## p.39
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts');
$dh->name('nsgroup-eurid');
$dh->add('ns1.eurid.eu');
$dh->add('ns2.eurid.eu');
$dh->add('ns3.eurid.eu');
$dh->add('ns4.eurid.eu');
$dh->add('ns5.eurid.eu');
$rc=$dri->nsgroup_create($dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><nsgroup:create xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid</nsgroup:name><nsgroup:ns>ns1.eurid.eu</nsgroup:ns><nsgroup:ns>ns2.eurid.eu</nsgroup:ns><nsgroup:ns>ns3.eurid.eu</nsgroup:ns><nsgroup:ns>ns4.eurid.eu</nsgroup:ns><nsgroup:ns>ns5.eurid.eu</nsgroup:ns></nsgroup:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_create build');
is($rc->is_success(),1,'nsgroup_create is_success');

## p.42
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts')->name('nsgroup-eurid3');
$toc=$dri->local_object('changes');
$toc->set('ns',$dri->local_object('hosts')->name('nsgroup-eurid3')->add('ns2.eurid.eu'));
$rc=$dri->nsgroup_update($dh,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><nsgroup:update xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid3</nsgroup:name><nsgroup:ns>ns2.eurid.eu</nsgroup:ns></nsgroup:update></update><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_update build');
is($rc->is_success(),1,'nsgroup_update is_success');


## p.44
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$dh->name('nsgroup-eurid3');
$rc=$dri->nsgroup_delete($dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><nsgroup:delete xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid3</nsgroup:name></nsgroup:delete></delete><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_delete build');
is($rc->is_success(),1,'nsgroup_delete is_success');


## p.46
$R2=$E1.'<response>'.r().'<resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid1</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="0">nsgroup-eurid2</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid3</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="0">nsgroup-eurid4</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid5</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid6</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid7</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData>'.$TRID.'</response>'.$E2;
my @dh=map { $dri->local_object('hosts')->name('nsgroup-eurid'.$_) } (1..7);
$rc=$dri->nsgroup_check(@dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><nsgroup:check xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid1</nsgroup:name><nsgroup:name>nsgroup-eurid2</nsgroup:name><nsgroup:name>nsgroup-eurid3</nsgroup:name><nsgroup:name>nsgroup-eurid4</nsgroup:name><nsgroup:name>nsgroup-eurid5</nsgroup:name><nsgroup:name>nsgroup-eurid6</nsgroup:name><nsgroup:name>nsgroup-eurid7</nsgroup:name></nsgroup:check></check><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_check multi build');
is($rc->is_success(),1,'nsgroup_check_multi is_success');
is($dri->get_info('exist','nsgroup','nsgroup-eurid1'),0,'nsgroup_check_multi get_info(exist) 1');
is($dri->get_info('exist','nsgroup','nsgroup-eurid2'),1,'nsgroup_check_multi get_info(exist) 2');
is($dri->get_info('exist','nsgroup','nsgroup-eurid3'),0,'nsgroup_check_multi get_info(exist) 3');
is($dri->get_info('exist','nsgroup','nsgroup-eurid4'),1,'nsgroup_check_multi get_info(exist) 4');
is($dri->get_info('exist','nsgroup','nsgroup-eurid5'),0,'nsgroup_check_multi get_info(exist) 5');
is($dri->get_info('exist','nsgroup','nsgroup-eurid6'),0,'nsgroup_check_multi get_info(exist) 6');
is($dri->get_info('exist','nsgroup','nsgroup-eurid7'),0,'nsgroup_check_multi get_info(exist) 7');

$R2=$E1.'<response>'.r().'<resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid1</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->nsgroup_check('nsgroup-eurid1');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><nsgroup:check xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid1</nsgroup:name></nsgroup:check></check><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_check build');
is($rc->is_success(),1,'nsgroup_check is_success');
is($dri->get_info('exist','nsgroup','nsgroup-eurid1'),0,'nsgroup_check get_info(exist) 1');
is($dri->get_info('exist'),0,'nsgroup_check get_info(exist) 2');


## p.48
$R2=$E1.'<response>'.r().'<resData><nsgroup:infData><nsgroup:name>nsgroup-eurid4</nsgroup:name><nsgroup:ns>ns1.eurid.eu</nsgroup:ns><nsgroup:ns>ns2.eurid.eu</nsgroup:ns><nsgroup:ns>ns3.eurid.eu</nsgroup:ns><nsgroup:ns>ns4.eurid.eu</nsgroup:ns><nsgroup:ns>ns5.eurid.eu</nsgroup:ns><nsgroup:ns>ns6.eurid.eu</nsgroup:ns><nsgroup:ns>ns7.eurid.eu</nsgroup:ns><nsgroup:ns>ns8.eurid.eu</nsgroup:ns><nsgroup:ns>ns9.eurid.eu</nsgroup:ns></nsgroup:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->nsgroup_info('nsgroup-eurid4');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><nsgroup:info xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid4</nsgroup:name></nsgroup:info></info><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_info build');
is($rc->is_success(),1,'nsgroup_info is_success');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','nsgroup_info get_info(self) isa');
is_deeply([$s->get_names()],['ns1.eurid.eu','ns2.eurid.eu','ns3.eurid.eu','ns4.eurid.eu','ns5.eurid.eu','ns6.eurid.eu','ns7.eurid.eu','ns8.eurid.eu','ns9.eurid.eu'],'nsgroup_info get_info(self) get_names');

};

############################################################################################################
## Domain

SKIP: {
  skip "TODO: These tests are probably all outdated",1;





################################################################################################################
## Release 5.6 october 2008

## page 28
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:infData><eurid:registrar><eurid:hitPoints><eurid:nbrHitPoints>1001</eurid:nbrHitPoints><eurid:maxNbrHitPoints>1000</eurid:maxNbrHitPoints><eurid:blockedUntil>2008-10-09T17:31:20.000Z</eurid:blockedUntil></eurid:hitPoints><eurid:amountAvailable>8922.00</eurid:amountAvailable><eurid:nbrRenewalCreditsAvailable>0</eurid:nbrRenewalCreditsAvailable><eurid:nbrPromoCreditsAvailable xsi:nil="true"/></eurid:registrar></eurid:infData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info();
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><registrar:info xmlns:registrar="http://www.eurid.eu/xml/epp/registrar-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrar-1.0 registrar-1.0.xsd"/></info><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:info><eurid:registrar version="1.0"/></eurid:info></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','registrar_info build');
$s=$rc->get_data('hitpoints');
isa_ok($s,'HASH','registrar_info get_data(hitpoints)');
is($s->{current_number},1001,'registrar_info get_data(hitpoints) current_number');
is($s->{maximum_number},1000,'registrar_info get_data(hitpoints) maximum_number');
isa_ok($s->{blocked_until},'DateTime','registrar_info get_data(hitpoints) blocked_until isa DateTime');
is(''.$s->{blocked_until},'2008-10-09T17:31:20','registrar_info get_data(hitpoints) blocked_until value');
is($rc->get_data('amount_available'),8922,'registrar_info get_data(amount_available)');
$s=$rc->get_data('credits');
isa_ok($s,'HASH','registrar_info get_data(credits)');
is($s->{renewal},0,'registrar_info get_data(credits) renewal');
is($s->{promo},undef,'registrar_info get_data(credits) promo');

## page 33
$rc=$dri->domain_remind('abc.eu',{destination=>'owner'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:command><eurid:transferRemind><eurid:domainname>abc.eu</eurid:domainname><eurid:destination>owner</eurid:destination></eurid:transferRemind><eurid:clTRID>TRID-0001</eurid:clTRID></eurid:command></eurid:ext></extension></epp>','domain_remind destionation=owner build'); 
$rc=$dri->domain_remind('abc.eu',{destination=>'buyer'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:command><eurid:transferRemind><eurid:domainname>abc.eu</eurid:domainname><eurid:destination>buyer</eurid:destination></eurid:transferRemind><eurid:clTRID>TRID-0001</eurid:clTRID></eurid:command></eurid:ext></extension></epp>','domain_remind destionation=owner build');


################################################################################################################

## Examples from Registration_guidelines_v1_0F-appendix2-sunrise.pdf
$dri->target('EURid')->add_current_profile('p2','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['EURid::Sunrise']});

## p.8
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1500"><msg>Command completed successfully; ending session</msg></result><resData><domain:appData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate></domain:appData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension><trID><clTRID>clientref-12310026</clTRID><svTRID>eurid-1589</svTRID></trID></response></epp>';

my $ro=$dri->remote_object('domain');
$h=$dri->local_object('hosts')->add('ns.c-and-a.eu',['81.2.4.4'],['2001:0:0:0:8:800:200C:417A'])->add('ns.isp.eu'); ## IPv6 changed
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('js5'),'registrant');
$cs->set($dri->local_object('contact')->srid('jd1'),'billing');
$cs->set($dri->local_object('contact')->srid('jd2'),'tech');
$rc=$ro->apply('c-and-a.eu',{reference=>'c-and-a_1',right=>'REG-TM-NAT','prior-right-on-name'=>'c&a','prior-right-country'=>'NL',documentaryevidence=>'applicant','evidence-lang'=>'nl',ns=>$h,contact=>$cs});

is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply><domain:apply xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:right>REG-TM-NAT</domain:right><domain:prior-right-on-name>c&amp;a</domain:prior-right-on-name><domain:prior-right-country>NL</domain:prior-right-country><domain:documentaryevidence><domain:applicant/></domain:documentaryevidence><domain:evidence-lang>nl</domain:evidence-lang><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact></domain:apply></apply><clTRID>TRID-0001</clTRID></command></epp>','domain_apply build'); ## IPv6 changed from EURid example
is($rc->is_success(),1,'domain_apply is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');

## p.12
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:appInfoData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate><domain:status>INITIAL</domain:status><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:docsReceivedDate>2005-11-08T21:46:56.000Z</domain:docsReceivedDate><domain:adr>false</domain:adr></domain:appInfoData></resData><trID><clTRID>TRID-0001</clTRID><svTRID>eurid-0</svTRID></trID></response></epp>'; ## IPv6 changed from EURid example

$ro=$dri->remote_object('domain');
$rc=$ro->apply_info('c-and-a_1');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply-info><domain:apply-info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:reference>c-and-a_1</domain:reference></domain:apply-info></apply-info><clTRID>TRID-0001</clTRID></command></epp>','domain_apply_info build');
is($rc->is_success(),1,'domain_apply_info is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');
is($dri->get_info('application_status'),'INITIAL','domain_apply get_info(application_status)');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_apply get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_apply get_info(contact) types');
is($s->get('billing')->srid(),'jd1','domain_apply get_info(contact) billing srid');
is($s->get('registrant')->srid(),'js5','domain_apply get_info(contact) registrant srid');
is($s->get('tech')->srid(),'jd2','domain_apply get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_apply get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.c-and-a.eu','ns.isp.eu'],'domain_apply get_info(ns) get_names');
@c=$dh->get_details(1);
is($c[0],'ns.c-and-a.eu','domain_apply get_info(ns) get_details(1) 0');
is_deeply($c[1],['81.2.4.4'],'domain_apply get_info(ns) get_details(1) 1');
is_deeply($c[2],['2001:0:0:0:8:800:200C:417A'],'domain_apply get_info(ns) get_details(1) 2');
@c=$dh->get_details(2);
is($c[0],'ns.isp.eu','domain_apply get_info(ns) get_details(2) 0');
is_deeply($c[1],[],'domain_apply get_info(ns) get_details(2) 1');
is_deeply($c[2],[],'domain_apply get_info(ns) get_details(2) 2');
is(''.$dri->get_info('docsReceivedDate'),'2005-11-08T21:46:56','domain_apply get_info(docsReceivedDate)');
is($dri->get_info('adr'),0,'domain_apply get_info(adr)');

####################################################################################################
## Release 7.1

## Keygroups

$rc=$dri->keygroup_create('kwkwwyjzorsqljbvlssqhzz');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>kwkwwyjzorsqljbvlssqhzz</keygroup:name></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 1');


$rc=$dri->keygroup_create('uvmsfcextoydtsltky',{ 'keys' => [{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},
{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}] });
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>uvmsfcextoydtsltky</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 2');


$rc=$dri->keygroup_delete('dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><keygroup:delete xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir</keygroup:name></keygroup:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','keygroup_delete build');



$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:chkData><keygroup:cd><keygroup:name avail="true">zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name></keygroup:cd><keygroup:cd><keygroup:name avail="false">bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:cd></keygroup:chkData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_check(qw/zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar jbzrndytpkijpejbmogzdoxmtfqzxus dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi bcoriadjxfgdtrapgkjwlyatof/);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><keygroup:check xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar</keygroup:name><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:name>dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi</keygroup:name><keygroup:name>bcoriadjxfgdtrapgkjwlyatof</keygroup:name></keygroup:check></check><clTRID>TRID-0001</clTRID></command></epp>','keygroup_check build');
is($rc->get_data('keygroup','zgrruirkeklhgeclxjnsccnwawexfigfzxvqwyjzzrrfdar','exist'),0,'keygroup_check get_data 1');
is($rc->get_data('keygroup','jbzrndytpkijpejbmogzdoxmtfqzxus','exist'),1,'keygroup_check get_data 2');
is($rc->get_data('keygroup','dhrejofkvcdrwwwddxqblgdpbpxgqayowadwvedqewnpqdyi','exist'),1,'keygroup_check get_data 3');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><keygroup:infData><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:infData></resData><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->keygroup_info('jbzrndytpkijpejbmogzdoxmtfqzxus');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><keygroup:info xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>jbzrndytpkijpejbmogzdoxmtfqzxus</keygroup:name></keygroup:info></info><clTRID>TRID-0001</clTRID></command></epp>','keygroup_info build');
is($rc->get_data('exist'),1,'keygroup_info get_data(exist)');
is_deeply($rc->get_data('keys'),[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}],'keygroup_info get_data(keys)');


$rc=$dri->keygroup_update('krqkdcnjtiigrbvgrsom',$dri->local_object('changes')->set('keys',[]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>krqkdcnjtiigrbvgrsom</keygroup:name></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup_update empty keys');


$rc=$dri->keygroup_update('latrvxveoruzciiuuqfurexahnxqf',$dri->local_object('changes')->set('keys',[{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}]));
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><keygroup:update xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>latrvxveoruzciiuuqfurexahnxqf</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZ YEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:update></update><clTRID>TRID-0001</clTRID></command></epp>','keygroup_update add 2 keys');



};



exit 0;
