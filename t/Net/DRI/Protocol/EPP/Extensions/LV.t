#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 83;

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
$dri->add_registry('LVRegistry');
$dri->target('LVRegistry')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->driver();
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::LV',{}],'LV - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
####### Contact Commands ########

### 1.0 Contact Create /w Extension
$co=$dri->local_object('contact')->srid('josh-12647');
$co->name('James Black');
$co->org('Shark \'n\' Hammer, SIA');
$co->street(['Neverending st.1111']);
$co->city('Rīga');
$co->pc('LV-2000');
$co->cc('LV');
$co->voice('+371.12345678');
$co->fax('+371.87654321');
$co->email('ghepardhus@snailmail.lv');
$co->vat('LV12345678901'); # VAT Number of the legal entity
$co->orgno('12345678901'); # 'Personal ID' number of the legal entity
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>josh-12647</contact:id><contact:postalInfo type="loc"><contact:name>James Black</contact:name><contact:org>Shark \'n\' Hammer, SIA</contact:org><contact:addr><contact:street>Neverending st.1111</contact:street><contact:city>Rīga</contact:city><contact:pc>LV-2000</contact:pc><contact:cc>LV</contact:cc></contact:addr></contact:postalInfo><contact:voice>+371.12345678</contact:voice><contact:fax>+371.87654321</contact:fax><contact:email>ghepardhus@snailmail.lv</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><lvcontact:create xmlns:lvcontact="http://www.nic.lv/epp/schema/lvcontact-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvcontact-ext-1.0 lvcontact-ext-1.0.xsd"><lvcontact:vatNr>LV12345678901</lvcontact:vatNr><lvcontact:regNr>12345678901</lvcontact:regNr></lvcontact:create></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');

### 1.1 Contact Update /w Extension
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013');
my $toc=$dri->local_object('changes');
my $co2=$dri->local_object('contact');
$co2->name('Example Latvia Name');
$co2->street(['Example Street 1','Example Street 2']);
$co2->city('Example Latvia City');
$co2->pc('012345');
$co2->cc('LV');
$co2->voice('+52.0123456789');
$co2->email('example@example.lv');
$co->vat('LV12345678901'); # VAT Number of the legal entity
$co->orgno('12345678901'); # 'Personal ID' number of the legal entity
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Example Latvia Name</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:city>Example Latvia City</contact:city><contact:pc>012345</contact:pc><contact:cc>LV</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.0123456789</contact:voice><contact:email>example@example.lv</contact:email></contact:chg></contact:update></update><extension><lvcontact:update xmlns:lvcontact="http://www.nic.lv/epp/schema/lvcontact-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvcontact-ext-1.0 lvcontact-ext-1.0.xsd"><lvcontact:vatNr>LV12345678901</lvcontact:vatNr><lvcontact:regNr>12345678901</lvcontact:regNr></lvcontact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update_extension is_success');

### 1.1.1 Contact Update w/o Extension
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh80131');
my $toc1=$dri->local_object('changes');
my $co21=$dri->local_object('contact');
$co21->name('Example Latvia Name');
$co21->street(['Example Street 1','Example Street 2']);
$co21->city('Example Latvia City');
$co21->pc('012345');
$co21->cc('LV');
$co21->voice('+52.0123456789');
$co21->email('example@example.lv');
$toc->set('info',$co21);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh80131</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Example Latvia Name</contact:name><contact:addr><contact:street>Example Street 1</contact:street><contact:street>Example Street 2</contact:street><contact:city>Example Latvia City</contact:city><contact:pc>012345</contact:pc><contact:cc>LV</contact:cc></contact:addr></contact:postalInfo><contact:voice>+52.0123456789</contact:voice><contact:email>example@example.lv</contact:email></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build no_extension');
is($rc->is_success(),1,'contact_update is_success no_extension');

### 1.2 Contact Info /w Extension
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>testholder-12345</contact:id><contact:roid>CNT-testholder-LVNIC</contact:roid><contact:clID>niceppuser</contact:clID><contact:voice>+371.12345678</contact:voice><contact:fax>+371.12345678</contact:fax><contact:email>test.holder@enterprise.lv</contact:email><contact:postalInfo type="loc"><contact:name>Gundars Kalns</contact:name><contact:org>The Latvian Enterprise, LTD</contact:org><contact:addr><contact:street>Brīvības st.333-1</contact:street><contact:city>Rīga</contact:city><contact:pc>LV-1111</contact:pc><contact:cc>LV</contact:cc></contact:addr></contact:postalInfo><contact:crID>niceppuser</contact:crID><contact:crDate>2011-05-16T13:42:39+03:00</contact:crDate><status s="linked" /><contact:authInfo><contact:pw><contact:null /></contact:pw></contact:authInfo></contact:infData></resData><extension><infData xmlns="http://www.nic.lv/epp/schema/lvcontact-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvcontact-ext-1.0 lvcontact-ext-1.0.xsd"><regNr>222212222112</regNr><vatNr>LV222212222112</vatNr></infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('testholder-12345');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>testholder-12345</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'testholder-12345','contact_info get_info(self) srid');
is($co->roid(),'CNT-testholder-LVNIC','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'Gundars Kalns','contact_info get_info(self) name');
is($co->org(),'The Latvian Enterprise, LTD','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['Brīvības st.333-1'],'contact_info get_info(self) street');
is($co->city(),'Rīga','contact_info get_info(self) city');
is($co->pc(),'LV-1111','contact_info get_info(self) pc');
is($co->cc(),'LV','contact_info get_info(self) cc');
is($co->voice(),'+371.12345678','contact_info get_info(self) voice');
is($co->fax(),'+371.12345678','contact_info get_info(self) fax');
is($co->email(),'test.holder@enterprise.lv','contact_info get_info(self) email');
is($dri->get_info('clID'),'niceppuser','contact_info get_info(clID)');
is($dri->get_info('crID'),'niceppuser','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'2011-05-16T13:42:39','contact_info get_info(crDate) value');
is(defined($co->vat()), 1 ,'contact_info_extension vat() defined');
is(defined($co->orgno()), 1 ,'contact_info_extension orgno() defined');
is($co->vat(),'LV222212222112','contact_info_extension vatNr correct_value');
is($co->orgno(),'222212222112','contact_info_extension regNr correct_value');

####################################################################################################
####### Domains Commands ########

### 2.0 Domain Update /w Extension
my $changes = $dri->local_object('changes');
$changes->set('auto_renew', 'true'); # 'true/false' 1/0
$changes->set('auto_renew_message',{ lang => 'en', message => 'Client did not pay for domain name: discard it'});
$rc = $dri->domain_update('example-lvnic.lv', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example-lvnic.lv</domain:name></domain:update></update><extension><lvdomain:update xmlns:lvdomain="http://www.nic.lv/epp/schema/lvdomain-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvdomain-ext-1.0 lvdomain-ext-1.0.xsd"><lvdomain:add><lvdomain:status lang="en" s="clientAutoRenewProhibited">Client did not pay for domain name: discard it</lvdomain:status></lvdomain:add></lvdomain:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

### 2.1 Domain Info Parse /w Extension
$R2 = $E1 . '<response><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example-mydomain.lv</domain:name><domain:roid>DOM-example-mydomain-LVNIC</domain:roid><domain:status s="ok" /><domain:registrant>regi0412-12345</domain:registrant><domain:contact type="admin">huma1208-192</domain:contact><domain:contact type="tech">client-adm0</domain:contact><domain:contact type="billing">client-bill</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.example-mydomain.lv</domain:hostName><domain:hostAddr ip="v4">92.240.65.139</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.nonexisting.lv</domain:hostName></domain:hostAttr></domain:ns><domain:clID>test-client</domain:clID><domain:crDate>2011-04-09T13:04:03+03:00</domain:crDate><domain:exDate>2012-04-09T13:04:03+03:00</domain:exDate><domain:upID>test-client</domain:upID><domain:upDate>2011-06-09T13:04:03+03:00</domain:upDate></domain:infData></resData><extension><lvDomain:infData xmlns:lvDomain="http://www.nic.lv/epp/schema/lvdomain-ext-1.0" xsi:schemaLocation="http://www.nic.lv/epp/schema/lvdomain-ext-1.0 lvdomain-ext-1.0.xsd"><lvDomain:status s="clientAutoRenewProhibited" lang="en">Client did not pay for domain name: discard it</lvDomain:status></lvDomain:infData></extension><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;
$rc = $dri->domain_info('example-mydomain.lv');
is_string($R1,$E1 . '<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example-mydomain.lv</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>' . $E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'example-mydomain.lv','domain_info get_info(name)');
is($dri->get_info('roid'),'DOM-example-mydomain-LVNIC','domain_info get_info(roid)');
is($dri->get_info('clID'),'test-client','domain_info get_info(clID)');
is($dri->get_info('crDate'),'2011-04-09T13:04:03','domain_info get_info(crDate)');
is($dri->get_info('exDate'),'2012-04-09T13:04:03','domain_info get_info(exDate)');
is($dri->get_info('upDate'),'2011-06-09T13:04:03','domain_info get_info(upDate)');
is($dri->get_info('auto_renew'),'0','domain_info_extension get_info(auto_renew) = 0 - clientAutoRenewProhibited');
my $auto_renew_message = $dri->get_info('auto_renew_message');
is(defined($auto_renew_message), 1 ,'domain_info_extension get_info(auto_renew_message) defined');
is_deeply($dri->get_info('auto_renew_message'),{ lang => 'en', message => 'Client did not pay for domain name: discard it'},'domain_info_extension get_info(auto_renew_message) structure');
is($auto_renew_message->{'message'},'Client did not pay for domain name: discard it','domain_info_extension message');
is($auto_renew_message->{'lang'},'en','domain_info_extension lang');

### 2.1.1 Domain Info Parse w/o Extension
$R2 = $E1 . '<response><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example-mydomain.lv</domain:name><domain:roid>DOM-example-mydomain-LVNIC</domain:roid><domain:status s="ok" /><domain:registrant>regi0412-12345</domain:registrant><domain:contact type="admin">huma1208-192</domain:contact><domain:contact type="tech">client-adm0</domain:contact><domain:contact type="billing">client-bill</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.example-mydomain.lv</domain:hostName><domain:hostAddr ip="v4">92.240.65.139</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.nonexisting.lv</domain:hostName></domain:hostAttr></domain:ns><domain:clID>test-client</domain:clID><domain:crDate>2011-04-09T13:04:03+03:00</domain:crDate><domain:exDate>2012-04-09T13:04:03+03:00</domain:exDate><domain:upID>test-client</domain:upID><domain:upDate>2011-06-09T13:04:03+03:00</domain:upDate></domain:infData></resData><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;
$rc = $dri->domain_info('example1-mydomain.lv');
is($dri->get_info('auto_renew'),'1','domain_info_extension get_info(auto_renew) = 1 - clientAutoRenewAllowed');

### 2.2 Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('__DEFAULT__'),'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns.someserver.lv');
$dh->add('a-new-domain.lv',['1.2.3.4'],[],1);
$rc=$dri->domain_create('a-new-domain.lv',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'opqrstuv'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>a-new-domain.lv</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.someserver.lv</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>a-new-domain.lv</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="tech">__DEFAULT__</domain:contact><domain:authInfo><domain:pw>opqrstuv</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');


####################################################################################################
####### Poll Test ########

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ id="555" count="1"><qDate>2015-11-10T15:00:00+02:00</qDate><msg lang="en">[Transfer:Requested] Transfer of domain name [testdomain1.lv], currently managed by [old_registrar], was REQUESTED by [new_regisrtar]. [old_registrar] should approve or reject it until [2015-11-16 00:00:00].</msg></msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>testdomain1.lv</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>new_regisrtar</domain:reID><domain:reDate>2015-11-10T00:00:00+02:00</domain:reDate><domain:acID>old_registrar</domain:acID><domain:acDate>2015-11-16T00:00:00+02:00</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),555,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),555,'message get_info last_id 2');
is($dri->get_info('id','message',555),555,'message get_info id');
is(''.$dri->get_info('qdate','message',555),'2015-11-10T15:00:00','message get_info qdate');
is($dri->get_info('content','message',555),'[Transfer:Requested] Transfer of domain name [testdomain1.lv], currently managed by [old_registrar], was REQUESTED by [new_regisrtar]. [old_registrar] should approve or reject it until [2015-11-16 00:00:00].','message get_info msg');
is($dri->get_info('lang','message',555),'en','message get_info lang');
is($dri->get_info('object_type','message','555'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','555'),'testdomain1.lv','message get_info id');
is($dri->get_info('action','message','555'),'transfer','message get_info action'); ## with this, we know what action has triggered this delayed message
is($dri->get_info('reID','message','555'),'new_regisrtar','message get_info reID');


####################################################################################################
####### Transfer operations ########

### Transfer REQUEST operation
$R2=$E1.'<response><result code="1000"><msg lang="en">Command completed successfully</msg></result><trID><clTRID>5de52339104fa</clTRID><svTRID>LVNIC-20191202-31b3c6c4fc6f3119757ec5605410c28a-2</svTRID></trID></response>'.$E2;
$rc=$dri->domain_transfer_start('transfer-accept-testuser-1.lv',{auth=>{pw=>'transfer-accept-testuser-1.lv'}});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-accept-testuser-1.lv</domain:name><domain:authInfo><domain:pw>transfer-accept-testuser-1.lv</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');

### Transfer informative QUERY operation
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-accept-ignored-4.lv</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>TestUser2</domain:reID><domain:reDate>2019-12-02T16:44:09+02:00</domain:reDate><domain:acID>TestUser</domain:acID><domain:acDate>2019-12-08T00:00:00+02:00</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('transfer-accept-ignored-4.lv');
is($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-accept-ignored-4.lv</domain:name></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($dri->get_info('action'),'transfer','domain_transfer_query get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_query get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'TestUser2','domain_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(reDate)');
is("".$d,'2019-12-02T16:44:09','domain_transfer_query get_info(reDate) value');
is($dri->get_info('acID'),'TestUser','domain_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(acDate)');
is("".$d,'2019-12-08T00:00:00','domain_transfer_query get_info(acDate) value');

### Transfer CANCEL operation
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_stop('transfer-ignored-testuser-5.lv');
is_string($R1,$E1.'<command><transfer op="cancel"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-ignored-testuser-5.lv</domain:name></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_stop build');
is($rc->is_success(),1,'domain_transfer_stop is_success');

### Transfer APPROVE operation
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_accept('transfer-away-testuser-4.lv');
is_string($R1,$E1.'<command><transfer op="approve"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-away-testuser-4.lv</domain:name></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');

### Transfer REJECT operation
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_refuse('transfer-reject-testuser-4.lv');
is_string($R1,$E1.'<command><transfer op="reject"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>transfer-reject-testuser-4.lv</domain:name></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_reject build');
is($rc->is_success(),1,'domain_transfer_reject is_success');

exit 0;
