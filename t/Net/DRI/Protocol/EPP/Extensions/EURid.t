#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More skip_all => 'Update to release 9.0 to be tested';
use Test::More tests => 268;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

#our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd">';


our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0">';
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
## Examples taken from EPP_Guidelines_2_0_5.pdf

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
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>client_id001</contact:id><contact:postalInfo type="loc"><contact:name>Teki-Sue Porter</contact:name><contact:org>Tech Support Unlimited</contact:org><contact:addr><contact:street>Main Street 122</contact:street><contact:city>Nowhere City</contact:city><contact:pc>1234</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.123456789</contact:voice><contact:fax>+32.123456790</contact:fax><contact:email>nobody@example.eu</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><contact-ext:create xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.0 contact-ext-1.0.xsd"><contact-ext:type>tech</contact-ext:type><contact-ext:lang>en</contact-ext:lang></contact-ext:create></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 1');
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
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>client_id003</contact:id><contact:postalInfo type="loc"><contact:name>Ann Ployee</contact:name><contact:org>ACME Intercontinental</contact:org><contact:addr><contact:street>Main Street 122</contact:street><contact:street>Building 5</contact:street><contact:street>P.O. Box 123</contact:street><contact:city>Nowhere City</contact:city><contact:pc>1234</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.123456789</contact:voice><contact:fax>+32.123456790</contact:fax><contact:email>nobody@example.com</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><contact-ext:create xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.0 contact-ext-1.0.xsd"><contact-ext:type>registrant</contact-ext:type><contact-ext:vat>VAT1234567890</contact-ext:vat><contact-ext:lang>en</contact-ext:lang></contact-ext:create></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 3');
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
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org>Newco</contact:org><contact:addr><contact:street>Green Tower</contact:street><contact:street>City Square</contact:street><contact:city>London</contact:city><contact:pc>1111</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865332156</contact:voice><contact:fax>+44.1865332157</contact:fax><contact:email>noreply@eurid.eu</contact:email></contact:chg></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.0 contact-ext-1.0.xsd"><contact-ext:chg><contact-ext:vat>GB12345678</contact-ext:vat><contact-ext:lang>en</contact-ext:lang></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 1');
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
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.0 contact-ext-1.0.xsd"><contact-ext:chg><contact-ext:lang>nl</contact-ext:lang></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 3');
is($rc->is_success(),1,'contact_update is_success 3');

## p.31 (old)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->org('');
$co2->vat('');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org/></contact:postalInfo></contact:chg></contact:update></update><extension><contact-ext:update xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-ext-1.0 contact-ext-1.0.xsd"><contact-ext:chg><contact-ext:vat/></contact-ext:chg></contact-ext:update></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 4');
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

############################################################################################################
## Domain

## p.50
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>mykingdom.eu</domain:name><domain:crDate>2005-09-29T13:47:32.000Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mvw14'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$rc=$dri->domain_create('mykingdom.eu',{pure_create=>1,contact=>$cs});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>mykingdom.eu</domain:name><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'domain_create build 1');
is($rc->is_success(),1,'domain_create is_success 1');
my $crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T13:47:32','domain_create get_info(crDate) 1');


## p.52
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>everything.eu</domain:name><domain:crDate>2005-09-29T14:25:50.000Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs->set($dri->local_object('contact')->srid('mt24'),'admin');
$dh=$dri->local_object('hosts');
$dh->add('ns.eurid.eu');
$dh->add('ns.everything.eu',['193.12.11.1']);
$rc=$dri->domain_create('everything.eu',{pure_create=>1,contact=>$cs,duration=>DateTime::Duration->new(years=>1),ns=>$dh});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>everything.eu</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.eurid.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName><domain:hostAddr ip="v4">193.12.11.1</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>mvw14</domain:registrant><domain:contact type="admin">mt24</domain:contact><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><clTRID>TRID-0001</clTRID></command></epp>','domain_create build 2');
is($rc->is_success(),1,'domain_create is_success 2');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T14:25:50','domain_create get_info(crDate) 2');


## p.55
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>ecom.eu</domain:name><domain:crDate>2005-09-29T14:45:34.000Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mvw14'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$dh=$dri->local_object('hosts');
$dh->add('ns.anything.eu');
$dh->add('ns.everything.eu');
my $dh2=$dri->local_object('hosts');
$dh2->name('nsgroup-eurid');
$rc=$dri->domain_create('ecom.eu',{pure_create=>1,contact=>$cs,ns=>$dh,nsgroup=>$dh2,duration=>DateTime::Duration->new(years=>1)});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.anything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:create><eurid:domain><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:create></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_create build');
is($rc->is_success(),1,'domain_create is_success 3');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T14:45:34','domain_create get_info(crDate) 3');


## p.58
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->add('ns.unknown.eu'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mmai1'),'tech');
$toc->add('contact',$cs);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$toc->del('contact',$cs);
$toc->add('nsgroup',$dri->local_object('hosts')->name('nsgroup-eurid2'));
$toc->del('nsgroup',$dri->local_object('hosts')->name('nsgroup-eurid'));
$rc=$dri->domain_update('ecom.eu',$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns.unknown.eu</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">mmai1</domain:contact></domain:add><domain:rem><domain:contact type="tech">mt24</domain:contact></domain:rem></domain:update></update><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:update><eurid:domain><eurid:add><eurid:nsgroup>nsgroup-eurid2</eurid:nsgroup></eurid:add><eurid:rem><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:rem></eurid:domain></eurid:update></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_update 1 build');
is($rc->is_success(),1,'domain_update 1 is_success');
is_deeply([$rc->get_extended_results()],[{type=>'text',from=>'eurid',message=>'OK'}],'domain_update 1 info');


$R2=$E1.'<response>'.r(2308,'Data management policy violation').'<extension><eurid:ext><eurid:result><eurid:msg>Contact mt24 is not linked to domain ecom</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_update('ecom.eu',$toc);
is($rc->is_success(),0,'domain_update 2 is_success');
is_deeply([$rc->get_extended_results()],[{type=>'text',from=>'eurid',message=>'Contact mt24 is not linked to domain ecom'}],'domain_update 2 info');


## p.61
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('ecom.eu',{pure_delete=>1,deleteDate=>DateTime->new(year=>2005,month=>9,day=>29,hour=>14,minute=>40,second=>51)});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:delete></delete><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:delete><eurid:domain><eurid:deleteDate>2005-09-29T14:40:51.000000000Z</eurid:deleteDate></eurid:domain></eurid:delete></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

## Release 5.6, page 28
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('domain-to-update-overwrite-true.eu',{pure_delete=>1,deleteDate=>DateTime->new(year=>2010,month=>1,day=>1,hour=>0,minute=>0,second=>0)});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>domain-to-update-overwrite-true.eu</domain:name></domain:delete></delete><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:delete><eurid:domain><eurid:deleteDate>2010-01-01T00:00:00.000000000Z</eurid:deleteDate></eurid:domain></eurid:delete></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_delete build'); 
is($rc->is_success(),1,'domain_delete is_success');




## p.63
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_undelete('ecom.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><undelete><domain:undelete xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:undelete></undelete><clTRID>TRID-0001</clTRID></command></epp>','domain_undelete build');
is($rc->is_success(),1,'domain_undelete is_success');


## p.67
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
my %rd;
$rd{trDate}=DateTime->new(year=>2005,month=>9,day=>29,hour=>22);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$cs->set($dri->local_object('contact')->srid('ak4589'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$rd{contact}=$cs;
$rd{nsgroup}=$dri->local_object('hosts')->name('nsgroup-eurid');
$rc=$dri->domain_transfer_start('something.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>something.eu</domain:name></domain:transfer></transfer><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transfer><eurid:domain><eurid:registrant>ak4589</eurid:registrant><eurid:trDate>2005-09-29T22:00:00.000000000Z</eurid:trDate><eurid:billing>jj1</eurid:billing><eurid:tech>mt24</eurid:tech><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:transfer></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');


## Release 5.5, page 16
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
%rd=();
$rd{trDate}=DateTime->new(year=>2008,month=>4,day=>22,hour=>22);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c4436955'),'billing');
$cs->set('#auto#','registrant');
$cs->set($dri->local_object('contact')->srid('c4436957'),'tech');
$rd{contact}=$cs;
$rd{owner_auth_code}='238110218175066'; ## see also RN 5.5 Addedum page 2
$rc=$dri->domain_transfer_start('something.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>something.eu</domain:name></domain:transfer></transfer><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transfer><eurid:domain><eurid:registrant>#AUTO#</eurid:registrant><eurid:trDate>2008-04-22T22:00:00.000000000Z</eurid:trDate><eurid:billing>c4436955</eurid:billing><eurid:tech>c4436957</eurid:tech></eurid:domain><eurid:ownerAuthCode>238110218175066</eurid:ownerAuthCode></eurid:transfer></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_start with owner_auth_code build');

## Release 5.5 page 20
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
%rd=();
$rc=$dri->domain_transfer_stop('superdomain.eu',{reason => 'The reason for cancelling the transfer'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transfer op="cancel"><domain:transfer xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>superdomain.eu</domain:name></domain:transfer></transfer><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:cancel><eurid:reason>The reason for cancelling the transfer</eurid:reason></eurid:cancel></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_stop build');
is($rc->is_success(),1,'domain_transfer_stop is_success');


## p.70
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>Content check ok</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jd1'),'billing');
$cs->set($dri->local_object('contact')->srid('js5'),'registrant');
$cs->set($dri->local_object('contact')->srid('jb1'),'tech');
$rd{contact}=$cs;
$rd{trDate}=DateTime->new(year=>2002,month=>2,day=>18,hour=>22);
$rd{ns}=$dri->local_object('hosts')->add('ns1.superdomain.eu',['1.2.3.4'])->add('ns.test.eu');
$rd{nsgroup}='mynsgroup1';
$rc=$dri->domain_transfer_quarantine_start('superdomain.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transferq op="request"><domain:transferq xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>superdomain.eu</domain:name></domain:transferq></transferq><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transferq><eurid:domain><eurid:registrant>js5</eurid:registrant><eurid:trDate>2002-02-18T22:00:00.000000000Z</eurid:trDate><eurid:billing>jd1</eurid:billing><eurid:tech>jb1</eurid:tech><eurid:ns xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:hostAttr><domain:hostName>ns1.superdomain.eu</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.test.eu</domain:hostName></domain:hostAttr></eurid:ns><eurid:nsgroup>mynsgroup1</eurid:nsgroup></eurid:domain></eurid:transferq></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_quarantine_start build'); ## 3 corrections from EURid sample
is($rc->is_success(),1,'domain_transfer_quarantine_start is_success');

## Release 5.5, page 22
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
%rd=();
$rc=$dri->domain_transfer_quarantine_stop('superdomain.eu',{reason => 'The reason for cancelling the transfer from quarantine'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transferq op="cancel"><domain:transferq xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>superdomain.eu</domain:name></domain:transferq></transferq><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:cancel><eurid:reason>The reason for cancelling the transfer from quarantine</eurid:reason></eurid:cancel></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_quarantine_stop build');
is($rc->is_success(),1,'domain_transfer_quarantine_stop is_success');

## p.72
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$cs->set($dri->local_object('contact')->srid('ak4589'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$rd{contact}=$cs;
$rd{trDate}=DateTime->new(year=>2005,month=>9,day=>29,hour=>22);
$rd{nsgroup}='nsgroup-eurid';
$rc=$dri->domain_trade_start('fox.eu',\%rd);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><trade op="request"><domain:trade xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>fox.eu</domain:name></domain:trade></trade><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:trade><eurid:domain><eurid:registrant>ak4589</eurid:registrant><eurid:trDate>2005-09-29T22:00:00.000000000Z</eurid:trDate><eurid:billing>jj1</eurid:billing><eurid:tech>mt24</eurid:tech><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:trade></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_trade build'); ## corrected from EURid sample
is($rc->is_success(),1,'domain_trade build');

## Release 5.5 page 20
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
%rd=();
$rc=$dri->domain_trade_stop('superdomain.eu',{reason => 'The reason for cancelling the trade'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><trade op="cancel"><domain:trade xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>superdomain.eu</domain:name></domain:trade></trade><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:cancel><eurid:reason>The reason for cancelling the trade</eurid:reason></eurid:cancel></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_trade_stop build');

## p.74
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_reactivate('ecom.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><reactivate><domain:reactivate xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:reactivate></reactivate><clTRID>TRID-0001</clTRID></command></epp>','domain_reactivate build');
is($rc->is_success(),1,'domain_reactivate is_success');


## p.76
$R2=$E1.'<response>'.r().'<resData><domain:chkData><domain:cd><domain:name avail="0">nothing.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">anything.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">ecom.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">mykingdom.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">everything.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">something.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">mything.eu</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$dri->cache_clear();
$rc=$dri->domain_check('nothing.eu','anything.eu','ecom.eu','mykingdom.eu','everything.eu','something.eu','mything.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>nothing.eu</domain:name><domain:name>anything.eu</domain:name><domain:name>ecom.eu</domain:name><domain:name>mykingdom.eu</domain:name><domain:name>everything.eu</domain:name><domain:name>something.eu</domain:name><domain:name>mything.eu</domain:name></domain:check></check><clTRID>TRID-0001</clTRID></command></epp>','domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','nothing.eu'),1,'domain_check multi get_info(exist) 1/7');
is($dri->get_info('exist','domain','anything.eu'),0,'domain_check multi get_info(exist) 2/7');
is($dri->get_info('exist','domain','ecom.eu'),1,'domain_check multi get_info(exist) 3/7');
is($dri->get_info('exist','domain','mykingdom.eu'),1,'domain_check multi get_info(exist) 4/7');
is($dri->get_info('exist','domain','everything.eu'),1,'domain_check multi get_info(exist) 5/7');
is($dri->get_info('exist','domain','something.eu'),0,'domain_check multi get_info(exist) 6/7');
is($dri->get_info('exist','domain','mything.eu'),0,'domain_check multi get_info(exist) 7/7');


## p.78
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>ecom.eu</domain:name><domain:roid>19204-EURID</domain:roid><domain:status s="ok"/><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mmai1</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.anything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.unknown.eu</domain:hostName></domain:hostAttr></domain:ns><domain:clID>t000006</domain:clID><domain:crID>t000006</domain:crID><domain:crDate>2005-09-29T14:45:35.000Z</domain:crDate><domain:upID>t000006</domain:upID><domain:upDate>2005-09-29T14:45:35.000Z</domain:upDate><domain:exDate>2006-09-29T15:45:35.0Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>nsgroup-eurid2</eurid:nsgroup></eurid:domain></eurid:infData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('ecom.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name hosts="all">ecom.eu</domain:name></domain:info></info><clTRID>TRID-0001</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'19204-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'mvw14','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'jj1','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'mmai1','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.anything.eu','ns.everything.eu','ns.unknown.eu'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'t000006','domain_info get_info(clID)');
is($dri->get_info('crID'),'t000006','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2005-09-29T14:45:35','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'t000006','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'2005-09-29T14:45:35','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2006-09-29T15:45:35','domain_info get_info(exDate) value');
$d=$dri->get_info('nsgroup');
isa_ok($d,'ARRAY','domain_info get_info(nsgroup)');
is(@$d,1,'domain_info get_info(nsgroup) count');
$d=$d->[0];
isa_ok($d,'Net::DRI::Data::Hosts','domain_info get_info(nsgroup) [0]');
is($d->name(),'nsgroup-eurid2','domain_info get_info(nsgroup) [0] value');

## Examples from https://secure.registry.eu/images/Library/release%20notes%205%201.pdf (in effect since 2007-08-06)

# §1.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-inusedomain-0001-test.eu</domain:name><domain:roid>3787937-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c195332</domain:registrant><domain:contact type="billing">c31</domain:contact><domain:contact type="tech">c34</domain:contact><domain:clID>a000005</domain:clID><domain:crID>a000005</domain:crID><domain:crDate>2007-07-31T16:43:44.000Z</domain:crDate><domain:upID>a000005</domain:upID><domain:upDate>2007-07-31T16:46:16.000Z</domain:upDate><domain:exDate>2008-07-31T16:43:44.000Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>test</eurid:nsgroup><eurid:onhold>false</eurid:onhold><eurid:quarantined>false</eurid:quarantined></eurid:domain></eurid:infData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-inusedomain-0001-test.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name hosts="all">0001-inusedomain-0001-test.eu</domain:name></domain:info></info><clTRID>TRID-0001</clTRID></command></epp>','domain_info build');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');


# §2.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-scheduledfordelete-0001-test.eu</domain:name><domain:roid>3787636-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c195332</domain:registrant><domain:contact type="billing">c31</domain:contact><domain:contact type="tech">c34</domain:contact><domain:clID>a000005</domain:clID><domain:crID>a000005</domain:crID><domain:crDate>2007-07-31T14:50:19.000Z</domain:crDate><domain:upID>a000005</domain:upID><domain:upDate>2007-07-31T16:46:58.000Z</domain:upDate><domain:exDate>2008-07-31T14:50:19.000Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>test</eurid:nsgroup></eurid:domain></eurid:infData></eurid:ext><extendedInfo:infData xmlns:extendedInfo="http://www.eurid.eu/xml/epp/extendedInfo-1.0"><extendedInfo:onhold>false</extendedInfo:onhold><extendedInfo:quarantined>false</extendedInfo:quarantined><extendedInfo:deletionDate>2009-07-31T18:00:00.000Z</extendedInfo:deletionDate></extendedInfo:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-scheduledfordelete-0001-test.eu');
$d=$dri->get_info('deletionDate');
isa_ok($d,'DateTime','domain_info get_info(deletionDate)');
is(''.$d,'2009-07-31T18:00:00','domain_info get_info(deletionDate) value');


# §3.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-quarantinedomain-0001.eu</domain:name><domain:roid>3787640-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c195332</domain:registrant><domain:contact type="billing">c31</domain:contact><domain:contact type="tech">c34</domain:contact><domain:clID>a000005</domain:clID><domain:crID>a000005</domain:crID><domain:crDate>2007-07-31T14:51:37.000Z</domain:crDate><domain:upID>a000005</domain:upID><domain:upDate>2007-07-31T14:51:37.000Z</domain:upDate><domain:exDate>2008-07-31T14:51:37.000Z</domain:exDate></domain:infData></resData><extension><extendedInfo:infData xmlns:extendedInfo="http://www.eurid.eu/xml/epp/extendedInfo-1.0"><extendedInfo:onhold>false</extendedInfo:onhold><extendedInfo:quarantined>true</extendedInfo:quarantined><extendedInfo:availableDate>2007-09-09T23:00:00.000Z</extendedInfo:availableDate><extendedInfo:deletionDate>2007-07-31T14:00:00.000Z</extendedInfo:deletionDate></extendedInfo:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-quarantinedomain-0001.eu');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok','quarantined'],'domain_info get_info(status) list');
$d=$dri->get_info('deletionDate');
isa_ok($d,'DateTime','domain_info get_info(deletionDate)');
is(''.$d,'2007-07-31T14:00:00','domain_info get_info(deletionDate) value');
$d=$dri->get_info('availableDate');
isa_ok($d,'DateTime','domain_info get_info(availableDate)');
is(''.$d,'2007-09-09T23:00:00','domain_info get_info(availableDate) value');


# §4.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-domainonhold-0001-test.eu</domain:name><domain:roid>3787823-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c8033037</domain:registrant><domain:contact type="billing">c31</domain:contact><domain:contact type="tech">c34</domain:contact><domain:clID>a000005</domain:clID><domain:crID>a000005</domain:crID><domain:crDate>2007-07-31T16:01:26.000Z</domain:crDate><domain:upID>a000005</domain:upID><domain:upDate>2007-07-31T16:49:58.000Z</domain:upDate><domain:exDate>2008-07-31T16:01:26.000Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>test</eurid:nsgroup></eurid:domain></eurid:infData></eurid:ext><extendedInfo:infData xmlns:extendedInfo="http://www.eurid.eu/xml/epp/extendedInfo-1.0"><extendedInfo:onhold>true</extendedInfo:onhold><extendedInfo:quarantined>false</extendedInfo:quarantined></extendedInfo:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-domainonhold-0001-test.eu');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok','onhold'],'domain_info get_info(status) list');

# §5.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-internaltradedomain-0001-test.eu</domain:name><domain:roid>3787827-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c195332</domain:registrant><domain:contact type="billing">c31</domain:contact><domain:contact type="tech">c34</domain:contact><domain:clID>a000005</domain:clID><domain:crID>a000005</domain:crID><domain:crDate>2007-07-31T16:02:21.000Z</domain:crDate><domain:upID>a000005</domain:upID><domain:upDate>2007-07-31T16:50:25.000Z</domain:upDate><domain:exDate>2008-07-31T16:02:21.000Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>test</eurid:nsgroup></eurid:domain></eurid:infData></eurid:ext><extendedInfo:infData xmlns:extendedInfo="http://www.eurid.eu/xml/epp/extendedInfo-1.0"><extendedInfo:onhold>false</extendedInfo:onhold><extendedInfo:quarantined>false</extendedInfo:quarantined></extendedInfo:infData><pendingTransaction:infData xmlns:pendingTransaction="http://www.eurid.eu/xml/epp/pendingTransaction-1.0"><pendingTransaction:trade><pendingTransaction:domain><pendingTransaction:registrant>c7557462</pendingTransaction:registrant><pendingTransaction:trDate>2007-07-30T22:00:00.000Z</pendingTransaction:trDate><pendingTransaction:billing>c31</pendingTransaction:billing><pendingTransaction:tech>c34</pendingTransaction:tech></pendingTransaction:domain><pendingTransaction:initiationDate>2007-07-31T16:19:58.000Z</pendingTransaction:initiationDate><pendingTransaction:status>NotYetApproved</pendingTransaction:status><pendingTransaction:replySeller>NoAnswer</pendingTransaction:replySeller><pendingTransaction:replyBuyer>NoAnswer</pendingTransaction:replyBuyer></pendingTransaction:trade></pendingTransaction:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-internaltradedomain-0001-test.eu');
$s=$dri->get_info('pending_transaction');
is(ref($s),'HASH','domain_info get_info(pending_transaction) trade');
is($s->{type},'trade','domain_info get_info(pending_transaction) trade type');
isa_ok($s->{trDate},'DateTime','domain_info get_info(pending_transaction) trade trDate');
is(''.$s->{trDate},'2007-07-30T22:00:00','domain_info get_info(pending_transaction) trade trDate value');
$d=$s->{'contact'};
isa_ok($d,'Net::DRI::Data::ContactSet','domain_info get_info(pending_transaction) trade contact');
is_deeply([$d->types()],['billing','registrant','tech'],'domain_info get_info(pending_transaction) trade contact types');
is($d->get('registrant')->srid(),'c7557462','domain_info get_info(pending_transaction) trade registrant srid');
is($d->get('billing')->srid(),'c31','domain_info get_info(pending_transaction) trade billing srid');
is($d->get('tech')->srid(),'c34','domain_info get_info(pending_transaction) trade tech srid');
isa_ok($s->{initiationDate},'DateTime','domain_info get_info(pending_transaction) trade initiationDate');
is(''.$s->{initiationDate},'2007-07-31T16:19:58','domain_info get_info(pending_transaction) trade initiationDate value');
is($s->{status},'NotYetApproved','domain_info get_info(pending_transaction) trade status');
is($s->{replySeller},'NoAnswer','domain_info get_info(pending_transaction) trade replySeller');
is($s->{replyBuyer},'NoAnswer','domain_info get_info(pending_transaction) trade replyBuyer');

# §6.2, not done, same as §1.2
# §7.2 and §8.2, nothing new
# §9.2, same as §5.2

# §10.2
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>0001-domaintransfer-0001-test.eu</domain:name><domain:roid>0-EURID</domain:roid><domain:clID>#non-disclosed#</domain:clID></domain:infData></resData><extension><extendedInfo:infData xmlns:extendedInfo="http://www.eurid.eu/xml/epp/extendedInfo-1.0"><extendedInfo:onhold>false</extendedInfo:onhold><extendedInfo:quarantined>false</extendedInfo:quarantined></extendedInfo:infData><pendingTransaction:infData xmlns:pendingTransaction="http://www.eurid.eu/xml/epp/pendingTransaction-1.0"><pendingTransaction:transfer><pendingTransaction:domain><pendingTransaction:registrant>#AUTO#</pendingTransaction:registrant><pendingTransaction:trDate>2007-07-30T22:00:00.000Z</pendingTransaction:trDate><pendingTransaction:billing>c31</pendingTransaction:billing><pendingTransaction:tech>c34</pendingTransaction:tech></pendingTransaction:domain><pendingTransaction:initiationDate>2007-07-31T16:22:19.000Z</pendingTransaction:initiationDate><pendingTransaction:status>NotYetApproved</pendingTransaction:status><pendingTransaction:replyOwner>NoAnswer</pendingTransaction:replyOwner></pendingTransaction:transfer></pendingTransaction:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('0001-domaintransfer-0001-test.eu');
$s=$dri->get_info('pending_transaction');
is(ref($s),'HASH','domain_info get_info(pending_transaction) trade');
is($s->{type},'transfer','domain_info get_info(pending_transaction) transfer type');
isa_ok($s->{trDate},'DateTime','domain_info get_info(pending_transaction) transfer trDate');
is(''.$s->{trDate},'2007-07-30T22:00:00','domain_info get_info(pending_transaction) transfer trDate value');
$d=$s->{'contact'};
isa_ok($d,'Net::DRI::Data::ContactSet','domain_info get_info(pending_transaction) transfer contact');
is_deeply([$d->types()],['billing','registrant','tech'],'domain_info get_info(pending_transaction) transfer contact types');
is($d->get('registrant')->srid(),'#AUTO#','domain_info get_info(pending_transaction) transfer registrant srid');
is($d->get('billing')->srid(),'c31','domain_info get_info(pending_transaction) transfer billing srid');
is($d->get('tech')->srid(),'c34','domain_info get_info(pending_transaction) transfer tech srid');
isa_ok($s->{initiationDate},'DateTime','domain_info get_info(pending_transaction) transfer initiationDate');
is(''.$s->{initiationDate},'2007-07-31T16:22:19','domain_info get_info(pending_transaction) transfer initiationDate value');
is($s->{status},'NotYetApproved','domain_info get_info(pending_transaction) transfer status');
is($s->{replyOwner},'NoAnswer','domain_info get_info(pending_transaction) transfer replyOwner');

## Check commands
$R2=$E1.'<response>'.r().'<resData><domain:chkData><domain:cd><domain:name avail="false">0002-quarantinedomain-0001.eu</domain:name><domain:reason lang="en">quarantine</domain:reason></domain:cd></domain:chkData></resData><extension><eurid:ext><eurid:chkData><eurid:domain><eurid:cd><eurid:name accepted="0" expired="0" initial="0" rejected="0">0002-quarantinedomain-0001.eu</eurid:name><eurid:availableDate>2007-09-09T23:00:00.000Z</eurid:availableDate></eurid:cd></eurid:domain></eurid:chkData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('0002-quarantinedomain-0001.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>0002-quarantinedomain-0001.eu</domain:name></domain:check></check><clTRID>TRID-0001</clTRID></command></epp>','domain_check version 2.0 build');
is($rc->is_success(),1,'domain_check version 2.0 is_success');
is($dri->get_info('exist','domain','0002-quarantinedomain-0001.eu'),1,'domain_check version 2.0 get_info(exist)');
is($dri->get_info('exist_reason','domain','0002-quarantinedomain-0001.eu'),'quarantine','domain_check version 2.0 get_info(exist_reason)');
is($dri->get_info('application_accepted','domain','0002-quarantinedomain-0001.eu'),0,'domain_check version 2.0 get_info(application_accepted)');
is($dri->get_info('application_expired','domain','0002-quarantinedomain-0001.eu'),0,'domain_check version 2.0 get_info(application_expired)');
is($dri->get_info('application_initial','domain','0002-quarantinedomain-0001.eu'),0,'domain_check version 2.0 get_info(application_initial)');
is($dri->get_info('application_rejected','domain','0002-quarantinedomain-0001.eu'),0,'domain_check version 2.0 get_info(application_rejected)');
$s=$dri->get_info('availableDate','domain','0002-quarantinedomain-0001.eu');
isa_ok($s,'DateTime','domain_check version 2.0 get_info(availableDate)');
is(''.$s,'2007-09-09T23:00:00','domain_check version 2.0 get_info(availableDate) value');

## Release 5.5, page 18
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:response><eurid:checkContactForTransfer><eurid:percentage>100</eurid:percentage></eurid:checkContactForTransfer></eurid:response></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_contact_for_transfer('domainnametocheck1.eu',{registrant=>$dri->local_object('contact')->srid('c3456789')});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:command><eurid:checkContactForTransfer><eurid:domainName>domainnametocheck1.eu</eurid:domainName><eurid:registrant>c3456789</eurid:registrant></eurid:checkContactForTransfer></eurid:command></eurid:ext></extension></epp>','domain_check_contact_for_transfer build');
is($rc->is_success(),1,'domain_check_contact_for_transfer is_success');
is($dri->get_info('percentage'),100,'domain_check_contact_for_transfer get_info(percentage)');

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

## page 19
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="6830"><qDate>2008-09-18T21:29:28.179+02:00</qDate><msg>Transfer of domain name mytransferdomain.eu</msg></msgQ><resData><eurid:pollRes><eurid:action>CONFIRM</eurid:action><eurid:domainname>mytransferdomain.eu</eurid:domainname><eurid:returncode>1155</eurid:returncode><eurid:type>TRANSFER</eurid:type></eurid:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
## This is a *very* convoluted way to access data, it is only done so to test everything is there
$s=$rc->get_data('message','session','last_id');
is($s,6830,'notification get_data(message,session,last_id)');
$s=$rc->get_data('message',$s,'name');
is($s,'mytransferdomain.eu','notification get_data(message,ID,name)');
is($rc->get_data('domain',$s,'object_type'),$rc->get_data('object_type'),'notification get_data(domain,X,Y)=get_data(Y)');
is($rc->get_data('exist'),1,'notification get_data(exist)');
is($rc->get_data('return_code'),1155,'notification get_data(return_code)');
is($rc->get_data('action'),'confirm_transfer','notification get_data(action)');
is($rc->get_data('id'),6830,'notification get_data(id)');

## Another form found in the wild

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="4682495"><qDate>2011-10-31T23:25:17.071Z</qDate><msg>Watermark Reached</msg></msgQ><resData><eurid:pollRes><eurid:action>REACHED</eurid:action><eurid:level>1000.00</eurid:level><eurid:returncode>1000</eurid:returncode><eurid:type>WATERMARK</eurid:type></eurid:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
$s=$rc->get_data('message','session','last_id');
is($rc->get_data('message',$s,'action'),'reached_watermark','notification !domain get_data(action)');
is($rc->get_data('message',$s,'return_code'),1000,'notification !domain get_data(return_code)');
is($rc->get_data('message',$s,'level'),'1000.00','notification !domain get_data(level)');


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
## Release 6.1 (2010-12-01)

## p.21
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:creData><domain:name>dömain.eu</domain:name><domain:crDate>2009-10-14T08:44:50.618Z</domain:crDate></domain:creData></resData><extension><idn:mapping><idn:name><idn:ace>xn--dmain-jua.eu</idn:ace><idn:unicode>dömain.eu</idn:unicode></idn:name></idn:mapping></extension><trID><clTRID>create-domain-00</clTRID><svTRID>eurid-38562</svTRID></trID></response></epp>';
$R2=Encode::decode('iso-8859-15',$R2);

$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mvw14'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$rc=$dri->domain_create('dömain.eu',{pure_create=>1,contact=>$cs,auth=>{pw=>'not-used'}});

is($rc->get_data('ace'),'xn--dmain-jua.eu','domain_create idn get_data(ace)');
is($rc->get_data('unicode'),"d\x{00f6}main.eu",'domain_create idn get_data(unicode)');


## p.23
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData><domain:name>dömain.eu</domain:name><domain:roid>17941-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c100000</domain:registrant><domain:contact type="billing">c100003</domain:contact><domain:contact type="tech">c100002</domain:contact><domain:clID>a100000</domain:clID><domain:crID>a100000</domain:crID><domain:crDate>2009-10-14T08:44:50.000Z</domain:crDate><domain:upID>a100000</domain:upID><domain:upDate>2009-10-14T08:44:50.000Z</domain:upDate><domain:exDate>2010-10-31T22:59:59.999Z</domain:exDate></domain:infData></resData><extension><idn:mapping><idn:name><idn:ace>xn--dmain-jua.eu</idn:ace><idn:unicode>dömain.eu</idn:unicode></idn:name></idn:mapping></extension><trID><clTRID>info-domain-00</clTRID><svTRID>eurid-0</svTRID></trID></response></epp>';
$R2=Encode::decode('iso-8859-15',$R2);

$rc=$dri->domain_info('dömain.eu');
is($rc->get_data('ace'),'xn--dmain-jua.eu','domain_info idn get_data(ace)');
is($rc->get_data('unicode'),"d\x{00f6}main.eu",'domain_info idn get_data(unicode)');


## p.25
my $idndom1="\x{03B1}\x{03C7}\x{03B1}.eu";
my $idndom2="\x{0430}\x{0445}\x{0430}.eu";
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:chkData><domain:cd><domain:name avail="false">d'."\x{00f6}".'main.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="true">'.$idndom1.'</domain:name></domain:cd><domain:cd><domain:name avail="true">xn--80aa6d.eu</domain:name></domain:cd></domain:chkData></resData><extension><idn:mapping><idn:name><idn:ace>xn--80aa6d.eu</idn:ace><idn:unicode>'.$idndom2.'</idn:unicode></idn:name><idn:name><idn:ace>xn--dmain-jua.eu</idn:ace><idn:unicode>d'."\x{00f6}".'main.eu</idn:unicode></idn:name><idn:name><idn:ace>xn--mxaa9d.eu</idn:ace><idn:unicode>'.$idndom1.'</idn:unicode></idn:name></idn:mapping></extension><trID><clTRID>check-domain-00</clTRID><svTRID>eurid-0</svTRID></trID></response></epp>';

$rc=$dri->domain_check("d\x{00f6}main.eu",$idndom1,'xn--80aa6d.eu');
is($rc->get_data('domain','dömain.eu','ace'),'xn--dmain-jua.eu','domain_check idn get_data(ace) 1');
is($rc->get_data('domain','dömain.eu','unicode'),"d\x{00f6}main.eu",'domain_check idn get_data(unicode) 1');
is($rc->get_data('domain',$idndom1,'ace'),'xn--mxaa9d.eu','domain_check idn get_data(ace) 2');
is($rc->get_data('domain',$idndom1,'unicode'),$idndom1,'domain_check idn get_data(unicode) 2');
is($rc->get_data('domain','xn--80aa6d.eu','ace'),'xn--80aa6d.eu','domain_check idn get_data(ace) 3');
is($rc->get_data('domain','xn--80aa6d.eu','unicode'),$idndom2,'domain_check idn get_data(unicode) 3');


####################################################################################################
## Release 7.1

## p.19

$R2='';
%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c129179'),'billing');
$cs->set($dri->local_object('contact')->srid('c9232372'),'registrant');
$cs->set($dri->local_object('contact')->srid('c7838742'),'tech');
$rd{contact}=$cs;
$rd{secdns}=[{keyTag=>'6615',alg=>7,digestType=>1,digest=>'e8dadacffab754e9cf40b919d6f698c03309f47c',maxSigLife=>604800,key_flags=>257,key_protocol=>3,key_alg=>7,key_pubKey=>'AwEAAcTnEOkfH1FsT9EI2BmjMB83uDWXpSp57YHa0v6Xg60Usm3Y2Fct1emy+h0+uDstyUl5eILy9eO2eI67m5r0Lck='}];
$rc=$dri->domain_trade_start('ktz.eu',\%rd);

is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><trade op="request"><domain:trade xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ktz.eu</domain:name></domain:trade></trade><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:trade><eurid:domain><eurid:registrant>c9232372</eurid:registrant><eurid:billing>c129179</eurid:billing><eurid:tech>c7838742</eurid:tech></eurid:domain></eurid:trade></eurid:ext><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.0 secDNS-1.0.xsd"><secDNS:dsData><secDNS:keyTag>6615</secDNS:keyTag><secDNS:alg>7</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>e8dadacffab754e9cf40b919d6f698c03309f47c</secDNS:digest><secDNS:maxSigLife>604800</secDNS:maxSigLife><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>7</secDNS:alg><secDNS:pubKey>AwEAAcTnEOkfH1FsT9EI2BmjMB83uDWXpSp57YHa0v6Xg60Usm3Y2Fct1emy+h0+uDstyUl5eILy9eO2eI67m5r0Lck=</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:create></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_trade +DNSSEC build');

## Keygroups

$rc=$dri->keygroup_create('kwkwwyjzorsqljbvlssqhzz');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>kwkwwyjzorsqljbvlssqhzz</keygroup:name></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 1');


$rc=$dri->keygroup_create('uvmsfcextoydtsltky',{ 'keys' => [{keyTag=>49049,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0='},
{keyTag=>57695,flags=>256,protocol=>3,alg=>7,pubKey=>'AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0='}] });
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><keygroup:create xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>uvmsfcextoydtsltky</keygroup:name><keygroup:key><keygroup:keyTag>49049</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAaQx/SAfK9rmTYsyThhUgvUBQORqQhUNbcIx67sfUtC6Ii1WHn0CdIMcO8FUMT3PE7BhJ04zYiJdX2Gr6VEHXW0=</keygroup:pubKey></keygroup:key><keygroup:key><keygroup:keyTag>57695</keygroup:keyTag><keygroup:flags>256</keygroup:flags><keygroup:protocol>3</keygroup:protocol><keygroup:algorithm>7</keygroup:algorithm><keygroup:pubKey>AwEAAdVHFEnY8q8xuiiSO0XvX0LWlcCMWQByFyyCzPFfUmso0677qjIZYEF/fIx/WJuIRup1/Ay58U8pvCnsk0iXIV0=</keygroup:pubKey></keygroup:key></keygroup:create></create><clTRID>TRID-0001</clTRID></command></epp>','keygroup_create build 2');


$rc=$dri->keygroup_delete('dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><keygroup:delete xmlns:keygroup="http://www.eurid.eu/xml/epp/keygroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/keygroup-1.0 keygroup-1.0.xsd"><keygroup:name>dvnqbnzfwnxraquhyjcsizpxdjrclifavmfmebjir</keygroup:name></keygroup:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','keygroup_delete build');


$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c11130723'),'registrant');
$cs->set($dri->local_object('contact')->srid('c11130718'),'onsite');
$cs->set($dri->local_object('contact')->srid('c4436955'),'billing');
$rc=$dri->domain_create('cckyvtdduopvmkjzmikqpnawzjwxgkxqjotabpuw.eu',{pure_create=>1,contact=>$cs,auth=>{pw=>'not-used'},keygroup=>'sswuypdokyplknwrydxighecgprzgeo'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>cckyvtdduopvmkjzmikqpnawzjwxgkxqjotabpuw.eu</domain:name><domain:registrant>c11130723</domain:registrant><domain:contact type="billing">c4436955</domain:contact><domain:contact type="onsite">c11130718</domain:contact><domain:authInfo><domain:pw>not-used</domain:pw></domain:authInfo></domain:create></create><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:create><eurid:domain><eurid:keygroup>sswuypdokyplknwrydxighecgprzgeo</eurid:keygroup></eurid:domain></eurid:create></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_create + keygroup build');


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


## domain_update with keygroup => not specified in documentation nor XML schemas !


%rd=();
$rd{duration}=DateTime::Duration->new(years => 1);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c4436955'),'billing');
$cs->set($dri->local_object('contact')->srid('c11130723'),'registrant');
$cs->set($dri->local_object('contact')->srid('c4436957'),'tech');
$rd{contact}=$cs;
$rd{keygroup}='lmgpblhauvcmlxyrlldlhxzyzsguzesshqqkubcteacsc';
$rc=$dri->domain_transfer_start('avaialebledomainsaname2xr.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>avaialebledomainsaname2xr.eu</domain:name><domain:period unit="y">1</domain:period></domain:transfer></transfer><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transfer><eurid:domain><eurid:registrant>c11130723</eurid:registrant><eurid:billing>c4436955</eurid:billing><eurid:tech>c4436957</eurid:tech><eurid:keygroup>lmgpblhauvcmlxyrlldlhxzyzsguzesshqqkubcteacsc</eurid:keygroup></eurid:domain></eurid:transfer></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_start + keygroup build');


%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c4436955'),'billing');
$cs->set($dri->local_object('contact')->srid('c11130723'),'registrant');
$cs->set($dri->local_object('contact')->srid('c4436957'),'tech');
$rd{contact}=$cs;
$rd{keygroup}='roxqcrztngn';
$rc=$dri->domain_trade_start('cxlbbmyncvebyqsum.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><trade op="request"><domain:trade xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>cxlbbmyncvebyqsum.eu</domain:name></domain:trade></trade><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:trade><eurid:domain><eurid:registrant>c11130723</eurid:registrant><eurid:billing>c4436955</eurid:billing><eurid:tech>c4436957</eurid:tech><eurid:keygroup>roxqcrztngn</eurid:keygroup></eurid:domain></eurid:trade></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_trade_start + keygroup build');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData><domain:name>moscou.eu</domain:name><domain:roid>6590858-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c11814810</domain:registrant><domain:contact type="billing">c129179</domain:contact><domain:contact type="onsite">c11814791</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns2.domainmonster.com</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.domainmonster.com</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns3.domainmonster.com</domain:hostName></domain:hostAttr></domain:ns><domain:clID>a000475</domain:clID><domain:crID>a000475</domain:crID><domain:crDate>2009-12-21T07:41:31.000Z</domain:crDate><domain:upID>a000475</domain:upID><domain:upDate>2010-04-08T12:27:25.000Z</domain:upDate><domain:exDate>2010-12-31T22:59:59.999Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:keygroup>l2vor0ki4km3byl6twsin3v5lumi68i</eurid:keygroup><eurid:onhold>false</eurid:onhold><eurid:quarantined>false</eurid:quarantined></eurid:domain></eurid:infData></eurid:ext></extension><trID><svTRID>eurid-0</svTRID></trID></response></epp>';
$rc=$dri->domain_info('moscou.eu');
is($rc->get_data('keygroup'),'l2vor0ki4km3byl6twsin3v5lumi68i','domain_info parse keygroup');

####################################################################################################
## Release 8.0

## Domain renew reply §7.2

$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>some-domain.eu</domain:name><domain:exDate>2015-01-31T22:59:59.999Z</domain:exDate></domain:renData></resData><extension><eurid:ext><eurid:renew><eurid:removedDeletionDate>false</eurid:removedDeletionDate></eurid:renew></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('some-domain.eu',{duration => $dri->local_object('duration',years=>2), current_expiration => $dri->local_object('datetime',year=>2013,month=>1,day=>31)});
is($rc->get_data('removedDeletionDate'),0,'get_data removedDeletionDate');

exit 0;
