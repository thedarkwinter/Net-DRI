#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 43;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('AfiliasGRS');
$dri->target('AfiliasGRS')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{AfiliasGRS}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP',{}],'AfiliasGRS - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

### Mandatory EPP Acceptance Test Criteria ###

#####################################################################################################
######## Contact Commands ########

## 2.3.1.1 - Check Contact OTE-C1 (Contact Available)
$R2='';
my $c1=$dri->local_object('contact')->srid('OTE-C1');
$rc=$dri->contact_check($c1);
is($rc->is_success(),1,'contact_check contact_available is_success (2.3.1.1)');

## 2.3.1.2 - Create Contact OTE-C1
$R2='';
$c=$dri->local_object('contact');
$c->srid('OTE-C1');
$c->name('John Doe');
$c->org('Example Corp. Inc');
$c->street(['123 Example St.','Suite 100']);
$c->city('Anytown');
$c->pc('A1A1A1');
$c->sp('Any Prov');
$c->cc('CA');
$c->voice('+1.4165555555x1111');
$c->fax('+1.4165555556');
$c->email('jdoe@test.test');
$c->auth({pw => 'my secret'});
$rc=$dri->contact_create($c);
is($rc->is_success(),1,'contact_create [OTE-C1] is_success (2.3.1.2)');

## 2.3.1.3 - Check Contact (Contact Not Available)
$R2='';
$c1=$dri->local_object('contact')->srid('OTE-C1');
$rc=$dri->contact_check($c1);
is($rc->is_success(),1,'contact_check contact_not_available is_success (2.3.1.3)');

## 2.3.1.4 - Query Contact OTE-C1
$R2='';
$co=$dri->local_object('contact')->srid('OTE-C1');
$rc=$dri->contact_info($co);
is($rc->is_success(),1,'contact_info query_contact is_success (2.3.1.4)');

## 2.3.1.5 - Check Contact OTE-C2 (Contact Available)
$R2='';
$c1=$dri->local_object('contact')->srid('OTE-C2');
$rc=$dri->contact_check($c1);
is($rc->is_success(),1,'contact_check contact_available is_success (2.3.1.5)');

## 2.3.1.6 - Create Contact OTE-C2
$R2='';
my $c2=$dri->local_object('contact');
$c2->srid('OTE-C2');
$c2->name('John Doe');
$c2->org('Example Corp. Inc');
$c2->street(['123 Example St.','Suite 100']);
$c2->city('Anytown');
$c2->pc('A1A1A1');
$c2->sp('Any Prov');
$c2->cc('CA');
$c2->voice('+1.4165555555x1111');
$c2->fax('+1.4165555556');
$c2->email('jdoe@test.test');
$c2->auth({pw => 'my secret'});
$rc=$dri->contact_create($c2);
is($rc->is_success(),1,'contact_create [OTE-C2] is_success (2.3.1.6)');

## 2.3.1.7 - Check Contact OTE-C3 (Contact Available)
$R2='';
$c1=$dri->local_object('contact')->srid('OTE-C3');
$rc=$dri->contact_check($c1);
is($rc->is_success(),1,'contact_check contact_available is_success (2.3.1.7)');

## 2.3.1.8 - Create Contact OTE-C3
$R2='';
my $c3=$dri->local_object('contact');
$c3->srid('OTE-C3');
$c3->name('John Doe');
$c3->org('Example Corp. Inc');
$c3->street(['123 Example St.','Suite 100']);
$c3->city('Anytown');
$c3->pc('A1A1A1');
$c3->sp('Any Prov');
$c3->cc('CA');
$c3->voice('+1.4165555555x1111');
$c3->fax('+1.4165555556');
$c3->email('jdoe@test.test');
$c3->auth({pw => 'my secret'});
$rc=$dri->contact_create($c3);
is($rc->is_success(),1,'contact_create [OTE-C3] is_success (2.3.1.8)');

## 2.3.1.9 - Check Contact OTE-C4 (Contact Available)
$R2='';
$c1=$dri->local_object('contact')->srid('OTE-C4');
$rc=$dri->contact_check($c1);
is($rc->is_success(),1,'contact_check contact_available is_success (2.3.1.9)');

## 2.3.1.10 - Create Contact OTE-C4
$R2='';
my $c4=$dri->local_object('contact');
$c4->srid('OTE-C4');
$c4->name('John Doe');
$c4->org('Example Corp. Inc');
$c4->street(['123 Example St.','Suite 100']);
$c4->city('Anytown');
$c4->pc('A1A1A1');
$c4->sp('Any Prov');
$c4->cc('CA');
$c4->voice('+1.4165555555x1111');
$c4->fax('+1.4165555556');
$c4->email('jdoe@test.test');
$c4->auth({pw => 'my secret'});
$rc=$dri->contact_create($c4);
is($rc->is_success(),1,'contact_create [OTE-C4] is_success (2.3.1.10)');

## 2.3.1.11 - Update Contact (Change Element)
$R2='';
$co=$dri->local_object('contact')->srid('OTE-C3');
my $toc1=$dri->local_object('changes');
my $co21=$dri->local_object('contact');
$co21->name('Jane Smith');
$toc1->set('info',$co21);
$rc=$dri->contact_update($co,$toc1);
is($rc->is_success(),1,'contact_update is_success change_name (2.3.1.11)');

## 2.3.1.12 - Update Contact (Remove Element)
$R2='';
$co=$dri->local_object('contact')->srid('OTE-C3');
$toc1=$dri->local_object('changes');
$co21=$dri->local_object('contact');
$co21->fax('');
$toc1->set('info',$co21);
$rc=$dri->contact_update($co,$toc1);
is($rc->is_success(),1,'contact_update is_success remove_fax (2.3.1.12)');

## 2.3.1.13 - Update Contact (Add Element)
$R2='';
$co=$dri->local_object('contact')->srid('OTE-C3');
$toc1=$dri->local_object('changes');
$co21=$dri->local_object('contact');
$co21->fax('+1.4165555556');
$toc1->set('info',$co21);
$rc=$dri->contact_update($co,$toc1);
is($rc->is_success(),1,'contact_update is_success add_fax (2.3.1.13)');

## 2.3.1.14 - Check Name Server (Foreign Registry - Available)
$R2='';
$rc=$dri->host_check('ns1.example.com');
is($rc->is_success(),1,'host_check is_success (2.3.1.14)');

## Test 3 - Create Contact without Nexus or App Purpose
#my $c=$dri->local_object('contact');
#$c->srid(&SUB().'cont1');
#$c->name('Jim L. Anderson');
#$c->org('Cobolt Boats, Inc.');
#$c->street(['3375 Clear Creek Drive','Building One']);
#$c->city('Clearwater');
#$c->pc('50398-001');
#$c->sp('Florida');
#$c->cc('US');
#$c->voice('+1.7035555555x12');
#$c->fax('+1.7653455566');
#$c->email('janderson@worldnet.us');
#$c->auth({pw => 'mysecret'});
#$rc=$dri->contact_create($c);
#is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq03cont1</contact:id><contact:postalInfo type="int"><contact:name>Jim L. Anderson</contact:name><contact:org>Cobolt Boats, Inc.</contact:org><contact:addr><contact:street>3375 Clear Creek Drive</contact:street><contact:street>Building One</contact:street><contact:city>Clearwater</contact:city><contact:sp>Florida</contact:sp><contact:pc>50398-001</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="12">+1.7035555555</contact:voice><contact:fax>+1.7653455566</contact:fax><contact:email>janderson@worldnet.us</contact:email><contact:authInfo><contact:pw>mysecret</contact:pw></contact:authInfo></contact:create></create><clTRID>nom-iq03ote-testcase03cmd</clTRID></command>'.$E2,'contact_create with nexus info build (Test 3)');
#
## Test 4 - Check Contact (Contact Known)
#$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="0">cont1</contact:id></contact:cd></contact:chkData></resData><trID><clTRID>ote-testcase04cmd</clTRID><svTRID>ote-testcase04res</svTRID></trID>'.$TRID.'</response>'.$E2;
#my $c1=$dri->local_object('contact')->srid(&SUB().'cont1');
#$rc=$dri->contact_check($c1);
#is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq04cont1</contact:id></contact:check></check><clTRID>nom-iq04ote-testcase04cmd</clTRID></command>'.$E2,'contact_info contact_known build (Test 4)');
#is($rc->is_success(),1,'contact_info is_success (Test 4)');
#
## Test 5 - Check Contact (Contact Unknown)
#$R2='';
#my $c2=$dri->local_object('contact')->srid(&SUB().'cont99');
#$rc=$dri->contact_check($c2);
#is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq05cont99</contact:id></contact:check></check><clTRID>nom-iq05ote-testcase05cmd</clTRID></command>'.$E2,'contact_info contact_known build (Test 5)');
#is($rc->is_success(),1,'contact_info is_success (Test 5)');
#
## Test 6 - <info> Query Contact
#$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq03cont1</contact:id><contact:status s="linked" /><contact:status s="clientDeleteProhibited" /><contact:postalInfo type="int"><contact:name>Jim L. Anderson</contact:name><contact:org>Cobolt Boats, Inc.</contact:org><contact:addr><contact:street>3375 Clear Creek Drive</contact:street><contact:street>Building One</contact:street><contact:city>Clearwater</contact:city><contact:sp>Florida</contact:sp><contact:pc>50398-001</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="12">+1.7035555555</contact:voice><contact:fax>+1.7653455566</contact:fax><contact:email>janderson@worldnet.us</contact:email><contact:clID>100050000</contact:clID><contact:crID>100050000</contact:crID><contact:crDate>2001-09-04T22:00:00.0Z</contact:crDate><contact:authInfo><contact:pw>mysecret</contact:pw></contact:authInfo></contact:infData></resData><trID><clTRID>SUBote-testcase06cmd</clTRID><svTRID>nom-iq06ote-testcase06cmd</svTRID></trID></response>'.$E2;
#$co=$dri->local_object('contact')->srid('nom-iq03cont1'); &SUB();
#$rc=$dri->contact_info($co);
#is($rc->is_success(),1,'contact_info build is_success (Test 6)');
#$co=$dri->get_info('self');
#is($dri->get_info('action'),'info','contact_info get_info(action) (Test 6)');
#is($dri->get_info('exist'),1,'contact_info get_info(exist) (Test 6)');
#$co=$dri->get_info('self');
#isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self) (Test 6)');
#$s=$dri->get_info('status');
#isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status) (Test 6)');
#is($s->can_delete(),0,'contact_info get_info(status) can_delete (Test 6)' );
#is($c->srid(),'nom-iq03cont1','contact_info get_info(srid) (Test 6)');
#is($c->name(),'Jim L. Anderson','contact_info get_info(name) (Test 6)');
#is($c->org(),'Cobolt Boats, Inc.','contact_info get_info(org) (Test 6)');
#is_deeply(scalar $c->street(),['3375 Clear Creek Drive','Building One'],'contact_info get_info(street) (Test 6)');
#is($c->city(),'Clearwater','contact_info get_info(city) (Test 6)');
#is($c->sp(),'Florida','contact_info get_info(sp) (Test 6)');
#is($c->pc(),'50398-001','contact_info get_info(pc) (Test 6)');
#is($c->cc(),'US','contact_info get_info(cc) (Test 6)');
#is($c->voice(),'+1.7035555555x12','contact_info get_info(voice) (Test 6)');
#is($c->fax(),'+1.7653455566','contact_info get_info(fax) (Test 6)');
#is($c->email(),'janderson@worldnet.us','contact_info get_info(email) (Test 6)');
#
## Test 7 - Transfer Contact (Request)
#$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq07cont1</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>RegistrarX</contact:reID><contact:reDate>2001-06-08T22:00:00.0Z</contact:reDate><contact:acID>RegistrarY</contact:acID><contact:acDate>2001-06-13T22:00:00.0Z</contact:acDate></contact:trnData></resData><trID><clTRID>nom-iq07ote-testcase07cmd</clTRID><svTRID>ote-testcase07res</svTRID></trID></response>'.$E2;
#$c2=$dri->local_object('contact')->srid(&SUB().'cont1')->auth({pw=>'mysecret'});
#$rc=$dri->contact_transfer_start($c2);
#is_string($R1,$E1.'<command><transfer op="request"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq07cont1</contact:id><contact:authInfo><contact:pw>mysecret</contact:pw></contact:authInfo></contact:transfer></transfer><clTRID>nom-iq07ote-testcase07cmd</clTRID></command>'.$E2,'transfer_contact build (Test 7)');
#is($rc->is_success(),1,'transfer_contact is_success (Test 7)');
#
## Test 8 - Query Contact Transfer Status
#$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq08cont1</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>RegistrarX</contact:reID><contact:reDate>2001-06-06T22:00:00.0Z</contact:reDate><contact:acID>RegistrarY</contact:acID><contact:acDate>2001-06-11T22:00:00.0Z</contact:acDate></contact:trnData></resData><trID><clTRID>nom-iq08ote-testcase08cmd</clTRID><svTRID>ote-testcase08res</svTRID></trID></response>'.$E2;
#$c2=$dri->local_object('contact')->srid(&SUB().'cont1');
#$rc=$dri->contact_transfer_query($c2);
#is_string($R1,$E1.'<command><transfer op="query"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq08cont1</contact:id></contact:transfer></transfer><clTRID>nom-iq08ote-testcase08cmd</clTRID></command>'.$E2,'transfer_contact_query build (Test 8)');
#is($rc->is_success(),1,'transfer_contact_query is_success (Test 8)');
#
## Test 9 - Transfer Contact (Cancel)
#$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq09cont1</contact:id><contact:trStatus>clientCancelled</contact:trStatus><contact:reID>RegistrarX</contact:reID><contact:reDate>2001-06-08T22:00:00.0Z</contact:reDate><contact:acID>RegistrarY</contact:acID><contact:acDate>2001-06-13T22:00:00.0Z</contact:acDate></contact:trnData></resData><trID><clTRID>nom-iq09ote-testcase09cmd</clTRID><svTRID>ote-testcase09res</svTRID></trID></response>'.$E2;
#$c2=$dri->local_object('contact')->srid(&SUB().'cont1');
#$rc=$dri->contact_transfer_stop($c2);
#is_string($R1,$E1.'<command><transfer op="cancel"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq09cont1</contact:id></contact:transfer></transfer><clTRID>nom-iq09ote-testcase09cmd</clTRID></command>'.$E2,'transfer_contact_stop build (Test 9)');
#is($rc->is_success(),1,'transfer_contact_stop is_success (Test 9)');
#
## Test 10 - Change Contact (Change Element)
#$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
#$co=$dri->local_object('contact')->srid('nom-iq10cont1'); &SUB();
#my $toc1=$dri->local_object('changes');
#my $co21=$dri->local_object('contact');
#$co21->street(['3377 Clear Creek Drive','Pier 15']);
#$co21->org('');
#$co21->city('Clearwater');
#$co21->sp('Florida');
#$co21->pc('50398-001');
#$co21->cc('US');
#$co21->voice('+1.7034444444');
#$co21->fax('');
#$co21->auth({pw => 'newsecret'});
#$toc1->set('info',$co21);
#$toc1->add('status',$dri->local_object('status')->add('clientDeleteProhibited'));
#$rc=$dri->contact_update($co,$toc1);
#is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq10cont1</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="int"><contact:org/><contact:addr><contact:street>3377 Clear Creek Drive</contact:street><contact:street>Pier 15</contact:street><contact:city>Clearwater</contact:city><contact:sp>Florida</contact:sp><contact:pc>50398-001</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>newsecret</contact:pw></contact:authInfo></contact:chg></contact:update></update><clTRID>nom-iq10ote-testcase10cmd</clTRID></command>'.$E2,'contact_update build change_element (Test 10)');
#is($rc->is_success(),1,'contact_update is_success change_element (Test 10)');
#
## Test 11 - Change Contact (Remove Element)
#$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
#$co=$dri->local_object('contact')->srid(&SUB().'cont1');
#$toc1=$dri->local_object('changes');
#$toc1->del('status',$dri->local_object('status')->add('clientDeleteProhibited'));
#$rc=$dri->contact_update($co,$toc1);
#is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq11cont1</contact:id><contact:rem><contact:status s="clientDeleteProhibited"/></contact:rem></contact:update></update><clTRID>nom-iq11ote-testcase11cmd</clTRID></command>'.$E2,'contact_update build no_extension (Test 11)');
#is($rc->is_success(),1,'contact_update is_success no_extension (Test 11)');
#
## Test 12 - Delete Contact
#$R2='';
#$co=$dri->local_object('contact')->srid(&SUB().'cont1');
#$rc=$dri->contact_delete($co);
#is_string($R1,$E1.'<command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq12cont1</contact:id></contact:delete></delete><clTRID>nom-iq12ote-testcase12cmd</clTRID></command>'.$E2,'contact_delete build (Test 12)');
#is($rc->is_success(),1,'contact_delete is_success (Test 12)');
#
## Test 13 - Create two contacts, one without Nexus Category and App Purpose and one with Nexus Category and App Purpose
#my $t13=&SUB().'cont1';
## First Contact without Nexus Category & App Purpose
#$c=$dri->local_object('contact');
#$c->srid($t13);
#$c->name('Jim L. Anderson');
#$c->org('Cobolt Boats, Inc.');
#$c->street(['3375 Clear Creek Drive','Building One']);
#$c->city('Clearwater');
#$c->pc('50398-001');
#$c->sp('Florida');
#$c->cc('US');
#$c->voice('+1.7035555555x12');
#$c->fax('+1.7653455566');
#$c->email('janderson@worldnet.us');
#$c->auth({pw => 'mysecret'});
#$rc=$dri->contact_create($c);
#is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq13cont1</contact:id><contact:postalInfo type="int"><contact:name>Jim L. Anderson</contact:name><contact:org>Cobolt Boats, Inc.</contact:org><contact:addr><contact:street>3375 Clear Creek Drive</contact:street><contact:street>Building One</contact:street><contact:city>Clearwater</contact:city><contact:sp>Florida</contact:sp><contact:pc>50398-001</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="12">+1.7035555555</contact:voice><contact:fax>+1.7653455566</contact:fax><contact:email>janderson@worldnet.us</contact:email><contact:authInfo><contact:pw>mysecret</contact:pw></contact:authInfo></contact:create></create><clTRID>nom-iq13ote-testcase13cmd</clTRID></command>'.$E2,'contact_create without nexus info build (Test 13)');
#
## First Contact with Nexus Category & App Purpose
#$c=$dri->local_object('contact');
#$c->srid($t13);
#$c->name('Jim L. Anderson');
#$c->org('Cobolt Boats, Inc.');
#$c->street(['3375 Clear Creek Drive','Building One']);
#$c->city('Clearwater');
#$c->pc('50398-001');
#$c->sp('Florida');
#$c->cc('US');
#$c->voice('+1.7653455566x12');
#$c->fax('+1.7653455568');
#$c->email('janderson@worldnet.us');
#$c->auth({pw => 'mysecret'});
#$c->application_purpose('P1');
#$c->nexus_category('C21');
#$rc=$dri->contact_create($c);
#is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>nom-iq13cont1</contact:id><contact:postalInfo type="int"><contact:name>Jim L. Anderson</contact:name><contact:org>Cobolt Boats, Inc.</contact:org><contact:addr><contact:street>3375 Clear Creek Drive</contact:street><contact:street>Building One</contact:street><contact:city>Clearwater</contact:city><contact:sp>Florida</contact:sp><contact:pc>50398-001</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="12">+1.7653455566</contact:voice><contact:fax>+1.7653455568</contact:fax><contact:email>janderson@worldnet.us</contact:email><contact:authInfo><contact:pw>mysecret</contact:pw></contact:authInfo></contact:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><unspec>NexusCategory=C21 AppPurpose=P1</unspec></neulevel:extension></extension><clTRID>nom-iq13ote-testcase13cmd</clTRID></command>'.$E2,'contact_create with nexus info build (Test 13)');
#
#####################################################################################################
######## Domain Commands ########
#
## Test 14- Create Domain with Contacts
#my $dom_inc=&SUB();
#my $cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($dom_inc.'cont2'),'registrant');
#$cs->add($dri->local_object('contact')->srid($dom_inc.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($dom_inc.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($dom_inc.'cont2'),'billing');
#$rc=$dri->domain_create($dom_inc.'test-01.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq14test-01.us</domain:name><domain:period unit="y">2</domain:period><domain:registrant>nom-iq14cont2</domain:registrant><domain:contact type="admin">nom-iq14cont2</domain:contact><domain:contact type="billing">nom-iq14cont2</domain:contact><domain:contact type="tech">nom-iq14cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq14ote-testcase14cmd</clTRID></command>'.$E2,'domain_create contacts_only build_xml (Test 14)');
#is($rc->is_success(),1,'domain_create is_success (Test 14)');
#
#####################################################################################################
######## Host Commands ########
#
## Test 15 - Create Host
#$R2='';
#$rc=$dri->host_create($dri->local_object('hosts')->add('ns1.'.&SUB().'test-01.us',['192.1.2.3'],[]));
#is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq15test-01.us</host:name><host:addr ip="v4">192.1.2.3</host:addr></host:create></create><clTRID>nom-iq15ote-testcase15cmd</clTRID></command>'.$E2,'host_create build (Test 15)');
#is($rc->is_success(),1,'host_create is_success (Test 15)');
#
## Test 16 - Create Host with Maximum Length Host Name
#$R2='';
#$rc=$dri->host_create($dri->local_object('hosts')->add('abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqr.'.&SUB().'test-01.us',['192.5.7.9'],[]));
#is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqr.nom-iq16test-01.us</host:name><host:addr ip="v4">192.5.7.9</host:addr></host:create></create><clTRID>nom-iq16ote-testcase16cmd</clTRID></command>'.$E2,'host_create max_char build (Test 16)');
#is($rc->is_success(),1,'host_create max_char is_success (Test 16)');
#
## Test 17 - Check Host (Host Known)
#$R2='';
#$rc=$dri->host_check('ns1.'.&SUB().'test-01.us');
#is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq17test-01.us</host:name></host:check></check><clTRID>nom-iq17ote-testcase17cmd</clTRID></command>'.$E2,'host_check build (Test 17)');
#is($rc->is_success(),1,'host_check is_success (Test 17)');
#
## Test 18 - Check Host (Host Unknown)
#$R2='';
#$rc=$dri->host_check('ns1.'.&SUB().'test-99.us');
#is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq18test-99.us</host:name></host:check></check><clTRID>nom-iq18ote-testcase18cmd</clTRID></command>'.$E2,'host_check build (Test 18)');
#is($rc->is_success(),1,'host_check is_success (Test 18)');
#
## Test 19 - The <info> Query Host Command
#$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xmlns="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.SUBtest-01.us</host:name><host:status s="linked" /><host:status s="clientUpdateProhibited" /><host:addr ip="v4">192.1.2.3</host:addr><host:clID>100050000</host:clID><host:crID>100050000</host:crID><host:crDate>2001-09-04T22:00:00.0Z</host:crDate></host:infData></resData><trID><clTRID>SUBote-testcase19cmd</clTRID><svTRID>ote-testcase19res</svTRID></trID></response>'.$E2;
#$rc=$dri->host_info('ns1.'.&SUB().'test-01.us');
#is_string($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq19test-01.us</host:name></host:info></info><clTRID>nom-iq19ote-testcase19cmd</clTRID></command>'.$E2,'host_info build (Test 19)');
#is($rc->is_success(),1,'host_info is_success (Test 19)');
#
## Test 20 - Update Host
#my $t20='ns1.'.&SUB().'test-01.us';
#my $toc=$dri->local_object('changes');
#$toc->add('ip',$dri->local_object('hosts')->add($t20,['192.12.14.16'],[]));
#$rc=$dri->host_update($t20,$toc);
#is_string($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq20test-01.us</host:name><host:add><host:addr ip="v4">192.12.14.16</host:addr></host:add></host:update></update><clTRID>nom-iq20ote-testcase20cmd</clTRID></command>'.$E2,'host_update add_host build (Test 20)');
#is($rc->is_success(),1,'host_update add_host is_success (Test 20)');
#
## Test 21 - Update Host (Remove IP Address)
#my $t21='ns1.'.&SUB().'test-01.us';
#$toc=$dri->local_object('changes');
#$toc->del('ip',$dri->local_object('hosts')->add($t21,['192.1.2.3'],[]));
#$rc=$dri->host_update($t21,$toc);
#is_string($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq21test-01.us</host:name><host:rem><host:addr ip="v4">192.1.2.3</host:addr></host:rem></host:update></update><clTRID>nom-iq21ote-testcase21cmd</clTRID></command>'.$E2,'host_update remove_host build (Test 21)');
#is($rc->is_success(),1,'host_update remove_host is_success (Test 21)');
#
## Test 22 - Delete Host
#$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
#$rc=$dri->host_delete('ns1.'.&SUB().'test-01.us');
#is_string($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.nom-iq22test-01.us</host:name></host:delete></delete><clTRID>nom-iq22ote-testcase22cmd</clTRID></command>'.$E2,'host_delete build (Test 22)');
#is($rc->is_success(),1,'host_delete is_success (Test 22)');
#
## Test 23 - Create Host
#$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
#my $thosts=$dri->local_object('hosts');
#my $t23=&SUB();
#$thosts->add('ns2.'.$t23.'test-01.us',['192.1.2.3'],[]);
#$rc=$dri->host_create($thosts);
#is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.nom-iq23test-01.us</host:name><host:addr ip="v4">192.1.2.3</host:addr></host:create></create><clTRID>nom-iq23ote-testcase23cmd</clTRID></command>'.$E2,'host_create 2nd_ns build (Test 23)');
#is($rc->is_success(),1,'host_create 2nd_ns is_success (Test 23)');
#
#$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
#my $thosts1=$dri->local_object('hosts');
#$thosts1->add('ns3.'.$t23.'test-01.us',['192.1.2.3'],[]);
#$rc=$dri->host_create($thosts1);
#is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns3.nom-iq23test-01.us</host:name><host:addr ip="v4">192.1.2.3</host:addr></host:create></create><clTRID>nom-iq23ote-testcase23cmd</clTRID></command>'.$E2,'host_create 3rd_ns build (Test 23)');
#is($rc->is_success(),1,'host_create 3rd_ns is_success (Test 23)');
#
#####################################################################################################
######## Domain Commands ########
#
## Test 24 - Create Domain without Nameservers and without Contacts
#$dom_inc=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($dom_inc.'cont2'),'registrant');
#$rc=$dri->domain_create($dom_inc.'test-02.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq24test-02.us</domain:name><domain:period unit="y">2</domain:period><domain:registrant>nom-iq24cont2</domain:registrant><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq24ote-testcase24cmd</clTRID></command>'.$E2,'domain_create no_contact_&_ns build_xml (Test 24)');
#is($rc->is_success(),1,'domain_create no_contact_&_ns is_success (Test 24)');
#
## Test 25 Create Domain with registrant contact that has no Nexus Category or App purpose
#my $t25=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($t25.'cont1'),'registrant');
#$cs->add($dri->local_object('contact')->srid($t25.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($t25.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($t25.'cont2'),'billing');
#my $dh=$dri->local_object('hosts');
#$dh->add('ns2.'.$t25.'test-01.us');
#$dh->add('ns3.'.$t25.'test-01.us');
#$rc=$dri->domain_create($t25.'test-02.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq25test-02.us</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns2.nom-iq25test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq25test-01.us</domain:hostObj></domain:ns><domain:registrant>nom-iq25cont1</domain:registrant><domain:contact type="admin">nom-iq25cont2</domain:contact><domain:contact type="billing">nom-iq25cont2</domain:contact><domain:contact type="tech">nom-iq25cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq25ote-testcase25cmd</clTRID></command>'.$E2,'domain_create no_nexus_&_category_ext build_xml (Test 25)');
#is($rc->is_success(),1,'domain_create no_nexus_&_category_ext is_success (Test 25)');
#
## Test 26- Create Domain with all Required Attributes and correct contacts
#my $t26=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($t26.'cont2'),'registrant');
#$cs->add($dri->local_object('contact')->srid($t26.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($t26.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($t26.'cont2'),'billing');
#$dh=$dri->local_object('hosts');
#$dh->add('ns2.'.$t26.'test-01.us');
#$dh->add('ns3.'.$t26.'test-01.us');
#$rc=$dri->domain_create($t26.'test-02.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq26test-02.us</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns2.nom-iq26test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq26test-01.us</domain:hostObj></domain:ns><domain:registrant>nom-iq26cont2</domain:registrant><domain:contact type="admin">nom-iq26cont2</domain:contact><domain:contact type="billing">nom-iq26cont2</domain:contact><domain:contact type="tech">nom-iq26cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq26ote-testcase26cmd</clTRID></command>'.$E2,'domain_create with_nexus_&_category_ext build_xml (Test 26)');
#is($rc->is_success(),1,'domain_create with_nexus_&_category_ext is_success (Test 26)');
#
## Test 27 - Create Domain with Maximum Registration Period
#my $t27=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($t27.'cont2'),'registrant');
#$cs->add($dri->local_object('contact')->srid($t27.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($t27.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($t27.'cont2'),'billing');
#$dh=$dri->local_object('hosts');
#$dh->add('ns2.'.$t27.'test-01.us');
#$dh->add('ns3.'.$t27.'test-01.us');
#$rc=$dri->domain_create($t27.'test-03.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>10),contact=>$cs,ns=>$dh,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq27test-03.us</domain:name><domain:period unit="y">10</domain:period><domain:ns><domain:hostObj>ns2.nom-iq27test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq27test-01.us</domain:hostObj></domain:ns><domain:registrant>nom-iq27cont2</domain:registrant><domain:contact type="admin">nom-iq27cont2</domain:contact><domain:contact type="billing">nom-iq27cont2</domain:contact><domain:contact type="tech">nom-iq27cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq27ote-testcase27cmd</clTRID></command>'.$E2,'domain_create with_max_reg_period build_xml (Test 27)');
#is($rc->is_success(),1,'domain_create with_max_reg_period is_success (Test 27)');
#
## Test 28 - Create Domain with Maximum Length Domain Name
#my $t28=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($t28.'cont2'),'registrant');
#$cs->add($dri->local_object('contact')->srid($t28.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($t28.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($t28.'cont2'),'billing');
#$dh=$dri->local_object('hosts');
#$dh->add('ns2.'.$t28.'test-01.us');
#$dh->add('ns3.'.$t28.'test-01.us');
#$rc=$dri->domain_create($t28.'test-99-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrst.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq28test-99-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrst.us</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns2.nom-iq28test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq28test-01.us</domain:hostObj></domain:ns><domain:registrant>nom-iq28cont2</domain:registrant><domain:contact type="admin">nom-iq28cont2</domain:contact><domain:contact type="billing">nom-iq28cont2</domain:contact><domain:contact type="tech">nom-iq28cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq28ote-testcase28cmd</clTRID></command>'.$E2,'domain_create with_max_length_domain_name build_xml (Test 28)');
#is($rc->is_success(),1,'domain_create with_max_length_domain_name build_xml is_success (Test 28)');
#
## Test 29 - Create Domain with Invalid Name (Should Fail!)
#my $t29=&SUB();
#$cs=$dri->local_object('contactset');
#$cs->add($dri->local_object('contact')->srid($t29.'cont2'),'registrant');
#$cs->add($dri->local_object('contact')->srid($t29.'cont2'),'admin');
#$cs->add($dri->local_object('contact')->srid($t29.'cont2'),'tech');
#$cs->add($dri->local_object('contact')->srid($t29.'cont2'),'billing');
#$dh=$dri->local_object('hosts');
#$dh->add('ns2.'.$t29.'test-01.us');
#$dh->add('ns3.'.$t29.'test-01.us');
#$rc=$dri->domain_create('invalid-name.us',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,ns=>$dh,auth=>{pw=>'mysecret'}});
#is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>invalid-name.us</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns2.nom-iq29test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq29test-01.us</domain:hostObj></domain:ns><domain:registrant>nom-iq29cont2</domain:registrant><domain:contact type="admin">nom-iq29cont2</domain:contact><domain:contact type="billing">nom-iq29cont2</domain:contact><domain:contact type="tech">nom-iq29cont2</domain:contact><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:create></create><clTRID>nom-iq29ote-testcase29cmd</clTRID></command>'.$E2,'domain_create invalid_name should_fail build_xml (Test 29)');
#is($rc->is_success(),1,'domain_create invalid_name should_fail is_success (Test 29)');
#
## Test 30 - Check Domain (Domain Not Available)
#$R2='';
#my $t30=&SUB();
#$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="0">nom-iq30test-01.us</domain:name></domain:cd><domain:cd><domain:name avail="0">nom-iq30test-02.us</domain:name></domain:cd><domain:cd><domain:name avail="0">nom-iq30test-03.us</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
#$rc=$dri->domain_check($t30.'test-01.us',$t30.'test-02.us',$t30.'test-03.us');
#is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq30test-01.us</domain:name><domain:name>nom-iq30test-02.us</domain:name><domain:name>nom-iq30test-03.us</domain:name></domain:check></check><clTRID>nom-iq30ote-testcase30cmd</clTRID></command>'.$E2,'domain_check multiple_domains_unavaliable build (Test 30)');
#is($rc->is_success(),1,'domain_check multiple_domains_unavaliable is_success (Test 30)');
#
## Test 31 - Check Domain (Domain Available)
#$R2='';
#my $t31=&SUB();
#$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="0">nom-iq31test-97.us</domain:name></domain:cd><domain:cd><domain:name avail="0">nom-iq31test-98.us</domain:name></domain:cd><domain:cd><domain:name avail="0">nom-iq31test-99.us</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
#$rc=$dri->domain_check($t31.'test-97.us',$t31.'test-98.us',$t31.'test-99.us');
#is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq31test-97.us</domain:name><domain:name>nom-iq31test-98.us</domain:name><domain:name>nom-iq31test-99.us</domain:name></domain:check></check><clTRID>nom-iq31ote-testcase31cmd</clTRID></command>'.$E2,'domain_check multiple_domains_avaliable build (Test 31)');
#is($rc->is_success(),1,'domain_check multiple_domains_avaliable is_success (Test 31)');
#
## Test 32 - Query Domain <info>
#$R2='';
#my $t32=&SUB();
#$rc = $dri->domain_info($t32.'test-02.us');
#is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">nom-iq32test-02.us</domain:name></domain:info></info><clTRID>nom-iq32ote-testcase32cmd</clTRID></command>'.$E2,'domain_info_query build_xml (Test 32)');
#is($rc->is_success(),1,'domain_info_query is_success (Test 32)');
#
## Test 33 - Transfer a Domain [2nd OT&E Account]
#$R2='';
#$rc = $dri->domain_transfer_start(&SUB().'test-02.us',{auth=>{pw=>'mysecret'}},duration=>DateTime::Duration->new(years=>1));
#is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq33test-02.us</domain:name><domain:authInfo><domain:pw>mysecret</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>nom-iq33ote-testcase33cmd</clTRID></command>'.$E2, 'domain_transfer_start build (Test 33)');
#is($rc->is_success(), 1, 'domain_transfer_start is success (Test 33)');
#
## Test 34 - Transfer Query Command
#$R2='';
#$rc=$dri->domain_transfer_query(&SUB().'test-02.us');
#is($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq34test-02.us</domain:name></domain:transfer></transfer><clTRID>nom-iq34ote-testcase34cmd</clTRID></command>'.$E2,'domain_transfer_query build_xml (Test 34)');
#is($rc->is_success(), 1, 'domain_transfer_query is_success (Test 34)');
#
## Test 35 - Cancel a Domain Transfer [2nd OT&E Account]
#$R2='';
#$rc=$dri->domain_transfer_stop(&SUB().'test-02.us');
#is($R1,$E1.'<command><transfer op="cancel"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq35test-02.us</domain:name></domain:transfer></transfer><clTRID>nom-iq35ote-testcase35cmd</clTRID></command>'.$E2,'domain_transfer_stop build_xml (Test 35)');
#is($rc->is_success(), 1, 'domain_transfer_stop is_success (Test 35)');
#
## Test 36 - Renew Domain
#$R2='';
#my $du = DateTime::Duration->new( years => 5);
#my $exp = DateTime->new(year  => 2003,month => 8,day   => 29);
#$rc = $dri->domain_renew(&SUB().'test-01.us',{duration=>$du,current_expiration=>$exp} );
#is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq36test-01.us</domain:name><domain:curExpDate>2003-08-29</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>nom-iq36ote-testcase36cmd</clTRID></command>'.$E2, 'domain_renew build_xml (Test 36)');
#is($rc->is_success(), 1, 'domain_renew is success (Test 36)');
#
## Test 37 - Renew Domain to Maximum Registration Period
#$R2='';
#$du = DateTime::Duration->new( years => 3);
#$exp = DateTime->new(year  => 2008,month => 8,day   => 29);
#$rc = $dri->domain_renew(&SUB().'test-01.us',{duration=>$du,current_expiration=>$exp} );
#is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq37test-01.us</domain:name><domain:curExpDate>2008-08-29</domain:curExpDate><domain:period unit="y">3</domain:period></domain:renew></renew><clTRID>nom-iq37ote-testcase37cmd</clTRID></command>'.$E2, 'domain_renew max_reg_period build_xml (Test 37)');
#is($rc->is_success(), 1, 'domain_renew max_reg_period is success (Test 37)');
#
## Test 38 - Change Domain Name Servers
#my $t38=&SUB();
#$R2='';
#$toc=$dri->local_object('changes');
#$toc->add('ns',$dri->local_object('hosts')->set(['test.alextest1.us'],['test2.alextest1.us']));
#$toc->del('ns',$dri->local_object('hosts')->set(['ns2.'.$t38.'test-01.us'],['ns3.'.$t38.'test-01.us']));
#$rc=$dri->domain_update($t38.'test-02.us',$toc);
#is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq38test-02.us</domain:name><domain:add><domain:ns><domain:hostObj>test.alextest1.us</domain:hostObj><domain:hostObj>test2.alextest1.us</domain:hostObj></domain:ns></domain:add><domain:rem><domain:ns><domain:hostObj>ns2.nom-iq38test-01.us</domain:hostObj><domain:hostObj>ns3.nom-iq38test-01.us</domain:hostObj></domain:ns></domain:rem></domain:update></update><clTRID>nom-iq38ote-testcase38cmd</clTRID></command>'.$E2,'domain_update add_&_remove_hosts build_xml (Test 38)');
#is($rc->is_success(), 1, 'domain_update add_&_remove_hosts is success (Test 38)');
#
## Test 39 - Change Domain Contact
#my $t39=&SUB();
#$R2='';
#$toc=$dri->local_object('changes');
#$cs=$dri->local_object('contactset');
#my $cs1=$dri->local_object('contactset');
#$cs->set($dri->local_object('contact')->srid($t39.'cont2'),'admin'); # remove contact
#$cs1->set($dri->local_object('contact')->srid($t39.'cont1'),'admin'); # add contact
#$toc->add('contact',$cs1);
#$toc->del('contact',$cs);
#$rc=$dri->domain_update($t39.'test-01.us',$toc);
#is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq39test-01.us</domain:name><domain:add><domain:contact type="admin">nom-iq39cont1</domain:contact></domain:add><domain:rem><domain:contact type="admin">nom-iq39cont2</domain:contact></domain:rem></domain:update></update><clTRID>nom-iq39ote-testcase39cmd</clTRID></command>'.$E2,'domain_update add_&_remove_contacts build_xml (Test 39)');
#is($rc->is_success(), 1, 'domain_update add_&_remove_contacts is success (Test 39)');
#
## Test 40 - Change Domain Status
#my $t40=&SUB();
#$R2='';
#$toc=$dri->local_object('changes');
#$toc->add('status',$dri->local_object('status')->add('clientUpdateProhibited'));
#$rc=$dri->domain_update($t40.'test-01.us',$toc);
#is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq40test-01.us</domain:name><domain:add><domain:status s="clientUpdateProhibited"/></domain:add></domain:update></update><clTRID>nom-iq40ote-testcase40cmd</clTRID></command>'.$E2,'domain_update add_status build_xml (Test 40)');
#is($rc->is_success(), 1, 'domain_update add_status is success (Test 40)');
#
## Test 41 - Delete Domain
#$rc=$dri->domain_delete(&SUB().'test-02.us');
#is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nom-iq41test-02.us</domain:name></domain:delete></delete><clTRID>nom-iq41ote-testcase41cmd</clTRID></command>'.$E2,'domain_delete build_xml (Test 41)');
#is($rc->is_success(),1,'domain_delete is_success (Test 41)');
#
#####################################################################################################
######### Closing Commands ########
#
## Test 42 - Logout Command
#$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
#$rc=$dri->process('session','logout',[]);
#is($R1,$E1.'<command><logout/><clTRID>nom-iq41ote-testcase41cmd</clTRID></command>'.$E2,'session logout build_xml (Test 42)');
#is($rc->is_success(),1,'session logout is_success (Test 42)');

exit 0;
