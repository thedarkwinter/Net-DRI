#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 24;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('DNSPT');
$dri->target('DNSPT')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$dh,@c,$co);

####################################################################################################
## Domain commands

$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mytestdomain.pt</domain:name><domain:crDate>2006-03-21T11:58:50.6Z</domain:crDate></domain:creData></resData><extension><ptdomain:creData xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:roid>4569356</ptdomain:roid></ptdomain:creData></extension>'.$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('FCZA-142520-FCCN');
$cs->set($c1,'registrant');
$cs->set($c1,'tech');
$rc=$dri->domain_create('mytestdomain.pt',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,legitimacy=>1,registration_basis=>'090',add_period=>1,next_possible_registration=>0,auto_renew=>'true',owner_visible=>'true'});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mytestdomain.pt</domain:name><domain:period unit="y">1</domain:period><domain:registrant>FCZA-142520-FCCN</domain:registrant><domain:contact type="tech">FCZA-142520-FCCN</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><ptdomain:create xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:legitimacy type="1"/><ptdomain:registration_basis type="090"/><ptdomain:autoRenew>true</ptdomain:autoRenew><ptdomain:ownerVisible>true</ptdomain:ownerVisible></ptdomain:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('roid'),'4569356','domain_create get_info(roid)');

## Example corrected, domain:name needs a namespace
$R2=$E1.'<response><result code="2302"><msg>Object exists</msg><extValue><value><domain:name xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">mytestdomain2.pt</domain:name></value><reason>There was a previous submission for the same domain name that is still in pending create. To put a new submission into the next-possible-registration queue resend this command with the next-possible-registration extension element set to true</reason></extValue></result>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('mytestdomain2.pt',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,legitimacy=>1,registration_basis=>'090',add_period=>1,next_possible_registration=>0,auto_renew=>'true',owner_visible=>'true'});
is($rc->is_success(),0,'domain_create is_success');
is($rc->code(),2302,'domain_create code');
is_deeply([$rc->get_extended_results()],[{from=>'eppcom:extValue',type=>'rawxml',message=>'<domain:name xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">mytestdomain2.pt</domain:name>',reason=>'There was a previous submission for the same domain name that is still in pending create. To put a new submission into the next-possible-registration queue resend this command with the next-possible-registration extension element set to true',lang=>'en'}],'domain_create extra info');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mytestdomain3.pt</domain:name><domain:roid>2221881-FCCN</domain:roid><domain:status s="inactive"/><domain:status s="pendingUpdate"/><domain:registrant>FCZA-142520-FCCN</domain:registrant><domain:contact type="tech">FCZA-142520-FCCN</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.anything.pt</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.everything.pt</domain:hostName></domain:hostAttr></domain:ns><domain:clID>FCZA-142520-FCCN</domain:clID><domain:crID>FCZA-142520-FCCN</domain:crID><domain:crDate>2006-03-21T12:19:25.000Z</domain:crDate><domain:upID>FCZA-142520-FCCN</domain:upID><domain:upDate>2006-03-21T12:19:25.000Z</domain:upDate><domain:exDate>2007-03-21T12:19:25.000Z</domain:exDate></domain:infData></resData><extension><ptdomain:infData xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:legitimacy type="1"/><ptdomain:registration_basis type="30"/><ptdomain:autoRenew>true</ptdomain:autoRenew><ptdomain:ownerVisible>true</ptdomain:ownerVisible></ptdomain:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('mytestdomain3.pt');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">mytestdomain3.pt</domain:name></domain:info></info><extension><ptdomain:info xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:roid/></ptdomain:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info');
is($dri->get_info('legitimacy'),1,'domain_info get_info(legitimacy)');
is($dri->get_info('registration_basis'),30,'domain_info get_info(registration_basis)');
is($dri->get_info('auto_renew'),'true','domain_info get_info(auto_renew)');
is($dri->get_info('owner_visible'),'true','domain_info get_info(owner_visible)');

$R2='';
my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->add('ns.mytestdomain3.pt',['19.0.2.2']));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c112574'),'tech');
$toc->add('contact',$cs);
$toc->set('owner_visible','false');
$rc=$dri->domain_update('mytestdomain3.pt',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mytestdomain3.pt</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns.mytestdomain3.pt</domain:hostName><domain:hostAddr ip="v4">19.0.2.2</domain:hostAddr></domain:hostAttr></domain:ns><domain:contact type="tech">c112574</domain:contact></domain:add></domain:update></update><extension><ptdomain:update xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:roid/><ptdomain:ownerVisible>false</ptdomain:ownerVisible></ptdomain:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

$R2='';
$rc=$dri->domain_renew('example.pt',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2008,month=>4,day=>3),auto_renew=>'no',not_renew=>0}); # test xml_parse_auto_renew();
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.pt</domain:name><domain:curExpDate>2008-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><ptdomain:renew xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:roid/><ptdomain:autoRenew>false</ptdomain:autoRenew><ptdomain:notRenew>false</ptdomain:notRenew></ptdomain:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');

$R2='';
$rc=$dri->domain_renounce('telepac2.pt');
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>telepac2.pt</domain:name></domain:transfer></transfer><extension><ptdomain:transfer xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:roid/><ptdomain:renounce>true</ptdomain:renounce></ptdomain:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renounce build');


#########################################################################################################
## Contact commands

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>c1006441</contact:id><contact:crDate>2007-03-21T10:02:45Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('NIC-Handle');
$co->name('Smith Bill');
$co->street(['Blue Tower']);
$co->city('Lisboa');
$co->pc('1900');
$co->cc('PT');
$co->voice('+351.963456569');
$co->fax('+351.213456569');
$co->email('noreply@dns.pt');
$co->auth({pw=>'pA55w0rD'});
$co->identification({value=>'234561728'});
$co->mobile('+351.916589304');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>NIC-Handle</contact:id><contact:postalInfo type="int"><contact:name>Smith Bill</contact:name><contact:addr><contact:street>Blue Tower</contact:street><contact:city>Lisboa</contact:city><contact:pc>1900</contact:pc><contact:cc>PT</contact:cc></contact:addr></contact:postalInfo><contact:voice>+351.963456569</contact:voice><contact:fax>+351.213456569</contact:fax><contact:email>noreply@dns.pt</contact:email><contact:authInfo><contact:pw>pA55w0rD</contact:pw></contact:authInfo></contact:create></create><extension><ptcontact:create xmlns:ptcontact="http://eppdev.dns.pt/schemas/ptcontact-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptcontact-1.0 ptcontact-1.0.xsd"><ptcontact:identification>234561728</ptcontact:identification><ptcontact:mobile>+351.916589304</ptcontact:mobile></ptcontact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('id'),'c1006441','contact_create get_info(id)');
is($dri->get_info('action','contact','c1006441'),'create','contact_create get_info(action)');
is($dri->get_info('exist','contact','c1006441'),1,'contact_create get_info(exist)');


$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>c1006449</contact:id><contact:roid>1006449-FCCN</contact:roid><contact:postalInfo type="int"><contact:name>Smith Bill</contact:name><contact:addr><contact:street>Blue Tower</contact:street><contact:city>Paris</contact:city><contact:pc>571234</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.16345656</contact:voice><contact:fax>+33.16345656</contact:fax><contact:email>noreply@dns.pt</contact:email><contact:crID>t000005</contact:crID><contact:crDate>2006-03-21T10:04:54.000Z</contact:crDate><contact:upDate>2006-03-21T10:04:54.000Z</contact:upDate></contact:infData></resData><extension><ptcontact:infData xmlns:ptcontact="http://eppdev.dns.pt/schemas/ptcontact-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptcontact-1.0 ptcontact-1.0.xsd"><ptcontact:identification>234561728</ptcontact:identification><ptcontact:mobile>+33.9689304</ptcontact:mobile></ptcontact:infData></extension>'.$TRID.'</response>'.$E2;
$co->srid('c1006449');
my $co2=$dri->local_object('contact')->srid('c1006449');
$rc=$dri->contact_info($co2);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>c1006449</contact:id><contact:authInfo><contact:pw/></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info');


$co2=$dri->get_info('self');
is_deeply($co2->identification(),{type => undef, value=>'234561728'},'contact_info get_info(self) identification');
is($co2->mobile(),'+33.9689304','contact_info get_info(self) mobile');

$R2='';
$rc=$dri->contact_info($dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'}));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command></epp>','contact_info build');
is($rc->is_success(),1,'contact_info is_success');

#########################################################################################################
## GDPR changes
$R2='';
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('FCZA-142520-FCCN');
$cs->set($c1,'registrant');
$cs->set($c1,'tech');
$rc=$dri->domain_create('teste-12052018-2.pt',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,legitimacy=>1,registration_basis=>'090',add_period=>1,next_possible_registration=>0,auto_renew=>'false',owner_visible=>'false'});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>teste-12052018-2.pt</domain:name><domain:period unit="y">1</domain:period><domain:registrant>FCZA-142520-FCCN</domain:registrant><domain:contact type="tech">FCZA-142520-FCCN</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><ptdomain:create xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:legitimacy type="1"/><ptdomain:registration_basis type="090"/><ptdomain:autoRenew>false</ptdomain:autoRenew><ptdomain:ownerVisible>false</ptdomain:ownerVisible></ptdomain:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build GDPR changes - ownerVisible');


exit 0;
