#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::EPP::Connection;
use DateTime;
use DateTime::Duration;

use Encode ();
use Test::More tests => 113;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=substr(Net::DRI::Protocol::EPP::Connection->write_message(undef,$msg),4); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CAT');
$dri->target('CAT')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co);

####################################################################################################
## Contacts

## p.31

$co=$dri->local_object('contact')->srid('sh8013');
$co->name('John Doe');
$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.com');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
$co->lang('ca');
$co->maintainer('MyDomains.cat');
$co->email_sponsor('catsponsor@example.com');
$rc=$dri->contact_create($co);
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><cx:create xmlns:cx="http://xmlns.domini.cat/epp/contact-ext-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/contact-ext-1.0 puntcat-contact-ext-1.0.xsd"><cx:language>ca</cx:language><cx:maintainer>MyDomains.cat</cx:maintainer><cx:sponsorEmail>catsponsor@example.com</cx:sponsorEmail></cx:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');

##p.33
$R2='';
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
my $toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
my $co2=$dri->local_object('contact');
$co2->org('');
$co2->street(['124 Example Dr.','Suite 200']);
$co2->city('Dulles');
$co2->sp('VA');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+1.7034444444');
$co2->fax('');
$co2->auth({pw=>'2fooBAR'});
$co2->disclose({voice=>1,email=>1});
$co2->lang('ca');
$co2->maintainer('MyDomains.cat');
$co2->email_sponsor('catsponsor@example.com');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);

is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="loc"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><extension><cx:update xmlns:cx="http://xmlns.domini.cat/epp/contact-ext-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/contact-ext-1.0 puntcat-contact-ext-1.0.xsd"><cx:chg><cx:language>ca</cx:language><cx:maintainer>MyDomains.cat</cx:maintainer><cx:sponsorEmail>catsponsor@example.com</cx:sponsorEmail></cx:chg></cx:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');

##p.35

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>R-123</contact:clID><contact:crID>R-123</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>R-123</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><cx:infData xmlns:cx="http://xmlns.domini.cat/epp/contact-ext-1.0"><cx:language>ca</cx:language><cx:maintainer>myDomains.cat</cx:maintainer><cx:sponsorEmail>catsponsor@example.com</cx:sponsorEmail></cx:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact::CAT','contact_info get_info(self)');
is($co->srid(),'sh8013','contact_info get_info(self) srid');
is($co->roid(),'SH8013-REP','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited','linked'],'contact_info get_info(status) list_status');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'John Doe','contact_info get_info(self) name');
is($co->org(),'Example Inc.','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['123 Example Dr.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Dulles','contact_info get_info(self) city');
is($co->sp(),'VA','contact_info get_info(self) sp');
is($co->pc(),'20166-6503','contact_info get_info(self) pc');
is($co->cc(),'US','contact_info get_info(self) cc');
is($co->voice(),'+1.7035555555x1234','contact_info get_info(self) voice');
is($co->fax(),'+1.7035555556','contact_info get_info(self) fax');
is($co->email(),'jdoe@example.com','contact_info get_info(self) email');
is($dri->get_info('clID'),'R-123','contact_info get_info(clID)');
is($dri->get_info('crID'),'R-123','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'R-123','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','contact_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','contact_info get_info(trDate) value');
is_deeply($co->auth(),{pw=>'2fooBAR'},'contact_info get_info(self) auth');
is_deeply($co->disclose(),{voice=>0,email=>0},'contact_info get_info(self) disclose');
is($co->lang(),'ca','contact_info get_info(self) lang');
is($co->maintainer(),'myDomains.cat','contact_info get_info(self) maintainer');
is($co->email_sponsor(),'catsponsor@example.com','contact_info get_info(self) email_sponsor');

####################################################################################################
## Domains

##p.48
$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$cs->set($c2,'billing');
$rc=$dri->domain_create('barca.cat',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},name_variant=>['barcà.cat','xn--bara-2oa.cat'],lang=>'ca',maintainer=>'myDomains.cat',ens=>{sponsor=>['sponsor1@example.com','sponsor2@example.net','sponsor3@example.org'],intended_use=>'Website dedicated about sailing around Barcelona'},registrant_disclosure=>{type=>'natural',disclose=>0}});
is_string($R1,Encode::encode('utf8',$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>barca.cat</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><dx:create xmlns:dx="http://xmlns.domini.cat/epp/domain-ext-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/domain-ext-1.0 puntcat-domain-ext-1.0.xsd"><dx:nameVariant>barcà.cat</dx:nameVariant><dx:nameVariant>xn--bara-2oa.cat</dx:nameVariant><dx:language>ca</dx:language><dx:maintainer>myDomains.cat</dx:maintainer><dx:ens><dx:sponsoring><dx:sponsor>sponsor1@example.com</dx:sponsor><dx:sponsor>sponsor2@example.net</dx:sponsor><dx:sponsor>sponsor3@example.org</dx:sponsor></dx:sponsoring><dx:intendedUse>Website dedicated about sailing around Barcelona</dx:intendedUse></dx:ens><dx:disclosure><dx:natural disclose="false"/></dx:disclosure></dx:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2),'domain_create build registrant_disclosure.type=natural');

$rc=$dri->domain_create('barca.cat',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},name_variant=>['barcà.cat','xn--bara-2oa.cat'],lang=>'ca',maintainer=>'myDomains.cat',ens=>{sponsor=>['sponsor1@example.com','sponsor2@example.net','sponsor3@example.org'],intended_use=>'Website dedicated about sailing around Barcelona'},registrant_disclosure=>{type=>'legal'}});
is_string($R1,Encode::encode('utf8',$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>barca.cat</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><dx:create xmlns:dx="http://xmlns.domini.cat/epp/domain-ext-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/domain-ext-1.0 puntcat-domain-ext-1.0.xsd"><dx:nameVariant>barcà.cat</dx:nameVariant><dx:nameVariant>xn--bara-2oa.cat</dx:nameVariant><dx:language>ca</dx:language><dx:maintainer>myDomains.cat</dx:maintainer><dx:ens><dx:sponsoring><dx:sponsor>sponsor1@example.com</dx:sponsor><dx:sponsor>sponsor2@example.net</dx:sponsor><dx:sponsor>sponsor3@example.org</dx:sponsor></dx:sponsoring><dx:intendedUse>Website dedicated about sailing around Barcelona</dx:intendedUse></dx:ens><dx:disclosure><dx:legal/></dx:disclosure></dx:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2),'domain_create build registrant_disclosure.type=legal');



##p.51
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns2.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mak21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('publish','Payment overdue.'));
$toc->del('ns',$dri->local_object('hosts')->set('ns1.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('sh8013'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('update'));
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('auth',{pw=>'2BARfoo'});
$toc->add('name_variant',['bàrca.cat']);
$toc->del('name_variant',['barça.cat']);
$toc->set('maintainer','ACME Domains, Inc.');
$toc->set('registrant_disclosure',{type=>'natural',disclose=>1});
$rc=$dri->domain_update('barca.cat',$toc);
is_string($R1,Encode::encode('utf8',$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>barca.cat</domain:name><domain:add><domain:ns><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:contact type="tech">mak21</domain:contact><domain:status lang="en" s="clientHold">Payment overdue.</domain:status></domain:add><domain:rem><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:contact type="tech">sh8013</domain:contact><domain:status s="clientUpdateProhibited"/></domain:rem><domain:chg><domain:registrant>sh8013</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><dx:update xmlns:dx="http://xmlns.domini.cat/epp/domain-ext-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/domain-ext-1.0 puntcat-domain-ext-1.0.xsd"><dx:add><dx:nameVariant>bàrca.cat</dx:nameVariant></dx:add><dx:rem><dx:nameVariant>barça.cat</dx:nameVariant></dx:rem><dx:chg><dx:maintainer>ACME Domains, Inc.</dx:maintainer><dx:disclosure><dx:natural disclose="true"/></dx:disclosure></dx:chg></dx:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2),'domain_update build');

##p.58
$R2=Encode::encode('utf8',$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>barca.cat</domain:name><domain:roid>BARCA-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.barca.cat</domain:host><domain:host>ns2.barca.cat</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2006-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>2006-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2007-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2006-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><dx:infData xmlns:dx="http://xmlns.domini.cat/epp/domain-ext-1.0"><dx:nameVariant>bàrca.cat</dx:nameVariant><dx:nameVariant>barça.cat</dx:nameVariant><dx:language>ca</dx:language><dx:ens><dx:sponsoring><dx:sponsor>sponsor1@example.com</dx:sponsor><dx:sponsor>sponsor2@example.net</dx:sponsor><dx:sponsor>sponsor3@example.org</dx:sponsor></dx:sponsoring><dx:registrationType>standard</dx:registrationType><dx:intendedUse>Website dedicated about sailing around Barcelona</dx:intendedUse></dx:ens><dx:disclosure><dx:natural disclose="false"/></dx:disclosure></dx:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2);
$rc=$dri->domain_info('barca.cat',{auth=>{pw=>'2fooBAR'}});
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'BARCA-REP','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'sh8013','domain_info get_info(contact) tech srid');
is($s->get('billing')->srid(),'sh8013','domain_info get_info(contact) billing srid');
$dh=$dri->get_info('subordinate_hosts');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(subordinate_hosts)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.barca.cat','ns2.barca.cat'],'domain_info get_info(host) get_names');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns1.example.net'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');
is($dri->get_info('crID'),'ClientY','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2006-04-03T22:00:00','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'ClientX','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2006-12-03T09:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2007-04-03T22:00:00','domain_info get_info(exDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','domain_info get_info(trDate)');
is("".$d,'2006-04-08T09:00:00','domain_info get_info(trDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
is_deeply($dri->get_info('name_variant'),['bàrca.cat','barça.cat'],'domain_info get_info(name_variant)');
is($dri->get_info('lang'),'ca','domain_info get_info(lang)');
is(ref($dri->get_info('ens')),'HASH','domain_info get_info(ens) HASH');
my %ens=%{$dri->get_info('ens')};
is_deeply($ens{sponsor},['sponsor1@example.com','sponsor2@example.net','sponsor3@example.org'],'domain_info get_info(ens) sponsor');
is($ens{registration_type},'standard','domain_info get_info(ens) registration_type');
is($ens{intended_use},'Website dedicated about sailing around Barcelona','domain_info get_info(ens) intended_use');
my %disclose=%{$dri->get_info('registrant_disclosure')};
is($disclose{'type'},'natural','domain_info get_info(registrant_disclosure) type');
is($disclose{'disclose'},0,'domain_info get_info(registrant_disclosure) disclose');

####################################################################################################

## Defensive Registration

# p.71
my $ro=$dri->remote_object('defreg');
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('C100004');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'billing');
$rc=$ro->create('test28-id',{duration=>DateTime::Duration->new(years=>2),pattern=>'coca-cola',contact=>$cs,auth=>{pw=>'123456'},maintainer=>'myDomains Inc',trademark=>{name=>'Coca Cola',issue_date=>DateTime->new(year=>1923,month=>12,day=>30),country=>'US',number=>12345}});
is_string($R1,$E1.'<command><create><defreg:create xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>test28-id</defreg:id><defreg:period unit="y">2</defreg:period><defreg:pattern>coca-cola</defreg:pattern><defreg:registrant>C100004</defreg:registrant><defreg:contact type="billing">C100004</defreg:contact><defreg:contact type="admin">C100004</defreg:contact><defreg:authInfo><defreg:pw>123456</defreg:pw></defreg:authInfo><defreg:maintainer>myDomains Inc</defreg:maintainer><defreg:trademark><defreg:name>Coca Cola</defreg:name><defreg:issueDate>1923-12-30</defreg:issueDate><defreg:country>US</defreg:country><defreg:number>12345</defreg:number></defreg:trademark></defreg:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_create build');

# p.73
$ro=$dri->remote_object('defreg','test18-id');
$toc=$dri->local_object('changes');
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('C100004'),'admin');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('update'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('C100005'),'admin');
$toc->del('contact',$cs);
$toc->set('registrant',$dri->local_object('contact')->srid('C39392'));
$toc->set('auth',{pw=>'1234567'});
$toc->set('maintainer','test');
$toc->set('trademark',{name=>'ACMED',issue_date=>DateTime->new(year=>2005,month=>12,day=>31),country=>'DE',number=>123456});
$rc=$ro->update($toc);
is_string($R1,$E1.'<command><update><defreg:update xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>test18-id</defreg:id><defreg:add><defreg:contact type="admin">C100004</defreg:contact><defreg:status s="clientUpdateProhibited"/></defreg:add><defreg:rem><defreg:contact type="admin">C100005</defreg:contact></defreg:rem><defreg:chg><defreg:registrant>C39392</defreg:registrant><defreg:authInfo><defreg:pw>1234567</defreg:pw></defreg:authInfo><defreg:maintainer>test</defreg:maintainer><defreg:trademark><defreg:name>ACMED</defreg:name><defreg:issueDate>2005-12-31</defreg:issueDate><defreg:country>DE</defreg:country><defreg:number>123456</defreg:number></defreg:trademark></defreg:chg></defreg:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_update build');

# p.74
$ro=$dri->remote_object('defreg','DR39533');
$rc=$ro->delete();
is_string($R1,$E1.'<command><delete><defreg:delete xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>DR39533</defreg:id></defreg:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_delete build');

# p.75
$ro=$dri->remote_object('defreg','DR38328');
$rc=$ro->renew({duration=>DateTime::Duration->new(years=>2),current_expiration=>DateTime->new(year=>2009,month=>01,day=>23)});
is_string($R1,$E1.'<command><renew><defreg:renew xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>DR38328</defreg:id><defreg:curExpDate>2009-01-23</defreg:curExpDate><defreg:period unit="y">2</defreg:period></defreg:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_renew build');

# p.76
$R2=$E1.'<response>'.r().'<resData><defreg:infData xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0"><defreg:id>A29483</defreg:id><defreg:roid>39483-A</defreg:roid><defreg:pattern>coca-cola</defreg:pattern><defreg:status s="serverUpdateProhibited"/><defreg:status s="serverDeleteProhibited"/><defreg:registrant>jd1234</defreg:registrant><defreg:contact type="admin">sh8013</defreg:contact><defreg:contact type="billing">sh8013</defreg:contact><defreg:authInfo><defreg:pw>2fooBAR</defreg:pw></defreg:authInfo><defreg:maintainer>myDomains.cat</defreg:maintainer><defreg:trademark><defreg:name>ACMED</defreg:name><defreg:issueDate>2005-12-31</defreg:issueDate><defreg:country>DE</defreg:country><defreg:number>123456</defreg:number></defreg:trademark><defreg:clID>R-123</defreg:clID><defreg:crID>R-123</defreg:crID><defreg:crDate>2006-04-03T22:00:00.0Z</defreg:crDate></defreg:infData></resData><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$ro=$dri->remote_object('defreg','A29483');
$rc=$ro->info({auth=>{pw=>'mySecret',roid=>'DR-5932'}});
is_string($R1,$E1.'<command><info><defreg:info xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>A29483</defreg:id><defreg:authInfo><defreg:pw roid="DR-5932">mySecret</defreg:pw></defreg:authInfo></defreg:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_info build');
is($rc->is_success(),1,'defreg_info is_success');
is($dri->get_info('action'),'info','defreg_info get_info(action)');
is($dri->get_info('exist'),1,'defreg_info get_info(exist)');
is($dri->get_info('id'),'A29483','defreg_info get_info(id)');
is($dri->get_info('roid'),'39483-A','defreg_info get_info(roid)');
is($dri->get_info('pattern'),'coca-cola','defreg_info get_info(pattern)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','defreg_info get_info(status)');
is_deeply([$s->list_status()],['serverDeleteProhibited','serverUpdateProhibited'],'defreg_info get_info(status) list');
is($s->can_update(),0,'defreg_info get_info(status) can_update');
is($s->can_delete(),0,'defreg_info get_info(status) can_delete');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','defreg_info get_info(contact)');
is_deeply([$s->types()],['admin','billing','registrant'],'defreg_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','defreg_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','defreg_info get_info(contact) admin srid');
is($s->get('billing')->srid(),'sh8013','defreg_info get_info(contact) billing srid');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'defreg_info get_info(auth)');
is($dri->get_info('maintainer'),'myDomains.cat','defreg_info get_info(maintainer)');
is(ref($dri->get_info('trademark')),'HASH','defreg_info get_info(trademark) HASH');
my %t=%{$dri->get_info('trademark')};
is_deeply([sort(keys(%t))],['country','issue_date','name','number'],'defreg_info get_info(trademark) KEYS');
is($t{name},'ACMED','defreg_info get_info(trademark) name');
is(''.$t{issue_date},'2005-12-31T00:00:00','defreg_info get_info(trademark) issue_date');
is($t{country},'DE','defreg_info get_info(trademark) country');
is($t{number},'123456','defreg_info get_info(trademark) number');
is($dri->get_info('clID'),'R-123','defreg_info get_info(clID)');
is($dri->get_info('crID'),'R-123','defreg_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','defreg_info get_info(crDate)');
is("".$d,'2006-04-03T22:00:00','defreg_info get_info(crDate) value');

# p.78
$R2=$E1.'<response>'.r().'<resData><defreg:chkData xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0"><defreg:cd><defreg:id avail="1">DR3958</defreg:id></defreg:cd><defreg:cd><defreg:id avail="0">DR3959</defreg:id><defreg:reason>In use</defreg:reason></defreg:cd><defreg:cd><defreg:id avail="0">REG-38245</defreg:id><defreg:reason>Reserved</defreg:reason></defreg:cd></defreg:chkData></resData><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$ro=$dri->remote_object('defreg');
$rc=$ro->check('DR3958','DR3959','REG-38245');
is_string($R1,$E1.'<command><check><defreg:check xmlns:defreg="http://xmlns.domini.cat/epp/defreg-1.0" xsi:schemaLocation="http://xmlns.domini.cat/epp/defreg-1.0 puntcat-defreg-1.0.xsd"><defreg:id>DR3958</defreg:id><defreg:id>DR3959</defreg:id><defreg:id>REG-38245</defreg:id></defreg:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'defreg_check build');
is($rc->is_success(),1,'defreg_check is_success');
is($dri->get_info('action','defreg','DR3958'),'check','defreg_check get_info(action)');
is($dri->get_info('exist','defreg','DR3958'),0,'defreg_check get_info(exist) 1');
is($dri->get_info('exist','defreg','DR3959'),1,'defreg_check get_info(exist) 2');
is($dri->get_info('exist_reason','defreg','DR3959'),'In use','defreg_check get_info(exist_reason) 1');
is($dri->get_info('exist','defreg','REG-38245'),1,'defreg_check get_info(exist) 3');
is($dri->get_info('exist_reason','defreg','REG-38245'),'Reserved','defreg_check get_info(exist_reason) 2');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
