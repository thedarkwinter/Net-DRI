#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 17;
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
$dri->add_registry('CIRA');
$dri->target('CIRA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$h,$toc);

####################################################################################################
## Notifications

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ id="1901" count="108"><qDate>2010-01-20T16:58:17.0Z</qDate><msg lang="en">omain example.ca has been transferred to another Registrar</msg></msgQ><resData><poll:extData xmlns:poll="urn:ietf:params:xml:ns:poll-1.0"><msgID>3027</msgID><domainName>example.ca</domainName></poll:extData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->get_data('message',1901,'msg_id'),'3027','notification parsing msg_id');
is($rc->get_data('message',1901,'domain_name'),'example.ca','notification parsing domain_name');

####################################################################################################
## Contacts

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>11aabb</contact:id><contact:roid>roid1</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Contact Middle-name LastName</contact:name><contact:addr><contact:street>123 Everywhere Street</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1R7S8</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:email>contact1@domain.ca</contact:email><contact:clID>123</contact:clID><contact:crID>456</contact:crID><contact:crDate>2010-01-07T18:18:53.0Z</contact:crDate></contact:infData></resData><extension><cira:ciraInfo xmlns:cira="urn:ietf:params:xml:ns:cira-1.0"><cira:language>en</cira:language><cira:cprCategory>CCT</cira:cprCategory><cira:individual>Y</cira:individual><cira:ciraAgreementVersion>2.0</cira:ciraAgreementVersion><cira:agreementTimestamp>2010-01-26T18:18:53.0Z</cira:agreementTimestamp><cira:originatingIpAddress>192.168.45.59</cira:originatingIpAddress><cira:whoisDisplaySetting>PRIVATE</cira:whoisDisplaySetting></cira:ciraInfo></extension>>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('11aabb'));
$co=$rc->get_data('contact','11aabb','self');
is($co->lang(),'en','contact_info lang');
is($co->legal_form(),'CCT','contact_info legal_form');
is($co->is_individual(),1,'contact_info is_individual');
is_deeply($co->agreement(),{signed=>1,version=>'2.0',timestamp=>'2010-01-26T18:18:53'},'contact_info agreement');
is($co->ip_address(),'192.168.45.59','contact_info ip_address');
is($co->whois_display(),'PRIVATE','contact_info whois_display');


$R2='';
$co=$dri->local_object('contact');
$co->srid('sh8021');
$co->name('John Doe');
$co->org('Example Inc.');
$co->street(['350 Sparks Street','Suite 306']);
$co->city('Ottawa');
$co->sp('ON');
$co->pc('K1R 7S8');
$co->cc('CA');
$co->voice('+1.6132375335x1234');
$co->fax('+1.6132370534');
$co->email('jdoe@cira20.ca');
$co->lang('en');
$co->ip_address('192.118.22.26');
$co->legal_form('CCT');
$co->agreement({version => '1.9', signed => 1});
$co->reseller_id('12345');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8021</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>350 Sparks Street</contact:street><contact:street>Suite 306</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1R 7S8</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.6132375335</contact:voice><contact:fax>+1.6132370534</contact:fax><contact:email>jdoe@cira20.ca</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><cira:ciraCreate xmlns:cira="urn:ietf:params:xml:ns:cira-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-1.0 cira-1.0.xsd"><cira:language>en</cira:language><cira:originatingIpAddress>192.118.22.26</cira:originatingIpAddress><cira:cprCategory>CCT</cira:cprCategory><cira:ciraAgreementVersion>1.9</cira:ciraAgreementVersion><cira:agreementValue>Y</cira:agreementValue><cira:createdByResellerId>12345</cira:createdByResellerId></cira:ciraCreate></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');


$R2='';
$co=$dri->local_object('contact')->srid('flaguse19');
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
my $co2=$dri->local_object('contact');
$co2->name('Updated Name Field');
$co2->org('');
$co2->street(['32 Wish Bone Avenue']);
$co2->city('Ottawa');
$co2->sp('ON');
$co2->pc('K4M 1N6');
$co2->voice('+1.6134952324');
$co2->fax('+1.6134952323');
$co2->legal_form('CCT');
$co2->lang('fr');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>flaguse19</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="loc"><contact:name>Updated Name Field</contact:name><contact:org/><contact:addr><contact:street>32 Wish Bone Avenue</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K4M 1N6</contact:pc></contact:addr></contact:postalInfo><contact:voice>+1.6134952324</contact:voice><contact:fax>+1.6134952323</contact:fax></contact:chg></contact:update></update><extension><cira:ciraUpdate xmlns:cira="urn:ietf:params:xml:ns:cira-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-1.0 cira-1.0.xsd"><cira:ciraChg><cira:cprCategory>CCT</cira:cprCategory><cira:language>fr</cira:language></cira:ciraChg></cira:ciraUpdate></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');

####################################################################################################
## Domain commands

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>pc-case3.ca</domain:name><domain:roid>CIRA-lifecycle-00122</domain:roid><domain:status s="serverUpdateProhibited">all</domain:status><domain:status s="serverDeleteProhibited"/><domain:status s="serverRenewProhibited"/><domain:status s="serverTransferProhibited"/><domain:status s="serverHold"/><domain:registrant>rant003</domain:registrant><domain:contact type="admin">admin003</domain:contact><domain:contact type="tech">tech003</domain:contact><domain:clID>automatedRARsprint3</domain:clID><domain:crID>automatedRARsprint3</domain:crID><domain:crDate>2009-12-08T16:25:01.0Z</domain:crDate><domain:exDate>2010-12-08T16:25:01.0Z</domain:exDate><domain:authInfo><domain:pw>password2</domain:pw></domain:authInfo></domain:infData></resData><extension><cira:ciraInfo xmlns:cira="urn:ietf:params:xml:ns:cira-1.0"><cira:domainStageOfLife>pending delete</cira:domainStageOfLife><cira:domainStageOfLifeEnd>2009-12-16T16:29:05.0Z</cira:domainStageOfLifeEnd></cira:ciraInfo></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_info('pc-case3.ca',{auth=>{pw=>'password2'}});
is($rc->get_data('stage_of_life'),'pending delete','domain_info get_data(stage_of_life)');
is(''.$rc->get_data('stage_of_life_end'),'2009-12-16T16:29:05','domain_info get_data(stage_of_life_end)');

my $cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('transferrant'),'registrant');
$cs->add($dri->local_object('contact')->srid('transferadmin'),'admin');
$cs->add($dri->local_object('contact')->srid('transfertech1'),'tech');
$rc=$dri->domain_transfer_start('onetech.ca',{auth=>{pw=>'password'},contact=>$cs});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>onetech.ca</domain:name><domain:authInfo><domain:pw>password</domain:pw></domain:authInfo></domain:transfer></transfer><extension><cira:ciraTransfer xmlns:cira="urn:ietf:params:xml:ns:cira-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-1.0 cira-1.0.xsd"><cira:ciraChg><cira:registrant>transferrant</cira:registrant><cira:contact type="admin">transferadmin</cira:contact><cira:contact type="tech">transfertech1</cira:contact></cira:ciraChg></cira:ciraTransfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');


####################################################################################################
## Agreement

## Currently the registry expects a non conforming EPP frame with an <extension> inside <command>
$R2=$E1.'<response>'.r().'<extension><cira:ciraInfo xmlns:cira="urn:ietf:params:xml:ns:cira-1.0"><cira:language>en</cira:language><cira:ciraAgreementVersion>2.0</cira:ciraAgreementVersion><cira:ciraAgreement>REGISTRANT AGREEMENT...complete agreement here</cira:ciraAgreement></cira:ciraInfo></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->agreement_get('en');
is_string($R1,$E1.'<command><extension><cira:ciraInfo xmlns:cira="urn:ietf:params:xml:ns:cira-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-1.0 cira-1.0.xsd"><cira:action>get CIRA latest agreement</cira:action><cira:language>en</cira:language></cira:ciraInfo></extension></command>'.$E2,'agreement_get build');
is($rc->get_data('lang'),'en','agreement_get get_data(lang)');
is($rc->get_data('version'),'2.0','agreement_get get_data(version)');
is($rc->get_data('content'),'REGISTRANT AGREEMENT...complete agreement here','agreement_get get_data(content)');

exit 0;
