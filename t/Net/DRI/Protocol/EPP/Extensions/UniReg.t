#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 12;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider => 'UNIREG'} );
$dri->target('UNIREG')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

#####################
## Centric Extension

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.gift</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData>'.'<extension><urc:registrant xmlns:urc="http://ns.uniregistry.net/centric-1.0"><urc:postalInfo type="int"><urc:name>John Doe</urc:name><urc:org>Example Inc.</urc:org><urc:addr><urc:street>123 Example Dr.</urc:street><urc:street>Suite 100</urc:street><urc:city>Dulles</urc:city><urc:sp>VA</urc:sp><urc:pc>20166-6503</urc:pc><urc:cc>US</urc:cc></urc:addr></urc:postalInfo><urc:postalInfo type="loc"><urc:name>Juan Ordonez</urc:name><urc:org>Ejemplo Compania An6nima</urc:org><urc:addr><urc:street>123 Calle Ejemplo</urc:street><urc:street>Local numero 60</urc:street><urc:city>Caracas</urc:city><urc:sp>DC</urc:sp><urc:pc>1010</urc:pc><urc:cc>VE</urc:cc></urc:addr></urc:postalInfo><urc:voice x="1234">+1.7035555555</urc:voice><urc:fax x="4321">+1.7035555556</urc:fax><urc:email>jdoe@example.com</urc:email><urc:emailAlt>jdoe2@foobar.net</urc:emailAlt><urc:mobile>+1.6504231234</urc:mobile><urc:security><urc:challenge><urc:question>Question 1</urc:question><urc:answer>Answer 1</urc:answer></urc:challenge><urc:challenge><urc:question>Question 2</urc:question><urc:answer>Answer 2</urc:answer></urc:challenge><urc:challenge><urc:question>Question 3</urc:question><urc:answer>Answer 3</urc:answer></urc:challenge></urc:security></urc:registrant></extension>'.$TRID.'</response>'.$E2;$rc=$dri->domain_info('example3.gift');
is($dri->get_info('action'),'info','domain_info get_info(action)');
my $c = $dri->get_info('contact')->get('urc');
is($c->name(),'Juan Ordonez','domain_info get_info(urc name)');
is($c->mobile(),'+1.6504231234','domain_info get_info(urc mobile)');
is($c->alt_email(),'jdoe2@foobar.net','domain_info get_info(urc alt_email)');
is_deeply($c->challenge(),[ {question => 'Question 1',answer=>'Answer 1'},{question => 'Question 2',answer=>'Answer 2'},{question => 'Question 3',answer=>'Answer 3'} ],'domain_info get_info(urc challenge)');

  # a URC standard contact... careful to create the correct type of contact here!
my $urc = $dri->local_object('urc_contact');
$urc->name(['Juan Ordonez','John Doe'])->org(['Ejemplo Compania An6nima','Example Inc.'])->street([['123 Calle Ejemplo','Local numero 60'],['123 Example Dr.','Suite 100']])->city(['Caracas','Dulles'])->sp(['DC','VA'])->pc(['1010','20166-6503'])->cc(['VE','US'])->voice('+1.7035555555x1234')->fax('+1.7035555556x4321')->email('jdoe@example.com');
$urc->alt_email('jdoe2@foobar.net');
$urc->mobile('+1.6504231234');
my @ch = ( {question => 'Question 1',answer=>'Answer 1'},{question => 'Question 2',answer=>'Answer 2'},{question => 'Question 3',answer=>'Answer 3'} );
$urc->challenge(\@ch);

my $cs=$dri->local_object('contactset');
#$cs->set($c,'registrant'); # we are skipping the other contact types for the purpose of this test as we are just testing the extension
$cs->set($urc,'urc');

# create with bid
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.gift</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.gift',{pure_create=>1,auth=>{pw=>'2fooBAR'},contact=>$cs} );
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.gift</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create>'.'<extension><urc:registrant xmlns:urc="http://ns.uniregistry.net/centric-1.0" xsi:schemaLocation="http://ns.uniregistry.net/centric-1.0 centric-1.0.xsd"><urc:postalInfo type="loc"><urc:name>Juan Ordonez</urc:name><urc:org>Ejemplo Compania An6nima</urc:org><urc:addr><urc:street>123 Calle Ejemplo</urc:street><urc:street>Local numero 60</urc:street><urc:city>Caracas</urc:city><urc:sp>DC</urc:sp><urc:pc>1010</urc:pc><urc:cc>VE</urc:cc></urc:addr></urc:postalInfo><urc:postalInfo type="int"><urc:name>John Doe</urc:name><urc:org>Example Inc.</urc:org><urc:addr><urc:street>123 Example Dr.</urc:street><urc:street>Suite 100</urc:street><urc:city>Dulles</urc:city><urc:sp>VA</urc:sp><urc:pc>20166-6503</urc:pc><urc:cc>US</urc:cc></urc:addr></urc:postalInfo><urc:voice x="1234">+1.7035555555</urc:voice><urc:fax x="4321">+1.7035555556</urc:fax><urc:email>jdoe@example.com</urc:email><urc:emailAlt>jdoe2@foobar.net</urc:emailAlt><urc:mobile>+1.6504231234</urc:mobile><urc:security><urc:challenge><urc:question>Question 1</urc:question><urc:answer>Answer 1</urc:answer></urc:challenge><urc:challenge><urc:question>Question 2</urc:question><urc:answer>Answer 2</urc:answer></urc:challenge><urc:challenge><urc:question>Question 3</urc:question><urc:answer>Answer 3</urc:answer></urc:challenge></urc:security></urc:registrant></extension>'.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');

# domain update bid
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$toc->set('urc',$urc);
$rc=$dri->domain_update('example3.gift',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.gift</domain:name></domain:update></update>'.'<extension><urc:registrant xmlns:urc="http://ns.uniregistry.net/centric-1.0" xsi:schemaLocation="http://ns.uniregistry.net/centric-1.0 centric-1.0.xsd"><urc:postalInfo type="loc"><urc:name>Juan Ordonez</urc:name><urc:org>Ejemplo Compania An6nima</urc:org><urc:addr><urc:street>123 Calle Ejemplo</urc:street><urc:street>Local numero 60</urc:street><urc:city>Caracas</urc:city><urc:sp>DC</urc:sp><urc:pc>1010</urc:pc><urc:cc>VE</urc:cc></urc:addr></urc:postalInfo><urc:postalInfo type="int"><urc:name>John Doe</urc:name><urc:org>Example Inc.</urc:org><urc:addr><urc:street>123 Example Dr.</urc:street><urc:street>Suite 100</urc:street><urc:city>Dulles</urc:city><urc:sp>VA</urc:sp><urc:pc>20166-6503</urc:pc><urc:cc>US</urc:cc></urc:addr></urc:postalInfo><urc:voice x="1234">+1.7035555555</urc:voice><urc:fax x="4321">+1.7035555556</urc:fax><urc:email>jdoe@example.com</urc:email><urc:emailAlt>jdoe2@foobar.net</urc:emailAlt><urc:mobile>+1.6504231234</urc:mobile><urc:security><urc:challenge><urc:question>Question 1</urc:question><urc:answer>Answer 1</urc:answer></urc:challenge><urc:challenge><urc:question>Question 2</urc:question><urc:answer>Answer 2</urc:answer></urc:challenge><urc:challenge><urc:question>Question 3</urc:question><urc:answer>Answer 3</urc:answer></urc:challenge></urc:security></urc:registrant></extension>'.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');



#####################
## Notifications

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Launch Application LA_xyzabc-UR is now in status "pendingValidation"/"": default status for new launch domain objects</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'123','message_retrieve get_info(last_id)');
my  $lp = $dri->get_info('lp','message',123);
is($lp->{'application_id'},'LA_xyzabc-UR','message_retrieve get_info lp->{application_id}');
is($lp->{'status'},'pendingValidation','message_retrieve get_info lp->{status}');

# added after warning output from poll with <resData>
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="9" id="124"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Transfer request abcde-007410 / CO_xxxx111122223333-ISC.</msg></msgQ><resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>abcde-007410</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>registrar_a</contact:reID><contact:reDate>2014-12-02T16:00:00.000Z</contact:reDate><contact:acID>registrar_b</contact:acID><contact:acDate>2014-12-07T16:00:00.000Z</contact:acDate></contact:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'124','message_retrieve get_info(last_id)');
is($dri->get_info('reID','message',124),'registrar_a','message_retrieve get_info(reID)');

exit 0;
