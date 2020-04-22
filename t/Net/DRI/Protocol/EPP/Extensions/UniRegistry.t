#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 58;
use Test::Exception;
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
$dri->add_current_registry('UniRegistry::UniRegistry');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

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



#####################
## Test .inc profile
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::INC');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.inc</domain:name></domain:cd><domain:cd><domain:name avail="0">examexample2.inc</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.inc','examexample2.inc');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.inc</domain:name><domain:name>examexample2.inc</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check .inc multi build');
is($rc->is_success(),1,'domain_check .inc multi is_success');
is($dri->get_info('exist','domain','example22.inc'),0,'domain_check .inc multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','examexample2.inc'),1,'domain_check .inc multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','examexample2.inc'),'In use','domain_check .inc multi get_info(exist_reason)');

# urc is optional for .inc (mandatory for all other TLDs under Uniregistry!)
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.inc</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
# .inc create with urc
$rc=$dri->domain_create('example3-with-urc.inc',{pure_create=>1,auth=>{pw=>'2fooBAR'},contact=>$cs} );
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3-with-urc.inc</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create>'.'<extension><urc:registrant xmlns:urc="http://ns.uniregistry.net/centric-1.0" xsi:schemaLocation="http://ns.uniregistry.net/centric-1.0 centric-1.0.xsd"><urc:postalInfo type="loc"><urc:name>Juan Ordonez</urc:name><urc:org>Ejemplo Compania An6nima</urc:org><urc:addr><urc:street>123 Calle Ejemplo</urc:street><urc:street>Local numero 60</urc:street><urc:city>Caracas</urc:city><urc:sp>DC</urc:sp><urc:pc>1010</urc:pc><urc:cc>VE</urc:cc></urc:addr></urc:postalInfo><urc:postalInfo type="int"><urc:name>John Doe</urc:name><urc:org>Example Inc.</urc:org><urc:addr><urc:street>123 Example Dr.</urc:street><urc:street>Suite 100</urc:street><urc:city>Dulles</urc:city><urc:sp>VA</urc:sp><urc:pc>20166-6503</urc:pc><urc:cc>US</urc:cc></urc:addr></urc:postalInfo><urc:voice x="1234">+1.7035555555</urc:voice><urc:fax x="4321">+1.7035555556</urc:fax><urc:email>jdoe@example.com</urc:email><urc:emailAlt>jdoe2@foobar.net</urc:emailAlt><urc:mobile>+1.6504231234</urc:mobile><urc:security><urc:challenge><urc:question>Question 1</urc:question><urc:answer>Answer 1</urc:answer></urc:challenge><urc:challenge><urc:question>Question 2</urc:question><urc:answer>Answer 2</urc:answer></urc:challenge><urc:challenge><urc:question>Question 3</urc:question><urc:answer>Answer 3</urc:answer></urc:challenge></urc:security></urc:registrant></extension>'.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create .inc with urc build_xml');
# .inc create without urc
$cs = delete $cs->{'challenge'};
$rc=$dri->domain_create('example3-without-urc.inc',{pure_create=>1,auth=>{pw=>'2fooBAR'},contact=>$cs} );
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3-without-urc.inc</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create>'.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create .inc without urc build_xml');

# lets add an extra test - create a non .inc domain object without mandatory urc
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::UniRegistry');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.inc</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
throws_ok { $dri->domain_create('example3-without-urc.audio',{pure_create=>1,auth=>{pw=>'2fooBAR'},contact=>$cs} ) } qr/URC contact required/, 'domain_create non .inc without urc build_xml';



#####################
## Test unireg_icm profile
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::ICM');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.adult</domain:name></domain:cd><domain:cd><domain:name avail="0">examexample2.sex</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.adult','examexample2.sex');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.adult</domain:name><domain:name>examexample2.sex</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check unireg_icm multi build');
is($rc->is_success(),1,'domain_check unireg_icm multi is_success');
is($dri->get_info('exist','domain','example22.adult'),0,'domain_check unireg_icm multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','examexample2.sex'),1,'domain_check unireg_icm multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','examexample2.sex'),'In use','domain_check unireg_icm multi get_info(exist_reason)');



#####################
## test different greeting/per profile: unireg, inc and icm
# icm - still loaded from previous test
$R2=$E1.'<greeting>
    <svID>ICM Production LAX1</svID>
    <svDate>2019-11-11T10:41:43.848Z</svDate>
    <svcMenu>
      <version>1.0</version>
      <lang>en</lang>
      <lang>es</lang>
      <lang>fr</lang>
      <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
      <objURI>http://ns.uniregistry.net/eps-1.0</objURI>
      <svcExtension>
        <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
        <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
        <extURI>http://ns.uniregistry.net/centric-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
        <extURI>http://www.verisign.com/epp/sync-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:fee-0.7</extURI>
        <extURI>urn:afilias:params:xml:ns:association-1.0</extURI>
        <extURI>urn:afilias:params:xml:ns:ipr-1.1</extURI>
      </svcExtension>
    </svcMenu>
    <dcp>
      <access>
        <all/>
      </access>
      <statement>
        <purpose>
          <admin/>
          <prov/>
        </purpose>
        <recipient>
          <ours/>
          <public/>
        </recipient>
        <retention>
          <stated/>
        </retention>
      </statement>
    </dcp>
  </greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'ICM Production LAX1','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2019-11-11T10:41:43','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','es','fr'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0','urn:ietf:params:xml:ns:contact-1.0','http://ns.uniregistry.net/eps-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7','urn:afilias:params:xml:ns:association-1.0','urn:afilias:params:xml:ns:ipr-1.1'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7','urn:afilias:params:xml:ns:association-1.0','urn:afilias:params:xml:ns:ipr-1.1'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 0}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>http://ns.uniregistry.net/centric-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>http://www.verisign.com/epp/sync-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI><extURI>urn:afilias:params:xml:ns:association-1.0</extURI><extURI>urn:afilias:params:xml:ns:ipr-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'ICM - session login build only_local_extensions = 0');
is($rc->is_success(),1,'ICM - session login is_success');
# enforce local extensions
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 1 }]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>http://ns.uniregistry.net/centric-1.0</extURI><extURI>http://ns.uniregistry.net/market-1.0</extURI><extURI>urn:afilias:params:xml:ns:association-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'ICM - session login build only_local_extensions = 1');
is($rc->is_success(),1,'ICM - session login, only local, is_success');

# now add for standard uniregistry profile just to assure that we are not sending new tweak: $rp->{default_product} eq 'ICM'
# greeting from Production - we can see that Afilias::Association Afilias::IPR are not listed!
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::UniRegistry');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$R2=$E1.'<greeting>
    <svID>Uniregistry Production LAX1</svID>
    <svDate>2019-11-11T10:40:46.559Z</svDate>
    <svcMenu>
      <version>1.0</version>
      <lang>en</lang>
      <lang>es</lang>
      <lang>fr</lang>
      <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
      <objURI>http://ns.uniregistry.net/eps-1.0</objURI>
      <svcExtension>
        <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
        <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
        <extURI>http://ns.uniregistry.net/centric-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
        <extURI>http://www.verisign.com/epp/sync-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:fee-0.7</extURI>
      </svcExtension>
    </svcMenu>
    <dcp>
      <access>
        <all/>
      </access>
      <statement>
        <purpose>
          <admin/>
          <prov/>
        </purpose>
        <recipient>
          <ours/>
          <public/>
        </recipient>
        <retention>
          <stated/>
        </retention>
      </statement>
    </dcp>
  </greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Uniregistry Production LAX1','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2019-11-11T10:40:46','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','es','fr'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0','urn:ietf:params:xml:ns:contact-1.0','http://ns.uniregistry.net/eps-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 0}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>http://ns.uniregistry.net/centric-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>http://www.verisign.com/epp/sync-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'ICM - session login build only_local_extensions = 0');
is($rc->is_success(),1,'UniRegistry::UniRegistry - session login is_success');
# enforce local extensions on login just to assure that Afilias::Association Afilias::IPR is not sent for standard Uniregistry profile!
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 1}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>http://ns.uniregistry.net/centric-1.0</extURI><extURI>http://ns.uniregistry.net/market-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'ICM - session login build only_local_extensions = 1');
is($rc->is_success(),1,'UniRegistry::UniRegistry - session login, only local, is_success');

# add <host:create> test to check old bug - wasn't parsing Host namespace :p
$R2=$E1.'<response>'.r().'<resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_create($dri->local_object('hosts')->add('ns101.example1.com',['193.0.2.2','193.0.2.29'],['2000:0:0:0:8:800:200C:417A']));
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($dri->get_info('action'),'create','host_create get_info(action)');
is($dri->get_info('exist'),1,'host_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_create get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_create get_info(crDate) value');

exit 0;
