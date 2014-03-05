#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Test::More tests => 28;
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
$dri->add_registry('COOP');
$dri->target('COOP')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

## Domain commands
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>th1domain1test.coop</domain:name><domain:crDate>2004-12-06T11:32:39.0Z</domain:crDate><domain:exDate>2006-12-06T11:32:39.0Z</domain:exDate></domain:creData></resData><extension><coop:stateChange xmlns:coop="http://www.nic.coop/contactCoopExt-1.0"><coop:id>th1contact1Test</coop:id><coop:state code="verified">verified</coop:state></coop:stateChange></extension>'.$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234')->org('Whatever');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('th1domain1test.coop',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is(''.$d,'2004-12-06T11:32:39','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is(''.$d,'2006-12-06T11:32:39','domain_create get_info(exDate) value');
is($dri->get_info('registrant_id'),'th1contact1Test','domain_create get_info(registrant_id) value');
is($dri->get_info('registrant_state'),'verified','domain_create get_info(registrant_state) value');
is($dri->get_info('state','contact','th1contact1Test'),'verified','domain_create get_info(state,contact,X) value');

## Contact commands
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>th1domainTest</contact:id><contact:roid>62273C-COOP</contact:roid><contact:status s="ok">ok</contact:status><contact:postalInfo type="loc"><contact:name>Kermit The Frog</contact:name><contact:org>The Muppet Show</contact:org><contact:addr><contact:city>Chicago</contact:city><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:email>k.frog@example.tld</contact:email><contact:clID>TestHarness1</contact:clID><contact:crID>TestHarness1</contact:crID><contact:crDate>2004-10-29T12:29:02.6Z</contact:crDate><contact:authInfo><contact:pw>Match Sticks</contact:pw></contact:authInfo></contact:infData></resData><extension><coop:infData xmlns:coop="http://www.nic.coop/contactCoopExt-1.0"><coop:state code="verified">Verified</coop:state><coop:sponsor>th1Sponsor1</coop:sponsor><coop:sponsor>th1Sponsor2</coop:sponsor></coop:infData></extension>'.$TRID.'</response>'.$E2;
my $co=$dri->local_object('contact')->srid('th1domainTest');
$rc=$dri->contact_info($co);
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->state(),'verified','contact_info get_info(self) state');
is_deeply($co->sponsors(),['th1Sponsor1','th1Sponsor2'],'contact_info get_info(self) sponsors');


$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>th1domainTest</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('th1domainTest');
$co->name('Kermit The Frog');
$co->org('The Muppet Show');
$co->city('Chicago');
$co->cc('US');
$co->email('k.frog@example.tld');
$co->auth({pw=>'Match Sticks'});
$co->sponsors(['th1Sponsor1','th1Sponsor2']);
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>th1domainTest</contact:id><contact:postalInfo type="loc"><contact:name>Kermit The Frog</contact:name><contact:org>The Muppet Show</contact:org><contact:addr><contact:city>Chicago</contact:city><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:email>k.frog@example.tld</contact:email><contact:authInfo><contact:pw>Match Sticks</contact:pw></contact:authInfo></contact:create></create><extension><coop:create xmlns:coop="http://www.nic.coop/contactCoopExt-1.0"><coop:sponsor>th1Sponsor1</coop:sponsor><coop:sponsor>th1Sponsor2</coop:sponsor></coop:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('action'),'create','contact_create get_info(action)');
is($dri->get_info('exist'),1,'contact_create get_info(exist)');

####################################################################################################
## Registry Messages

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="11082"><qDate>2004-12-21T13:46:06.8Z</qDate><msg>Registrant verification state changed</msg></msgQ><extension><coop:stateChange xmlns:coop="http://www.nic.coop/contactCoopExt-1.0"><coop:id>th1Test2</coop:id><coop:state code="verified">verified</coop:state></coop:stateChange></extension><trID><svTRID>00000000000000032212</svTRID></trID></response></epp>';
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),11082,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),11082,'message get_info last_id 2');
is($dri->get_info('id','message',11082),11082,'message get_info id');
is(''.$dri->get_info('qdate','message',11082),'2004-12-21T13:46:06','message get_info qdate');
is($dri->get_info('content','message',11082),'Registrant verification state changed','message get_info msg');
is($dri->get_info('lang','message',11082),'en','message get_info lang');

is($dri->get_info('object_type','message',11082),'contact','message get_info object_type');
is($dri->get_info('object_id','message',11082),'th1Test2','message get_info id');
is($dri->get_info('action','message',11082),'verification_review','message get_info action'); ## with this, we know what action has triggered this delayed message

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
