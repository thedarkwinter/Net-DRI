#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 28;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn,$toc);
my @core_modules = map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Contact Host/;

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('Neustar::Narwal');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});
is_deeply( $dri->protocol()->{loaded_modules},[@core_modules, map { 'Net::DRI::Protocol::EPP::Extensions::'.$_ } qw/GracePeriod SecDNS NeuLevel::Message AllocationToken ARI::IDNVariant ARI::KeyValue ARI::ExAvail ARI::Price ARI::TMCHApplication ARI::Block NeuLevel::EXTContact/],'Neustar::Narwal (Ari): loaded_modules');

#####################
## TMCHApplication Extension (TMCH + Application = LaunchPhase type system)

my $encoded_mark = <<'EOF';
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWdu
ZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRN
YXJrLTEuMCIgeG1sOmlkPSJzaWduZWRNYXJrIj4KICA8c21kOmlkPjEtMjwvc21k
OmlkPgogIDxzbWQ6aXNzdWVySW5mbyBpc3N1ZXJJRD0iMiI+CiAgICA8c21kOm9y
Zz5FeGFtcGxlIEluYy48L3NtZDpvcmc+CiAgICA8c21kOmVtYWlsPnN1cHBvcnRA
ZXhhbXBsZS50bGQ8L3NtZDplbWFpbD4KICAgIDxzbWQ6dXJsPmh0dHA6Ly93d3cu
ZXhhbXBsZS50bGQ8L3NtZDp1cmw+CiAgICA8c21kOnZvaWNlIHg9IjEyMzQiPisx
LjcwMzU1NTU1NTU8L3NtZDp2b2ljZT4KICA8L3NtZDppc3N1ZXJJbmZvPgogIDxz
bWQ6bm90QmVmb3JlPjIwMDktMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RCZWZv
cmU+CiAgPHNtZDpub3RBZnRlcj4yMDEwLTA4LTE2VDA5OjAwOjAwLjBaPC9zbWQ6
bm90QWZ0ZXI+CiAgPG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJh
bXM6eG1sOm5zOm1hcmstMS4wIj4KICAgIDxtYXJrOnRyYWRlbWFyaz4KICAgICAg
PG1hcms6aWQ+MTIzNC0yPC9tYXJrOmlkPgogICAgICA8bWFyazptYXJrTmFtZT5F
eGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT4KICAgICAgPG1hcms6aG9sZGVyIGVu
dGl0bGVtZW50PSJvd25lciI+CiAgICAgICAgPG1hcms6b3JnPkV4YW1wbGUgSW5j
LjwvbWFyazpvcmc+CiAgICAgICAgPG1hcms6YWRkcj4KICAgICAgICAgIDxtYXJr
OnN0cmVldD4xMjMgRXhhbXBsZSBEci48L21hcms6c3RyZWV0PgogICAgICAgICAg
PG1hcms6c3RyZWV0PlN1aXRlIDEwMDwvbWFyazpzdHJlZXQ+CiAgICAgICAgICA8
bWFyazpjaXR5PlJlc3RvbjwvbWFyazpjaXR5PgogICAgICAgICAgPG1hcms6c3A+
VkE8L21hcms6c3A+CiAgICAgICAgICA8bWFyazpwYz4yMDE5MDwvbWFyazpwYz4K
ICAgICAgICAgIDxtYXJrOmNjPlVTPC9tYXJrOmNjPgogICAgICAgIDwvbWFyazph
ZGRyPgogICAgICA8L21hcms6aG9sZGVyPgogICAgICA8bWFyazpqdXJpc2RpY3Rp
b24+VVM8L21hcms6anVyaXNkaWN0aW9uPgogICAgICA8bWFyazpjbGFzcz4zNTwv
bWFyazpjbGFzcz4KICAgICAgPG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+CiAg
ICAgIDxtYXJrOmxhYmVsPmV4YW1wbGUtb25lPC9tYXJrOmxhYmVsPgogICAgICA8
bWFyazpsYWJlbD5leGFtcGxlb25lPC9tYXJrOmxhYmVsPgogICAgICA8bWFyazpn
b29kc0FuZFNlcnZpY2VzPkRpcmlnZW5kYXMgZXQgZWl1c21vZGkKICAgICAgICBm
ZWF0dXJpbmcgaW5mcmluZ28gaW4gYWlyZmFyZSBldCBjYXJ0YW0gc2VydmljaWEu
CiAgICAgIDwvbWFyazpnb29kc0FuZFNlcnZpY2VzPiAKICAgICAgPG1hcms6cmVn
TnVtPjIzNDIzNTwvbWFyazpyZWdOdW0+CiAgICAgIDxtYXJrOnJlZ0RhdGU+MjAw
OS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpyZWdEYXRlPgogICAgICA8bWFyazpl
eERhdGU+MjAxNS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpleERhdGU+CiAgICA8
L21hcms6dHJhZGVtYXJrPgogIDwvbWFyazptYXJrPgogIDxTaWduYXR1cmUgeG1s
bnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPgogICAgPFNp
Z25lZEluZm8+CiAgICAgIDxDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRo
bT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAg
ICAgIDxTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9y
Zy8yMDAxLzA0L3htbGRzaWctbW9yZSNyc2Etc2hhMjU2Ii8+CiAgICAgIDxSZWZl
cmVuY2UgVVJJPSIjc2lnbmVkTWFyayI+CiAgICAgICAgPFRyYW5zZm9ybXM+CiAg
ICAgICAgICA8VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcv
MjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz4KICAgICAgICA8
L1RyYW5zZm9ybXM+CiAgICAgICAgPERpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0
dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPgogICAgICAg
IDxEaWdlc3RWYWx1ZT4rSDc3ajNlMVZ4bDM1bk9MdHdLbHdvdFdZSTFaTnIycm1G
ZmlPRnZMM3VjPTwvRGlnZXN0VmFsdWU+CiAgICAgIDwvUmVmZXJlbmNlPgogICAg
PC9TaWduZWRJbmZvPgogICAgPFNpZ25hdHVyZVZhbHVlPlZpYUdaZWxnOU5tL1Bm
SkVONGxGYXRoSnhPL3YxTndJV0hQTjFyZ0Z4a2lsK1lwT08xK1RNa2Y5Ymx1eW1B
ZGcKekpFQWQrTlVuRURZa2swQ2RkTDgxb095cmE1T0F0UHNjeEpGVmt5ZzdBS3U3
SDdwTTArMHZ6bnJWakU5TFE1ZApiMTEwUjFRQnJpcUxIcmpkYzZOSnhHVlhqRXEy
bTE0VXQ0VFdtcWdsTVNWdTluL2lVRVg0SHJDSFBSbE9ra01yCmVwVHk2M21xdWZB
c3JrTk54WllJSnBDL1Y5blZnU1hOVE56Zjg0UVMvTG5GNnhkS25ZTDY3Z0VXa1pU
YnppWWoKNU43RnhnM003OEgrU0NvOEQ4YUJzZFl5VkxZS1ByUC9FUWFQbHh3K2Z4
UFQ2MUl4U0VJVy81UnZ6cjdYalpDNwpybEFoNGdDOU5DazlDMnVyVXlycEVnPT08
L1NpZ25hdHVyZVZhbHVlPgogICAgPEtleUluZm8+CiAgICAgIDxLZXlWYWx1ZT4K
PFJTQUtleVZhbHVlPgo8TW9kdWx1cz4Kby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVU
VlpWVmNNQ292VVZOZy9zd1dpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQwpGVnY0ZXZi
VXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1cERxYTUxRmxrMFRNYU1r
SVFqczdhVUtDCm1BNFJHNHRUVEdLL0VqUjFpeDgvRDBnSFlWUmxkeTFZUHJNUCtv
dTc1Yk9WbklvcytIaWZyQXRySXY0cUVxd0wKTDRGVFpBVXBhQ2EyQm1nWGZ5MkNT
UlFieEQ1T3IxZ2NTYTN2dXJoNXNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTQpNOHRs
ZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2TDRHZ0RZcWhKWVdW
NjFEblhneC9KZDZDCld4dnNuREY2c2NzY1F6VVRFbCtoeXc9PQo8L01vZHVsdXM+
CjxFeHBvbmVudD4KQVFBQgo8L0V4cG9uZW50Pgo8L1JTQUtleVZhbHVlPgo8L0tl
eVZhbHVlPgogICAgICA8WDUwOURhdGE+CjxYNTA5Q2VydGlmaWNhdGU+TUlJRVNU
Q0NBekdnQXdJQkFnSUJBakFOQmdrcWhraUc5dzBCQVFzRkFEQmlNUXN3Q1FZRFZR
UUdFd0pWVXpFTApNQWtHQTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJi
bWRsYkdWek1STXdFUVlEVlFRS0V3cEpRMEZPClRpQlVUVU5JTVJzd0dRWURWUVFE
RXhKSlEwRk9UaUJVVFVOSUlGUkZVMVFnUTBFd0hoY05NVE13TWpBNE1EQXcKTURB
d1doY05NVGd3TWpBM01qTTFPVFU1V2pCc01Rc3dDUVlEVlFRR0V3SlZVekVMTUFr
R0ExVUVDQk1DUTBFeApGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJjd0ZR
WURWUVFLRXc1V1lXeHBaR0YwYjNJZ1ZFMURTREVoCk1COEdBMVVFQXhNWVZtRnNh
V1JoZEc5eUlGUk5RMGdnVkVWVFZDQkRSVkpVTUlJQklqQU5CZ2txaGtpRzl3MEIK
QVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVU
VlpWVmNNQ292VVZOZy9zdwpXaW51TWdFV2dWUUZyejB4QTA0cEVoWENGVnY0ZXZi
VXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1CnBEcWE1MUZsazBUTWFN
a0lRanM3YVVLQ21BNFJHNHRUVEdLL0VqUjFpeDgvRDBnSFlWUmxkeTFZUHJNUCtv
dTcKNWJPVm5Jb3MrSGlmckF0ckl2NHFFcXdMTDRGVFpBVXBhQ2EyQm1nWGZ5MkNT
UlFieEQ1T3IxZ2NTYTN2dXJoNQpzUE1DTnhxYVhtSVhtUWlwUytEdUVCcU1NOHRs
ZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2Ckw0R2dEWXFoSllX
VjYxRG5YZ3gvSmQ2Q1d4dnNuREY2c2NzY1F6VVRFbCtoeXdJREFRQUJvNEgvTUlI
OE1Bd0cKQTFVZEV3RUIvd1FDTUFBd0hRWURWUjBPQkJZRUZQWkVjSVFjRC9CajJJ
RnovTEVSdW8yQURKdmlNSUdNQmdOVgpIU01FZ1lRd2dZR0FGTzAvN2tFaDNGdUVL
UytRL2tZSGFEL1c2d2lob1dha1pEQmlNUXN3Q1FZRFZRUUdFd0pWClV6RUxNQWtH
QTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJibWRsYkdWek1STXdFUVlE
VlFRS0V3cEoKUTBGT1RpQlVUVU5JTVJzd0dRWURWUVFERXhKSlEwRk9UaUJVVFVO
SUlGUkZVMVFnUTBHQ0FRRXdEZ1lEVlIwUApBUUgvQkFRREFnZUFNQzRHQTFVZEh3
UW5NQ1V3STZBaG9CK0dIV2gwZEhBNkx5OWpjbXd1YVdOaGJtNHViM0puCkwzUnRZ
Mmd1WTNKc01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjJxU3k3dWkrNDNjZWJL
VUt3V1Byeno5eS8KSWtyTWVKR0tqbzQwbis5dWVrYXczREo1RXFpT2YvcVo0cGpC
RCsrb1I2QkpDYjZOUXVRS3dub0F6NWxFNFNzdQp5NStpOTNvVDNIZnlWYzRnTk1J
b0htMVBTMTlsN0RCS3Jid2J6QWVhLzBqS1dWenJ2bVY3VEJmanhEM0FRbzFSCmJV
NWRCcjZJamJkTEZsbk81eDBHMG1yRzd4NU9VUHV1cmloeWlVUnBGRHB3SDhLQUgx
d01jQ3BYR1hGUnRHS2sKd3lkZ3lWWUF0eTdvdGtsL3ozYlprQ1ZUMzRnUHZGNzBz
UjYrUXhVeTh1MEx6RjVBL2JlWWFacHhTWUczMWFtTApBZFhpdFRXRmlwYUlHZWE5
bEVHRk0wTDkrQmc3WHpObjRuVkxYb2t5RUIzYmdTNHNjRzZRem5YMjNGR2s8L1g1
MDlDZXJ0aWZpY2F0ZT4KPC9YNTA5RGF0YT4KICAgIDwvS2V5SW5mbz4KICA8L1Np
Z25hdHVyZT4KPC9zbWQ6c2lnbmVkTWFyaz4K
EOF
chomp $encoded_mark;
$encoded_mark =~ s/^\s+//gs;
$encoded_mark =~ s/\s+$//gs;
#$encoded_mark =~ s/\s+//gs;
#print $encoded_mark;

# domain check (claims check)
my $lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><tmch:chkData xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0"><tmch:cd><tmch:name claim="1">example2.menu</tmch:name><tmch:key>CLAIM_KEY</tmch:key></tmch:cd></tmch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example2.menu',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.menu</domain:name></domain:check></check><extension><tmch:check xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check claims build_xml');
my $lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check get_info(exist)');
is($lpres->{'type'},'claims','domain_check get_info(type) ');
is($lpres->{'claim_key'},'CLAIM_KEY','domain_check get_info(claim_key) ');

# domain info
$lp = {'application_id'=>'3F2504E0-4F89-11D3-9A0C-0305E82C3301','include_mark'=>'true'};
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><application:infData xmlns:application="urn:ar:params:xml:ns:application-1.0"><application:id>3F2504E0-4F89-11D3-9A0C-0305E82C3301</application:id><application:phase>landrush</application:phase><application:status s="pendingAllocation" /></application:infData><tmch:infData xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0"><tmch:smd>'.$encoded_mark.'</tmch:smd></tmch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example4.menu',{lp => $lp});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example4.menu</domain:name></domain:info></info><extension><application:info xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>3F2504E0-4F89-11D3-9A0C-0305E82C3301</application:id></application:info><tmch:info xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info lp build_xml');
is($dri->get_info('action'),'info','domain_info lp get_info(action)');
is($dri->get_info('name'),'example4.menu','domain_info lp get_info name');
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'landrush','domain_info lp get_info(phase) ');
is($lpres->{'application_id'},'3F2504E0-4F89-11D3-9A0C-0305E82C3301','domain_info lp get_info(application_id) ');
is($lpres->{'status'},'pendingAllocation','domain_info lp get_info(launch_status) ');
my @marks = @{$lpres->{'marks'}};
my $m = shift @marks;
is ($m->{mark_name},'Example One','domain_info lp get_info(mark name)');

# domain create

## Application Create
$lp = {phase => 'landrush'};
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>landrush</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>landrush</application:phase></application:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [application phase]');
$lpres = $dri->get_info('lp');
is($lpres->{phase},'landrush','domain_create lp get_info (phase)');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (application_id)');

## Application Allocatate
$lp = {phase => 'landrush','application_id' => 'NEWAPP123'};
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>landrush</application:phase></application:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [application allocate]');

## SUNRISE - unpadded SMD
my $encoded_mark_test = 'ACB123=';
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $encoded_mark_test ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>'.$encoded_mark_test.'</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using unpadded string]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## SUNRISE - padded SMD
$encoded_mark_test = '<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">ABC123=</smd:encodedSignedMark>';
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $encoded_mark_test ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using padded (xml) string]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## SUNRISE - SMD XML::Element
my $po=$dri->target('Neustar::Narwal')->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();
my ($doc,$root,$rh);
$doc=$parser->parse_string($encoded_mark_test);
$root=$doc->getDocumentElement();

$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $root ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using xml root element]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## Claims
$lp = {phase => 'claims', notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>claims</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>claims</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:noticeID>abc123</tmch:noticeID><tmch:notAfter>2008-12-01T00:00:00Z</tmch:notAfter><tmch:accepted>2009-10-01T00:00:00Z</tmch:accepted></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [claims create]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (claims application_id)');

## Mixed (theoretical)
$lp = {phase => 'claims', 'encoded_signed_marks'=>[ $encoded_mark_test ], notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>claims</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>claims</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd><tmch:noticeID>abc123</tmch:noticeID><tmch:notAfter>2008-12-01T00:00:00Z</tmch:notAfter><tmch:accepted>2009-10-01T00:00:00Z</tmch:accepted></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [mixed create]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (mixed application_id)');

# UPDATE
$lp = {phase => 'sunrise','application_id'=>'abc123'};
$R2='';
$toc=$dri->local_object('changes');
$toc->set('lp',$lp);
$rc=$dri->domain_update('example5.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example5.menu</domain:name></domain:update></update><extension><application:update xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>abc123</application:id><application:phase>sunrise</application:phase></application:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update lp build_xml');

# DELETE
$lp = {'application_id'=>'abc123' };
$R2='';
$rc=$dri->domain_delete('example8.menu',{pure_delete=>1,lp=>$lp});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example8.menu</domain:name></domain:delete></delete><extension><application:delete xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>abc123</application:id></application:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete lp build_xml');

exit 0;
