#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;
use Test::More tests => 25;
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
$dri->add_registry('DK');
$dri->target('DK')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$co_old,$dh,$cs,$ns,$toc);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{DK}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{'ssl_version' => 'TLSv12', 'ssl_cipher_list' => undef},'Net::DRI::Protocol::EPP::Extensions::DK',{}],'DK - epp transport_protocol_default');
$R2=$E1.'<greeting><svID>DK Hostmaster EPP Service (production): 2.2.3</svID><svDate>2017-01-26T09:53:33.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:dkhm:params:xml:ns:dkhm-2.0</extURI></svcExtension></svcMenu><dcp><access><personalAndOther /></access><statement><purpose><admin /><prov /></purpose><recipient><other /><unrelated /></recipient><retention><legal /></retention></statement></dcp></greeting></epp>';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1');
is($dri->protocol()->ns()->{'dkhm'}->[0],'urn:dkhm:params:xml:ns:dkhm-2.0','dkhm-2.0 for server announcing 2.0');

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
####### Contact Commands ########

### 1.1 Contact Create
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
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:voice>+45.33646060</contact:voice><contact:fax/><contact:email>tech@dk-hostmaster.dk</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><dkhm:userType xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">company</dkhm:userType><dkhm:CVR xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">1234567891231</dkhm:CVR></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
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
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="int"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><extension><dkhm:secondaryEmail xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">email@eksempel.dk</dkhm:secondaryEmail><dkhm:mobilephone xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">+1.7034444445</dkhm:mobilephone></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_update build');

$R2 = $E1 . '<response><result code="1000"><msg>Info result</msg></result><resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>DKHM1-DK</contact:id><contact:roid>DKHM1-DK</contact:roid><contact:status s="serverUpdateProhibited" /><contact:status s="serverTransferProhibited" /><contact:status s="linked" /><contact:status s="serverDeleteProhibited" /><contact:postalInfo type="loc"><contact:name>DK Hostmaster A/S</contact:name><contact:addr><contact:street>Kalvebod Brygge 45,3</contact:street><contact:city>København V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:voice>+45.33646060</contact:voice><contact:email>anonymous@dk-hostmaster.dk</contact:email><contact:clID>DKHM1-DK</contact:clID><contact:crID>n/a</contact:crID><contact:crDate>2013-01-24T15:40:37.0Z</contact:crDate></contact:infData></resData><extension><dkhm:contact_validated xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">1</dkhm:contact_validated></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('DKHM1-DK'));
is($rc->is_success(), 1, 'contact_info is_success');
$co = $dri->get_info('self');
is($co->name(), 'DK Hostmaster A/S', 'contact_info get_info name');
is($co->contact_validated(), 1, 'contact_info get_info contact_validated');

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
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.eksempel.dk</host:name><host:addr ip="v4">162.0.2.2</host:addr><host:addr ip="v4">162.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><extension><dkhm:requestedNsAdmin xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">ADMIN2-DK</dkhm:requestedNsAdmin></extension><clTRID>ABC-12345</clTRID></command></epp>','host_create(2) build');

# host update with requested_ns_admin
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
#$toc->set('ip',$dri->local_object('hosts')->add('ns1.eksempel.dk',['193.0.2.22'],[]));
$toc->set('requested_ns_admin','DKHM1-DK');
$rc=$dri->host_update('ns1.eksempel.dk',$toc);
is($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns1.eksempel.dk</host:name></host:update></update><extension><dkhm:requestedNsAdmin xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">DKHM1-DK</dkhm:requestedNsAdmin></extension><clTRID>ABC-12345</clTRID></command></epp>','host_update build');
is($rc->is_success(),1,'host_update is_success');

####################################################################################################
####### Domains Commands ########

### 2.1 Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DKHM1-DK'),'registrant');
$dh=$dri->local_object('hosts');
$dh->add('ns1.dk-hostmaster.dk');
$dh->add('ns2.dk-hostmaster.dk');
$R2 = $E1 . '<response><result code="1001"><msg>Create domain pending for dk-hostmaster-test-906.dk</msg></result><extension><dkhm:trackingNo xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">2014061800002</dkhm:trackingNo></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_create('dk-hostmaster-test-906.dk',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,confirmation_token=>'testtoken',auth=>{pw=>''}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dk-hostmaster-test-906.dk</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.dk-hostmaster.dk</domain:hostObj><domain:hostObj>ns2.dk-hostmaster.dk</domain:hostObj></domain:ns><domain:registrant>DKHM1-DK</domain:registrant><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><dkhm:orderconfirmationToken xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0">testtoken</dkhm:orderconfirmationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('tracking_no'),'2014061800002','domain_create_parse get_info(tracking_no)');

### 2.2 Domain Check
$R2 = $E1 . '<response><result code="1000"><msg>Check result</msg></result><resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">blockeddomain.dk</domain:name></domain:cd></domain:chkData></resData><extension><dkhm:domainAdvisory xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.0" domain="blockeddomain.dk" advisory="Blocked" /></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_check('blockeddomain.dk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>blockeddomain.dk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('advisory'),'Blocked','domain_check_extension get_info(advisory)');

exit 0;
