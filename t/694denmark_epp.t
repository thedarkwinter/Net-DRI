#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;
use Test::More tests => 16;

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
$dri->add_registry('DK');
$dri->target('DK')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{DK}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::DK',{}],'DK - epp transport_protocol_default');
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
$co->userType('company'); # Type of contact (company|public_organization|association|individual)
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Johnny Login</contact:name><contact:org>DK Hostmaster A/S</contact:org><contact:addr><contact:street>Kalvebod brygge 45, 3. sal</contact:street><contact:city>Copenhagen V</contact:city><contact:pc>1560</contact:pc><contact:cc>DK</contact:cc></contact:addr></contact:postalInfo><contact:voice>+45.33646060</contact:voice><contact:fax/><contact:email>tech@dk-hostmaster.dk</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><dkhm:CVR xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2">1234567891231</dkhm:CVR><dkhm:userType xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2">company</dkhm:userType></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create build');
is($rc->is_success(),1,'contact_create is_success');

####################################################################################################
####### Domains Commands ########

### 2.1 Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DKHM1-DK'),'registrant');
$dh=$dri->local_object('hosts');
$dh->add('ns1.dk-hostmaster.dk');
$dh->add('ns2.dk-hostmaster.dk');
$R2 = $E1 . '<response><result code="1001"><msg>Create domain pending for dk-hostmaster-test-906.dk</msg></result><extension><dkhm:trackingNo xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2">2014061800002</dkhm:trackingNo></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_create('dk-hostmaster-test-906.dk',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,confirmationToken=>'testtoken',auth=>{pw=>''}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dk-hostmaster-test-906.dk</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.dk-hostmaster.dk</domain:hostObj><domain:hostObj>ns2.dk-hostmaster.dk</domain:hostObj></domain:ns><domain:registrant>DKHM1-DK</domain:registrant><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><dkhm:orderconfirmationToken xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2">testtoken</dkhm:orderconfirmationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('trackingNo'),'2014061800002','domain_create_parse get_info(trackingNo)');

### 2.2 Domain Check
$R2 = $E1 . '<response><result code="1000"><msg>Check result</msg></result><resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">blockeddomain.dk</domain:name></domain:cd></domain:chkData></resData><extension><dkhm:domainAdvisory xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2" domain="blockeddomain.dk" advisory="Blocked" /></extension>' . $TRID . '</response>' . $E2;
$rc=$dri->domain_check('blockeddomain.dk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>blockeddomain.dk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
my $domainAdvisory = $dri->get_info('domainAdvisory');
is(defined($domainAdvisory), 1 ,'domain_check_extension get_info(domainAdvisory) defined');
is_deeply($dri->get_info('domainAdvisory'),{ advisory => 'Blocked', domain_name => 'blockeddomain.dk'},'domain_check_extension get_info(domainAdvisory) structure');
is($domainAdvisory->{'advisory'},'Blocked','domain_check_extension advisory');
is($domainAdvisory->{'domain_name'},'blockeddomain.dk','domain_check_extension domain_name');

exit 0;
