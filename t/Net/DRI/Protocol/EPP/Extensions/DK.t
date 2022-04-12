#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;
use Test::More tests => 81;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=30; };
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
$dri->add_registry('DKHostmaster');
$dri->target('DKHostmaster')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$co_old,$dh,$cs,$ns,$toc);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->driver();
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::DK',{}],'DK - epp transport_protocol_default');
$R2=$E1.'<greeting><svID>DK Hostmaster EPP Service (production): 2.2.3</svID><svDate>2017-01-26T09:53:33.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://www.verisign.com/epp/balance-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:dkhm:params:xml:ns:dkhm-4.3</extURI><extURI>urn:dkhm:params:xml:ns:dkhm-domain-4.0</extURI></svcExtension></svcMenu><dcp><access><personalAndOther /></access><statement><purpose><admin /><prov /></purpose><recipient><other /><unrelated /></recipient><retention><legal /></retention></statement></dcp></greeting></epp>';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1');
is($dri->protocol()->ns()->{'dkhm'}->[0],'urn:dkhm:params:xml:ns:dkhm-4.3','dkhm-4.3 for server announcing 4.3');
is($dri->protocol()->ns()->{'balance'}->[0],'http://www.verisign.com/epp/balance-1.0','Verisign balance for server announcing 1.0');

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
####### Contact Commands ########

### 1.1 Contact Create (with management)
$co=$dri->local_object('contact');
$co->name('Johnny Login');
$co->org('DK Hostmaster A/S');
$co->street(['Kalvebod brygge 45, 3. sal']);
$co->city('Copenhagen V');
$co->pc('1560');
$co->cc('DK');
$co->voice('+45.33646060');
$co->fax('');
$co->email('tech@dk-hostmaster.dk');
#$co->ean('453784957293'); # 'EAN' number of the contact (not supported by userType 'individual')
$co->vat('1234567891231'); # 'VAT' number of the entity.
$co->type('company'); # Type of contact (company|public_organization|association|individual)
$co->management('registrar');   #contact managemtn overide (registrar|registrant)
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:voice>+45.33646060</contact:voice><contact:fax/><contact:email>tech@dk-hostmaster.dk</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><dkhm:userType xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">company</dkhm:userType><dkhm:CVR xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">1234567891231</dkhm:CVR><dkhm:management xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">registrar</dkhm:management></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');

### Contact Update
$co_old = $dri->local_object('contact')->srid('sh8013');
$toc    = $dri->local_object('changes');
$s      = $dri->local_object('status')->no('delete');
$co     = $dri->local_object('contact')->org(undef,'')->street(undef,['124 Example Dr.', 'Suite 200'])->city(undef,'Dulles')->sp(undef,'VA')->pc(undef,'20166-6503')->cc(undef,'US')->voice('+1.7034444444')->fax('')->auth({'pw' =>'2fooBAR'});
$co->disclose({voice => 1, email => 1});
$co->alt_email('email@eksempel.dk');
$co->mobile('+1.7034444445');
$toc->add('status',$s);
$toc->set('info',$co);
$rc=$dri->contact_update($co_old,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="int"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><extension><dkhm:secondaryEmail xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">email@eksempel.dk</dkhm:secondaryEmail><dkhm:mobilephone xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">+1.7034444445</dkhm:mobilephone></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_update build');

$R2 = $E1 . '<response><result code="1000"><msg>Info result</msg></result><resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>DKHM1-DK</contact:id><contact:roid>DKHM1-DK</contact:roid><contact:status s="serverUpdateProhibited" /><contact:status s="serverTransferProhibited" /><contact:status s="linked" /><contact:status s="serverDeleteProhibited" /><contact:postalInfo type="loc"><contact:name>DK Hostmaster A/S</contact:name><contact:addr><contact:street>Kalvebod Brygge 45,3</contact:street><contact:city>København V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:voice>+45.33646060</contact:voice><contact:email>anonymous@dk-hostmaster.dk</contact:email><contact:clID>DKHM1-DK</contact:clID><contact:crID>n/a</contact:crID><contact:crDate>2013-01-24T15:40:37.0Z</contact:crDate></contact:infData></resData><extension><dkhm:contact_validated xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">1</dkhm:contact_validated><dkhm:CVR xmlns:dkhm=\'urn:dkhm:params:xml:ns:dkhm-4.3\'>12345</dkhm:CVR><dkhm:userType xmlns:dkhm=\'urn:dkhm:params:xml:ns:dkhm-4.3\'>company</dkhm:userType></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('DKHM1-DK'));
is($rc->is_success(), 1, 'contact_info is_success');
$co = $dri->get_info('self');
is($co->name(), 'DK Hostmaster A/S', 'contact_info get_info name');
is($co->contact_validated(), 1, 'contact_info get_info contact_validated');
is($co->vat(), 12345, 'contact_info get_info vat');
is($co->type(), 'company', 'contact_info get_info type');

####################################################################################################
####### Host Commands ########

# Host create
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns1.eksempel.dk</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>' . $TRID .'</response>'. $E2;
$ns = $dri->local_object('hosts')->add('ns1.eksempel.dk',['162.0.2.2','162.0.2.29'],['2000:0:0:0:8:800:200C:417A']);
$dri->host_create($ns);
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.eksempel.dk</host:name><host:addr ip="v4">162.0.2.2</host:addr><host:addr ip="v4">162.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command></epp>','host_create(1) build');
is($rc->is_success(), 1, 'contact_info is_success');
is($dri->get_info('crDate'),'1999-04-03T22:00:00','host_create get_info crdate');

# Host create with requested_ns_admin
$dri->host_create($ns, {'requested_ns_admin' => 'ADMIN2-DK'});
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.eksempel.dk</host:name><host:addr ip="v4">162.0.2.2</host:addr><host:addr ip="v4">162.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><extension><dkhm:requestedNsAdmin xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">ADMIN2-DK</dkhm:requestedNsAdmin></extension><clTRID>ABC-12345</clTRID></command></epp>','host_create(2) build');

# host update with requested_ns_admin
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
#$toc->set('ip',$dri->local_object('hosts')->add('ns1.eksempel.dk',['193.0.2.22'],[]));
$toc->set('requested_ns_admin','DKHM1-DK');
$rc=$dri->host_update('ns1.eksempel.dk',$toc);
is($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.eksempel.dk</host:name></host:update></update><extension><dkhm:requestedNsAdmin xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">DKHM1-DK</dkhm:requestedNsAdmin></extension><clTRID>ABC-12345</clTRID></command></epp>','host_update build');
is($rc->is_success(),1,'host_update is_success');

####################################################################################################
####### Domains Commands ########

### 2.1 Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DKHM1-DK'),'registrant');
$dh=$dri->local_object('hosts');
$dh->add('ns1.dk-hostmaster.dk');
$dh->add('ns2.dk-hostmaster.dk');
$R2 = $E1 . '<response><result code="1001"><msg>Create domain pending for dk-xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3"hostmaster-test-906.dk</msg></result><extension><dkhm:trackingNo xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">2014061800002</dkhm:trackingNo><dkhm:url xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">https://selfservice-dk-hostmaster.dk/6102505a2e8d0cfbe8c3c99ea49977f36e2d4ee3</dkhm:url></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_create('dk-hostmaster-test-906.dk',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,confirmation_token=>'testtoken',auth=>{pw=>''},management=>'registrar'});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dk-hostmaster-test-906.dk</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.dk-hostmaster.dk</domain:hostObj><domain:hostObj>ns2.dk-hostmaster.dk</domain:hostObj></domain:ns><domain:registrant>DKHM1-DK</domain:registrant><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><dkhm:orderconfirmationToken xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">testtoken</dkhm:orderconfirmationToken><dkhm:management xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">registrar</dkhm:management></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('tracking_no'),'2014061800002','domain_create_parse get_info(tracking_no)');
is($dri->get_info('url'),'https://selfservice-dk-hostmaster.dk/6102505a2e8d0cfbe8c3c99ea49977f36e2d4ee3','domain_create_parse get_info(url)');

### 2.2 Domain Check
$R2 = $E1 . '<response><result code="1000"><msg>Check result</msg></result><resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">blockeddomain.dk</domain:name></domain:cd></domain:chkData></resData><extension><dkhm:domainAdvisory xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3" domain="blockeddomain.dk" advisory="Blocked" /></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_check('blockeddomain.dk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>blockeddomain.dk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('advisory'),'Blocked','domain_check_extension get_info(advisory)');

### Domain Info with AuthIfnoToken
$R2 = $E1 . '<response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <resData>
      <domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>dk-hostmaster.dk</domain:name>
        <domain:roid>EXAMPLE1-REP</domain:roid>
        <domain:status s="ok"/>
        <domain:registrant>jd1234</domain:registrant>
        <domain:contact type="admin">sh8013</domain:contact>
        <domain:contact type="tech">sh8013</domain:contact>
        <domain:ns>
          <domain:hostObj>ns1.example.com</domain:hostObj>
          <domain:hostObj>ns1.example.net</domain:hostObj>
        </domain:ns>
        <domain:host>ns1.example.com</domain:host>
        <domain:host>ns2.example.com</domain:host>
        <domain:clID>ClientX</domain:clID>
        <domain:crID>ClientY</domain:crID>
        <domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate>
        <domain:upID>ClientX</domain:upID>
        <domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate>
        <domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate>
        <domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate>
        <domain:authInfo>
          <domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</domain:pw>
        </domain:authInfo>
      </domain:infData>
    </resData>
    <extension>
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
      <dkhm:authInfo expdate="2021-10-17T14:16:35.0Z" op="transfer" xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">REG-0-d5288a8aa482bcf2fb5152bfbb7d877d</dkhm:authInfo>
      <dkhm:delDate xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">2021-01-31T00:00:00.0Z</dkhm:delDate>
      <dkhm:autoRenew xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">true</dkhm:autoRenew>
    </extension>
' . $TRID . '</response>' . $E2;

$rc=$dri->domain_info('dk-hostmaster.dk');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">dk-hostmaster.dk</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2, 'domain_info_build');
is($rc->is_success(),1,'domain_info is_success');
is_deeply($dri->get_info('auth', 'domain', 'dk-hostmaster.dk'), { pw => 'DKHM1-DK-098f6bcd4621d373cade4e832627b4f6' }, 'domain_info auth token retrieved');
is ($dri->get_info('auth_info_ex_date', 'domain', 'dk-hostmaster.dk'), '2018-11-14T09:00:00', 'domain_info auth_token expiration date retrieved');
is ($dri->get_info('auth_info_token', 'domain', 'dk-hostmaster.dk'), 'REG-0-d5288a8aa482bcf2fb5152bfbb7d877d', 'domain_info auth_info_token retrieved');
is ($dri->get_info('auth_info_token_expdate', 'domain', 'dk-hostmaster.dk'), '2021-10-17T14:16:35', 'domain_info auth_info_token_expdate retrieved');
is ($dri->get_info('auth_info_token_op', 'domain', 'dk-hostmaster.dk'), 'transfer', 'domain_info auth_info_token_op retrieved');
is ($dri->get_info('del_date', 'domain', 'dk-hostmaster.dk'), '2021-01-31T00:00:00', 'domain_info domain delDate retrieved');
is ($dri->get_info('auto_renew', 'domain', 'dk-hostmaster.dk'), 'true', 'domain_info domain autoRenew retrieved');


#### Domain Transfer (No pending, only serverApproved)

$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>eksempel.dk</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;#{
$rc=$dri->domain_transfer_start('eksempel.dk',{auth=>{pw=>'DKHM1-DK-098f6bcd4621d373cade4e832627b4f6'},duration=>DateTime::Duration->new(years=>1)});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>eksempel.dk</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
is("".$d,'2000-06-13T22:00:00','domain_transfer_start get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_start get_info(exDate) value');

$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>eksempel.dk</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-06T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-11T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('eksempel.dk',{auth=>{pw=>'DKHM1-DK-098f6bcd4621d373cade4e832627b4f6'}});
is($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>eksempel.dk</domain:name><domain:authInfo><domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($dri->get_info('action'),'transfer','domain_transfer_query get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_query get_info(exist)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(reDate)');
is("".$d,'2000-06-06T22:00:00','domain_transfer_query get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(acDate)');
is("".$d,'2000-06-11T22:00:00','domain_transfer_query get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_query get_info(exDate) value');

####################################################################################################
####### Verisign balance + RGP standard ########

### Verisign balance
$R2=$E1.'<response>'.r().'<resData><balance:infData xmlns:balance="http://www.verisign.com/epp/balance-1.0"><balance:creditLimit>1000.00</balance:creditLimit><balance:balance>200.00</balance:balance><balance:availableCredit>800.00</balance:availableCredit><balance:creditThreshold><balance:fixed>500.00</balance:fixed></balance:creditThreshold></balance:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->balance_info();
is_string($R1,$E1.'<command><info><balance:info xmlns:balance="http://www.verisign.com/epp/balance-1.0" xsi:schemaLocation="http://www.verisign.com/epp/balance-1.0 balance-1.0.xsd"/></info><clTRID>ABC-12345</clTRID></command>'.$E2,'balance_info build');
is($rc->get_data('session','balance','credit_limit'),1000,'balance_info get_data(credit_limit) 1');
is($rc->get_data('session','balance','balance'),200,'balance_info get_data(balance) 1');
is($rc->get_data('session','balance','available_credit'),800,'balance_info get_data(available_credit) 1');
is($rc->get_data('session','balance','credit_threshold'),500,'balance_info get_data(credit_threshold) 1');
is($rc->get_data('session','balance','credit_threshold_type'),'FIXED','balance_info get_data(credit_threshold_type) 1');

### RGP - Registry Grace Period
# op request
$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$rc=$dri->domain_update('example51.dk',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example51.dk</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_request');
is($rc->is_success(),1,'domain_update is_success +RGP');

# op report
$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'report', report => {predata=>'Pre-delete registration data goes here. Both XML and free text are allowed.', postdata=>'Post-restore registration data goes here. Both XML and free text are allowed.',deltime=>DateTime->new(year=>2003,month=>7,day=>10,hour=>22),restime=>DateTime->new(year=>2003,month=>7,day=>20,hour=>22),reason=>'Registrant error.',statement1=>'This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.',statement2=>'The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.',other=>'Supporting information goes here.' }});
$rc=$dri->domain_update('example52.dk',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example52.dk</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="report"><rgp:report><rgp:preData>Pre-delete registration data goes here. Both XML and free text are allowed.</rgp:preData><rgp:postData>Post-restore registration data goes here. Both XML and free text are allowed.</rgp:postData><rgp:delTime>2003-07-10T22:00:00.0Z</rgp:delTime><rgp:resTime>2003-07-20T22:00:00.0Z</rgp:resTime><rgp:resReason>Registrant error.</rgp:resReason><rgp:statement>This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.</rgp:statement><rgp:statement>The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.</rgp:statement><rgp:other>Supporting information goes here.</rgp:other></rgp:report></rgp:restore></rgp:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_report');
is($rc->is_success(),1,'domain_update is_success +RGP');

#Domain update unset authinfo 
$R2 = $E1 . ' <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <msgQ count="10" id="1">
    </msgQ>
' . $TRID . '</response>' . $E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set(auth=>{pw=>undef});
$rc=$dri->domain_update('example.dk',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.dk</domain:name><domain:chg><domain:authInfo><domain:null/></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build set authinfo');
is($rc->is_success(), 1, 'Domain update unset authinfo sucess');

# The withdraw command extension
$R2 = $E1 . ' <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
' . $TRID . '</response>' . $E2;
$rc=$dri->domain_withdraw('eksempel.dk');
is_string($R1, $E1.'<extension><command xmlns="urn:dkhm:params:xml:ns:dkhm-4.3" xsi:schemaLocation="urn:dkhm:params:xml:ns:dkhm-4.3 dkhm-4.3.xsd"><withdraw><domain:withdraw xmlns:domain="urn:dkhm:params:xml:ns:dkhm-4.3" xsi:schemaLocation="urn:dkhm:params:xml:ns:dkhm-4.3 dkhm-4.3.xsd"><domain:name>eksempel.dk</domain:name></domain:withdraw></withdraw><clTRID>ABC-12345</clTRID></command></extension>'.$E2,'domain_withdraw build command');
is($rc->is_success(),1,'domain_withdraw is_success');

# Message
$R2 = $E1 . '
  <response>
    <result code="1301">
      <msg>Command completed successfully; ack to dequeue</msg>
    </result>
    <msgQ count="1" id="2">
      <msg>Created domain for eksempel.dk has been approved</msg>
    </msgQ>
    <resData>
      <domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name paResult="1">eksempel.dk</domain:name>
        <domain:paTRID>
          <clTRID>916e2f64ca0956a1bfc24140b23b8fb3</clTRID>
          <svTRID>001C6E66-761D-11E8-8775-F5EABB5937F7-2018062200008</svTRID>
        </domain:paTRID>
        <domain:paDate>2018-06-22T15:07:00.0Z</domain:paDate></domain:panData>
    </resData>
    <extension>
      <dkhm:risk_assessment xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-4.3">N/A</dkhm:risk_assessment>
    </extension>
    ' . $TRID . '
  </response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message_retrieve');
is($dri->get_info('last_id'), 2, 'message get_info last_id');
is($dri->get_info('content', 'message', '2'), 'Created domain for eksempel.dk has been approved', 'message text retrieved');
is($dri->get_info('risk_assessment','domain', 'eksempel.dk'),'N/A', 'domain get_info risk_assessment');  #dedicate message parse risk_assessment
is($dri->get_info('risk_assessment', 'message', '2'), 'N/A', 'message get_info risk_assessment'); #defaut risk assessment in message

exit 0;
