#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 97;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider => 'Tango',name=>'ruhr'});
$dri->target('ruhr')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$dri->add_registry('NGTLD',{provider => 'Tango',name=>'nrw'});
$dri->target('nrw')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$dri->add_registry('NGTLD',{provider => 'Tango',name=>'whoswho'});
$dri->target('whoswho')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$dri->add_registry('NGTLD',{provider => 'corenic',name=>'eus'});
$dri->target('eus')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$idn,$co,$co2);

###################################################################################################

## For whoswho Tango uses fee-0.21 (based on Greeting: 09/09/2020)
$dri->target('whoswho');
$R2=$E1.'<greeting><svID>TANGO testing server</svID><svDate>2014-06-25T10:44:01.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.21</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.21','fee-0.21 loaded correctly');

## For nrw Tango uses the last Fee extension - https://tools.ietf.org/html/rfc8748
$dri->target('nrw');
$R2=$E1.'<greeting><svID>TANGO testing server</svID><svDate>2014-06-25T10:44:01.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:epp:fee-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:epp:fee-1.0','standard Fee-1.0 loaded correctly');

# For ruhr, we make sure no fee extension is loaded
$dri->target('ruhr');
$R2=$E1.'<greeting><svID>TANGO testing server</svID><svDate>2014-06-25T10:44:01.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee},undef,'Fee extension not loaded');



#####################
## IDN Extension

# check with idn language (iso639-1)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example1.ruhr</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example1.ruhr',{'idn' => $dri->local_object('idn')->autodetect('','zh') });
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.ruhr</domain:name></domain:check></check><extension><idn:check xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build_xml');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

# check with idn script (iso15924)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example2.ruhr</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example2.ruhr',{'idn' => $dri->local_object('idn')->autodetect('','Latn')} );
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.ruhr</domain:name></domain:check></check><extension><idn:check xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:script>Latn</idn:script></idn:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build_xml');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

# create with idn language and no variants
$idn = $dri->local_object('idn')->autodetect('example3.ruhr','zh');
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},'idn' => $idn});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants/></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# create with idn language and variants
$idn->variants(['abc.ruhr','xyz.ruhr']);
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},idn => $idn });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:variants></idn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# domain info with variants
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>zh</idn:lang><idn:variants><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:variants></idn:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.ruhr','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso639_1(),'zh','domain_info get_info idn language');
is_deeply($dri->get_info('idn')->variants(),['abc.ruhr','xyz.ruhr'],'domain_info get_info idn_variants');

# domain info with no variants
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example1.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:lang>de</idn:lang><idn:variants /></idn:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example1.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example1.ruhr','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso639_1(),'de','domain_info get_info idn language Tag 639_1');

# domain update with variants
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$idn = $dri->local_object('idn');
$toc->add('idn',$idn->clone()->variants(['ggg.ruhr']));
$toc->del('idn',$idn->clone()->variants(['abc.ruhr','xyz.ruhr']));
$rc=$dri->domain_update('example3.ruhr',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name></domain:update></update><extension><idn:update xmlns:idn="http://xmlns.tango-rs.net/epp/idn-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/idn-1.0 idn-1.0.xsd"><idn:add><idn:nameVariant>ggg.ruhr</idn:nameVariant></idn:add><idn:rem><idn:nameVariant>abc.ruhr</idn:nameVariant><idn:nameVariant>xyz.ruhr</idn:nameVariant></idn:rem></idn:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');


#####################
## Auction Extension

# create with bid
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.ruhr',{pure_create=>1,auth=>{pw=>'2fooBAR'},auction=>{'bid'=>'100.00','currency'=>'EUR'}} );
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><auction:create xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">100.00</auction:bid></auction:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');

# domain update bid
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
$toc=$dri->local_object('changes');
$toc->set('auction',{'bid'=>'200.00','currency'=>'EUR'});
$rc=$dri->domain_update('example3.ruhr',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.ruhr</domain:name></domain:update></update><extension><auction:update xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">200.00</auction:bid></auction:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.ruhr</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><auction:infData xmlns:auction="http://xmlns.tango-rs.net/epp/auction-1.0" xsi:schemaLocation="http://xmlns.tango-rs.net/epp/auction-1.0 auction-1.0.xsd"><auction:bid currency="EUR">10000.00</auction:bid></auction:infData></extension>'.$TRID.'</response>'.$E2;$rc=$dri->domain_info('example3.ruhr');
is($dri->get_info('action'),'info','domain_info get_info(action)');
my $auction = $dri->get_info('auction');
is($auction->{bid},'10000.00','domain_info get_info(bid)');
is($auction->{currency},'EUR','domain_info get_info(currency)');


#####################
## Price fee Extension
# domain_check_price (defaults)
# See fee-0.21.t

#####################
## Augmented Mark (LaunchPhase) Extension (based on dotSCOT-TechDoc-20140710.pdf)

$dri->add_registry('NGTLD',{provider => 'corenic',name=>'scot'});
$dri->target('scot')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

# for the mark processing
my $po=$dri->{registries}->{scot}->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();
my ($doc,$root);
my ($enc,$lp);

# Encoded signed mark validation model
$enc=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWdu
ZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRN
YXJrLTEuMCIgaWQ9InNpZ25lZE1hcmsiPgogIDxzbWQ6aWQ+MS0yPC9zbWQ6aWQ+
CiAgPHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSIyIj4KICAgIDxzbWQ6b3JnPkV4
YW1wbGUgSW5jLjwvc21kOm9yZz4KICAgIDxzbWQ6ZW1haWw+c3VwcG9ydEBleGFt
cGxlLnRsZDwvc21kOmVtYWlsPgogICAgPHNtZDp1cmw+aHR0cDovL3d3dy5leGFt
cGxlLnRsZDwvc21kOnVybD4KICAgIDxzbWQ6dm9pY2UgeD0iMTIzNCI+KzEuNzAz
NTU1NTU1NTwvc21kOnZvaWNlPgogIDwvc21kOmlzc3VlckluZm8+CiAgPHNtZDpu
b3RCZWZvcmU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvc21kOm5vdEJlZm9yZT4K
ICA8c21kOm5vdEFmdGVyPjIwMTAtMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RB
ZnRlcj4KICA8bWFyazptYXJrIHhtbG5zOm1hcms9InVybjppZXRmOnBhcmFtczp4
bWw6bnM6bWFyay0xLjAiPgogICAgPG1hcms6dHJhZGVtYXJrPgogICAgICA8bWFy
azppZD4xMjM0LTI8L21hcms6aWQ+CiAgICAgIDxtYXJrOm1hcmtOYW1lPkV4YW1w
bGUgT25lPC9tYXJrOm1hcmtOYW1lPgogICAgICA8bWFyazpob2xkZXIgZW50aXRs
ZW1lbnQ9Im93bmVyIj4KICAgICAgICA8bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9t
YXJrOm9yZz4KICAgICAgICA8bWFyazphZGRyPgogICAgICAgICAgPG1hcms6c3Ry
ZWV0PjEyMyBFeGFtcGxlIERyLjwvbWFyazpzdHJlZXQ+CiAgICAgICAgICA8bWFy
azpzdHJlZXQ+U3VpdGUgMTAwPC9tYXJrOnN0cmVldD4KICAgICAgICAgIDxtYXJr
OmNpdHk+UmVzdG9uPC9tYXJrOmNpdHk+CiAgICAgICAgICA8bWFyazpzcD5WQTwv
bWFyazpzcD4KICAgICAgICAgIDxtYXJrOnBjPjIwMTkwPC9tYXJrOnBjPgogICAg
ICAgICAgPG1hcms6Y2M+VVM8L21hcms6Y2M+CiAgICAgICAgPC9tYXJrOmFkZHI+
CiAgICAgIDwvbWFyazpob2xkZXI+CiAgICAgIDxtYXJrOmp1cmlzZGljdGlvbj5V
UzwvbWFyazpqdXJpc2RpY3Rpb24+CiAgICAgIDxtYXJrOmNsYXNzPjM1PC9tYXJr
OmNsYXNzPgogICAgICA8bWFyazpjbGFzcz4zNjwvbWFyazpjbGFzcz4KICAgICAg
PG1hcms6bGFiZWw+ZXhhbXBsZS1vbmU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJr
OmxhYmVsPmV4YW1wbGVvbmU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmdvb2Rz
QW5kU2VydmljZXM+RGlyaWdlbmRhcyBldCBlaXVzbW9kaQogICAgICAgIGZlYXR1
cmluZyBpbmZyaW5nbyBpbiBhaXJmYXJlIGV0IGNhcnRhbSBzZXJ2aWNpYS4KICAg
ICAgPC9tYXJrOmdvb2RzQW5kU2VydmljZXM+IAogICAgICA8bWFyazpyZWdOdW0+
MjM0MjM1PC9tYXJrOnJlZ051bT4KICAgICAgPG1hcms6cmVnRGF0ZT4yMDA5LTA4
LTE2VDA5OjAwOjAwLjBaPC9tYXJrOnJlZ0RhdGU+CiAgICAgIDxtYXJrOmV4RGF0
ZT4yMDE1LTA4LTE2VDA5OjAwOjAwLjBaPC9tYXJrOmV4RGF0ZT4KICAgIDwvbWFy
azp0cmFkZW1hcms+CiAgPC9tYXJrOm1hcms+CiAgPFNpZ25hdHVyZSB4bWxucz0i
aHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgICA8U2lnbmVk
SW5mbz4KICAgICAgPENhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJo
dHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgICAg
PFNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIw
MDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz4KICAgICAgPFJlZmVyZW5j
ZSBVUkk9IiNzaWduZWRNYXJrIj4KICAgICAgICA8VHJhbnNmb3Jtcz4KICAgICAg
ICAgIDxUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAw
LzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPgogICAgICAgIDwvVHJh
bnNmb3Jtcz4KICAgICAgICA8RGlnZXN0TWV0aG9kIEFsZ29yaXRobT0iaHR0cDov
L3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjc2hhMjU2Ii8+CiAgICAgICAgPERp
Z2VzdFZhbHVlPm1pRjRNMmFUZDFZM3RLT3pKdGl5bDJWcHpBblZQblYxSHE3WmF4
K3l6ckE9PC9EaWdlc3RWYWx1ZT4KICAgICAgPC9SZWZlcmVuY2U+CiAgICA8L1Np
Z25lZEluZm8+CiAgICA8U2lnbmF0dXJlVmFsdWU+TUVMcEhUV0VWZkcxSmNzRzEv
YS8vbzU0T25sSjVBODY0K1g1SndmcWdHQkJlWlN6R0hOend6VEtGekl5eXlmbgps
R3hWd05Nb0JWNWFTdmtGN29FS01OVnpmY2wvUDBjek5RWi9MSjgzcDNPbDI3L2lV
TnNxZ0NhR2Y5WnVwdytNClhUNFEybE9ySXcrcVN4NWc3cTlUODNzaU1MdmtENXVF
WWxVNWRQcWdzT2JMVFc4L2RvVFFyQTE0UmN4Z1k0a0cKYTQrdDVCMWNUKzVWYWdo
VE9QYjh1VVNFREtqbk9zR2R5OHAyNHdneUs5bjhoMENUU1MyWlE2WnEvUm1RZVQ3
RApzYmNlVUhoZVErbWtRV0lsanBNUXFzaUJqdzVYWGg0amtFZ2ZBenJiNmdrWUVG
K1g4UmV1UFp1T1lDNFFqSUVUCnl4OGlmTjRLRTNHSWJNWGVGNExEc0E9PTwvU2ln
bmF0dXJlVmFsdWU+CiAgICA8S2V5SW5mbz4KICAgICAgPEtleVZhbHVlPgo8UlNB
S2V5VmFsdWU+CjxNb2R1bHVzPgpvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZW
Y01Db3ZVVk5nL3N3V2ludU1nRVdnVlFGcnoweEEwNHBFaFhDCkZWdjRldmJVcGVr
SjVidXFVMWdtUXlPc0NLUWxoT0hUZFBqdmtDNXVwRHFhNTFGbGswVE1hTWtJUWpz
N2FVS0MKbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291NzVi
T1ZuSW9zK0hpZnJBdHJJdjRxRXF3TApMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4
RDVPcjFnY1NhM3Z1cmg1c1BNQ054cWFYbUlYbVFpcFMrRHVFQnFNCk04dGxkYU43
UllvalVFS3JHVnNOazVpOXkyLzdzam4xenl5VVBmN3ZMNEdnRFlxaEpZV1Y2MURu
WGd4L0pkNkMKV3h2c25ERjZzY3NjUXpVVEVsK2h5dz09CjwvTW9kdWx1cz4KPEV4
cG9uZW50PgpBUUFCCjwvRXhwb25lbnQ+CjwvUlNBS2V5VmFsdWU+CjwvS2V5VmFs
dWU+CiAgICAgIDxYNTA5RGF0YT4KPFg1MDlDZXJ0aWZpY2F0ZT5NSUlFU1RDQ0F6
R2dBd0lCQWdJQkFqQU5CZ2txaGtpRzl3MEJBUXNGQURCaU1Rc3dDUVlEVlFRR0V3
SlZVekVMCk1Ba0dBMVVFQ0JNQ1EwRXhGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxi
R1Z6TVJNd0VRWURWUVFLRXdwSlEwRk8KVGlCVVRVTklNUnN3R1FZRFZRUURFeEpK
UTBGT1RpQlVUVU5JSUZSRlUxUWdRMEV3SGhjTk1UTXdNakE0TURBdwpNREF3V2hj
Tk1UZ3dNakEzTWpNMU9UVTVXakJzTVFzd0NRWURWUVFHRXdKVlV6RUxNQWtHQTFV
RUNCTUNRMEV4CkZEQVNCZ05WQkFjVEMweHZjeUJCYm1kbGJHVnpNUmN3RlFZRFZR
UUtFdzVXWVd4cFpHRjBiM0lnVkUxRFNERWgKTUI4R0ExVUVBeE1ZVm1Gc2FXUmhk
Rzl5SUZSTlEwZ2dWRVZUVkNCRFJWSlVNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVG
QUFPQ0FROEFNSUlCQ2dLQ0FRRUFvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZW
Y01Db3ZVVk5nL3N3CldpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQ0ZWdjRldmJVcGVr
SjVidXFVMWdtUXlPc0NLUWxoT0hUZFBqdmtDNXUKcERxYTUxRmxrMFRNYU1rSVFq
czdhVUtDbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291Nwo1
Yk9WbklvcytIaWZyQXRySXY0cUVxd0xMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4
RDVPcjFnY1NhM3Z1cmg1CnNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTU04dGxkYU43
UllvalVFS3JHVnNOazVpOXkyLzdzam4xenl5VVBmN3YKTDRHZ0RZcWhKWVdWNjFE
blhneC9KZDZDV3h2c25ERjZzY3NjUXpVVEVsK2h5d0lEQVFBQm80SC9NSUg4TUF3
RwpBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRlBaRWNJUWNEL0JqMklGei9M
RVJ1bzJBREp2aU1JR01CZ05WCkhTTUVnWVF3Z1lHQUZPMC83a0VoM0Z1RUtTK1Ev
a1lIYUQvVzZ3aWhvV2FrWkRCaU1Rc3dDUVlEVlFRR0V3SlYKVXpFTE1Ba0dBMVVF
Q0JNQ1EwRXhGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJNd0VRWURWUVFL
RXdwSgpRMEZPVGlCVVRVTklNUnN3R1FZRFZRUURFeEpKUTBGT1RpQlVUVU5JSUZS
RlUxUWdRMEdDQVFFd0RnWURWUjBQCkFRSC9CQVFEQWdlQU1DNEdBMVVkSHdRbk1D
VXdJNkFob0IrR0hXaDBkSEE2THk5amNtd3VhV05oYm00dWIzSm4KTDNSdFkyZ3VZ
M0pzTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFCMnFTeTd1aSs0M2NlYktVS3dX
UHJ6ejl5LwpJa3JNZUpHS2pvNDBuKzl1ZWthdzNESjVFcWlPZi9xWjRwakJEKytv
UjZCSkNiNk5RdVFLd25vQXo1bEU0U3N1Cnk1K2k5M29UM0hmeVZjNGdOTUlvSG0x
UFMxOWw3REJLcmJ3YnpBZWEvMGpLV1Z6cnZtVjdUQmZqeEQzQVFvMVIKYlU1ZEJy
NklqYmRMRmxuTzV4MEcwbXJHN3g1T1VQdXVyaWh5aVVScEZEcHdIOEtBSDF3TWND
cFhHWEZSdEdLawp3eWRneVZZQXR5N290a2wvejNiWmtDVlQzNGdQdkY3MHNSNitR
eFV5OHUwTHpGNUEvYmVZYVpweFNZRzMxYW1MCkFkWGl0VFdGaXBhSUdlYTlsRUdG
TTBMOStCZzdYek5uNG5WTFhva3lFQjNiZ1M0c2NHNlF6blgyM0ZHazwvWDUwOUNl
cnRpZmljYXRlPgo8L1g1MDlEYXRhPgogICAgPC9LZXlJbmZvPgogIDwvU2lnbmF0
dXJlPgo8L3NtZDpzaWduZWRNYXJrPgo=
</smd:encodedSignedMark>
EOF
chomp $enc;
$doc=$parser->parse_string($enc);
$root=$doc->getDocumentElement();

# 1.2 "Sunrise" Launch Phase
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $root ]};
$rc=$dri->domain_create('example1-2.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-2.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0">'.$root.'<ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create sunrise launch phase build_xml [encoded_signed_mark validation model - using xml root element]');

# 1.3 "Public Interest" Launch Phase
$lp = {phase => 'public-interest'};
$rc=$dri->domain_create('example1-3.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,reference_url=>'http://xmlns.corenic.net/epp/test',intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-3.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase name="public-interest">custom</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="reference-url">http://xmlns.corenic.net/epp/test</ext:applicationInfo><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create public interest launch phase');

# 1.4 "Local Trademark" Launch Phase
$lp = {phase => 'local-trademark'};
$rc=$dri->domain_create('example1-4.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,trademark_id=>'my-mark-123',trademark_issuer=>'Trademark Administration of Someplace',intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-4.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase name="local-trademark">custom</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="trademark-id">my-mark-123</ext:applicationInfo><ext:applicationInfo type="trademark-issuer">Trademark Administration of Someplace</ext:applicationInfo><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create local trademark launch phase');

# 1.5 "Local Entities" Launch Phase
$lp = {phase => 'local-entities'};
$rc=$dri->domain_create('example1-5.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,reference_url=>'http://xmlns.corenic.net/epp/test',intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-5.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase name="local-entities">custom</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="reference-url">http://xmlns.corenic.net/epp/test</ext:applicationInfo><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create local entities launch phase');

# 1.6 "Landrush" Launch Phase
$lp = {phase => 'landrush'};
$rc=$dri->domain_create('example1-6.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-6.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>landrush</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create landrush launch phase');

# 1.7 "Claims" Phase
$lp = {phase => 'claims'};
$rc=$dri->domain_create('example1-7.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-7.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create claims phase');

# 1.8 "GA" Phase
$lp = {phase => 'open'};
$rc=$dri->domain_create('example1-8.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1-8.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>open</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create GA phase');

## Not documented, but testing with claims notices
$lp = {phase => 'claims', notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$rc=$dri->domain_create('examplen-d.scot',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp,intended_use=>'fooBAR'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplen-d.scot</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><ext:augmentedMark xmlns:ext="http://xmlns.corenic.net/epp/mark-ext-1.0"><ext:applicationInfo type="intended-use">fooBAR</ext:applicationInfo></ext:augmentedMark><launch:notice><launch:noticeID>abc123</launch:noticeID><launch:notAfter>2008-12-01T00:00:00Z</launch:notAfter><launch:acceptedDate>2009-10-01T00:00:00Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create GA phase');

#####################
## Contact Eligibility Extension

$dri->add_registry('NGTLD',{provider => 'corenic',name=>'swiss'});
$dri->{registries}->{swiss}->{driver}->{info}->{contact_i18n} = 2;
$dri->target('swiss')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

# contact info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="int"><contact:name>Hans Mustermann</contact:name><contact:org>Musterfirma</contact:org><contact:addr><contact:street>Beispielweg 1</contact:street><contact:city>Bern</contact:city><contact:sp>Bern</contact:sp><contact:pc>123456</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><el:infData xmlns:el="http://xmlns.corenic.net/epp/contact-eligibility-1.0"><el:enterpriseID>DE-ID-122322322</el:enterpriseID><el:validationStatus>validationPending</el:validationStatus></el:infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($dri->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('enterprise_id'),'DE-ID-122322322','contact_info get_info(enterpriseID)');
is($dri->get_info('validation_status'),'validationPending','contact_info get_info(validationStatus)');

# contact create
$R2='';
$co=$dri->local_object('contact')->srid('sh8013');
$co->name('Hans Mustermann');
$co->org('Musterfirma');
$co->street(['Beispielweg 1']);
$co->city('Bern');
$co->sp('Bern');
$co->pc('123456');
$co->cc('CH');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.com');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
$co->enterprise_id('DE-ID-122322322');
$rc=$dri->contact_create($co);
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:postalInfo type="int"><contact:name>Hans Mustermann</contact:name><contact:org>Musterfirma</contact:org><contact:addr><contact:street>Beispielweg 1</contact:street><contact:city>Bern</contact:city><contact:sp>Bern</contact:sp><contact:pc>123456</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><el:create xmlns:el="http://xmlns.corenic.net/epp/contact-eligibility-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/contact-eligibility-1.0 contact-eligibility-1.0.xsd"><el:enterpriseID>DE-ID-122322322</el:enterpriseID></el:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');

# contact update: changing the eligibility information of a contact, along with other contact data
$R2='';
$co=$dri->local_object('contact')->srid('sh8013');
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
$co2=$dri->local_object('contact');
$co2->name('Hans Mustermann');
$co2->org('');
$co2->street(['Beispielweg 1']);
$co2->city('Bern');
$co2->sp('Bern');
$co2->pc('123456');
$co2->cc('CH');
$co2->voice('+1.7034444444');
$co2->fax('');
$co2->auth({pw=>'2fooBAR'});
$co2->disclose({voice=>1,email=>1});
$co2->enterprise_id('DE-ID-122322325');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="int"><contact:name>Hans Mustermann</contact:name><contact:org/><contact:addr><contact:street>Beispielweg 1</contact:street><contact:city>Bern</contact:city><contact:sp>Bern</contact:sp><contact:pc>123456</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><extension><el:update xmlns:el="http://xmlns.corenic.net/epp/contact-eligibility-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/contact-eligibility-1.0 contact-eligibility-1.0.xsd"><el:chg><el:enterpriseID>DE-ID-122322325</el:enterpriseID></el:chg></el:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build along other contact data');
is($rc->is_success(),1,'contact_update is_success');

# contact update: changing the eligibility information of a contact, retaining other contact data
$R2='';
$co=$dri->local_object('contact')->srid('sh8013');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->enterprise_id('DE-ID-122322324');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id></contact:update></update><extension><el:update xmlns:el="http://xmlns.corenic.net/epp/contact-eligibility-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/contact-eligibility-1.0 contact-eligibility-1.0.xsd"><el:chg><el:enterpriseID>DE-ID-122322324</el:enterpriseID></el:chg></el:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build retaining other contact data');
is($rc->is_success(),1,'contact_update is_success');

# contact update: removing the eligibility information of a contact, retaining other contact data
$R2='';
$co=$dri->local_object('contact')->srid('sh8013');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->enterprise_id('');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id></contact:update></update><extension><el:update xmlns:el="http://xmlns.corenic.net/epp/contact-eligibility-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/contact-eligibility-1.0 contact-eligibility-1.0.xsd"><el:chg><el:enterpriseID/></el:chg></el:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build removing the eligibility information');
is($rc->is_success(),1,'contact_update is_success');

#####################
## Promotion Extension

# domain create: with promotional code
$dri->target('eus');
$R2='';
my $cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('abc123'),'registrant');
$cs->add($dri->local_object('contact')->srid('def456'),'admin');
$cs->add($dri->local_object('contact')->srid('ghi789'),'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net');
$dh->add('ns2.example.net');
my $promo_c='EXAMPLE-PROMO-1231';
$rc=$dri->domain_create('example.eus',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'secret42'},promo_code=>$promo_c} );
is($rc->is_success(),1,'domain_create is_success adding promotion extension');
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.eus</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>abc123</domain:registrant><domain:contact type="admin">def456</domain:contact><domain:contact type="tech">ghi789</domain:contact><domain:authInfo><domain:pw>secret42</domain:pw></domain:authInfo></domain:create></create><extension><promo:create xmlns:promo="http://xmlns.corenic.net/epp/promotion-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/promotion-1.0 promotion-1.0.xsd"><promo:code>EXAMPLE-PROMO-1231</promo:code></promo:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml adding promotion extension');

# domain renew: with promotional code
$R2='';
$rc=$dri->domain_renew('example.eus',{current_expiration => DateTime->new(year=>2015,month=>04,day=>03),duration=>DateTime::Duration->new(years=>1),promo_code=>$promo_c});
is_string($R1,$E1.'<command><update><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.eus</domain:name><domain:curExpDate>2015-04-03</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></update><extension><promo:renew xmlns:promo="http://xmlns.corenic.net/epp/promotion-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/promotion-1.0 promotion-1.0.xsd"><promo:code>EXAMPLE-PROMO-1231</promo:code></promo:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build adding promotion extension');
is($rc->is_success(),1,'domain_renew is_success adding promotion extension');

# domain promo info response: testing promotional codes info commands
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><promo:infData xmlns:promo="http://xmlns.domini.cat/epp/promo-1.0"><promo:promo><promo:promotionName>Promotion 2015</promo:promotionName><promo:validity from="2015-01-01T00:00:00.0Z" to="2015-04-01T00:00:00.0Z" /><promo:utilization avail="true"><promo:enabled>true</promo:enabled><promo:operations>create renew</promo:operations><promo:codeUsable>true</promo:codeUsable><promo:inValidityPeriod>true</promo:inValidityPeriod><promo:validDomainName>true</promo:validDomainName></promo:utilization></promo:promo><promo:pricing><promo:total value="20.00" mu="EUR" /></promo:pricing></promo:infData></resData>' . $TRID . '</response>' . $E2;

# domain promo info details
my $promo_hash = {
  domain => {name => 'example.eus'},
  price => {
    type => 'create',
    duration => DateTime::Duration->new(years=>4,months=>6)},
  ref_date => {
    rdate => DateTime->new(year=>2016,month=>07,day=>01,hour=>10,minute=>10,second=>0)},
  lp => {
    phase => 'custom',
    sub_phase => 'special-phase'}
}; # for the duration you can use any date time units as long as your TOTAL time is less than 99 months..

$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><infData xmlns="http://xmlns.tango-rs.net/epp/promotion-info-1.0"><promo><promotionName>Unlimited Creation codes</promotionName><validity from="2016-09-20T13:40:00.000Z" /><utilization avail="true"><enabled>true</enabled><operations>create</operations><codeUsable>true</codeUsable><inValidityPeriod>true</inValidityPeriod><validDomainName>true</validDomainName></utilization></promo><pricing><total mu="EUR" value="25" /></pricing></infData></resData>' . $TRID . '</response>' . $E2;
$rc=$dri->promo_info('EXAMPLE-PROMO-1231',{promo_data=>$promo_hash});
is_string($R1,$E1.'<command><info ><promo:info xmlns:promo="http://xmlns.corenic.net/epp/promotion-info-1.0" xsi:schemaLocation="http://xmlns.corenic.net/epp/promotion-info-1.0 promotion-info-1.0.xsd"><promo:code>EXAMPLE-PROMO-1231</promo:code><promo:domain><promo:name>example.eus</promo:name></promo:domain><promo:pricing><promo:create><promo:period unit="m">54</promo:period></promo:create></promo:pricing><promo:refdate>2016-07-01T10:10:00.0Z</promo:refdate><promo:phase name="special-phase">custom</promo:phase></promo:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_promo_info build quering promotion details');
is($rc->is_success(),1,'domain_promo_info is_success quering promotion details');

# domain promo info parse: testing the parsing of promotional information from the response
my $promo_validity = $dri->get_info('validity');
my $promo_utilization = $dri->get_info('utilization');
my $promo_total = $dri->get_info('total');
my $promo_promotionName = $dri->get_info('promotion_name');

# validity
is(defined($promo_validity), 1 ,'promo_info get_info(validity) defined');
is($promo_validity->{'valid_until'},undef,'promo_info parse (validUntil)');
is($promo_validity->{'valid_from'},'2016-09-20T13:40:00','promo_info parse (validFrom)');

# utilization
is(defined($promo_utilization), 1 ,'promo_info get_info(utilization) defined');
is($promo_utilization->{'valid_domain_name'},'true','promo_info parse (validDomainName)');
is($promo_utilization->{'code_usable'},'true','promo_info parse (codeUsable)');
is($promo_utilization->{'available'},'true','promo_info parse (available)');
is($promo_utilization->{'operations'},'create','promo_info parse (operations)');
is($promo_utilization->{'in_validity_period'},'true','promo_info parse (inValidityPeriod)');
is($promo_utilization->{'enabled'},'true','promo_info parse (enabled)');

# total
is(defined($promo_total), 1 ,'promo_info get_info(total) defined');
is($promo_total->{'price'},'25','promo_info parse (price)');
is($promo_total->{'currency'},'EUR','promo_info parse (currency)');

# promotion name
is(defined($promo_promotionName), 1 ,'promo_info get_info(promotionName) defined');
is($promo_promotionName,'Unlimited Creation codes','promo_info parse (promotionName)');

#########################################################################################################
## CHECK That normal LaunchPhase functions still will when using TangoRS::LaunchPhase extension
$dri->target('eus');
$dri->cache_clear();
my ($lpres);

# Claims Check Form using a custom phase name with custom (autodetected)
$lp = {type=>'claims','phase'=>'foobar'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="foobar">custom</launch:phase><launch:cd><launch:name exists="1">examplef.eus</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplef.eus',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplef.eus</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="foobar">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');

# Claims Check Form using a claims phase with custom sub_phase
$lp = { type=>'claims','phase'=>'claims', 'sub_phase'=>'barfoo' } ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase name="barfoo">claims</launch:phase><launch:cd><launch:name exists="1">examplef2.eus</launch:name><launch:claimKey validatorID="sample">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('examplef2.eus',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>examplef2.eus</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase name="barfoo">claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');

# With multiple claims (launchphase-02), claim_key became 1 or more, so we need to make room for this without breaking backwards compatibility
$lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="1">exampleg2.eus</launch:name><launch:claimKey validatorID="tmch">2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001</launch:claimKey><launch:claimKey validatorID="custom-tmch">20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('exampleg2.eus',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampleg2.eus</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="claims"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check get_info(exist)');
is($lpres->{'phase'},'claims','domain_check get_info(phase)');
# pre launchphase-02 method will only get the last claim, but its safe if there is only one claim
is($lpres->{'claim_key'},'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','domain_check get_info(claim_key) ');
is($lpres->{'validator_id'},'custom-tmch','domain_check get_info(validator_id) ');
# added claims_count and claims in launchphase-02
is($lpres->{'claims_count'},'2','domain_check get_info(claims_count)');
is_deeply($lpres->{'claims'},[{claim_key=>'2013041500/2/6/9/rJ1NrDO92vDsAzf7EQzgjX4R0000000001','validator_id'=>'tmch'},{claim_key=>'20140423200/1/2/3/rJ1Nr2vDsAzasdff7EasdfgjX4R000000002','validator_id'=>'custom-tmch'}],'domain_check get_info(claims_count)');

#3.1.2.  Availability Check Form
$lp = {phase=>'idn-release',type=>'avail'};
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.eus</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.eus',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.eus</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="avail"><launch:phase name="idn-release">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

#3.1.2.  Availability Check Form
$lp = {phase=>'idn-release',type=>'avail'};
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.eus</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.eus',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.eus</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="avail"><launch:phase name="idn-release">custom</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check build_xml');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');

## INFO
#3.2.  EPP <info> Command
$lp = {phase => 'sunrise','application_id'=>'abc123','include_mark'=>'true'};
my $markxml = '<mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>1234-2</mark:id><mark:markName>Example One</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>US</mark:cc></mark:addr></mark:holder><mark:jurisdiction>US</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:label>example-one</mark:label><mark:label>exampleone</mark:label><mark:goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-16T09:00:00.0Z</mark:regDate><mark:exDate>2015-08-16T09:00:00.0Z</mark:exDate></mark:trademark></mark:mark>';
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.eus</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.eus</domain:hostObj><domain:hostObj>ns2.example.eus</domain:hostObj></domain:ns><domain:host>ns1.example.eus</domain:host><domain:host>ns2.example.eus</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>abc123</launch:applicationID><launch:status s="pendingAllocation"/>'.$markxml.'</launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.eus',{lp => $lp});
is ($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example2.eus</domain:name></domain:info></info><extension><launch:info xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" includeMark="true"><launch:phase>sunrise</launch:phase><launch:applicationID>abc123</launch:applicationID></launch:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build_xml');
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'sunrise','domain_info get_info(phase) ');
is($lpres->{'application_id'},'abc123','domain_info get_info(application_id) ');
is($lpres->{'status'},'pendingAllocation','domain_info get_info(launch_status) ');
my @marks = @{$lpres->{'marks'}};
my $m = $marks[0];
is ($m->{mark_name},'Example One','domain_info get_info(mark name)');

$doc=$parser->parse_string('<?xml version="1.0" encoding="UTF-8"?>'.$markxml);
$root=$doc->getDocumentElement();
my $m2=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_mark($po,$root);
is_deeply($m, @{$m2}[0], 'data structures should be the same');

# UPDATE
$lp = {phase => 'sunrise','application_id'=>'abc321'};
$R2='';
$toc=$dri->local_object('changes');
$toc->set('lp',$lp);
$rc=$dri->domain_update('example10.eus',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.eus</domain:name></domain:update></update><extension><launch:update xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>abc321</launch:applicationID></launch:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');


# DELETE
$lp = {phase => 'sunrise','application_id'=>'abc321'};
$R2='';
$rc=$dri->domain_delete('example10.eus',{pure_delete=>1,lp=>$lp});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.eus</domain:name></domain:delete></delete><extension><launch:delete xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>abc321</launch:applicationID></launch:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build_xml');

#########################################################################################################
## POLL MESSAGE

# *with* domain:infData
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="81"><qDate>2017-07-13T12:00:00.000Z</qDate></msgQ><resData><panData xmlns="urn:ietf:params:xml:ns:domain-1.0"><name paResult="true">examplepoll.eus</name><paTRID><svTRID xmlns="urn:ietf:params:xml:ns:epp-1.0">54322-XYZ</svTRID></paTRID><paDate>2017-07-13T00:00:00.000Z</paDate></panData></resData><extension><infData xmlns="urn:ietf:params:xml:ns:launch-1.0"><phase>open</phase><applicationID>app123</applicationID><status s="allocated" /></infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),81,'message_retrieve get_info(last_id)');
$lp = $dri->get_info('lp','message',81);
is($lp->{'application_id'},'app123','message_retrieve get_info lp->{application_id}');
is($lp->{'phase'},'open','message_retrieve get_info lp->{phase}');
is($lp->{'status'},'allocated','message_retrieve get_info lp->{status}');

exit 0;
