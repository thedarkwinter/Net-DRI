#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 35;
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

my $rc;
my $s;
my $d;
my ($dh,@c,$idn);

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


exit 0;
