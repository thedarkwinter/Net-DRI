#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More skip_all => 'EURid/Sunrise extension not in use, and probably never needed again in light of the TMCH';
use Test::More tests => 1;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'TRID-0001'; };
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

############################################################################################################
## Sunrise

## Examples from Registration_guidelines_v1_0F-appendix2-sunrise.pdf
$dri->target('EURid')->add_current_profile('p2','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['EURid::Sunrise']});

## p.8
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1500"><msg>Command completed successfully; ending session</msg></result><resData><domain:appData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate></domain:appData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension><trID><clTRID>clientref-12310026</clTRID><svTRID>eurid-1589</svTRID></trID></response></epp>';

my $ro=$dri->remote_object('domain');
$h=$dri->local_object('hosts')->add('ns.c-and-a.eu',['81.2.4.4'],['2001:0:0:0:8:800:200C:417A'])->add('ns.isp.eu'); ## IPv6 changed
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('js5'),'registrant');
$cs->set($dri->local_object('contact')->srid('jd1'),'billing');
$cs->set($dri->local_object('contact')->srid('jd2'),'tech');
$rc=$ro->apply('c-and-a.eu',{reference=>'c-and-a_1',right=>'REG-TM-NAT','prior-right-on-name'=>'c&a','prior-right-country'=>'NL',documentaryevidence=>'applicant','evidence-lang'=>'nl',ns=>$h,contact=>$cs});

is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply><domain:apply xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:right>REG-TM-NAT</domain:right><domain:prior-right-on-name>c&amp;a</domain:prior-right-on-name><domain:prior-right-country>NL</domain:prior-right-country><domain:documentaryevidence><domain:applicant/></domain:documentaryevidence><domain:evidence-lang>nl</domain:evidence-lang><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact></domain:apply></apply><clTRID>TRID-0001</clTRID></command></epp>','domain_apply build'); ## IPv6 changed from EURid example
is($rc->is_success(),1,'domain_apply is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');

## p.12
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:appInfoData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate><domain:status>INITIAL</domain:status><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:docsReceivedDate>2005-11-08T21:46:56.000Z</domain:docsReceivedDate><domain:adr>false</domain:adr></domain:appInfoData></resData><trID><clTRID>TRID-0001</clTRID><svTRID>eurid-0</svTRID></trID></response></epp>'; ## IPv6 changed from EURid example

$ro=$dri->remote_object('domain');
$rc=$ro->apply_info('c-and-a_1');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply-info><domain:apply-info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:reference>c-and-a_1</domain:reference></domain:apply-info></apply-info><clTRID>TRID-0001</clTRID></command></epp>','domain_apply_info build');
is($rc->is_success(),1,'domain_apply_info is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');
is($dri->get_info('application_status'),'INITIAL','domain_apply get_info(application_status)');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_apply get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_apply get_info(contact) types');
is($s->get('billing')->srid(),'jd1','domain_apply get_info(contact) billing srid');
is($s->get('registrant')->srid(),'js5','domain_apply get_info(contact) registrant srid');
is($s->get('tech')->srid(),'jd2','domain_apply get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_apply get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.c-and-a.eu','ns.isp.eu'],'domain_apply get_info(ns) get_names');
@c=$dh->get_details(1);
is($c[0],'ns.c-and-a.eu','domain_apply get_info(ns) get_details(1) 0');
is_deeply($c[1],['81.2.4.4'],'domain_apply get_info(ns) get_details(1) 1');
is_deeply($c[2],['2001:0:0:0:8:800:200C:417A'],'domain_apply get_info(ns) get_details(1) 2');
@c=$dh->get_details(2);
is($c[0],'ns.isp.eu','domain_apply get_info(ns) get_details(2) 0');
is_deeply($c[1],[],'domain_apply get_info(ns) get_details(2) 1');
is_deeply($c[2],[],'domain_apply get_info(ns) get_details(2) 2');
is(''.$dri->get_info('docsReceivedDate'),'2005-11-08T21:46:56','domain_apply get_info(docsReceivedDate)');
is($dri->get_info('adr'),0,'domain_apply get_info(adr)');

exit 0;
