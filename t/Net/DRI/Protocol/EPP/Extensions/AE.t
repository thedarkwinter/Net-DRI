#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 36;

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
$dri->add_registry('TRA::AE');
$dri->target('TRA::AE')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->driver();
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{ssl_version => 'TLSv1'},'Net::DRI::Protocol::EPP::Extensions::AE',{}],'AE - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

####################################################################################################
######## Create With IDN ########

$R2=$E1.'<response>'.r().'<resData>
<domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">
<domain:name>xn--wgbhl7a9a.xn--mgbaam7a8h</domain:name>
<domain:crDate>2008-10-06T23:49:30.0Z</domain:crDate>
<domain:exDate>2010-10-06T23:49:30.0Z</domain:exDate>
</domain:creData>
</resData>
<extension>
<creData xmlns="urn:X-ar:paramxml:idnadomain-1.0">
<userForm language="ar-AE ">عصفور.امارات</userForm>
<canonicalForm>عصفور</canonicalForm>
</creData>
</extension>
<trID>
<clTRID>ABC-12345</clTRID>
<svTRID>54321-XYZ</svTRID>
</trID>
</response>'.$E2;

$cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('CON-1');
$cs->set($c1,'registrant');
$rc=$dri->domain_create('xn--wgbhl7a9a.xn--mgbaam7a8h',{pure_create =>1,
                                                        contact     =>$cs,
                                                        auth        =>{pw=>'SjweDcB84E'},
                                                        idn         =>{language=>'ar-AE',user_form=>'عصفور.امارات'}
});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--wgbhl7a9a.xn--mgbaam7a8h</domain:name><domain:registrant>CON-1</domain:registrant><domain:authInfo><domain:pw>SjweDcB84E</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="urn:X-ar:params:xml:ns:idnadomain-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:idnadomain-1.0 idnadomain-1.0.xsd"><idn:userForm language="ar-AE">عصفور.امارات</idn:userForm></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2008-10-06T23:49:30','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2010-10-06T23:49:30','domain_create get_info(exDate) value');


####################################################################################################
######## Info With IDN ########

$R2=$E1.'<response>'.r().'<resData>
<domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">
<domain:name>xn--wgbhl7a9a.xn--mgbaam7a8h</domain:name>
<domain:roid>DF3B3744034DFE2EB3A9154270A6EEF39-ARI</domain:roid>
<domain:status s="ok"/>
<domain:registrant>CTC-057025</domain:registrant>
<domain:contact type="billing">CTC-000277</domain:contact>
<domain:contact type="tech">CTC-000284</domain:contact>
<domain:contact type="admin">CTC-057026</domain:contact>
<domain:ns>
<domain:hostObj>ns1.example.com</domain:hostObj>
<domain:hostObj>ns2.example.com</domain:hostObj>
<domain:hostObj>ns3.example.com</domain:hostObj>
</domain:ns>
<domain:clID>CLIENT1</domain:clID>
<domain:crID>CLIENT2</domain:crID>
<domain:crDate>2022-03-07T18:37:27.0Z</domain:crDate>
<domain:exDate>2023-03-07T18:37:27.0Z</domain:exDate>
<domain:authInfo>
<domain:pw>0;wurc;I08P[0JM]</domain:pw>
</domain:authInfo>
</domain:infData>
</resData>
<extension>
<infData xmlns="urn:X-ar:params:xml:ns:idnadomain-1.0">
<userForm language="ar-AE">عصفور.امارات</userForm>
<canonicalForm>عصفور</canonicalForm>
</infData>
</extension>
'.$TRID.'</response>'.$E2;

$rc=$dri->domain_info('xn--wgbhl7a9a.xn--mgbaam7a8h');

is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">xn--wgbhl7a9a.xn--mgbaam7a8h</domain:name></domain:info></info><extension><variant:info xmlns:variant="urn:X-ar:params:xml:ns:variant-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:variant-1.0 variant-1.0.xsd" variants="all"/></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'DF3B3744034DFE2EB3A9154270A6EEF39-ARI','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'CTC-057025','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'CTC-000277','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'CTC-000284','domain_info get_info(contact) tech srid');
is($s->get('admin')->srid(),'CTC-057026','domain_info get_info(contact) admin srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns2.example.com','ns3.example.com'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'CLIENT1','domain_info get_info(clID)');
is($dri->get_info('crID'),'CLIENT2','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2022-03-07T18:37:27','domain_info get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2023-03-07T18:37:27','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'0;wurc;I08P[0JM]'},'domain_info get_info(auth)');
is($dri->get_info('language'),'ar-AE','domain_info get_info(language)');# idn standard
$d=$dri->get_info('idn');
is_deeply($d,{'user_form' => "عصفور.امارات", 'canonical_form' => "عصفور",'language' => 'ar-AE'}, 'domain_info get_info(idn)'); #AE idn data

#####################################################################################################
######### Closing Commands ########

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

exit 0;
