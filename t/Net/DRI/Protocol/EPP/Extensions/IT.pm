#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 74;
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
$dri->add_registry('IT');
$dri->target('IT')->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c);

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
#print Dumper $test;
#print Dumper $queries;

# dns check success with warnings
$R2 = $E1 . '<response><result code="1301"><msg lang="en">Command completed successfully; ack to dequeue</msg></result><msgQ id="4" count="12"><qDate>2013-06-19T11:36:31.000+02:00</qDate><msg lang="en">DNS check ended successfully with warning</msg></msgQ><extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0"><extdom:dnsWarningMsgData><extdom:chgStatusMsgData><extdom:name>testdomain.it</extdom:name><extdom:targetStatus><domain:status lang="en" s="ok" /></extdom:targetStatus></extdom:chgStatusMsgData><extdom:dnsWarningData version="2.0"><extdom:domain>testdomain.it</extdom:domain><extdom:status>WARNING</extdom:status><extdom:validationId>0492cc0e-c1c8-4a44-9c2c-db9db64f4079</extdom:validationId><extdom:validationDate>2013-06-19T11:36:31.108+02:00</extdom:validationDate><extdom:nameservers><extdom:nameserver name="dns3.testservers.com."><extdom:address type="IPv4">123.123.3.2</extdom:address></extdom:nameserver><extdom:nameserver name="dns4.testservers.com."><extdom:address type="IPv4">123.123.3.3</extdom:address></extdom:nameserver></extdom:nameservers><extdom:tests><extdom:test status="SUCCEEDED" name="NameserversResolvableTest"><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NameserversAnswerTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NameserverReturnCodeTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="AATest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NSCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="NSCountTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="SUCCEEDED" name="CNAMEHostTest"><extdom:detail status="SUCCEEDED" name="dns4.testservers.com." /><extdom:detail status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test skipped="true" name="IPCompareTest" /><extdom:test status="SUCCEEDED" name="MXCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test status="WARNING" name="MXRecordIsPresentTest"><extdom:nameserver status="WARNING" name="dns4.testservers.com."><extdom:detail queryId="4">No MX Records found</extdom:detail></extdom:nameserver><extdom:nameserver status="WARNING" name="dns3.testservers.com."><extdom:detail queryId="3">No MX Records found</extdom:detail></extdom:nameserver></extdom:test><extdom:test status="SUCCEEDED" name="SOAMasterCompareTest"><extdom:nameserver status="SUCCEEDED" name="dns4.testservers.com." /><extdom:nameserver status="SUCCEEDED" name="dns3.testservers.com." /></extdom:test><extdom:test skipped="true" name="IPSoaTest" /></extdom:tests><extdom:queries><extdom:query id="1"><extdom:queryFor>dns3.testservers.com.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>local resolver</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="2"><extdom:queryFor>dns4.testservers.com.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>local resolver</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="3"><extdom:queryFor>testdomain.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>dns3.testservers.com./[IPAddress(address=/123.123.3.2, family=1)]</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query><extdom:query id="4"><extdom:queryFor>testdomain.it.</extdom:queryFor><extdom:type>ANY</extdom:type><extdom:destination>dns4.testservers.com./[IPAddress(address=/123.123.3.3, family=1)]</extdom:destination><extdom:result>SNIP</extdom:result></extdom:query></extdom:queries></extdom:dnsWarningData></extdom:dnsWarningMsgData></extension>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($dri->get_info('last_id'),4,'dns check success message get_info(last_id)');
is($dri->get_info('action','message',4),'update','dns check success message get_info(action)');
is($dri->get_info('target_status','message',4),'ok','dns check success message get_info(target_status)');
$test = $dri->get_info('test','message',4);
$queries = $dri->get_info('queries','message',4);
#print Dumper $test;
#print Dumper $queries;

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
exit 0;

#<extension xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0">
#  xmlns:extepp="http://www.nic.it/ITNIC-EPP/extepp-2.0" xmlns:extdom="http://www.nic.it/ITNIC-EPP/extdom-2.0" xmlns:extcon="http://www.nic.it/ITNIC-EPP/extcon-1.0"