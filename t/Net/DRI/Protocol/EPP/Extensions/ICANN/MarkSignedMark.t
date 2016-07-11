#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More tests => 43;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

use XML::LibXML ();

use Net::DRI::Protocol::EPP;
use Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark;
use Net::DRI::Util;

{
 package FakeRegistry;
 sub new { my ($class)=@_; my $self={}; bless($self,$class); return $self; }
 sub name { return ''; };
 sub logging { return {}; };
 sub driver { return __PACKAGE__->new(); }
 sub info { return 0 };
 1;
}

{
 no warnings;
 *Net::DRI::Protocol::EPP::log_setup_channel=sub {};
 *Net::DRI::Protocol::EPP::log_output=sub {};
}

my $po=Net::DRI::Protocol::EPP->new({registry => FakeRegistry->new()});
Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);

####################################################################################################

my %rm;
$rm{id}='1234-2';
$rm{mark_name}='Example One';
my $contactset=$po->create_local_object('contactset');
my $contact=$po->create_local_object('contact');
$contact->org('Example Inc.');
$contact->street(['123 Example Dr.','Suite 100']);
$contact->city('Reston');
$contact->sp('VA');
$contact->pc('20190');
$contact->cc('US');
$contactset->add($contact,'holder_owner');
$rm{contact}=$contactset;
$rm{jurisdiction}='US';
$rm{class}=[35,36];
$rm{label}=[qw/example-one exampleone/];
$rm{goods_services}='Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.';
$rm{registration_number}='234235';
$rm{registration_date}=$po->create_local_object('datetime',year=>2009,month=>8,day=>16,hour=>9,time_zone=>'UTC');
$rm{expiration_date}=$po->create_local_object('datetime',year=>2015,month=>8,day=>16,hour=>9,time_zone=>'UTC');

my $mark=<<'EOF';
   <mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0">
    <mark:trademark>
     <mark:id>1234-2</mark:id>
     <mark:markName>Example One</mark:markName>
     <mark:holder entitlement="owner">
      <mark:org>Example Inc.</mark:org>
      <mark:addr>
       <mark:street>123 Example Dr.</mark:street>
       <mark:street>Suite 100</mark:street>
       <mark:city>Reston</mark:city>
       <mark:sp>VA</mark:sp>
       <mark:pc>20190</mark:pc>
       <mark:cc>US</mark:cc>
      </mark:addr>
     </mark:holder>
     <mark:jurisdiction>US</mark:jurisdiction>
     <mark:class>35</mark:class>
     <mark:class>36</mark:class>
     <mark:label>example-one</mark:label>
     <mark:label>exampleone</mark:label>
     <mark:goodsAndServices>Dirigendas et eiusmodi 
      featuring infringo in airfare et cartam servicia.
     </mark:goodsAndServices>
     <mark:regNum>234235</mark:regNum>
     <mark:regDate>2009-08-16T09:00:00Z</mark:regDate>
     <mark:exDate>2015-08-16T09:00:00Z</mark:exDate>
    </mark:trademark>
   </mark:mark>
EOF
$mark=~s/^\s+//mg;
$mark=~s/\n//g;

is_string(join('',Net::DRI::Util::xml_write(Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::build_marks($po,\%rm))),$mark,'build_mark');

####################################################################################################

my $smd=<<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
  <smd:signedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0"
  id="smd1">
   <smd:id>0000001751376056503931-65535</smd:id>
   <smd:issuerInfo issuerID="65535">
     <smd:org>ICANN TMCH TESTING TMV</smd:org>
     <smd:email>notavailable@example.com</smd:email>
     <smd:url>https://www.example.com</smd:url>
     <smd:voice>+32.000000</smd:voice>
   </smd:issuerInfo>
   <smd:notBefore>2013-08-09T13:55:03.931Z</smd:notBefore>
   <smd:notAfter>2017-07-23T22:00:00.000Z</smd:notAfter>
   <mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0">
     <mark:trademark>
       <mark:id>00052013734689731373468973-65535</mark:id>
       <mark:markName>Test &amp; Validate</mark:markName>
       <mark:holder entitlement="owner">
         <mark:org>Ag corporation</mark:org>
         <mark:addr>
           <mark:street>1305 Bright Avenue</mark:street>
           <mark:city>Arcadia</mark:city>
           <mark:sp>CA</mark:sp>
           <mark:pc>90028</mark:pc>
           <mark:cc>US</mark:cc>
         </mark:addr>
       </mark:holder>
       <mark:contact type="agent">
         <mark:name>Tony Holland</mark:name>
         <mark:org>Ag corporation</mark:org>
         <mark:addr>
           <mark:street>1305 Bright Avenue</mark:street>
           <mark:city>Arcadia</mark:city>
           <mark:sp>CA</mark:sp>
           <mark:pc>90028</mark:pc>
           <mark:cc>US</mark:cc>
         </mark:addr>
         <mark:voice>+1.2025562302</mark:voice>
         <mark:fax>+1.2025562301</mark:fax>
         <mark:email>info@agcorporation.com</mark:email>
       </mark:contact>
       <mark:jurisdiction>US</mark:jurisdiction>
       <mark:class>15</mark:class>
       <mark:label>testandvalidate</mark:label>
       <mark:label>test---validate</mark:label>
       <mark:label>testand-validate</mark:label>
       <mark:label>test-et-validate</mark:label>
       <mark:label>test-validate</mark:label>
       <mark:label>test--validate</mark:label>
       <mark:label>test-etvalidate</mark:label>
       <mark:label>testetvalidate</mark:label>
       <mark:label>testvalidate</mark:label>
       <mark:label>testet-validate</mark:label>
       <mark:goodsAndServices>guitar</mark:goodsAndServices>
       <mark:regNum>1234</mark:regNum>
       <mark:regDate>2012-12-31T23:00:00.000Z</mark:regDate>
     </mark:trademark>
   </mark:mark>
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
   <SignedInfo>
    <CanonicalizationMethod
 Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <SignatureMethod
 Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
    <Reference URI="#smd1">
     <Transforms>
      <Transform
 Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
     </Transforms>
     <DigestMethod
 Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
     <DigestValue>wgyW3nZPoEfpptlhRILKnOQnbdtU6ArM7ShrAfHgDFg=</DigestValue>
    </Reference>
   </SignedInfo>
   <SignatureValue>
jMu4PfyQGiJBF0GWSEPFCJjmywCEqR2h4LD+ge6XQ+JnmKFFCuCZS/3SLKAx0L1w
QDFO2e0Y69k2G7/LGE37X3vOflobFM1oGwja8+GMVraoto5xAd4/AF7eHukgAymD
o9toxoa2h0yV4A4PmXzsU6S86XtCcUE+S/WM72nyn47zoUCzzPKHZBRyeWehVFQ+
jYRMIAMzM57HHQA+6eaXefRvtPETgUO4aVIVSugc4OUAZZwbYcZrC6wOaQqqqAZi
30aPOBYbAvHMSmWSS+hFkbshomJfHxb97TD2grlYNrQIzqXk7WbHWy2SYdA+sI/Z
ipJsXNa6osTUw1CzA7jfwA==
   </SignatureValue>
   <KeyInfo>
    <X509Data>
    <X509Certificate>
MIIESTCCAzGgAwIBAgIBAjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEL
MAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FO
TiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0EwHhcNMTMwMjA4MDAw
MDAwWhcNMTgwMjA3MjM1OTU5WjBsMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0Ex
FDASBgNVBAcTC0xvcyBBbmdlbGVzMRcwFQYDVQQKEw5WYWxpZGF0b3IgVE1DSDEh
MB8GA1UEAxMYVmFsaWRhdG9yIFRNQ0ggVEVTVCBDRVJUMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAo/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/sw
WinuMgEWgVQFrz0xA04pEhXCFVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5u
pDqa51Flk0TMaMkIQjs7aUKCmA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou7
5bOVnIos+HifrAtrIv4qEqwLL4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5
sPMCNxqaXmIXmQipS+DuEBqMM8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7v
L4GgDYqhJYWV61DnXgx/Jd6CWxvsnDF6scscQzUTEl+hywIDAQABo4H/MIH8MAwG
A1UdEwEB/wQCMAAwHQYDVR0OBBYEFPZEcIQcD/Bj2IFz/LERuo2ADJviMIGMBgNV
HSMEgYQwgYGAFO0/7kEh3FuEKS+Q/kYHaD/W6wihoWakZDBiMQswCQYDVQQGEwJV
UzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJ
Q0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0GCAQEwDgYDVR0P
AQH/BAQDAgeAMC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuaWNhbm4ub3Jn
L3RtY2guY3JsMA0GCSqGSIb3DQEBCwUAA4IBAQB2qSy7ui+43cebKUKwWPrzz9y/
IkrMeJGKjo40n+9uekaw3DJ5EqiOf/qZ4pjBD++oR6BJCb6NQuQKwnoAz5lE4Ssu
y5+i93oT3HfyVc4gNMIoHm1PS19l7DBKrbwbzAea/0jKWVzrvmV7TBfjxD3AQo1R
bU5dBr6IjbdLFlnO5x0G0mrG7x5OUPuurihyiURpFDpwH8KAH1wMcCpXGXFRtGKk
wydgyVYAty7otkl/z3bZkCVT34gPvF70sR6+QxUy8u0LzF5A/beYaZpxSYG31amL
AdXitTWFipaIGea9lEGFM0L9+Bg7XzNn4nVLXokyEB3bgS4scG6QznX23FGk
   </X509Certificate>
   </X509Data>
   </KeyInfo>
  </Signature>
 </smd:signedMark>
EOF

my $parser=XML::LibXML->new();
my $doc=$parser->parse_string($smd);
my $root=$doc->getDocumentElement();

my $rh=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_signed_mark($po,$root,0);

## header
is($rh->{id},'0000001751376056503931-65535','parse_signed_mark id');
is_deeply($rh->{issuer},{id=>65535,org=>'ICANN TMCH TESTING TMV',email=>'notavailable@example.com',url=>'https://www.example.com',voice=>'+32.000000'},'parse_signed_mark issuer');
is(''.$rh->{creation_date},'2013-08-09T13:55:03','parse_signed_mark creation_date');
is(''.$rh->{expiration_date},'2017-07-23T22:00:00','parse_signed_mark expiration_date');

## mark
my $rm=$rh->{mark};
is(scalar @$rm,1,'parse_signed_mark mark length');
$rm=$rm->[0];
is($rm->{type},'trademark','parse_signed_mark mark type');
is($rm->{id},'00052013734689731373468973-65535','parse_signed_mark mark id');
is($rm->{mark_name},'Test & Validate','parse_signed_mark mark mark_name');
my $cs=$rm->{contact};
is_deeply([$cs->types()],[qw/contact_agent holder_owner/],'parse_signed_mark mark holder');

my @h=$cs->get('holder_owner');
is(scalar @h,1,'parse_signed_mark mark holder count');
my $h=$h[0];
is($h->org(),'Ag corporation','parse_signed_mark mark holder org');
is_deeply(scalar $h->street(),['1305 Bright Avenue'],'parse_signed_mark mark holder street');
is($h->city(),'Arcadia','parse_signed_mark mark holder city');
is($h->sp(),'CA','parse_signed_mark mark holder sp');
is($h->pc(),'90028','parse_signed_mark mark holder pc');
is($h->cc(),'US','parse_signed_mark mark holder cc');

@h=$cs->get('contact_agent');
is(scalar @h,1,'parse_signed_mark mark agent count');
$h=$h[0];
is($h->name(),'Tony Holland','parse_signed_mark mark agent name');
is($h->org(),'Ag corporation','parse_signed_mark mark agent org');
is_deeply(scalar $h->street(),['1305 Bright Avenue'],'parse_signed_mark mark agent street');
is($h->city(),'Arcadia','parse_signed_mark mark agent city');
is($h->sp(),'CA','parse_signed_mark mark agent sp');
is($h->pc(),'90028','parse_signed_mark mark agent pc');
is($h->cc(),'US','parse_signed_mark mark agent cc');
is($h->voice(),'+1.2025562302','parse_signed_mark mark agent voice');
is($h->fax(),'+1.2025562301','parse_signed_mark mark agent fax');
is($h->email(),'info@agcorporation.com','parse_signed_mark mark agent email');

is($rm->{jurisdiction},'US','parse_signed_mark jurisdiction');
is_deeply($rm->{class},[15],'parse_signed_mark mark class');
is_deeply($rm->{label},[qw/testandvalidate test---validate testand-validate test-et-validate test-validate test--validate test-etvalidate testetvalidate testvalidate testet-validate/],'parse_signed_mark mark label');
is_string($rm->{goods_services},'guitar','parse_signed_mark mark goods_services');
is($rm->{registration_number},1234,'parse_signed_mark mark registration_number');
is(''.$rm->{registration_date},'2012-12-31T23:00:00','parse_signed_mark mark registration_date');

SKIP: {
	eval { require MIME::Base64; };
	skip 'MIME::Base64 not installed',2 if $@;

$smd=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJ
rIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaW
Q9Il84Yzk0ZjRmMS1jZTlmLTRjOTAtOTUzMS01MzE1ZDIzY2EzYmQiPgogIDxzbWQ6aWQ+M
DAwMDAwMTc1MTM3NjA1NjUwMzkzMS02NTUzNTwvc21kOmlkPgogIDxzbWQ6aXNzdWVySW5m
byBpc3N1ZXJJRD0iNjU1MzUiPgogICAgPHNtZDpvcmc+SUNBTk4gVE1DSCBURVNUSU5HIFR
NVjwvc21kOm9yZz4KICAgIDxzbWQ6ZW1haWw+bm90YXZhaWxhYmxlQGV4YW1wbGUuY29tPC
9zbWQ6ZW1haWw+CiAgICA8c21kOnVybD5odHRwOi8vd3d3LmV4YW1wbGUuY29tPC9zbWQ6d
XJsPgogICAgPHNtZDp2b2ljZT4rMzIuMDAwMDAwPC9zbWQ6dm9pY2U+CiAgPC9zbWQ6aXNz
dWVySW5mbz4KICA8c21kOm5vdEJlZm9yZT4yMDEzLTA4LTA5VDEzOjU1OjAzLjkzMVo8L3N
tZDpub3RCZWZvcmU+CiAgPHNtZDpub3RBZnRlcj4yMDE3LTA3LTIzVDIyOjAwOjAwLjAwMF
o8L3NtZDpub3RBZnRlcj4KICA8bWFyazptYXJrIHhtbG5zOm1hcms9InVybjppZXRmOnBhc
mFtczp4bWw6bnM6bWFyay0xLjAiPgogICAgPG1hcms6dHJhZGVtYXJrPgogICAgICA8bWFy
azppZD4wMDA1MjAxMzczNDY4OTczMTM3MzQ2ODk3My02NTUzNTwvbWFyazppZD4KICAgICA
gPG1hcms6bWFya05hbWU+VGVzdCAmYW1wOyBWYWxpZGF0ZTwvbWFyazptYXJrTmFtZT4KIC
AgICAgPG1hcms6aG9sZGVyIGVudGl0bGVtZW50PSJvd25lciI+CiAgICAgICAgPG1hcms6b
3JnPkFnIGNvcnBvcmF0aW9uPC9tYXJrOm9yZz4KICAgICAgICA8bWFyazphZGRyPgogICAg
ICAgICAgPG1hcms6c3RyZWV0PjEzMDUgQnJpZ2h0IEF2ZW51ZTwvbWFyazpzdHJlZXQ+CiA
gICAgICAgICA8bWFyazpjaXR5PkFyY2FkaWE8L21hcms6Y2l0eT4KICAgICAgICAgIDxtYX
JrOnNwPkNBPC9tYXJrOnNwPgogICAgICAgICAgPG1hcms6cGM+OTAwMjg8L21hcms6cGM+C
iAgICAgICAgICA8bWFyazpjYz5VUzwvbWFyazpjYz4KICAgICAgICA8L21hcms6YWRkcj4K
ICAgICAgPC9tYXJrOmhvbGRlcj4KICAgICAgPG1hcms6Y29udGFjdCB0eXBlPSJhZ2VudCI
+CiAgICAgICAgPG1hcms6bmFtZT5Ub255IEhvbGxhbmQ8L21hcms6bmFtZT4KICAgICAgIC
A8bWFyazpvcmc+QWcgY29ycG9yYXRpb248L21hcms6b3JnPgogICAgICAgIDxtYXJrOmFkZ
HI+CiAgICAgICAgICA8bWFyazpzdHJlZXQ+MTMwNSBCcmlnaHQgQXZlbnVlPC9tYXJrOnN0
cmVldD4KICAgICAgICAgIDxtYXJrOmNpdHk+QXJjYWRpYTwvbWFyazpjaXR5PgogICAgICA
gICAgPG1hcms6c3A+Q0E8L21hcms6c3A+CiAgICAgICAgICA8bWFyazpwYz45MDAyODwvbW
FyazpwYz4KICAgICAgICAgIDxtYXJrOmNjPlVTPC9tYXJrOmNjPgogICAgICAgIDwvbWFya
zphZGRyPgogICAgICAgIDxtYXJrOnZvaWNlPisxLjIwMjU1NjIzMDI8L21hcms6dm9pY2U+
CiAgICAgICAgPG1hcms6ZmF4PisxLjIwMjU1NjIzMDE8L21hcms6ZmF4PgogICAgICAgIDx
tYXJrOmVtYWlsPmluZm9AYWdjb3Jwb3JhdGlvbi5jb208L21hcms6ZW1haWw+CiAgICAgID
wvbWFyazpjb250YWN0PgogICAgICA8bWFyazpqdXJpc2RpY3Rpb24+VVM8L21hcms6anVya
XNkaWN0aW9uPgogICAgICA8bWFyazpjbGFzcz4xNTwvbWFyazpjbGFzcz4KICAgICAgPG1h
cms6bGFiZWw+dGVzdGFuZHZhbGlkYXRlPC9tYXJrOmxhYmVsPgogICAgICA8bWFyazpsYWJ
lbD50ZXN0LS0tdmFsaWRhdGU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmxhYmVsPnRlc3
RhbmQtdmFsaWRhdGU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmxhYmVsPnRlc3QtZXQtd
mFsaWRhdGU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmxhYmVsPnRlc3QtdmFsaWRhdGU8
L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmxhYmVsPnRlc3QtLXZhbGlkYXRlPC9tYXJrOmx
hYmVsPgogICAgICA8bWFyazpsYWJlbD50ZXN0LWV0dmFsaWRhdGU8L21hcms6bGFiZWw+Ci
AgICAgIDxtYXJrOmxhYmVsPnRlc3RldHZhbGlkYXRlPC9tYXJrOmxhYmVsPgogICAgICA8b
WFyazpsYWJlbD50ZXN0dmFsaWRhdGU8L21hcms6bGFiZWw+CiAgICAgIDxtYXJrOmxhYmVs
PnRlc3RldC12YWxpZGF0ZTwvbWFyazpsYWJlbD4KICAgICAgPG1hcms6Z29vZHNBbmRTZXJ
2aWNlcz5ndWl0YXI8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz4KICAgICAgPG1hcms6cmVnTn
VtPjEyMzQ8L21hcms6cmVnTnVtPgogICAgICA8bWFyazpyZWdEYXRlPjIwMTItMTItMzFUM
jM6MDA6MDAuMDAwWjwvbWFyazpyZWdEYXRlPgogICAgPC9tYXJrOnRyYWRlbWFyaz4KICA8
L21hcms6bWFyaz4KPGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmc
vMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il81ODg5YzM5Zi1jMzM3LTQ0NzctOTU1Ni05NTNiZT
A5Y2NkMTgiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ
29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRz
OlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQ
veG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI184Yzk0Zj
RmMS1jZTlmLTRjOTAtOTUzMS01MzE1ZDIzY2EzYmQiPjxkczpUcmFuc2Zvcm1zPjxkczpUc
mFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcj
ZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8
vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PG
RzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQve
G1sZW5jI3NoYTI1NiIvPjxkczpEaWdlc3RWYWx1ZT5IdUdKYlZCWkVaVGlFelB2d0NObVFs
NmFMZEExWHo1QzAzdnhDWFBIZW1BPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U
+PGRzOlJlZmVyZW5jZSBVUkk9IiNfMWRlNTg5OGMtNmY3Ny00ZDViLTlkZDgtMzE4MWM5MT
E3Yzk3Ij48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL
3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxk
czpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3h
tbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+NHBiU0M2M2xObVBxelc3TDBNRDBxZ0
5GNHc5SUE3YXQ3OWxEVE5VZjBndz08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlP
jwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il9hODAwZmIwNS02NjRh
LTQ2OTItYjM5MS04OTM4NTlhNTM0OGQiPlc5VHAxQ09HeEk4dlZQNkZONEdpYlhtc3RRM1Z
0bmpSZVN3VVdicFZCTEtmenZ1L1c1OGNoOUdxdnRQTm9HZTdXOXVvQUt0U1J0MUkKMzdPeD
IwQmVQb2xGdWZmekVVR3NGMHBETkRoWmNiRUdEMlVWRTBpYnhIRkVDUU13d0ppK1NVb2ora
3JIWmRXM0FybmNaZ0RkMkhXZgpudVJZSmVucnpCS2k2RG1YVlVRYlhXRFVkbGxzcjlDSmtB
THYrd0s2V2RweE9Na0NTc2E0WUU2bEVNTjVXNGhzUXFlZ2N6ZGkwdUZ0CnZxQ2JLVnM3RTJ
3c0VIZC94aUxzbldZNEUxNWdLNnI0UW9tWHJqdFI0ZkFyZ1lMTnRLK09NRCt6UktNeGNuNV
F2QzJVeHlzNUV6RHcKNmhlenYrdXBxTldkRjRYL2lCNW1JY25DMzAraVBpY3lDb2JHUlE9P
TwvZHM6U2lnbmF0dXJlVmFsdWU+PGRzOktleUluZm8gSWQ9Il8xZGU1ODk4Yy02Zjc3LTRk
NWItOWRkOC0zMTgxYzkxMTdjOTciPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXR
lPk1JSUZMekNDQkJlZ0F3SUJBZ0lnTHJBYmV2b2FlNTJ5M2Y2QzJ0QjBTbjNwN1hKbTBUMD
JGb2d4S0NmTmhYb3dEUVlKS29aSWh2Y04KQVFFTEJRQXdmREVMTUFrR0ExVUVCaE1DVlZNe
FBEQTZCZ05WQkFvVE0wbHVkR1Z5Ym1WMElFTnZjbkJ2Y21GMGFXOXVJR1p2Y2lCQgpjM05w
WjI1bFpDQk9ZVzFsY3lCaGJtUWdUblZ0WW1WeWN6RXZNQzBHQTFVRUF4TW1TVU5CVGs0Z1Z
ISmhaR1Z0WVhKcklFTnNaV0Z5CmFXNW5hRzkxYzJVZ1VHbHNiM1FnUTBFd0hoY05NVE13Tm
pJMk1EQXdNREF3V2hjTk1UZ3dOakkxTWpNMU9UVTVXakNCanpFTE1Ba0cKQTFVRUJoTUNRa
1V4SURBZUJnTlZCQWdURjBKeWRYTnpaV3h6TFVOaGNHbDBZV3dnVW1WbmFXOXVNUkV3RHdZ
RFZRUUhFd2hDY25WegpjMlZzY3pFUk1BOEdBMVVFQ2hNSVJHVnNiMmwwZEdVeE9EQTJCZ05
WQkFNVEwwbERRVTVPSUZSTlEwZ2dRWFYwYUc5eWFYcGxaQ0JVCmNtRmtaVzFoY21zZ1VHbH
NiM1FnVm1Gc2FXUmhkRzl5TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ
2dLQ0FRRUEKeGxwM0twWUhYM1d5QXNGaFNrM0x3V2ZuR2x4blVERnFGWkEzVW91TVlqL1hp
Z2JNa05lRVhJamxrUk9LVDRPUEdmUngvTEF5UmxRUQpqQ012NHFoYmtjWDFwN2FyNjNmbHE
0U1pOVmNsMTVsN2gwdVQ1OEZ6U2ZubHowdTVya0hmSkltRDQzK21hUC84Z3YzNkZSMjdqVz
hSCjl3WTRoaytXczRJQjBpRlNkOFNYdjFLcjh3L0ptTVFTRGtpdUcrUmZJaXVid1EvZnk3R
WtqNVFXaFBadyttTXhOS25IVUx5M3hZejIKTHdWZmZ0andVdWVhY3ZxTlJDa01YbENsT0FE
cWZUOG9TWm9lRFhlaEh2bFBzTENlbUdCb1RLdXJza0lTNjlGMHlQRUg1Z3plMEgrZgo4RlJ
Pc0lvS1NzVlEzNEI0Uy9qb0U2N25wc0pQVGRLc05QSlR5UUlEQVFBQm80SUJoekNDQVlNd0
RBWURWUjBUQVFIL0JBSXdBREFkCkJnTlZIUTRFRmdRVW9GcFk3NnA1eW9ORFJHdFFwelZ1U
jgxVVdRMHdnY1lHQTFVZEl3U0J2akNCdTRBVXc2MCtwdFlSQUVXQVhEcFgKU29wdDNERU5u
bkdoZ1lDa2ZqQjhNUXN3Q1FZRFZRUUdFd0pWVXpFOE1Eb0dBMVVFQ2hNelNXNTBaWEp1Wlh
RZ1EyOXljRzl5WVhScApiMjRnWm05eUlFRnpjMmxuYm1Wa0lFNWhiV1Z6SUdGdVpDQk9kVz
FpWlhKek1TOHdMUVlEVlFRREV5WkpRMEZPVGlCVWNtRmtaVzFoCmNtc2dRMnhsWVhKcGJtZ
G9iM1Z6WlNCUWFXeHZkQ0JEUVlJZ0xyQWJldm9hZTUyeTNmNkMydEIwU24zcDdYSm0wVDAy
Rm9neEtDZk4KaFhrd0RnWURWUjBQQVFIL0JBUURBZ2VBTURRR0ExVWRId1F0TUNzd0thQW5
vQ1dHSTJoMGRIQTZMeTlqY213dWFXTmhibTR1YjNKbgpMM1J0WTJoZmNHbHNiM1F1WTNKc0
1FVUdBMVVkSUFRK01Ed3dPZ1lES2dNRU1ETXdNUVlJS3dZQkJRVUhBZ0VXSldoMGRIQTZMe
TkzCmQzY3VhV05oYm00dWIzSm5MM0JwYkc5MFgzSmxjRzl6YVhSdmNua3dEUVlKS29aSWh2
Y05BUUVMQlFBRGdnRUJBSWVEWVlKcjYwVzMKeTlRcyszelJWSTlrZWtLb201dmtIT2FsQjN
3SGFaSWFBRllwSTk4dFkwYVZOOWFHT04wdjZXUUYrbnZ6MUtSWlFiQXowMUJYdGFSSgo0bV
BrYXJoaHVMbjlOa0J4cDhIUjVxY2MrS0g3Z3Y2ci9jMGlHM2JDTkorUVNyN1FmKzVNbE1vN
npMNVVkZFUvVDJqaWJNWENqL2YyCjFRdzN4OVFnb3lYTEZKOW96YUxnUTlSTWtMbE9temtD
QWlYTjVBYjQzYUo5ZjdOMmdFMk5uUmpOS21tQzlBQlEwVFJ3RUtWTGhWbDEKVUdxQ0hKM0F
sQlhXSVhONXNqUFFjRC8rbkhlRVhNeFl2bEF5cXhYb0QzTVd0UVZqN2oyb3FsYWtPQk1nRz
grcTJxWWxtQnRzNEZOaQp3NzQ4SWw1ODZIS0JScXhIdFpkUktXMlZxYVE9PC9kczpYNTA5Q
2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+
PC9zbWQ6c2lnbmVkTWFyaz4=
</smd:encodedSignedMark>
EOF

$doc=$parser->parse_string($smd);
$root=$doc->getDocumentElement();

$rh=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_encoded_signed_mark($po,$root,0);

is($rh->{id},'0000001751376056503931-65535','parse_encoded_signed_mark (xml) id');
my $rs=$rh->{signature};
my $rk=$rs->{key};
is($rk->{x509_certificate},'MIIFLzCCBBegAwIBAgIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXowDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBBc3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEvMC0GA1UEAxMmSUNBTk4gVHJhZGVtYXJrIENsZWFyaW5naG91c2UgUGlsb3QgQ0EwHhcNMTMwNjI2MDAwMDAwWhcNMTgwNjI1MjM1OTU5WjCBjzELMAkGA1UEBhMCQkUxIDAeBgNVBAgTF0JydXNzZWxzLUNhcGl0YWwgUmVnaW9uMREwDwYDVQQHEwhCcnVzc2VsczERMA8GA1UEChMIRGVsb2l0dGUxODA2BgNVBAMTL0lDQU5OIFRNQ0ggQXV0aG9yaXplZCBUcmFkZW1hcmsgUGlsb3QgVmFsaWRhdG9yMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxlp3KpYHX3WyAsFhSk3LwWfnGlxnUDFqFZA3UouMYj/XigbMkNeEXIjlkROKT4OPGfRx/LAyRlQQjCMv4qhbkcX1p7ar63flq4SZNVcl15l7h0uT58FzSfnlz0u5rkHfJImD43+maP/8gv36FR27jW8R9wY4hk+Ws4IB0iFSd8SXv1Kr8w/JmMQSDkiuG+RfIiubwQ/fy7Ekj5QWhPZw+mMxNKnHULy3xYz2LwVfftjwUueacvqNRCkMXlClOADqfT8oSZoeDXehHvlPsLCemGBoTKurskIS69F0yPEH5gze0H+f8FROsIoKSsVQ34B4S/joE67npsJPTdKsNPJTyQIDAQABo4IBhzCCAYMwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUoFpY76p5yoNDRGtQpzVuR81UWQ0wgcYGA1UdIwSBvjCBu4AUw60+ptYRAEWAXDpXSopt3DENnnGhgYCkfjB8MQswCQYDVQQGEwJVUzE8MDoGA1UEChMzSW50ZXJuZXQgQ29ycG9yYXRpb24gZm9yIEFzc2lnbmVkIE5hbWVzIGFuZCBOdW1iZXJzMS8wLQYDVQQDEyZJQ0FOTiBUcmFkZW1hcmsgQ2xlYXJpbmdob3VzZSBQaWxvdCBDQYIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXkwDgYDVR0PAQH/BAQDAgeAMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuaWNhbm4ub3JnL3RtY2hfcGlsb3QuY3JsMEUGA1UdIAQ+MDwwOgYDKgMEMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93d3cuaWNhbm4ub3JnL3BpbG90X3JlcG9zaXRvcnkwDQYJKoZIhvcNAQELBQADggEBAIeDYYJr60W3y9Qs+3zRVI9kekKom5vkHOalB3wHaZIaAFYpI98tY0aVN9aGON0v6WQF+nvz1KRZQbAz01BXtaRJ4mPkarhhuLn9NkBxp8HR5qcc+KH7gv6r/c0iG3bCNJ+QSr7Qf+5MlMo6zL5UddU/T2jibMXCj/f21Qw3x9QgoyXLFJ9ozaLgQ9RMkLlOmzkCAiXN5Ab43aJ9f7N2gE2NnRjNKmmC9ABQ0TRwEKVLhVl1UGqCHJ3AlBXWIXN5sjPQcD/+nHeEXMxYvlAyqxXoD3MWtQVj7j2oqlakOBMgG8+q2qYlmBts4FNiw748Il586HKBRqxHtZdRKW2VqaQ=','parse_encoded_signed_mark (xml) signature key x590_certificate');

$smd=<<'EOF';
Marks: Example One
smdID: 1-2
U-labels: example-one, exampleone
notBefore: 2011-08-16 09:00
notAfter: 2012-08-16 09:00
-----BEGIN ENCODED SMD-----
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
-----END ENCODED SMD-----
EOF

$rh=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_encoded_signed_mark($po,$smd,0);

is($rh->{id},'1-2','parse_encoded_signed_mark (string) id');
$rs=$rh->{signature};
$rk=$rs->{key};
is($rk->{x509_certificate},'MIIESTCCAzGgAwIBAgIBAjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0EwHhcNMTMwMjA4MDAwMDAwWhcNMTgwMjA3MjM1OTU5WjBsMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRcwFQYDVQQKEw5WYWxpZGF0b3IgVE1DSDEhMB8GA1UEAxMYVmFsaWRhdG9yIFRNQ0ggVEVTVCBDRVJUMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/swWinuMgEWgVQFrz0xA04pEhXCFVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5upDqa51Flk0TMaMkIQjs7aUKCmA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou75bOVnIos+HifrAtrIv4qEqwLL4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5sPMCNxqaXmIXmQipS+DuEBqMM8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7vL4GgDYqhJYWV61DnXgx/Jd6CWxvsnDF6scscQzUTEl+hywIDAQABo4H/MIH8MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFPZEcIQcD/Bj2IFz/LERuo2ADJviMIGMBgNVHSMEgYQwgYGAFO0/7kEh3FuEKS+Q/kYHaD/W6wihoWakZDBiMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0GCAQEwDgYDVR0PAQH/BAQDAgeAMC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuaWNhbm4ub3JnL3RtY2guY3JsMA0GCSqGSIb3DQEBCwUAA4IBAQB2qSy7ui+43cebKUKwWPrzz9y/IkrMeJGKjo40n+9uekaw3DJ5EqiOf/qZ4pjBD++oR6BJCb6NQuQKwnoAz5lE4Ssuy5+i93oT3HfyVc4gNMIoHm1PS19l7DBKrbwbzAea/0jKWVzrvmV7TBfjxD3AQo1RbU5dBr6IjbdLFlnO5x0G0mrG7x5OUPuurihyiURpFDpwH8KAH1wMcCpXGXFRtGKkwydgyVYAty7otkl/z3bZkCVT34gPvF70sR6+QxUy8u0LzF5A/beYaZpxSYG31amLAdXitTWFipaIGea9lEGFM0L9+Bg7XzNn4nVLXokyEB3bgS4scG6QznX23FGk','parse_encoded_signed_mark (string) signature key x590_certificate');

SKIP: {
	eval { require XML::LibXML::XPathContext; require Digest::SHA; require Crypt::OpenSSL::X509; require Crypt::OpenSSL::RSA; };
	skip 'Modules not installed to validate signature',5 if $@;

$smd=<<'EOF';
<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHht
bG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il85MGNm
MWJjMi03MjMzLTRjZTEtODA4NC1mMjUwMDY5Y2YzZDEiPjxzbWQ6aWQ+MDAwMDAwMTc1MTM4NTEx
NjkzNjkyMC02NTUzNTwvc21kOmlkPjxzbWQ6aXNzdWVySW5mbyBpc3N1ZXJJRD0iNjU1MzUiPjxz
bWQ6b3JnPklDQU5OIFRNQ0ggVEVTVElORyBUTVY8L3NtZDpvcmc+PHNtZDplbWFpbD5ub3RhdmFp
bGFibGVAZXhhbXBsZS5jb208L3NtZDplbWFpbD48c21kOnVybD5odHRwOi8vd3d3LmV4YW1wbGUu
Y29tPC9zbWQ6dXJsPjxzbWQ6dm9pY2U+KzMyLjAwMDAwMDwvc21kOnZvaWNlPjwvc21kOmlzc3Vl
ckluZm8+PHNtZDpub3RCZWZvcmU+MjAxMy0xMS0yMlQxMDo0MjoxNi45MjBaPC9zbWQ6bm90QmVm
b3JlPjxzbWQ6bm90QWZ0ZXI+MjAxNy0wNy0yM1QyMjowMDowMC4wMDBaPC9zbWQ6bm90QWZ0ZXI+
PG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJhbXM6eG1sOm5zOm1hcmstMS4wIj48
bWFyazp0cmFkZW1hcms+PG1hcms6aWQ+MDAwNTIwMTM3MzQ2ODk3MzEzNzM0Njg5NzMtNjU1MzU8
L21hcms6aWQ+PG1hcms6bWFya05hbWU+VGVzdCAmYW1wOyBWYWxpZGF0ZTwvbWFyazptYXJrTmFt
ZT48bWFyazpob2xkZXIgZW50aXRsZW1lbnQ9Im93bmVyIj48bWFyazpvcmc+QWcgY29ycG9yYXRp
b248L21hcms6b3JnPjxtYXJrOmFkZHI+PG1hcms6c3RyZWV0PjEzMDUgQnJpZ2h0IEF2ZW51ZTwv
bWFyazpzdHJlZXQ+PG1hcms6Y2l0eT5BcmNhZGlhPC9tYXJrOmNpdHk+PG1hcms6c3A+Q0E8L21h
cms6c3A+PG1hcms6cGM+OTAwMjg8L21hcms6cGM+PG1hcms6Y2M+VVM8L21hcms6Y2M+PC9tYXJr
OmFkZHI+PC9tYXJrOmhvbGRlcj48bWFyazpjb250YWN0IHR5cGU9ImFnZW50Ij48bWFyazpuYW1l
PlRvbnkgSG9sbGFuZDwvbWFyazpuYW1lPjxtYXJrOm9yZz5BZyBjb3Jwb3JhdGlvbjwvbWFyazpv
cmc+PG1hcms6YWRkcj48bWFyazpzdHJlZXQ+MTMwNSBCcmlnaHQgQXZlbnVlPC9tYXJrOnN0cmVl
dD48bWFyazpjaXR5PkFyY2FkaWE8L21hcms6Y2l0eT48bWFyazpzcD5DQTwvbWFyazpzcD48bWFy
azpwYz45MDAyODwvbWFyazpwYz48bWFyazpjYz5VUzwvbWFyazpjYz48L21hcms6YWRkcj48bWFy
azp2b2ljZT4rMS4yMDI1NTYyMzAyPC9tYXJrOnZvaWNlPjxtYXJrOmZheD4rMS4yMDI1NTYyMzAx
PC9tYXJrOmZheD48bWFyazplbWFpbD5pbmZvQGFnY29ycG9yYXRpb24uY29tPC9tYXJrOmVtYWls
PjwvbWFyazpjb250YWN0PjxtYXJrOmp1cmlzZGljdGlvbj5VUzwvbWFyazpqdXJpc2RpY3Rpb24+
PG1hcms6Y2xhc3M+MTU8L21hcms6Y2xhc3M+PG1hcms6bGFiZWw+dGVzdGFuZHZhbGlkYXRlPC9t
YXJrOmxhYmVsPjxtYXJrOmxhYmVsPnRlc3QtLS12YWxpZGF0ZTwvbWFyazpsYWJlbD48bWFyazps
YWJlbD50ZXN0YW5kLXZhbGlkYXRlPC9tYXJrOmxhYmVsPjxtYXJrOmxhYmVsPnRlc3QtZXQtdmFs
aWRhdGU8L21hcms6bGFiZWw+PG1hcms6bGFiZWw+dGVzdC12YWxpZGF0ZTwvbWFyazpsYWJlbD48
bWFyazpsYWJlbD50ZXN0LS12YWxpZGF0ZTwvbWFyazpsYWJlbD48bWFyazpsYWJlbD50ZXN0LWV0
dmFsaWRhdGU8L21hcms6bGFiZWw+PG1hcms6bGFiZWw+dGVzdGV0dmFsaWRhdGU8L21hcms6bGFi
ZWw+PG1hcms6bGFiZWw+dGVzdHZhbGlkYXRlPC9tYXJrOmxhYmVsPjxtYXJrOmxhYmVsPnRlc3Rl
dC12YWxpZGF0ZTwvbWFyazpsYWJlbD48bWFyazpnb29kc0FuZFNlcnZpY2VzPmd1aXRhcjwvbWFy
azpnb29kc0FuZFNlcnZpY2VzPjxtYXJrOnJlZ051bT4xMjM0PC9tYXJrOnJlZ051bT48bWFyazpy
ZWdEYXRlPjIwMTItMTItMzFUMjM6MDA6MDAuMDAwWjwvbWFyazpyZWdEYXRlPjwvbWFyazp0cmFk
ZW1hcms+PC9tYXJrOm1hcms+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5v
cmcvMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il8wODVlZjcxNS1hOWM0LTRlM2ItYTZmMi00NjM2NDM1
NTU4YTIiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRo
bT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVy
ZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3Jl
I3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI185MGNmMWJjMi03MjMzLTRjZTEtODA4
NC1mMjUwMDY5Y2YzZDEiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJo
dHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxk
czpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMt
YzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6
Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPjxkczpEaWdlc3RWYWx1ZT4rT1Vu
b2dBSzc0ekU3UXVRWWZMeVU2MEdsQnd3SG9SZGppbjQ2dFFlWDRZPTwvZHM6RGlnZXN0VmFsdWU+
PC9kczpSZWZlcmVuY2U+PGRzOlJlZmVyZW5jZSBVUkk9IiNfMDgwNGEwMGEtZWQ5My00ZGNjLWIy
NTItMDE5MjBkOTRmNzc3Ij48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0i
aHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1z
PjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3ht
bGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+WGZtRURkdEUybzg5RVNQbEExNGdjN3VpTXpB
YlRSRklCZ0hidzdlcDhlcz08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2ln
bmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il9hOTEyYzc0NC00NzM5LTRjZDYtYjg4NS05
Yzc5M2I4NGFiOTkiPmVkUkFMRjYwR1ZFb3NLV2Q2MjNKb1RwWGdXbEE0WE9xOXpjMFhXTmtqNVpT
eTVwQ2tWTm5kNTZocW53NFVoSjRFd09NN3E3TVNuUEgKMHM5UlFTQVRKZjdWOXlPN2FIeldUakQz
TnU4aGFTbTZXZlBaUWhHbURUMWN2Q2NlcDc4NDFSYmgrMHpVQ09qQ09aTG53ZHZETW9acgppSDg4
Z2Ewb3k3OEpWK2JPczJnNVYzSSt5eGxaa2RMRzVkaEJkNnpEWFdHcXA2cVhrbVlxdG1TVnlKQjAz
eVFnM2ZHNjF2QklhS0dZCmovdVI0cW9WenVVbnVncDhINzVvY0xadWR4U2VXZ2RRQjdMblNNU3l0
dHdWMEtpWlRxUVliaElUVDNuc3JsZWowbUU4ei9MTGJuNloKcUNNaUczS2poYTM5Z20vK095NnlU
dDA5UnJYa2YxMVJVWXdQZXc9PTwvZHM6U2lnbmF0dXJlVmFsdWU+PGRzOktleUluZm8gSWQ9Il8w
ODA0YTAwYS1lZDkzLTRkY2MtYjI1Mi0wMTkyMGQ5NGY3NzciPjxkczpYNTA5RGF0YT48ZHM6WDUw
OUNlcnRpZmljYXRlPk1JSUZMekNDQkJlZ0F3SUJBZ0lnTHJBYmV2b2FlNTJ5M2Y2QzJ0QjBTbjNw
N1hKbTBUMDJGb2d4S0NmTmhYb3dEUVlKS29aSWh2Y04KQVFFTEJRQXdmREVMTUFrR0ExVUVCaE1D
VlZNeFBEQTZCZ05WQkFvVE0wbHVkR1Z5Ym1WMElFTnZjbkJ2Y21GMGFXOXVJR1p2Y2lCQgpjM05w
WjI1bFpDQk9ZVzFsY3lCaGJtUWdUblZ0WW1WeWN6RXZNQzBHQTFVRUF4TW1TVU5CVGs0Z1ZISmha
R1Z0WVhKcklFTnNaV0Z5CmFXNW5hRzkxYzJVZ1VHbHNiM1FnUTBFd0hoY05NVE13TmpJMk1EQXdN
REF3V2hjTk1UZ3dOakkxTWpNMU9UVTVXakNCanpFTE1Ba0cKQTFVRUJoTUNRa1V4SURBZUJnTlZC
QWdURjBKeWRYTnpaV3h6TFVOaGNHbDBZV3dnVW1WbmFXOXVNUkV3RHdZRFZRUUhFd2hDY25Wegpj
MlZzY3pFUk1BOEdBMVVFQ2hNSVJHVnNiMmwwZEdVeE9EQTJCZ05WQkFNVEwwbERRVTVPSUZSTlEw
Z2dRWFYwYUc5eWFYcGxaQ0JVCmNtRmtaVzFoY21zZ1VHbHNiM1FnVm1Gc2FXUmhkRzl5TUlJQklq
QU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEKeGxwM0twWUhYM1d5QXNGaFNr
M0x3V2ZuR2x4blVERnFGWkEzVW91TVlqL1hpZ2JNa05lRVhJamxrUk9LVDRPUEdmUngvTEF5UmxR
UQpqQ012NHFoYmtjWDFwN2FyNjNmbHE0U1pOVmNsMTVsN2gwdVQ1OEZ6U2ZubHowdTVya0hmSklt
RDQzK21hUC84Z3YzNkZSMjdqVzhSCjl3WTRoaytXczRJQjBpRlNkOFNYdjFLcjh3L0ptTVFTRGtp
dUcrUmZJaXVid1EvZnk3RWtqNVFXaFBadyttTXhOS25IVUx5M3hZejIKTHdWZmZ0andVdWVhY3Zx
TlJDa01YbENsT0FEcWZUOG9TWm9lRFhlaEh2bFBzTENlbUdCb1RLdXJza0lTNjlGMHlQRUg1Z3pl
MEgrZgo4RlJPc0lvS1NzVlEzNEI0Uy9qb0U2N25wc0pQVGRLc05QSlR5UUlEQVFBQm80SUJoekND
QVlNd0RBWURWUjBUQVFIL0JBSXdBREFkCkJnTlZIUTRFRmdRVW9GcFk3NnA1eW9ORFJHdFFwelZ1
UjgxVVdRMHdnY1lHQTFVZEl3U0J2akNCdTRBVXc2MCtwdFlSQUVXQVhEcFgKU29wdDNERU5ubkdo
Z1lDa2ZqQjhNUXN3Q1FZRFZRUUdFd0pWVXpFOE1Eb0dBMVVFQ2hNelNXNTBaWEp1WlhRZ1EyOXlj
Rzl5WVhScApiMjRnWm05eUlFRnpjMmxuYm1Wa0lFNWhiV1Z6SUdGdVpDQk9kVzFpWlhKek1TOHdM
UVlEVlFRREV5WkpRMEZPVGlCVWNtRmtaVzFoCmNtc2dRMnhsWVhKcGJtZG9iM1Z6WlNCUWFXeHZk
Q0JEUVlJZ0xyQWJldm9hZTUyeTNmNkMydEIwU24zcDdYSm0wVDAyRm9neEtDZk4KaFhrd0RnWURW
UjBQQVFIL0JBUURBZ2VBTURRR0ExVWRId1F0TUNzd0thQW5vQ1dHSTJoMGRIQTZMeTlqY213dWFX
TmhibTR1YjNKbgpMM1J0WTJoZmNHbHNiM1F1WTNKc01FVUdBMVVkSUFRK01Ed3dPZ1lES2dNRU1E
TXdNUVlJS3dZQkJRVUhBZ0VXSldoMGRIQTZMeTkzCmQzY3VhV05oYm00dWIzSm5MM0JwYkc5MFgz
SmxjRzl6YVhSdmNua3dEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSWVEWVlKcjYwVzMKeTlRcysz
elJWSTlrZWtLb201dmtIT2FsQjN3SGFaSWFBRllwSTk4dFkwYVZOOWFHT04wdjZXUUYrbnZ6MUtS
WlFiQXowMUJYdGFSSgo0bVBrYXJoaHVMbjlOa0J4cDhIUjVxY2MrS0g3Z3Y2ci9jMGlHM2JDTkor
UVNyN1FmKzVNbE1vNnpMNVVkZFUvVDJqaWJNWENqL2YyCjFRdzN4OVFnb3lYTEZKOW96YUxnUTlS
TWtMbE9temtDQWlYTjVBYjQzYUo5ZjdOMmdFMk5uUmpOS21tQzlBQlEwVFJ3RUtWTGhWbDEKVUdx
Q0hKM0FsQlhXSVhONXNqUFFjRC8rbkhlRVhNeFl2bEF5cXhYb0QzTVd0UVZqN2oyb3FsYWtPQk1n
RzgrcTJxWWxtQnRzNEZOaQp3NzQ4SWw1ODZIS0JScXhIdFpkUktXMlZxYVE9PC9kczpYNTA5Q2Vy
dGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PC9zbWQ6
c2lnbmVkTWFyaz4=
</smd:encodedSignedMark>
EOF

$doc=$parser->parse_string($smd);
$root=$doc->getDocumentElement();

$rh=Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::parse_encoded_signed_mark($po,$root,1);

## signature
my $rs=$rh->{signature};
is($rs->{id},'_90cf1bc2-7233-4ce1-8084-f250069cf3d1','parse_signed_mark signature id');
is($rs->{value},'edRALF60GVEosKWd623JoTpXgWlA4XOq9zc0XWNkj5ZSy5pCkVNnd56hqnw4UhJ4EwOM7q7MSnPH0s9RQSATJf7V9yO7aHzWTjD3Nu8haSm6WfPZQhGmDT1cvCcep7841Rbh+0zUCOjCOZLnwdvDMoZriH88ga0oy78JV+bOs2g5V3I+yxlZkdLG5dhBd6zDXWGqp6qXkmYqtmSVyJB03yQg3fG61vBIaKGYj/uR4qoVzuUnugp8H75ocLZudxSeWgdQB7LnSMSyttwV0KiZTqQYbhITT3nsrlej0mE8z/LLbn6ZqCMiG3Kjha39gm/+Oy6yTt09RrXkf11RUYwPew==','parse_signed_mark signature value');
my $rk=$rs->{key};
is($rk->{algorithm},'rsa','parse_signed_mark signature key algorithm');
is($rk->{x509_certificate},'MIIFLzCCBBegAwIBAgIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXowDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBBc3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEvMC0GA1UEAxMmSUNBTk4gVHJhZGVtYXJrIENsZWFyaW5naG91c2UgUGlsb3QgQ0EwHhcNMTMwNjI2MDAwMDAwWhcNMTgwNjI1MjM1OTU5WjCBjzELMAkGA1UEBhMCQkUxIDAeBgNVBAgTF0JydXNzZWxzLUNhcGl0YWwgUmVnaW9uMREwDwYDVQQHEwhCcnVzc2VsczERMA8GA1UEChMIRGVsb2l0dGUxODA2BgNVBAMTL0lDQU5OIFRNQ0ggQXV0aG9yaXplZCBUcmFkZW1hcmsgUGlsb3QgVmFsaWRhdG9yMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxlp3KpYHX3WyAsFhSk3LwWfnGlxnUDFqFZA3UouMYj/XigbMkNeEXIjlkROKT4OPGfRx/LAyRlQQjCMv4qhbkcX1p7ar63flq4SZNVcl15l7h0uT58FzSfnlz0u5rkHfJImD43+maP/8gv36FR27jW8R9wY4hk+Ws4IB0iFSd8SXv1Kr8w/JmMQSDkiuG+RfIiubwQ/fy7Ekj5QWhPZw+mMxNKnHULy3xYz2LwVfftjwUueacvqNRCkMXlClOADqfT8oSZoeDXehHvlPsLCemGBoTKurskIS69F0yPEH5gze0H+f8FROsIoKSsVQ34B4S/joE67npsJPTdKsNPJTyQIDAQABo4IBhzCCAYMwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUoFpY76p5yoNDRGtQpzVuR81UWQ0wgcYGA1UdIwSBvjCBu4AUw60+ptYRAEWAXDpXSopt3DENnnGhgYCkfjB8MQswCQYDVQQGEwJVUzE8MDoGA1UEChMzSW50ZXJuZXQgQ29ycG9yYXRpb24gZm9yIEFzc2lnbmVkIE5hbWVzIGFuZCBOdW1iZXJzMS8wLQYDVQQDEyZJQ0FOTiBUcmFkZW1hcmsgQ2xlYXJpbmdob3VzZSBQaWxvdCBDQYIgLrAbevoae52y3f6C2tB0Sn3p7XJm0T02FogxKCfNhXkwDgYDVR0PAQH/BAQDAgeAMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuaWNhbm4ub3JnL3RtY2hfcGlsb3QuY3JsMEUGA1UdIAQ+MDwwOgYDKgMEMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93d3cuaWNhbm4ub3JnL3BpbG90X3JlcG9zaXRvcnkwDQYJKoZIhvcNAQELBQADggEBAIeDYYJr60W3y9Qs+3zRVI9kekKom5vkHOalB3wHaZIaAFYpI98tY0aVN9aGON0v6WQF+nvz1KRZQbAz01BXtaRJ4mPkarhhuLn9NkBxp8HR5qcc+KH7gv6r/c0iG3bCNJ+QSr7Qf+5MlMo6zL5UddU/T2jibMXCj/f21Qw3x9QgoyXLFJ9ozaLgQ9RMkLlOmzkCAiXN5Ab43aJ9f7N2gE2NnRjNKmmC9ABQ0TRwEKVLhVl1UGqCHJ3AlBXWIXN5sjPQcD/+nHeEXMxYvlAyqxXoD3MWtQVj7j2oqlakOBMgG8+q2qYlmBts4FNiw748Il586HKBRqxHtZdRKW2VqaQ=','parse_signed_mark signature key x590_certificate');
is($rs->{validated},1,'parse_signed_mark signature validated');

}
}

exit 0;
