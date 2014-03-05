#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Test::More tests => 304;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('Nominet');
$dri->target('Nominet')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co);

# ## Domain commands
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:cd><domain:name avail="0">example.co.uk</domain:name></domain:cd><domain:cd><domain:name avail="1">example2.co.uk</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.co.uk','example2.co.uk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name><domain:name>example2.co.uk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example.co.uk'),1,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.co.uk'),0,'domain_check multi get_info(exist) 2/2');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name><domain:reg-status>Registration request being processed.</domain:reg-status><domain:account><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1"><account:roid>S123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr type="admin"><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="admin" order="2"><contact:infData><contact:roid>C23456</contact:roid><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="billing" order="1"><contact:infData><contact:roid>C12347</contact:roid><contact:name>A. Ccountant</contact:name><contact:phone>01865 657893</contact:phone><contact:email>acc@billing.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></domain:account><domain:clID>TEST</domain:clID><domain:crID>TEST</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>domains@isp.com</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2007-12-03T09:00:00.0Z</domain:exDate></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.co.uk');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('reg-status'),'Registration request being processed.','domain_info get_info(reg-status)');

$co=$dri->get_info('contact');
isa_ok($co,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$co->types()],['admin','billing','registrant'],'domain_info get_info(contact) types');

$d=$co->get('registrant');
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(registrant)');
is($d->roid(),'S123456','domain_info get_info(contact) get(registrant) roid');
is($d->name(),'Mr R. Strant','domain_info get_info(contact) get(registrant) name');
is($d->org(),'R. S. Industries','domain_info get_info(contact) get(registrant) org/trad-name');
is($d->type(),'STRA','domain_info get_info(contact) get(registrant) type');
is($d->co_no(),'NI123456','domain_info get_info(contact) get(registrant) co_no');
is($d->opt_out(),'N','domain_info get_info(contact) get(registrant) opt_out');
is_deeply(scalar $d->street(),['2102 High Street','Carfax'],'domain_info get_info(contact) get(registrant) street');
is($d->city(),'Oxford','domain_info get_info(contact) get(registrant) city');
is($d->sp(),'Oxfordshire','domain_info get_info(contact) get(registrant) sp/county');
is($d->pc(),'OX1 1DF','domain_info get_info(contact) get(registrant) pc/postcode');
is($d->cc(),'GB','domain_info get_info(contact) get(registrant) country');

$d=($co->get('admin'))[0];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(admin1)');
is($dri->get_info('action','contact',$d->roid()),'info','domain_info get_info(action,contact,admin1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'domain_info get_info(exist,contact,admin1->roid)');
is($d->roid(),'C12345','domain_info get_info(contact) get(admin1) roid');
is($d->name(),'Mr R.Strant','domain_info get_info(contact) get(admin1) name');
is($d->voice(),'01865 123456','domain_info get_info(contact) get(admin1) voice');
is($d->fax(),'01865 123456','domain_info get_info(contact) get(admin1) fax');
is($d->email(),'r.strant@strant.co.uk','domain_info get_info(contact) get(admin1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,admin1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,admin1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,admin1->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,admin1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,admin1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,admin1->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,admin1->roid) value');

$d=($co->get('admin'))[1];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(admin2)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin2->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin2->roid)');
is($d->roid(),'C23456','domain_info get_info(contact) get(admin2) roid');
is($d->name(),'Ms S. Strant','domain_info get_info(contact) get(admin2) name');
is($d->voice(),'01865 123457','domain_info get_info(contact) get(admin2) voice');
is($d->fax(),'01865 123456','domain_info get_info(contact) get(admin2) fax');
is($d->email(),'s.strant@strant.co.uk','domain_info get_info(contact) get(admin2) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,admin2->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,admin2->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,admin2->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,admin2->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,admin2->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,admin2->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,admin2->roid) value');

$d=($co->get('billing'))[0];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(billing1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,billing1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'domain_info get_info(exist,contact,billing1->roid)');
is($d->roid(),'C12347','domain_info get_info(contact) get(billing1) roid');
is($d->name(),'A. Ccountant','domain_info get_info(contact) get(billing1) name');
is($d->voice(),'01865 657893','domain_info get_info(contact) get(billing1) voice');
is($d->email(),'acc@billing.co.uk','domain_info get_info(contact) get(billing1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,billing1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,billing1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,billing1->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,billing1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,billing1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,billing1->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,billing1->roid) value');

is($dri->get_info('clID','account','S123456'),'TEST','domain_info get_info(clID,account,registrant->srid)');
is($dri->get_info('crID','account','S123456'),'TEST','domain_info get_info(crID,account,registrant->srid)'),
$d=$dri->get_info('crDate','account','S123456');
isa_ok($d,'DateTime','domain_info get_info(crDate,account,registrant->srid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,account,registrant->srid) value');
is($dri->get_info('upID','account','S123456'),'domains@isp.com','domain_info get_info(upID,account,registrant->srid)');
$d=$dri->get_info('upDate','account','S123456');
isa_ok($d,'DateTime','domain_info get_info(upDate,account,registrant->srid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,account,registrant->srid) value');

is($dri->get_info('clID'),'TEST','domain_info get_info(clID)');
is($dri->get_info('crID'),'TEST','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2007-12-03T09:00:00','domain_info get_info(exDate) value');

$R2='';
$rc=$dri->domain_delete('example.co.uk',{pure_delete=>1});
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name><domain:exDate>2007-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example.co.uk',{duration => DateTime::Duration->new(years=>2)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name><domain:period unit="y">2</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is(''.$d,'2007-04-03T22:00:00','domain_renew get_info(exDate) value');

$R2='';
$rc=$dri->domain_transfer_start('example.co.uk',{registrar_tag => 'TEST', account_id => '123456'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name><domain:registrar-tag>TEST</domain:registrar-tag><domain:account><domain:account-id>123456</domain:account-id></domain:account></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
is($rc->is_success(),1,'domain_transfer_request is_success');

## The domain is not really used for accept/refuse, nor even sent to registry, but must be there, whatever value it has as long as it is a domain name in the .UK registry
$R2='';
$rc=$dri->domain_transfer_accept('whatever.co.uk',{case_id => 10001});
is_string($R1,$E1.'<command><transfer op="approve"><n:rcCase xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:case-id>10001</n:case-id></n:rcCase></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept build');
is($rc->is_success(),1,'domain_transfer_accept is_success');

$R2='';
$rc=$dri->domain_transfer_refuse('whatever.co.uk',{case_id => 10001});
is_string($R1,$E1.'<command><transfer op="reject"><n:rcCase xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:case-id>10001</n:case-id></n:rcCase></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept build');
is($rc->is_success(),1,'domain_transfer_refuse is_success');



$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>whatever.co.uk</domain:name><domain:account><account:creData><account:roid>100029-UK</account:roid><account:name>Mr R. Strant</account:name><account:contact type="admin" order="1"><contact:creData><contact:roid>C100081-UK</contact:roid><contact:name>Mr R. Strant</contact:name></contact:creData></account:contact><account:contact type="billing" order="1"><contact:creData><contact:roid>C100082-UK</contact:roid><contact:name>A. Ccountant</contact:name></contact:creData></account:contact><account:contact type="admin" order="2"><contact:creData><contact:roid>C100083-UK</contact:roid><contact:name>Ms S. Strant</contact:name></contact:creData></account:contact></account:creData></domain:account><domain:crDate>2005-10-14T13:40:50</domain:crDate><domain:exDate>2007-10-14T13:40:50</domain:exDate></domain:creData></resData><extension><domain:warning xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd">YOU ARE WARNED !</domain:warning></extension>'.$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts');
$dh->add('ns0.whatever.co.uk',['1.2.3.4']);
$dh->add('ns3.example.net');
my $cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->name('Mr R. Strant');
$co->org('R. S. Industries');
$co->type('LTD');
$co->co_no('NI123456');
$co->opt_out('N');
$co->street(['2102 High Street','Carfax']);
$co->city('Oxford');
$co->sp('Oxfordshire');
$co->pc('OX1 1DF');
$co->cc('GB');
$cs->set($co,'registrant');
$co=$dri->local_object('contact');
$co->name('Mr R. Strant');
$co->voice('01865 123456');
$co->fax('01865 123456');
$co->email('r.strant@strant.co.uk');
$cs->set($co,'admin');
$co=$dri->local_object('contact');
$co->name('Ms S. Strant');
$co->voice('01865 123457');
$co->fax('01865 123456');
$co->email('s.strant@strant.co.uk');
$cs->add($co,'admin');
$co=$dri->local_object('contact');
$co->name('A. Ccountant');
$co->voice('01865 657893');
$co->email('acc@billing.co.uk');
$cs->set($co,'billing');
$rc=$dri->domain_create('whatever.co.uk',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dh,contact=>$cs,'recur-bill'=>'bc'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>whatever.co.uk</domain:name><domain:period unit="y">2</domain:period><domain:account><account:create xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1"><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>LTD</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr type="admin"><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact order="1" type="admin"><contact:create><contact:name>Mr R. Strant</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email></contact:create></account:contact><account:contact order="2" type="admin"><contact:create><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email></contact:create></account:contact><account:contact order="1" type="billing"><contact:create><contact:name>A. Ccountant</contact:name><contact:phone>01865 657893</contact:phone><contact:email>acc@billing.co.uk</contact:email></contact:create></account:contact></account:create></domain:account><domain:ns><domain:host><domain:hostName>ns0.whatever.co.uk</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr></domain:host><domain:host><domain:hostName>ns3.example.net</domain:hostName></domain:host></domain:ns><domain:recur-bill>bc</domain:recur-bill></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build with new account');
is($rc->is_success(),1,'domain_create is_success');
$cs=$dri->get_info('contact');
isa_ok($cs,'Net::DRI::Data::ContactSet');
is_deeply([$cs->types()],['admin','billing','registrant'],'get_info(contact) has 3 types');
$co=$cs->get('registrant');
isa_ok($co,'Net::DRI::Data::Contact::Nominet');
is($co->srid(),'100029-UK','get_info(contact) registrant srid');
is($co->name(),'Mr R. Strant','get_info(contact) registrant name');
my @co=$cs->get('admin');
is(scalar(@co),2,'get_info(contact) admin count');
isa_ok($co[0],'Net::DRI::Data::Contact::Nominet');
is($co[0]->srid(),'C100081-UK','get_info(contact) admin1 srid');
is($co[0]->name(),'Mr R. Strant','get_info(contact) admin1 name');
isa_ok($co[1],'Net::DRI::Data::Contact::Nominet');
is($co[1]->srid(),'C100083-UK','get_info(contact) admin2 srid');
is($co[1]->name(),'Ms S. Strant','get_info(contact) admin2 name');
$co=$cs->get('billing');
isa_ok($co,'Net::DRI::Data::Contact::Nominet');
is($co->srid(),'C100082-UK','get_info(contact) billing srid');
is($co->name(),'A. Ccountant','get_info(contact) billing name');

is($dri->get_info('exist','contact','C100082-UK'),1,'get_info(exist,contact,C100082-UK)');
is($dri->get_info('roid','contact','C100082-UK'),'C100082-UK','get_info(roid,contact,C100082-UK)');
my $co2=$dri->get_info('self','contact','C100082-UK');
is_deeply($co2,$co,'get_info(self,contact,C100082-UK');

$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is($d.'','2005-10-14T13:40:50','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is($d.'','2007-10-14T13:40:50','domain_create get_info(exDate) value');

is($dri->get_info('warning'),'YOU ARE WARNED !','domain_create get_info(warning)');


my $toc=$dri->local_object('changes');
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->srid(1);  ## just make it any true value to make sure it is a contact:update and not a contact:create ; the value itself is not used during account:update anyway
$co->email('admin@strant.co.uk');
$cs->set($co,'admin');
$toc->set('contact',$cs);
$dh=$dri->local_object('hosts');
$dh->add('ns2.example1.co.uk');
$toc->set('ns',$dh);
$toc->set('auto-bill','');
$toc->set('next-bill',5);
$rc=$dri->domain_update('whatever.co.uk',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>whatever.co.uk</domain:name><domain:account><account:update xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1"><account:contact order="1" type="admin"><contact:update><contact:email>admin@strant.co.uk</contact:email></contact:update></account:contact></account:update></domain:account><domain:ns><domain:host><domain:hostName>ns2.example1.co.uk</domain:hostName></domain:host></domain:ns><domain:auto-bill/><domain:next-bill>5</domain:next-bill></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update_build');
is($rc->is_success(),1,'domain_update is_success');


$dri->cache_clear(); ## this is needed to make sure that calls below to host_info & contact_info do in fact do the query and not take results from cache

##################################################################################################################
## Host commands

$R2=$E1.'<response>'.r().'<resData><ns:infData xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.1 nom-ns-1.1.xsd"><ns:roid>NS12345</ns:roid><ns:name>ns1.example.co.uk</ns:name><ns:addr ip="v4">10.10.10.10</ns:addr><ns:clID>TEST</ns:clID><ns:crID>TEST</ns:crID><ns:crDate>1999-04-03T22:00:00.0Z</ns:crDate><ns:upID>TEST</ns:upID><ns:upDate>1999-12-03T09:00:00.0Z</ns:upDate></ns:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('NS12345');
is_string($R1,$E1.'<command><info><ns:info xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.1 nom-ns-1.1.xsd"><ns:roid>NS12345</ns:roid></ns:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('action'),'info','host_info get_info(action)');
is($dri->get_info('exist'),1,'host_info get_info(exist)');
is($dri->get_info('roid'),'NS12345','host_info get_info(roid)');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','host_info get_info(self)');
my ($name,$ip4,$ip6,$rextra)=$s->get_details(1);
is($name,'ns1.example.co.uk','host_info self name');
isa_ok($rextra,'HASH','host_info self extra info');
is($rextra->{roid},'NS12345','host_info self roid');
is_deeply($ip4,['10.10.10.10'],'host_info self ip4');
is($dri->get_info('clID'),'TEST','host_info get_info(clID)');
is($dri->get_info('crID'),'TEST','host_info get_info(crID)');
is($dri->get_info('upID'),'TEST','host_info get_info(upID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_info get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','host_info get_info(upDate)');
is($d.'','1999-12-03T09:00:00','host_info get_info(upDate) value');

$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$toc->set('name','ns0.example2.co.uk');
$rc=$dri->host_update('NS1001',$toc);
is_string($R1,$E1.'<command><update><ns:update xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.1 nom-ns-1.1.xsd"><ns:roid>NS1001</ns:roid><ns:name>ns0.example2.co.uk</ns:name></ns:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

#########################################################################################################
## Contact commands

$co=$dri->local_object('contact');
isa_ok($co,'Net::DRI::Data::Contact::Nominet','contact');
$co->srid('T1');
is($co->roid(),'T1','contact roid = srid');
$co->roid('T2');
is($co->srid(),'T2','contact srid = roid');

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.1 nom-contact-1.1.xsd"><contact:roid>C12345</contact:roid><contact:name>Mr Contact</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>TEST</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>TEST</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('C12345');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.1 nom-contact-1.1.xsd"><contact:roid>C12345</contact:roid></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'C12345','contact_info get_info(self) srid');
is($co->roid(),'C12345','contact_info get_info(self) roid');
is($co->name(),'Mr Contact','contact_info get_info(self) name');
is($co->voice(),'01865 123456','contact_info get_info(self) voice');
is($co->fax(),'01865 123456','contact_info get_info(self) fax');
is($co->email(),'r.strant@strant.co.uk','contact_info get_info(self) email');
is($dri->get_info('clID'),'TEST','contact_info get_info(clID)');
is($dri->get_info('crID'),'TEST','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'TEST','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');

$R2='';
$co=$dri->local_object('contact')->srid('C11001');
$toc=$dri->local_object('changes');
$co->fax('');
$co->email('contact@example.co.uk');
$toc->set('info',$co);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.1 nom-contact-1.1.xsd"><contact:roid>C11001</contact:roid><contact:fax/><contact:email>contact@example.co.uk</contact:email></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

####################################################################################################
## Account

$R2=$E1.'<response>'.r().'<resData><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>S123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="admin" order="2"><contact:infData><contact:roid>C23456</contact:roid><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="billing" order="1"><contact:infData><contact:roid>C12347</contact:roid><contact:name>A. Ccountant</contact:name><contact:phone>01865 657893</contact:phone><contact:email>acc@billing.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->account_info('S123456');
is_string($R1,$E1.'<command><info><account:info xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>S123456</account:roid></account:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'account_info build');
is($rc->is_success(),1,'account_info is_success');
is($dri->get_info('action'),'info','account_info get_info(action)');
is($dri->get_info('exist'),1,'account_info get_info(exist)');
is($dri->get_info('roid'),'S123456','account_info get_info(roid)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::ContactSet','account_info get_info(self)');
is_deeply([$co->types()],[qw/admin billing registrant/],'account_info get_info(self) types');
$d=$co->get('registrant');
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(registrant)');
is($d->roid(),'S123456','account_info get_info(self) get(registrant) roid');
is($d->name(),'Mr R. Strant','account_info get_info(self) get(registrant) name');
is($d->org(),'R. S. Industries','account_info get_info(self) get(registrant) org/trad-name');
is($d->type(),'STRA','account_info get_info(self) get(registrant) type');
is($d->co_no(),'NI123456','account_info get_info(self) get(registrant) co_no');
is($d->opt_out(),'N','account_info get_info(self) get(registrant) opt_out');
is_deeply(scalar $d->street(),['2102 High Street','Carfax'],'account_info get_info(self) get(registrant) street');
is($d->city(),'Oxford','account_info get_info(self) get(registrant) city');
is($d->sp(),'Oxfordshire','account_info get_info(self) get(registrant) sp/county');
is($d->pc(),'OX1 1DF','account_info get_info(self) get(registrant) pc/postcode');
is($d->cc(),'GB','account_info get_info(self) get(registrant) country');

$d=($co->get('admin'))[0];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(admin1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin1->roid)');
is($d->roid(),'C12345','account_info get_info(self) get(admin1) roid');
is($d->name(),'Mr R.Strant','account_info get_info(self) get(admin1) name');
is($d->voice(),'01865 123456','account_info get_info(self) get(admin1) voice');
is($d->fax(),'01865 123456','account_info get_info(self) get(admin1) fax');
is($d->email(),'r.strant@strant.co.uk','account_info get_info(self) get(admin1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,admin1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,admin1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,admin1->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,admin1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,admin1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,admin1->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,admin1->roid) value');

$d=($co->get('admin'))[1];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(admin2)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin2->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin2->roid)');
is($d->roid(),'C23456','account_info get_info(self) get(admin2) roid');
is($d->name(),'Ms S. Strant','account_info get_info(self) get(admin2) name');
is($d->voice(),'01865 123457','account_info get_info(self) get(admin2) voice');
is($d->fax(),'01865 123456','account_info get_info(self) get(admin2) fax');
is($d->email(),'s.strant@strant.co.uk','account_info get_info(self) get(admin2) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,admin2->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,admin2->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,admin2->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,admin2->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,admin2->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,admin2->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,admin2->roid) value');

$d=($co->get('billing'))[0];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(billing1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,billing1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,billing1->roid)');
is($d->roid(),'C12347','account_info get_info(self) get(billing1) roid');
is($d->name(),'A. Ccountant','account_info get_info(self) get(billing1) name');
is($d->voice(),'01865 657893','account_info get_info(self) get(billing1) voice');
is($d->email(),'acc@billing.co.uk','account_info get_info(self) get(billing1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,billing1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,billing1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,billing1->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,billing1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,billing1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,billing1->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,billing1->roid) value');

is($dri->get_info('clID'),'TEST','account_info get_info(clID)');
is($dri->get_info('crID'),'TEST','account_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','account_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate) value');



$toc=$dri->local_object('changes');
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->org('R. S. Industries');
$co->type('STRA');
$co->co_no('NI123456');
$cs->set($co,'registrant');
$co=$dri->local_object('contact');
$cs->add($co,'registrant'); ## second empty slot is for the billing addr
$co=$dri->local_object('contact');
$co->name('Ms S. Strant');
$co->voice('01865 123457');
$co->fax('01865 123456');
$co->email('s.strant@strant.co.uk');
$cs->set($co,'admin');
$co=$dri->local_object('contact');
$cs->set($co,'billing');
$co=$dri->local_object('contact');
$co->srid(1);  ## just make it any true value to make sure it is a contact:update and not a contact:create ; the value itself is not used during account:update anyway
$co->voice('01865 232564');
$cs->add($co,'admin');
$toc->set('contact',$cs);
$rc=$dri->account_update('286467',$toc);
is_string($R1,$E1.'<command><update><account:update xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>286467</account:roid><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:addr type="billing"/><account:contact order="1" type="admin"><contact:create><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email></contact:create></account:contact><account:contact order="2" type="admin"><contact:update><contact:phone>01865 232564</contact:phone></contact:update></account:contact><account:contact order="1" type="billing"/></account:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'account_update build');


$R2=$E1.'<response>'.r().'<resData><account:creData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>100029-UK</account:roid><account:name>Mr R. Strant</account:name><account:contact type="admin" order="1"><contact:creData xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.1 nom-contact-1.1.xsd"><contact:roid>C100081-UK</contact:roid><contact:name>Mr R. Strant</contact:name></contact:creData></account:contact><account:crDate>2008-01-12T15:00:12</account:crDate></account:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->account_fork('567867845',{domains=>[qw/example1.co.uk example2.co.uk example3.co.uk/]});
is_string($R1,$E1.'<command><update><account:fork xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>567867845</account:roid><account:domain-name>example1.co.uk</account:domain-name><account:domain-name>example2.co.uk</account:domain-name><account:domain-name>example3.co.uk</account:domain-name></account:fork></update><clTRID>ABC-12345</clTRID></command>'.$E2,'account_fork build');
is($rc->is_success(),1,'account_fork is_success');
is($dri->get_info('fork_to'),'100029-UK','account_fork get_info(fork_to)');
is($dri->get_info('action','account','100029-UK'),'fork','account_fork get_info(action)');
is($dri->get_info('exist','account','100029-UK'),1,'account_fork get_info(exist)');
$co=$dri->get_info('self','account','100029-UK');
isa_ok($co,'Net::DRI::Data::ContactSet','account_fork get_info(self)');
is_deeply([$co->types()],[qw/admin registrant/],'account_fork get_info(self) types');
$d=$co->get('registrant');
isa_ok($d,'Net::DRI::Data::Contact','account_fork get_info(self) get(registrant)');
is($d->roid(),'100029-UK','account_fork get_info(self) get(registrant) roid');
is($d->name(),'Mr R. Strant','account_fork get_info(self) get(registrant) name');
$d=($co->get('admin'))[0];
isa_ok($d,'Net::DRI::Data::Contact','account_fork get_info(self) get(admin1)');
is($d->roid(),'C100081-UK','account_fork get_info(self) get(admin1) roid');
is($d->name(),'Mr R. Strant','account_fork get_info(self) get(admin1) name');


$rc=$dri->account_merge('567867845',{roid_source=>[qw/99999/],names=>['Company X Ltd'],domains=>[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk/]});
is_string($R1,$E1.'<command><update><account:merge xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>567867845</account:roid><account:roid source="y">99999</account:roid><account:name>Company X Ltd</account:name><account:domain-name>epp-example1.co.uk</account:domain-name><account:domain-name>epp-example2.co.uk</account:domain-name><account:domain-name>epp-example3.co.uk</account:domain-name></account:merge></update><clTRID>ABC-12345</clTRID></command>'.$E2,'account_merge build');


####################################################################################################
## Notifications

## http://www.nominet.org.uk/registrars/systems/epp/referralreject/
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Referral Rejected Notification</msg></msgQ><resData><domain:failData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>epp-example2.ltd.uk</domain:name><domain:reason>V205 Registrant does not match domain name</domain:reason></domain:failData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),12345,'message get_info last_id 2');
is($dri->get_info('id','message',12345),12345,'message get_info id');
is(''.$dri->get_info('qdate','message',12345),'2007-09-26T07:31:30','message get_info qdate');
is($dri->get_info('content','message',12345),'Referral Rejected Notification','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('object_type','message','12345'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','12345'),'epp-example2.ltd.uk','message get_info id');
is($dri->get_info('action','message','12345'),'fail','message get_info action'); ## with this, we know what action has triggered this delayed message
is($dri->get_info('exist','domain','epp-example2.ltd.uk'),0,'message get_info(exist,domain,DOM)');
is($dri->get_info('fail_reason','domain','epp-example2.ltd.uk'),'V205 Registrant does not match domain name','message get_info(reason,domain,DOM)');

## http://www.nominet.org.uk/registrars/systems/epp/registrarchange/
## We only do a very simple parse
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2005-10-06T10:29:30Z</qDate><msg>Registrar Change Notification</msg></msgQ><resData><n:rcData xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:orig>p@automaton-example.org.uk</n:orig><n:registrar-tag>EXAMPLE</n:registrar-tag></n:rcData><domain:listData no-domains="2" xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:simpleInfData><domain:name>auto-example1.co.uk</domain:name><domain:reg-status>Registered until expiry date</domain:reg-status><domain:ns xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1"><ns:infData><ns:roid>NS1015-UK</ns:roid><ns:name>epp-example1.co.uk</ns:name><ns:clID>EXAMPLE-TAG</ns:clID></ns:infData></domain:ns><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example.co.uk</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:simpleInfData><domain:simpleInfData><domain:name>epp-example2.co.uk</domain:name><domain:reg-status>Renewal required</domain:reg-status><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example2.co.uk</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:simpleInfData></domain:listData><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1"><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:voice>01865 123456</contact:voice><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),123456,'message get_info(last_id) 2');
is($dri->get_info('action','message',123456),'registrar_change','message get_info(action)');
is($dri->get_info('orig','message',123456),'p@automaton-example.org.uk','message get_info(orig)');
is($dri->get_info('registrar_to','message',123456),'EXAMPLE','message get_info(registrar_to)');
is_deeply($dri->get_info('domains','message',123456),[qw/auto-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

## http://www.nominet.org.uk/registrars/systems/epp/registrantchange/
## We only do a very simple parse
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2007-10-06T10:29:30Z</qDate><msg>Registrant Transfer Notification</msg></msgQ><resData><n:trnData xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:orig>p@automaton-example.org.uk</n:orig><n:account-id>58658458</n:account-id><n:old-account-id>596859</n:old-account-id></n:trnData><domain:domainList no_domains="2" xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:simpleInfData><domain:name>epp-example1.co.uk</domain:name><domain:reg-status>Registered until expiry date</domain:reg-status><domain:ns xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1"><ns:infData><ns:roid>NS1015-UK</ns:roid><ns:name>ns1.epp-example1.co.uk</ns:name><ns:clID>EXAMPLE-TAG</ns:clID></ns:infData></domain:ns><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example.co.uk</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:simpleInfData><domain:simpleInfData><domain:name>epp-example2.co.uk</domain:name><domain:reg-status>Renewal required</domain:reg-status><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example.co.uk</domain:crID><domain:crDate>2005-06-03T12:45:34</domain:crDate><domain:exDate>2007-06-02T12:45:34</domain:exDate></domain:simpleInfData></domain:domainList><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.1"><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:voice>01865 123456</contact:voice><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),123456,'message get_info(last_id) 3');
is($dri->get_info('action','message',123456),'registrant_change','message get_info(action)');
is($dri->get_info('account_from','message',123456),'596859','message get_info(account_from)');
is($dri->get_info('account_to','message',123456),'58658458','message get_info(account_to)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

## http://www.nominet.org.uk/registrars/systems/epp/domaincancelled/
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123456"><qDate>2007-09-26T07:31:30</qDate><msg>Domain name Cancellation Notification</msg></msgQ><resData><n:cancData xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:domain-name>epp-example1.co.uk</n:domain-name><n:orig>example@nominet</n:orig></n:cancData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),123456,'message get_info(last_id) 4');
is($dri->get_info('object_type','message','123456'),'domain','message get_info(object_type)');
is($dri->get_info('object_id','message','123456'),'epp-example1.co.uk','message get_info(object_id)');
is($dri->get_info('action','domain','epp-example1.co.uk'),'cancelled','message get_info(action)');
is($dri->get_info('cancelled_orig','domain','epp-example1.co.uk'),'example@nominet','message get_info(cancelled_orig)');

## http://www.nominet.org.uk/registrars/systems/epp/handshakerequest/
## We only do a very simple parse
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Registrar Change Authorisation Request</msg></msgQ><resData><n:rcData xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:orig>p@epp-example.org.uk</n:orig><n:registrar-tag>EXAMPLE</n:registrar-tag><n:case-id>3560</n:case-id></n:rcData><domain:listData no-domains="2" xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:simpleInfData><domain:name>epp-example1.co.uk</domain:name><domain:reg-status>Registered until expiry date</domain:reg-status><domain:ns xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.1"><ns:infData><ns:roid>NS1015-UK</ns:roid><ns:name>automaton-example1.co.uk</ns:name><ns:clID>EXAMPLE-TAG</ns:clID></ns:infData></domain:ns><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example.co.uk</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:simpleInfData><domain:simpleInfData><domain:name>epp-example2.co.uk</domain:name><domain:reg-status>Renewal required</domain:reg-status><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-example2.co.uk</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:simpleInfData></domain:listData><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.1 nom-account-1.1.xsd"><account:roid>123456</account:roid><account:name>T. Example</account:name><account:trad-name>Example Inc</account:trad-name><account:type>STRA</account:type><account:co-no>57846548</account:co-no><account:opt-out>N</account:opt-out><account:addr type="admin"><account:street>10 High Street</account:street><account:locality>Little Rising</account:locality><account:city>Birmingham</account:city><account:county>West Midlands</account:county><account:postcode>B1 5AA</account:postcode><account:country>GB</account:country></account:addr></account:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info(last_id) 5');
is($dri->get_info('action','message',12345),'handshake_request','message get_info(action)');
is($dri->get_info('orig','message',12345),'p@epp-example.org.uk','message get_info(orig)');
is($dri->get_info('registrar_to','message',12345),'EXAMPLE','message get_info(registrar_to)');
is($dri->get_info('case_id','message',12345),'3560','message get_info(case_id)');
is_deeply($dri->get_info('domains','message',12345),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

## http://www.nominet.org.uk/registrars/systems/epp/poorqualitydata/
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123456"><qDate>2007-10-06T10:29:30Z</qDate><msg>Poor Quality Data Notification</msg></msgQ><resData><n:pqData stage="initial" xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><account:roid>589695</account:roid><account:name>E. Example</account:name><account:addr type="admin"><account:street>n/a</account:street><account:city>n/a</account:city><account:postcode>N1 1NA</account:postcode><account:country>GB</account:country></account:addr><n:suspend-date>2007-10-26T00:00:00</n:suspend-date><n:cancel-date>2007-11-25T00:00:00</n:cancel-date></n:pqData><domain:listData no-domains="6" xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>epp-example1.co.uk</domain:name><domain:name>epp-example2.co.uk</domain:name><domain:name>epp-example3.co.uk</domain:name><domain:name>epp-example4.co.uk</domain:name><domain:name>epp-example5.co.uk</domain:name><domain:name>epp-example6.co.uk</domain:name></domain:listData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),123456,'message get_info(last_id) 6');
is($dri->get_info('action','message',123456),'poor_quality','message get_info(action)');
is($dri->get_info('poor_quality_stage','message',123456),'initial','message get_info(poor_quality_stage)');
$co=$dri->get_info('poor_quality_account','message',123456);
isa_ok($co,'Net::DRI::Data::Contact','message get_info(poor_quality_account)');
is($co->roid(),'589695','account roid');
is($co->name(),'E. Example','account name');
is_deeply(scalar $co->street(),['n/a'],'account street');
is($co->city(),'n/a','account city');
is($co->pc(),'N1 1NA','account pc');
is($co->cc(),'GB','account cc');
is(''.$dri->get_info('poor_quality_suspend','message',123456),'2007-10-26T00:00:00','message get_info(poor_quality_suspend)');
is(''.$dri->get_info('poor_quality_cancel','message',123456),'2007-11-25T00:00:00','message get_info(poor_quality_cancel)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk epp-example4.co.uk epp-example5.co.uk epp-example6.co.uk/],'message get_info(domains)');

## http://www.nominet.org.uk/registrars/systems/epp/domainsreleased/
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Domains Released Notification</msg></msgQ><resData><n:relData xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.2 nom-notifications-1.2.xsd"><n:account-id moved="Y">12345</n:account-id><n:from>EXAMPLE1-TAG</n:from><n:registrar-tag>EXAMPLE2-TAG</n:registrar-tag></n:relData><domain:listData no-domains="6" xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>epp-example1.co.uk</domain:name><domain:name>epp-example2.co.uk</domain:name><domain:name>epp-example3.co.uk</domain:name><domain:name>epp-example4.co.uk</domain:name><domain:name>epp-example5.co.uk</domain:name><domain:name>epp-example6.co.uk</domain:name></domain:listData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info(last_id) 6');
is($dri->get_info('action','message',12345),'domains_released','message get_info(action)');
is($dri->get_info('account_id','message',12345),'12345','message get_info(account_id)');
is($dri->get_info('account_moved','message',12345),1,'message get_info(account_moved)');
is($dri->get_info('registrar_from','message',12345),'EXAMPLE1-TAG','message get_info(registrar_from)');
is($dri->get_info('registrar_to','message',12345),'EXAMPLE2-TAG','message get_info(registrar_to)');
is_deeply($dri->get_info('domains','message',12345),[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk epp-example4.co.uk epp-example5.co.uk epp-example6.co.uk/],'message get_info(domains)');

## http://www.nominet.org.uk/registrars/systems/nominetepp/Unrenew/
$rc=$dri->domain_unrenew('example.co.uk');
is_string($R1,$E1.'<command><update><domain:unrenew xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>example.co.uk</domain:name></domain:unrenew></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_unrenew build');

$R2=$E1.'<response>'.r().'<resData><domain:listData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:name>epp-example1.co.uk</domain:name><domain:name>epp-example2.co.uk</domain:name><domain:name>epp-example3.co.uk</domain:name><domain:name>epp-example4.co.uk</domain:name><domain:name>epp-example5.co.uk</domain:name><domain:name>epp-example6.co.uk</domain:name></domain:listData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->account_list_domains({registration=>DateTime->new({year=>2008,month=>12})});
is_string($R1,$E1.'<command><info><domain:list xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-2.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-2.0 nom-domain-2.0.xsd"><domain:month>2008-12</domain:month><domain:fields>none</domain:fields></domain:list></info><clTRID>ABC-12345</clTRID></command>'.$E2,'account_list_domains build'); 
is_deeply($rc->get_data('account','domains','list'),[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk epp-example4.co.uk epp-example5.co.uk epp-example6.co.uk/],'account_list_domains get_data(account,domains,list)');

exit 0;
