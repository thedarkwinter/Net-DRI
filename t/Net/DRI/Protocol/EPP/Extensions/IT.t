#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 142;
use Test::Exception;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';  }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 0});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('IITCNR');
$dri->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c, $c1, $c2, $toc, $e, $ext_ns_validate, $ext_ds_validate);

####################################################################################################

### IDNs - .IT requires that the native IDN be used in domain commands. This section test that the automatic handling (conversion) works correctly.

## UTF8 encoding is normally done at transport level, so for these tests I have including manual encoding along the way. This needs to be tested properly against OT&E server.

# domain_check with non idn
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">test.it</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('test.it');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.it</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check standard build');
is($rc->is_success(),1,'domain_check standard is_success');
is($dri->get_info('action'),'check','domain_check standard get_info(action)');
is($dri->get_info('exist'),0,'domain_check standard get_info(exist)');
is($dri->get_info('exist','domain','test.it'),0,'domain_check standard get_info(exist) from cache');

# domain check idn using ace
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">tëst.it</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('xn--tst-jma.it');
utf8::encode($R1);
my $command = $E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>tëst.it</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2;
utf8::encode($command);
is($R1,$command,'domain_check ace build');
is($rc->is_success(),1,'domain_check ace is_success');
is($dri->get_info('action'),'check','domain_check ace get_info(action)');
is($dri->get_info('exist'),0,'domain_check ace get_info(exist)');
is($dri->get_info('name_idn'),'tëst.it','domain_check ace get_info(name_idn)');
is($dri->get_info('name_ace'),'xn--tst-jma.it','domain_check ace get_info(name_idn)');
is($dri->get_info('exist','domain','xn--tst-jma.it'),0,'domain_check ace get_info(exist) from cache');
is($dri->get_info('exist','domain','tëst.it'),0,'domain_check ace get_info(exist) from cache');

# domain check idn using native idn
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">tëst2.it</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('tëst2.it');
utf8::encode($R1);
$command = $E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>tëst2.it</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2;
utf8::encode($command);
is($R1,$command,'domain_check idn build');
is($rc->is_success(),1,'domain_check idn is_success');
is($dri->get_info('action'),'check','domain_check idn get_info(action)');
is($dri->get_info('exist'),0,'domain_check idn get_info(exist)');
is($dri->get_info('exist','domain','tëst2.it'),0,'domain_check idn get_info(exist) from cache');
is($dri->get_info('exist','domain','xn--tst2-lpa.it'),0,'domain_check idn get_info(exist) from cache');

# domain create remappedIdnData
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>ᾀᾀᾀᾀ.it</domain:name><domain:crDate>2013-10-16T16:52:24.013Z</domain:crDate><domain:exDate>2014-10-16T16:52:24.013Z</domain:exDate></domain:creData></resData><extension><extdom:remappedIdnData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0"><extdom:idnRequested>ἀιἀιἀιἀι.it</extdom:idnRequested><extdom:idnCreated>ᾀᾀᾀᾀ.it</extdom:idnCreated></extdom:remappedIdnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('ᾀᾀᾀᾀ.it',{pure_create=>1,auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>ᾀᾀᾀᾀ.it</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
is($dri->get_info('idn_requested'),'ἀιἀιἀιἀι.it','domain_create get_info (idn_requested)');
is($dri->get_info('idn_created'),'ᾀᾀᾀᾀ.it','domain_create get_info (idn_created)');

####################################################################################################

# domain info with inf_contacts
$R2 = $E1 . '<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>esempio.it</domain:name><domain:roid>ITNIC-162761</domain:roid><domain:status lang="en" s="ok" /><domain:registrant>MR0001</domain:registrant><domain:contact type="admin">MR0001</domain:contact><domain:contact type="tech">TECH001</domain:contact><domain:contact type="tech">TECH002</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.esempio.it</domain:hostName><domain:hostAddr ip="v4">193.205.245.6</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.esempio.it</domain:hostName><domain:hostAddr ip="v4">193.205.245.7</domain:hostAddr></domain:hostAttr></domain:ns><domain:host>ns1.esempio.it</domain:host><domain:host>ns2.esempio.it</domain:host><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2013-01-24T16:41:53.000+01:00</domain:crDate><domain:exDate>2014-01-24T16:41:53.000+01:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0"><extdom:infContactsData><extdom:registrant><extdom:infContact><contact:id>MR0001</contact:id><contact:roid>ITNIC-326982</contact:roid><contact:status lang="en" s="ok" /><contact:status lang="en" s="linked" /><contact:postalInfo type="loc"><contact:name>Mario Rossi</contact:name><contact:org>Mario Rossi</contact:org><contact:addr><contact:street>Via Moruzzi, 1</contact:street><contact:city>Pisa</contact:city><contact:sp>PI</contact:sp><contact:pc>56100</contact:pc><contact:cc>IT</contact:cc></contact:addr></contact:postalInfo><contact:voice x="">+39.050315111</contact:voice><contact:fax x="">+39.050315111</contact:fax><contact:email>mario.rossi@esempio.it</contact:email><contact:clID>DEMO-REG</contact:clID><contact:crID>DEMO-REG</contact:crID><contact:crDate>2013-01-24T16:41:53.000+01:00</contact:crDate></extdom:infContact><extdom:extInfo><extcon:consentForPublishing>true</extcon:consentForPublishing><extcon:registrant><extcon:nationalityCode>IT</extcon:nationalityCode><extcon:entityType>1</extcon:entityType><extcon:regCode>RSSMRA64C14G702Q</extcon:regCode></extcon:registrant></extdom:extInfo></extdom:registrant><extdom:contact type="admin"><extdom:infContact><contact:id>MR0001</contact:id><contact:roid>ITNIC-326982</contact:roid><contact:status lang="en" s="ok" /><contact:status lang="en" s="linked" /><contact:postalInfo type="loc"><contact:name>Mario Rossi</contact:name><contact:org>Mario Rossi</contact:org><contact:addr><contact:street>Via Moruzzi, 1</contact:street><contact:city>Pisa</contact:city><contact:sp>PI</contact:sp><contact:pc>56100</contact:pc><contact:cc>IT</contact:cc></contact:addr></contact:postalInfo><contact:voice x="">+39.050315111</contact:voice><contact:fax x="">+39.050315111</contact:fax><contact:email>mario.rossi@esempio.it</contact:email><contact:clID>DEMO-REG</contact:clID><contact:crID>DEMO-REG</contact:crID><contact:crDate>2013-01-24T16:41:53.000+01:00</contact:crDate></extdom:infContact><extdom:extInfo><extcon:consentForPublishing>true</extcon:consentForPublishing><extcon:registrant><extcon:nationalityCode>IT</extcon:nationalityCode><extcon:entityType>1</extcon:entityType><extcon:regCode>RSSMRA64C14G702Q</extcon:regCode></extcon:registrant></extdom:extInfo></extdom:contact><extdom:contact type="tech"><extdom:infContact><contact:id>TECH001</contact:id><contact:roid>ITNIC-326980</contact:roid><contact:status lang="en" s="ok" /><contact:status lang="en" s="linked" /><contact:postalInfo type="loc"><contact:name>Mirco Bartolini</contact:name><contact:org>Demo Registrar Srl</contact:org><contact:addr><contact:street>via 4 Novembre, 12</contact:street><contact:city>Barga</contact:city><contact:sp>LU</contact:sp><contact:pc>55052</contact:pc><contact:cc>IT</contact:cc></contact:addr></contact:postalInfo><contact:voice x="">+39.0583123456</contact:voice><contact:fax x="">+39.058375124</contact:fax><contact:email>mirco.bartolini@demoreg.it</contact:email><contact:clID>DEMO-REG</contact:clID><contact:crID>DEMO-REG</contact:crID><contact:crDate>2013-01-24T16:41:53.000+01:00</contact:crDate></extdom:infContact><extdom:extInfo><extcon:consentForPublishing>true</extcon:consentForPublishing></extdom:extInfo></extdom:contact><extdom:contact type="tech"><extdom:infContact><contact:id>TECH002</contact:id><contact:roid>ITNIC-326982</contact:roid><contact:status lang="en" s="ok" /><contact:status lang="en" s="linked" /><contact:postalInfo type="loc"><contact:name>Andrea Bianchi</contact:name><contact:org>Demo Registrar Srl</contact:org><contact:addr><contact:street>via 4 Novembre, 12</contact:street><contact:city>Barga</contact:city><contact:sp>LU</contact:sp><contact:pc>55052</contact:pc><contact:cc>IT</contact:cc></contact:addr></contact:postalInfo><contact:voice x="">+39.0583123458</contact:voice><contact:fax x="">+39.058375124</contact:fax><contact:email>andrea.bianchi@demoreg.it</contact:email><contact:clID>DEMO-REG</contact:clID><contact:crID>DEMO-REG</contact:crID><contact:crDate>2013-01-24T16:41:53.000+01:00</contact:crDate></extdom:infContact><extdom:extInfo><extcon:consentForPublishing>true</extcon:consentForPublishing></extdom:extInfo></extdom:contact></extdom:infContactsData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->domain_info('esempio.it', {'inf_contacts' => 'all'});
is_string($R1,$E1 . '<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">esempio.it</domain:name></domain:info></info><extension><extdom:infContacts op="all" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command>' . $E2,'domain_info build');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'esempio.it','domain_info get_info(name)');
my $cs = $dri->get_info('contact');
my $reg = $cs->get('registrant');
isa_ok($reg,'Net::DRI::Data::Contact::IT','domain_info get registrant');
is($reg->name(),'Mario Rossi','domain_info get registrant name');
my $reg2 = $dri->get_info('self','contact','MR0001');
is($reg2->name(),'Mario Rossi','domain_info get_info self/contact/srid registrant name');

# domain transfer+trade
$R2 = $E1 . '<response><result code="1000"><msg lang="en">Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;
$rc = $dri->domain_transfer_start('esempio.it', {'auth' => {'pw' => 'ABC321'}, 'new_registrant' => 'C123', 'new_authinfo' => 'ABC123'});
is_string($R1,$E1 . '<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name><domain:authInfo><domain:pw>ABC321</domain:pw></domain:authInfo></domain:transfer></transfer><extension><extdom:trade xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:transferTrade><extdom:newRegistrant>C123</extdom:newRegistrant><extdom:newAuthInfo><extdom:pw>ABC123</extdom:pw></extdom:newAuthInfo></extdom:transferTrade></extdom:trade></extension><clTRID>ABC-12345</clTRID></command>' . $E2,'domain_transfer_start build');

# contact info get additional elements
$R2 = $E1 . '<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>ABC-123</contact:id><contact:roid>ITNIC-3914315</contact:roid><contact:status lang="en" s="ok" /><contact:postalInfo type="loc"><contact:name>Andrew Fuller</contact:name><contact:org>ACME ltd.</contact:org><contact:addr><contact:street>12 London Rd</contact:street><contact:city>London</contact:city><contact:sp>London</contact:sp><contact:pc>W1X 1RF</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice x="">+44.207865654</contact:voice><contact:fax x="">+44.207865655</contact:fax><contact:email>andrewf@acme.com</contact:email><contact:clID>DEMO-REG</contact:clID><contact:crID>DEMO-REG</contact:crID><contact:crDate>2013-06-13T11:58:08.000+02:00</contact:crDate><contact:upID>DEMO-REG</contact:upID><contact:upDate>2013-06-13T11:58:07.000+02:00</contact:upDate></contact:infData></resData><extension xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0"><extcon:infData><extcon:consentForPublishing>true</extcon:consentForPublishing><extcon:registrant><extcon:nationalityCode>GB</extcon:nationalityCode><extcon:entityType>7</extcon:entityType><extcon:regCode>123123123</extcon:regCode></extcon:registrant></extcon:infData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('ABC-123'));
is_string($R1,$E1 . '<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>ABC-123</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>' . $E2,'contact_info build');
my $c = $dri->get_info('self');
is ($c->entity_type(),'7','contact_info get_info(entity_type)');

# extvalue parsing
$R2 = $E1 . '<response xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><result code="2302"><msg lang="en">Object exists</msg><value><extepp:wrongValue><extepp:element>id</extepp:element><extepp:namespace>urn:ietf:params:xml:ns:contact-1.0</extepp:namespace><extepp:value>ABC-124</extepp:value></extepp:wrongValue></value><extValue><value><extepp:reasonCode>8058</extepp:reasonCode></value><reason lang="en">Contact already exists</reason></extValue></result>' . $TRID . '</response>' . $E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('ABC-124'));
my ($r1,$r2) = ($rc->get_extended_results());
is ($r1->{message},'wrongValue ABC-124 for id','extValue get_info message 1');
is ($r2->{message},'Reasoncode 8058','extValue get_info message 1');


####################################################################################################
## Notifications

# password expiring
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="26" count="1"><qDate>2008-07-22T09:07:43+02:00</qDate><msg lang="en">Password will expire soon</msg></msgQ><extension xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extepp:passwdReminder><extepp:exDate>2008-07-30T12:28:42+02:00</extepp:exDate></extepp:passwdReminder></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),26,'password expiring message get_info(last_id)');
is($dri->get_info('action','message',26),'password_expiring','password expiring message get_info(action)');
is($dri->get_info('exDate','message',26),'2008-07-30T12:28:42','password expiring message get_info(action)');

# wrong namespace
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="26" count="1"><qDate>2012-04-12T10:00:42.000+02:00</qDate><msg lang="en">Wrong namespace in Login Request</msg></msgQ><extension xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extepp:wrongNamespaceReminder><extepp:wrongNamespaceInfo><extepp:wrongNamespace>http://www.nic.it/ITNIC-EPP/extepp-1.0</extepp:wrongNamespace><extepp:rightNamespace>http://www.nic.it/ITNIC-EPP/extepp-2.0</extepp:rightNamespace></extepp:wrongNamespaceInfo><extepp:wrongNamespaceInfo><extepp:wrongNamespace>http://www.nic.it/ITNIC-EPP/extdom-1.0</extepp:wrongNamespace><extepp:rightNamespace>http://www.nic.it/ITNIC-EPP/extdom-2.0</extepp:rightNamespace></extepp:wrongNamespaceInfo></extepp:wrongNamespaceReminder></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),26,'wrong namespace message get_info(last_id)');
is($dri->get_info('action','message',26),'wrong_namespace','wrong namespace message get_info(action)');
is_deeply($dri->get_info('wrong_namespace','message',26),['http://www.nic.it/ITNIC-EPP/extepp-1.0','http://www.nic.it/ITNIC-EPP/extdom-1.0'],'wrong namespace message get_info(wrong_namespace)');

# dns check failed
my ($test,$queries);
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="4" count="36"><qDate>2012-04-04T18:25:14.000+02:00</qDate><msg lang="en">DNS check ended unsuccessfully</msg></msgQ><extension xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:dnsErrorMsgData version="2.0"><extdom:domain>esempio.it</extdom:domain><extdom:status>FAILED</extdom:status><extdom:validationId>e7edc45c-7e38-4d98-bf40-96c9f604dec8</extdom:validationId><extdom:validationDate>2012-04-04T18:20:13.993+02:00</extdom:validationDate><extdom:nameservers><extdom:nameserver name="ns1.esempio.it."><extdom:address type="IPv4">192.12.192.23</extdom:address></extdom:nameserver><extdom:nameserver name="ns2.esempio.it."><extdom:address type="IPv4">192.12.192.24</extdom:address></extdom:nameserver></extdom:nameservers><extdom:tests><extdom:test status="SUCCEEDED" name="NameserversResolvableTest"><extdom:nameserver status="SUCCEEDED" name="ns1.esempio.it." /><extdom:nameserver status="SUCCEEDED" name="ns2.esempio.it." /></extdom:test><extdom:test status="FAILED" name="NameserversAnswerTest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="FAILED" name="NameserverReturnCodeTest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="FAILED" name="AATest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="FAILED" name="NSCompareTest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="FAILED" name="NSCountTest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="WARNING" name="CNAMEHostTest" /><extdom:test status="FAILED" name="IPCompareTest"><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail>Unresolveable ns1.esempio.it.</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail>Unresolveable ns2.esempio.it.</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="FAILED" name="MXCompareTest"><extdom:nameserver status="FAILED" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="FAILED" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="WARNING" name="MXRecordIsPresentTest"><extdom:nameserver status="WARNING" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="WARNING" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="WARNING" name="SOAMasterCompareTest"><extdom:nameserver status="WARNING" name="ns2.esempio.it."><extdom:detail queryId="2">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver><extdom:nameserver status="WARNING" name="ns1.esempio.it."><extdom:detail queryId="1">Nameserver test skipped for error in query: java.net.SocketTimeoutException</extdom:detail></extdom:nameserver></extdom:test><extdom:test skipped="true" name="IPSoaTest" /></extdom:tests><extdom:queries><extdom:query id="1"><extdom:queryFor>esempio.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>ns1.esempio.it./[IPAddress(address=/192.12.192.23, family=1)]</extdom:destination><extdom:result>java.net.SocketTimeoutException</extdom:result></extdom:query><extdom:query id="2"><extdom:queryFor>esempio.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>ns2.esempio.it./[IPAddress(address=/192.12.192.24, family=1)]</extdom:destination><extdom:result>java.net.SocketTimeoutException</extdom:result></extdom:query><extdom:query id="3"><extdom:queryFor>ns1.esempio.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>ns1.esempio.it./[IPAddress(address=/192.12.192.23, family=1)], ns2.esempio.it./[IPAddress(address=/192.12.192.24, family=1)]</extdom:destination><extdom:result>java.net.SocketTimeoutException</extdom:result></extdom:query><extdom:query id="4"><extdom:queryFor>ns2.esempio.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>ns1.esempio.it./[IPAddress(address=/192.12.192.23, family=1)], ns2.esempio.it./[IPAddress(address=/192.12.192.24, family=1)]</extdom:destination><extdom:result>java.net.SocketTimeoutException</extdom:result></extdom:query></extdom:queries></extdom:dnsErrorMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),4,'dns check failed message get_info(last_id)');
is($dri->get_info('action','message',4),'dns_error','dns check failed message get_info(action)');
is($dri->get_info('validation_id','message',4),'e7edc45c-7e38-4d98-bf40-96c9f604dec8','dns check failed message get_info(validation_id)');
$test = $dri->get_info('test','message',4);
$queries = $dri->get_info('queries','message',4);

# dns check success with warnings
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="4" count="12"><qDate>2013-06-19T11:36:31.000+02:00</qDate><msg lang="en">DNS check ended successfully with warning</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:dnsWarningMsgData><extdom:chgStatusMsgData><extdom:name>testdomain.it</extdom:name><extdom:targetStatus><domain:status lang="en" s="ok" /></extdom:targetStatus></extdom:chgStatusMsgData><extdom:dnsWarningData version="2.0"><extdom:domain>testdomain.it</extdom:domain><extdom:status>WARNING</extdom:status><extdom:validationId>0492cc0e-c1c8-4a44-9c2c-db9db64f4079</extdom:validationId><extdom:validationDate>2013-06-19T11:36:31.108+02:00</extdom:validationDate><extdom:nameservers><extdom:nameserver name="dns3.testservers.com."><extdom:address type="IPv4">123.123.3.2</extdom:address></extdom:nameserver><extdom:nameserver name="dns4.testservers.com."><extdom:address type="IPv4">123.123.3.3</extdom:address></extdom:nameserver></extdom:nameservers><extdom:tests><extdom:test status="SUCCEEDED" name="NameserversResolvableTest"><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NameserversAnswerTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NameserverReturnCodeTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="AATest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NSCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NSCountTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="CNAMEHostTest"><extdom:detail status="SUCCEEDED" name="dns4.testservers.com." /><extdom:detail status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test skipped="true" name="IPCompareTest" /><extdom:test status="SUCCEEDED" name="MXCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="WARNING" name="MXRecordIsPresentTest"><extdom:nameserver status="WARNING" name="dns4.testservers.com."><extdom:detail queryId="4">No MX Records found</extdom:detail></extdom:nameserver><extdom:nameserver status="WARNING" name="dns3.testservers.com."><extdom:detail queryId="3">No MX Records found</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="SUCCEEDED" name="SOAMasterCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test skipped="true" name="IPSoaTest" /></extdom:tests><extdom:queries><extdom:query id="1"><extdom:queryFor>dns3.testservers.com.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>local resolver</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="2"><extdom:queryFor>dns4.testservers.com.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>local resolver</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="3"><extdom:queryFor>testdomain.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>dns3.testservers.com./[IPAddress(address=/123.123.3.2, family=1)]</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="4"><extdom:queryFor>testdomain.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>dns4.testservers.com./[IPAddress(address=/123.123.3.3, family=1)]</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query></extdom:queries></extdom:dnsWarningData></extdom:dnsWarningMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),4,'dns check success message get_info(last_id)');
is($dri->get_info('action','message',4),'update','dns check success message get_info(action)');
is($dri->get_info('target_status','message',4),'ok','dns check success message get_info(target_status)');
$test = $dri->get_info('test','message',4);
$queries = $dri->get_info('queries','message',4);

# domain deleted
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack todequeue</msg></result><msgQ id="24" count="1"><qDate>2008-07-21T12:44:37+02:00</qDate><msg lang="en">Domain has been deleted</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:simpleMsgData><extdom:name>esempio.it</extdom:name></extdom:simpleMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),24,'domain deleted message get_info(last_id)');
is($dri->get_info('action','message',24),'delete','domain deleted message get_info(action)');
is($dri->get_info('name','message',24),'esempio.it','domain deleted message get_info(name)');

# redemtion started
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack todequeue</msg></result><msgQ id="84" count="1"><qDate>2008-08-04T18:57:45+02:00</qDate><msg lang="en">redemptionPeriod is started</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:chgStatusMsgData><extdom:name>esempio.it</extdom:name><extdom:targetStatus><domain:status lang="en" s="pendingDelete"/><rgp:rgpStatus lang="en" s="redemptionPeriod"/></extdom:targetStatus></extdom:chgStatusMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',84),'update','redemtion started message get_info(action)');
is($dri->get_info('name','message',84),'esempio.it','redemtion started message get_info(name)');
is($dri->get_info('target_status','message',84),'pendingDelete','redemtion started message get_info(target_status)');
is($dri->get_info('rgp_status','message',84),'redemptionPeriod','redemtion started message get_info(rgp_status)');

# lost delegation
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack todequeue</msg></result><msgQ id="24" count="1"><qDate>2008-07-21T12:50:57+02:00</qDate><msg lang="en">Lost delegation</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:dlgMsgData><extdom:name>dominio.it</extdom:name><extdom:ns>ns1.esempio.it</extdom:ns></extdom:dlgMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',24),'lost_delegation','lost delegation message get_info(action)');
is($dri->get_info('name','message',24),'dominio.it','lost delegation message get_info(name)');
is($dri->get_info('ns','message',24),'ns1.esempio.it','lost delegation message get_info(ns)');

# transfer requested (pending transfer)
$R2 = $E1 . '<response xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><result code="1301"><msg lang="en">Command completed successfully; ack todequeue</msg></result><msgQ id="33" count="1"><qDate>2008-07-29T10:19:16+02:00</qDate><msg lang="en">Domain transfer has been requested:pendingTransfer is started</msg></msgQ><resData><domain:trnData><domain:name>esempio.it</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>NEW-REGISTRAR</domain:reID><domain:reDate>2008-07-29T10:19:16+02:00</domain:reDate><domain:acID>DEMO-REGISTRAR</domain:acID><domain:acDate>2008-08-03T23:59:59+02:00</domain:acDate></domain:trnData></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',33),'transfer','transfer requested message get_info(action)');
is($dri->get_info('name','message',33),'esempio.it','transfer requested message get_info(name)');
is($dri->get_info('name_ace','message',33),'esempio.it','transfer requested message get_info(name_ace)');
is($dri->get_info('name_idn','message',33),'esempio.it','transfer requested message get_info(name_ace)');

# idn transfer requested (pending transfer)
$R2 = $E1 . '<response xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><result code="1301"><msg lang="en">Command completed successfully; ack todequeue</msg></result><msgQ id="33" count="1"><qDate>2008-07-29T10:19:16+02:00</qDate><msg lang="en">Domain transfer has been requested:pendingTransfer is started</msg></msgQ><resData><domain:trnData><domain:name>øsempio.it</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>NEW-REGISTRAR</domain:reID><domain:reDate>2008-07-29T10:19:16+02:00</domain:reDate><domain:acID>DEMO-REGISTRAR</domain:acID><domain:acDate>2008-08-03T23:59:59+02:00</domain:acDate></domain:trnData></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',33),'transfer','transfer requested idn message get_info(action)');
is($dri->get_info('name','message',33),'øsempio.it','transfer requested idn message get_info(name)');
is($dri->get_info('trStatus','message',33),'pending','transfer requested idn message get_info(name)');
is($dri->get_info('name_ace','message',33),'xn--sempio-9xa.it','transfer requested idn message get_info(name_ace)');
is($dri->get_info('name_idn','message',33),'øsempio.it','transfer requested idn message get_info(name_ace)');

# refund renew
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="71" count="129"><qDate>2013-06-26T01:15:03.000+02:00</qDate><msg lang="en">Refund renew for deleting domain in autoRenewPeriod</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:delayedDebitAndRefundMsgData><extdom:name>esempio.it</extdom:name> <extdom:debitDate>2013-06-13T01:06:07.000+02:00</extdom:debitDate><extdom:amount>4.000</extdom:amount></extdom:delayedDebitAndRefundMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',71),'refund','refund renew message get_info(action)');
is($dri->get_info('debitDate','message',71),'2013-06-13T01:06:07','refund renew message get_info(debitDate)');
is($dri->get_info('amount','message',71),'4.000','refund renew message get_info(amount)');

# low balance
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="26" count="1"><qDate>2013-07-03T03:00:00.000+02:00</qDate><msg lang="en">Credit is under the threshold set by the registrar</msg></msgQ><extension xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extepp:creditMsgData><extepp:credit>999.000</extepp:credit></extepp:creditMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',26),'low_balance','low balance message get_info(action)');
is($dri->get_info('credit','message',26),'999.000','low balance message get_info(credit)');

# idn_remapped - Requested IDN domain contains remapped chars
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="92" count="1"><qDate>2013-07-03T03:00:00.000+02:00</qDate><msg lang="en">Requested IDN domain contains remapped chars</msg></msgQ><extension><extdom:remappedIdnData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0"><extdom:idnRequested>ἀιἀιἀιἀι.it</extdom:idnRequested><extdom:idnCreated>ᾀᾀᾀᾀ.it</extdom:idnCreated></extdom:remappedIdnData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('action','message',92),'idn_remapped','idn remapped message get_info(action)');
is($dri->get_info('idn_requested','message',92),'ἀιἀιἀιἀι.it','idn remapped message get_info (idn_requested)');
is($dri->get_info('idn_created','message',92),'ᾀᾀᾀᾀ.it','idn remapped message get_info (idn_created)');


# tests based on: DNSSEC in the ccTLD-IT-ENG.pdf (Last update: August 1, 2017)
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 0});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('IITCNR');
$dri->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv},{ custom => { secdns_accredited => 1 } });

# force secDNS-1.1
$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.nic.it/ITNIC-EPP/extcon-2.0</extURI>http://www.nic.it/ITNIC-EPP/extdom-2.0<extURI></extURI><extURI>http://www.nic.it/ITNIC-EPP/extsecDNS-1.0</extURI><extURI>http://www.nic.it/ITNIC-EPP/extepp-2.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1 only');

# domain create with dnssec
$R2='';
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('mm001');
$c2=$dri->local_object('contact')->srid('mb001');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('esempio.it',{
        pure_create=>1,
        duration=>DateTime::Duration->new(years=>1),
        ns=>$dri->local_object('hosts')->set(['x.dns.it'],['y.dns.it']),
        contact=>$cs,
        auth=>{pw=>'22fooBAR'},
        secdns=>[
            {
                keyTag=>'12345',
                alg=>3,
                digestType=>1,
                digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'
            }
        ]
    });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>x.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>y.dns.it</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>mm001</domain:registrant><domain:contact type="admin">mm001</domain:contact><domain:contact type="tech">mb001</domain:contact><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create SecDNS build');

# domain update with dnssec
$R2='';
$toc=$dri->local_object('changes');
$toc->del('secdns',[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'}]);
$toc->add('secdns',[{keyTag=>'45063',alg=>3,digestType=>2,digest=>'E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43'}]);
$rc=$dri->domain_update('esempio.it',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:rem><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></secDNS:rem><secDNS:add><secDNS:dsData><secDNS:keyTag>45063</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update SecDNS build');

# domain update - example how to remove ALL DS records associated to a domain object
$R2='';
$toc=$dri->local_object('changes');
$toc->del('secdns','all');
$rc=$dri->domain_update('esempio.it',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:rem><secDNS:all>true</secDNS:all></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update SecDNS build (remove ALL)');

# domain info - of a “signed” domain name that has been registered but not validated by the DNS check service, and which therefore is in inactive/dnsHold status, has the following XML format <extsecDNS:infDsOrKeyToValidateData>
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name><domain:roid>ITNIC-306194</domain:roid><domain:status s="inactive" lang="en"/><domain:registrant>MM001</domain:registrant><domain:contact type="admin">MM001</domain:contact><domain:contact type="tech">MB001</domain:contact><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2016-06-29T08:26:44.000+02:00</domain:crDate><domain:exDate>2017-06-29T23:59:59.000+02:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><extdom:infData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:ownStatus s="dnsHold" lang="en"/></extdom:infData><extdom:infNsToValidateData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:nsToValidate><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>m.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>j.dns.it</domain:hostName></domain:hostAttr></extdom:nsToValidate></extdom:infNsToValidateData><extsecDNS:infDsOrKeyToValidateData xmlns:extsecDNS="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0 extsecDNS-1.0.xsd"><extsecDNS:dsOrKeysToValidate><secDNS:dsData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></extsecDNS:dsOrKeysToValidate></extsecDNS:infDsOrKeyToValidateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('esenpio.it');
$ext_ds_validate=$dri->get_info('ds_or_keys_to_validate');
is_deeply($ext_ds_validate,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'}],'domain_info get_info(extsecDNS) extsecDNS');

# domain info - of a “signed” domain name that has been registered but not validated by the DNS check service, and which therefore is in inactive/dnsHold status, has the following XML format <extsecDNS:infDsOrKeyToValidateData>
# with multiple dsData (example not in documentation but added just in case it happens!)
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esempio.it</domain:name><domain:roid>ITNIC-306194</domain:roid><domain:status s="inactive" lang="en"/><domain:registrant>MM001</domain:registrant><domain:contact type="admin">MM001</domain:contact><domain:contact type="tech">MB001</domain:contact><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2016-06-29T08:26:44.000+02:00</domain:crDate><domain:exDate>2017-06-29T23:59:59.000+02:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><extdom:infData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:ownStatus s="dnsHold" lang="en"/></extdom:infData><extdom:infNsToValidateData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:nsToValidate><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>m.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>j.dns.it</domain:hostName></domain:hostAttr></extdom:nsToValidate></extdom:infNsToValidateData><extsecDNS:infDsOrKeyToValidateData xmlns:extsecDNS="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0 extsecDNS-1.0.xsd"><extsecDNS:dsOrKeysToValidate><secDNS:dsData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData><secDNS:dsData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyTag>45063</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43</secDNS:digest></secDNS:dsData></extsecDNS:dsOrKeysToValidate></extsecDNS:infDsOrKeyToValidateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('esenpio.it');
$ext_ns_validate=$dri->get_info('ns_to_validate');
is_deeply($ext_ns_validate,['m.dns.it','j.dns.it'],'domain_info get_info(ns_to_validate)');
$ext_ds_validate=$dri->get_info('ds_or_keys_to_validate');
is_deeply($ext_ds_validate,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'},{keyTag=>'45063',alg=>3,digestType=>2,digest=>'E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43'}],'domain_info get_info(extsecDNS) extsecDNS multi dsData');

# domain info - if validation is successful
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esenpio.it</domain:name><domain:roid>ITNIC-306194</domain:roid><domain:status s="ok" lang="en"/><domain:registrant>MM001</domain:registrant><domain:contact type="admin">MM001</domain:contact><domain:contact type="tech">MB001</domain:contact><domain:ns><domain:hostAttr><domain:hostName>m.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>j.dns.it</domain:hostName></domain:hostAttr></domain:ns><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2016-06-29T08:26:44.000+02:00</domain:crDate><domain:upID>DEMO-REG</domain:upID><domain:upDate>2016-06-29T08:26:45.000+02:00</domain:upDate><domain:exDate>2017-06-29T23:59:59.000+02:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('esenpio.it');
is($dri->get_info('exist'),1,'domain_info get_info(exist) SecDNS');
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'}],'domain_info get_info(secdns) SecDNS');

# domain info - for which authoritative name servers and DS records update were requested
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esenpio2.it</domain:name><domain:roid>ITNIC-306194</domain:roid><domain:status s="pendingUpdate" lang="en"/><domain:registrant>MM001</domain:registrant><domain:contact type="admin">MM001</domain:contact><domain:contact type="tech">MB001</domain:contact><domain:ns><domain:hostAttr><domain:hostName>m.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>j.dns.it</domain:hostName></domain:hostAttr></domain:ns><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2016-06-29T08:26:44.000+02:00</domain:crDate><domain:upID>DEMO-REG</domain:upID><domain:upDate>2016-06-29T08:26:45.000+02:00</domain:upDate><domain:exDate>2017-06-29T23:59:59.000+02:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><extdom:infNsToValidateData xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extdom-2.0 extdom-2.0.xsd"><extdom:nsToValidate><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>n.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:hostName>k.dns.it</domain:hostName></domain:hostAttr></extdom:nsToValidate></extdom:infNsToValidateData><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></secDNS:infData><extsecDNS:infDsOrKeyToValidateData xmlns:extsecDNS="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0 extsecDNS-1.0.xsd"><extsecDNS:dsOrKeysToValidate><secDNS:dsData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyTag>45063</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43</secDNS:digest></secDNS:dsData></extsecDNS:dsOrKeysToValidate></extsecDNS:infDsOrKeyToValidateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('esenpio2.it');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'ITNIC-306194','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['pendingUpdate'],'domain_info get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'MM001','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'MM001','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'MB001','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['m.dns.it','j.dns.it'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'DEMO-REG','domain_info get_info(clID)');
is($dri->get_info('crID'),'DEMO-REG','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2016-06-29T08:26:44','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'DEMO-REG','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2016-06-29T08:26:45','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2017-06-29T23:59:59','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'22fooBAR'},'domain_info get_info(auth)');
# <extdom:infNsToValidateData>
$ext_ns_validate=$dri->get_info('ns_to_validate');
is_deeply($ext_ns_validate,['n.dns.it','k.dns.it'],'domain_info get_info(ns_to_validate)');
# <secDNS:infData>
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'}],'domain_info get_info(secdns) SecDNS');
# <extsecDNS:infDsOrKeyToValidateData>
$ext_ds_validate=$dri->get_info('ds_or_keys_to_validate');
is_deeply($ext_ds_validate,[{keyTag=>'45063',alg=>3,digestType=>2,digest=>'E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43'}],'domain_info get_info(extsecDNS) extsecDNS dsData');

# domain info - for a domain which removal of ALL DS records has been requested
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>esenpio3.it</domain:name><domain:roid>ITNIC-306194</domain:roid><domain:status s="pendingUpdate" lang="en"/><domain:registrant>MM001</domain:registrant><domain:contact type="admin">MM001</domain:contact><domain:contact type="tech">MB001</domain:contact><domain:ns><domain:hostAttr><domain:hostName>m.dns.it</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>j.dns.it</domain:hostName></domain:hostAttr></domain:ns><domain:clID>DEMO-REG</domain:clID><domain:crID>DEMO-REG</domain:crID><domain:crDate>2016-06-29T08:26:44.000+02:00</domain:crDate><domain:upID>DEMO-REG</domain:upID><domain:upDate>2016-06-29T08:26:45.000+02:00</domain:upDate><domain:exDate>2017-06-29T23:59:59.000+02:00</domain:exDate><domain:authInfo><domain:pw>22fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>4347d0f8ba661234a8eadc005e2e1d1b646c9682</secDNS:digest></secDNS:dsData></secDNS:infData><extsecDNS:infDsOrKeyToValidateData xmlns:extsecDNS="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0" xsi:schemaLocation="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0 extsecDNS-1.0.xsd"><extsecDNS:remAll/></extsecDNS:infDsOrKeyToValidateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('esenpio3.it');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'ITNIC-306194','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['pendingUpdate'],'domain_info get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'MM001','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'MM001','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'MB001','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['m.dns.it','j.dns.it'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'DEMO-REG','domain_info get_info(clID)');
is($dri->get_info('crID'),'DEMO-REG','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2016-06-29T08:26:44','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'DEMO-REG','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2016-06-29T08:26:45','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2017-06-29T23:59:59','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'22fooBAR'},'domain_info get_info(auth)');
# <secDNS:infData>
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'12345',alg=>3,digestType=>1,digest=>'4347d0f8ba661234a8eadc005e2e1d1b646c9682'}],'domain_info get_info(secdns) SecDNS');
# <extsecDNS:infDsOrKeyToValidateData>
$ext_ds_validate=$dri->get_info('ds_or_keys_to_validate');
is_deeply($ext_ds_validate,{remAll=>'remAll'},'domain_info get_info(extsecDNS) extsecDNS remAll');

# epp poll - dns check wit extsecdns ended unsuccessfully
my $extdomsecpoll = <<'EOF';
  <response>
    <result code="1301">
      <msg lang="en">Command completed successfully; ack to dequeue</msg>
    </result>
    <msgQ count="1" id="6369665">
      <qDate>2019-02-07T17:55:15.000+01:00</qDate>
      <msg lang="en">DNS check ended unsuccessfully</msg>
    </msgQ>
    <extension xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0" xmlns:extsecDNS="http://www.nic.it/ITNIC-EPP/extsecDNS-1.0" xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
      <extdom:dnsErrorMsgData version="2.1">
        <extdom:domain>esenpio-extsecdns-poll-fail.it</extdom:domain>
        <extdom:status>FAILED</extdom:status>
        <extdom:validationId>cd84a3c4-1e50-4d74-aac6-1ee1183d811d</extdom:validationId>
        <extdom:validationDate>2019-02-07T17:55:14.695+01:00</extdom:validationDate>
        <extdom:nameservers>
          <extdom:nameserver name="x.dns.it">
            <extdom:address type="IPv4">192.12.192.23</extdom:address>
          </extdom:nameserver>
          <extdom:nameserver name="y.dns.it">
            <extdom:address type="IPv4">192.12.192.24</extdom:address>
          </extdom:nameserver>
        </extdom:nameservers>
        <extdom:tests>
          <extdom:test name="NameserversResolvableTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="IPCompareTest" skipped="true"/>
          <extdom:test name="SOAQueryAnswerTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="SOAMasterCompareTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="IPSoaTest" skipped="true"/>
          <extdom:test name="NSQueryAnswerTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="NSCompareTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="NSCountTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
tests            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="MXQueryAnswerTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="MXCompareTest" status="SUCCEEDED">
            <extdom:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extdom:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extdom:test>
          <extdom:test name="MXRecordIsPresentTest" status="WARNING">
            <extdom:nameserver name="x.dns.it" status="WARNING">
              <extdom:detail queryId="13">No MX Records found</extdom:detail>
            </extdom:nameserver>
            <extdom:nameserver name="y.dns.it" status="WARNING">
              <extdom:detail queryId="14">No MX Records found</extdom:detail>
            </extdom:nameserver>
tests          </extdom:test>
          <extdom:test name="CNAMEHostTest" status="SUCCEEDED">
            <extdom:detail name="x.dns.it" status="SUCCEEDED">
      </extdom:detail>
            <extdom:detail name="y.dns.it" status="SUCCEEDED">
      </extdom:detail>
          </extdom:test>
        </extdom:tests>
        <extdom:queries>
          <extdom:query id="1">
            <extdom:queryFor>x.dns.it</extdom:queryFor>
            <extdom:type>A</extdom:type>
            <extdom:destination>local resolver</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 36016
       ;; flags: qr rd ra ; qd: 1 an: 1 au: 3 ad: 2
       ;; QUESTIONS:
       ;;	x.dns.it, type = A, class = IN
       ;; ANSWERS:
       x.dns.it	30960	IN	A	192.12.192.23
       ;; Message size: 163 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="2">
            <extdom:queryFor>x.dns.it</extdom:queryFor>
            <extdom:type>AAAA</extdom:type>
            <extdom:destination>local resolver</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 16166
       ;; flags: qr rd ra ; qd: 1 an: 0 au: 1 ad: 0
       ;; QUESTIONS:
       ;;	x.dns.it, type = AAAA, class = IN
       ;; ANSWERS:
       ;; Message size: 97 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="3">
            <extdom:queryFor>y.dns.it</extdom:queryFor>
            <extdom:type>A</extdom:type>
            <extdom:destination>local resolver</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 3993
       ;; flags: qr rd ra ; qd: 1 an: 1 au: 3 ad: 2
       ;; QUESTIONS:
       ;;	y.dns.it, type = A, class = IN
       ;; ANSWERS:
       y.dns.it	261	IN	A	192.12.192.24
       ;; Message size: 163 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="4">
            <extdom:queryFor>y.dns.it</extdom:queryFor>
            <extdom:type>AAAA</extdom:type>
            <extdom:destination>local resolver</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 41179
       ;; flags: qr rd ra ; qd: 1 an: 0 au: 1 ad: 0
       ;; QUESTIONS:
       ;;	y.dns.it, type = AAAA, class = IN
       ;; ANSWERS:
       ;; Message size: 94 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="7"><extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor><extdom:type>SOA</extdom:type><extdom:destination>x.dns.it/[192.12.192.23]</extdom:destination>4
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 12860
       ;; flags: qr aa ; qd: 1 an: 1 au: 3 ad: 4
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = SOA, class = IN
       ;; ANSWERS:
       esempio-poll-extsecdns.it	86400	IN	SOA	x.dns.it hostmaster.foobar.com. 2019020702 86400 7200 2419200 3600
       ;; Message size: 268 bytes
      </extdom:result></extdom:query>
          <extdom:query id="8">
            <extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor>
            <extdom:type>SOA</extdom:type>
            <extdom:destination>y.dns.it/[192.12.192.24]</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 37985
       ;; flags: qr aa ; qd: 1 an: 1 au: 3 ad: 4
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = SOA, class = IN
       ;; ANSWERS:
tests       esempio-poll-extsecdns.it	86400	IN	SOA	x.dns.it hostmaster.foobar.com. 2019020702 86400 7200 2419200 3600
       ;; Message size: 268 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="10">
            <extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor>
            <extdom:type>NS</extdom:type>
            <extdom:destination>x.dns.it/[192.12.192.23]</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 42974
       ;; flags: qr aa ; qd: 1 an: 3 au: 0 ad: 4
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = NS, class = IN
       ;; ANSWERS:
       esempio-poll-extsecdns.it	86400	IN	NS	x.dns.it
       esempio-poll-extsecdns.it	86400	IN	NS	y.dns.it
       ;; Message size: 209 bytes
tests      </extdom:result>
          </extdom:query>
          <extdom:query id="11">
            <extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor>
            <extdom:type>NS</extdom:type>
            <extdom:destination>y.dns.it/[192.12.192.24]</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 12413
       ;; flags: qr aa ; qd: 1 an: 3 au: 0 ad: 4
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = NS, class = IN
       ;; ANSWERS:
       esempio-poll-extsecdns.it	86400	IN	NS	y.dns.it
       esempio-poll-extsecdns.it	86400	IN	NS	x.dns.it
       ;; Message size: 209 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="13">
            <extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor>
            <extdom:type>MX</extdom:type>
            <extdom:destination>x.dns.it/[192.12.192.23]</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 40625
       ;; flags: qr aa ; qd: 1 an: 0 au: 1 ad: 1
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = MX, class = IN
       ;; ANSWERS:
       ;; Message size: 143 bytes
      </extdom:result>
          </extdom:query>
          <extdom:query id="14">
            <extdom:queryFor>esempio-poll-extsecdns.it</extdom:queryFor>
            <extdom:type>MX</extdom:type>
            <extdom:destination>y.dns.it/[192.12.192.24]</extdom:destination>
            <extdom:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 13527
       ;; flags: qr aa ; qd: 1 an: 0 au: 1 ad: 1
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = MX, class = IN
       ;; ANSWERS:
       ;; Message size: 143 bytes
      </extdom:result>
          </extdom:query>
        </extdom:queries>
      </extdom:dnsErrorMsgData>
      <extsecDNS:secDnsErrorMsgData>
        <extsecDNS:dsOrKeys>
          <secDNS:dsData>
            <secDNS:keyTag>45063</secDNS:keyTag>
            <secDNS:alg>3</secDNS:alg>
            <secDNS:digestType>2</secDNS:digestType>
            <secDNS:digest>E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43</secDNS:digest>
          </secDNS:dsData>
        </extsecDNS:dsOrKeys>
        <extsecDNS:tests>
          <extsecDNS:test name="DNSKEYQueryAnswerTest" status="SUCCEEDED">
            <extsecDNS:nameserver name="x.dns.it" status="SUCCEEDED"/>
            <extsecDNS:nameserver name="y.dns.it" status="SUCCEEDED"/>
          </extsecDNS:test>
          <extsecDNS:test name="DSRecordValidationTest" status="FAILED">
            <extsecDNS:nameserver name="x.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="16">Cannot find DNSKey records for KSK</extsecDNS:detail>
            </extsecDNS:nameserver>
            <extsecDNS:nameserver name="y.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="17">Cannot find DNSKey records for KSK</extsecDNS:detail>
            </extsecDNS:nameserver>
          </extsecDNS:test>
          <extsecDNS:test name="DNSKEYSignatureValidationTest" status="FAILED">
            <extsecDNS:nameserver name="x.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="16">DNSKEY record set is empty</extsecDNS:detail>
            </extsecDNS:nameserver>
            <extsecDNS:nameserver name="y.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="17">DNSKEY record set is empty</extsecDNS:detail>
            </extsecDNS:nameserver>
          </extsecDNS:test>
          <extsecDNS:test name="SOASignatureValidationTest" status="FAILED">
            <extsecDNS:nameserver name="x.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="7">Cannot find RRSIG record for SOA record set </extsecDNS:detail>
            </extsecDNS:nameserver>
            <extsecDNS:nameserver name="y.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="8">Cannot find RRSIG record for SOA record set </extsecDNS:detail>
            </extsecDNS:nameserver>
          </extsecDNS:test>
          <extsecDNS:test name="NSSignatureValidationTest" status="FAILED">
            <extsecDNS:nameserver name="x.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="10">Cannot find RRSIG record for NS record set </extsecDNS:detail>
            </extsecDNS:nameserver>
            <extsecDNS:nameserver name="y.dns.it" status="FAILED">
              <extsecDNS:detail status="FAILED" queryId="11">Cannot find RRSIG record for NS record set </extsecDNS:detail>
            </extsecDNS:nameserver>
          </extsecDNS:test>
        </extsecDNS:tests>
        <extsecDNS:queries>
          <extsecDNS:query id="16">
            <extsecDNS:queryFor>esempio-poll-extsecdns.it</extsecDNS:queryFor>
            <extsecDNS:type>DNSKEY</extsecDNS:type>
            <extsecDNS:destination>x.dns.it/[192.12.192.23]</extsecDNS:destination>
$test            <extsecDNS:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 21848
       ;; flags: qr aa ; qd: 1 an: 0 au: 1 ad: 1
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = DNSKEY, class = IN
       ;; ANSWERS:
       ;; Message size: 143 bytes
      </extsecDNS:result>
          </extsecDNS:query>
          <extsecDNS:query id="17">
            <extsecDNS:queryFor>esempio-poll-extsecdns.it</extsecDNS:queryFor>
            <extsecDNS:type>DNSKEY</extsecDNS:type>
            <extsecDNS:destination>y.dns.it/[192.12.192.24]</extsecDNS:destination>
            <extsecDNS:result>
       ;; - HEADER - opcode: QUERY, status: NOERROR, id: 12740
$test       ;; flags: qr aa ; qd: 1 an: 0 au: 1 ad: 1
       ;; QUESTIONS:
       ;;	esempio-poll-extsecdns.it, type = DNSKEY, class = IN
       ;; ANSWERS:
       ;; Message size: 143 bytes
      </extsecDNS:result>
          </extsecDNS:query>
        </extsecDNS:queries>
      </extsecDNS:secDnsErrorMsgData>
    </extension>
EOF
chomp $extdomsecpoll;
my ($extsecdns_dsokeys, $extsecdns_tests, $extsecdns_queries);
$R2=$E1 . "$extdomsecpoll" . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),6369665,'dns check with extsecdns failed message');
is($dri->get_info('action','message',6369665),'dns_error','dns check with extsecdns failed message get_info(action)');
is($dri->get_info('validation_id','message',6369665),'cd84a3c4-1e50-4d74-aac6-1ee1183d811d','dns check with extsecdns failed message get_info(validation_id)');
is($dri->get_info('validation_date','message',6369665),'2019-02-07T17:55:14.695+01:00','dns check with extsecdns failed message get_info(validation_date)');
$extsecdns_dsokeys = $dri->get_info('extsecdns','message',6369665)->{'dsorkeys'};
is_deeply($extsecdns_dsokeys,[{keyTag=>'45063',alg=>3,digestType=>2,digest=>'E9B696C3AC8644735BF0A6409BE6D77BBFB4142D667E0EB0D41AD75BCC9D0D43'}],'dns check with extsecdns failed message get_info(extsecdns - dsOrKeys)');
$extsecdns_tests = $dri->get_info('extsecdns','message',6369665)->{'tests'};
is($extsecdns_tests->{'DNSKEYQueryAnswerTest'}->{'status'}, 'SUCCEEDED','dns check with extsecdns failed message get_info(extsecdns - tests DNSKEYQueryAnswerTest status');
is_deeply($extsecdns_tests->{'DNSKEYQueryAnswerTest'}->{'dns'}, {'y.dns.it' => 'SUCCEEDED', 'x.dns.it' => 'SUCCEEDED'},'dns check with extsecdns failed message get_info(extsecdns - tests DNSKEYQueryAnswerTest dns');
$extsecdns_queries = $dri->get_info('extsecdns','message',6369665)->{'queries'};
is($extsecdns_queries->{'17'}->{'queryFor'}, 'esempio-poll-extsecdns.it','dns check with extsecdns failed message get_info(extsecdns - query 17 queryFor value');
is($extsecdns_queries->{'17'}->{'destination'}, "y.dns.it/[192.12.192.24]",'dns check with extsecdns failed message get_info(extsecdns - query 17 destination value');
is($extsecdns_queries->{'16'}->{'destination'}, "x.dns.it/[192.12.192.23]",'dns check with extsecdns failed message get_info(extsecdns - query 16 destination value');

exit 0;