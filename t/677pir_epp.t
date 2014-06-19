#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 63;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend	{ my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv	{ return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r       { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }
sub r1      { my ($c,$m)=@_; return '<result code="'.($c || 1001).'"><msg>'.($m || 'Command completed successfully; action pending').'</msg></result>'; }
sub r2      { my ($c,$m)=@_; return '<result code="'.($c || 1301).'"><msg>'.($m || 'Command completed successfully; ack to dequeue').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider=>'pir'});
$dri->target('pir')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['LaunchPhase']});

# for the mark processing
my $po=$dri->{registries}->{pir}->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();

my ($rc,$dh,$cs,$toc,$v,$lp,$lpres,$s);
my ($crdate,$exdate,$d);


### 7.4: EPP extensions Related to Validation ###

## 7.4.1: Domain Create EPP Response
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>testing.ngo</domain:name><domain:crDate>2014-03-17T22:00:00.0Z</domain:crDate><domain:exDate>2016-03-17T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><validation:creData xmlns:validation="urn:afilias:params:xml:ns:validation-1.0"><validation:claimID>claimIDValue</validation:claimID></validation:creData></extension>'.$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts');
$dh->add('ns1.testing.ngo');
$dh->add('ns2.testing.ngo');
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('jd1234'),'registrant');
$cs->add($dri->local_object('contact')->srid('sh8013'),'admin');
$cs->add($dri->local_object('contact')->srid('sh8013'),'tech');
$cs->add($dri->local_object('contact')->srid('sh8013'),'billing');
$rc=$dri->domain_create('testing.ngo',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dh,contact=>$cs,auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.testing.ngo</domain:hostObj><domain:hostObj>ns2.testing.ngo</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('name'),'testing.ngo','domain_create get_info(name)');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2014-03-17T22:00:00','domain_create get_info(crDate)');
$exdate=$dri->get_info('exDate');
is(''.$exdate,'2016-03-17T22:00:00','domain_create get_info(exDate)');
# extension
$v=$rc->get_data('validation');
is($v->{claim_id},'claimIDValue','Validation extension: domain_create parse claimID');


## 7.4.2: Change of Ownership of Domain Names
$R2=$E1.'<response>'.r().'<extension><validation:updData xmlns:validation="urn:afilias:params:xml:ns:validation-1.0"><validation:claimID>claimIDValue2</validation:claimID></validation:updData></extension>'.$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set('validation',1); # set to a true value
$rc=$dri->domain_update('testing2.ngo',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing2.ngo</domain:name></domain:update></update><extension><validation:update xmlns:validation="urn:afilias:params:xml:ns:validation-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:validation-1.0 validation-1.0.xsd"><validation:ownership><validation:chg/></validation:ownership></validation:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Validation extension: domain_update build');
is($rc->is_success(),1,'domain_update is_success');
$v=$rc->get_data('validation');
is($v->{claim_id},'claimIDValue2','Validation extension: domain_update parse claimID');


### 11.1: Sunrise and Landrush Technical Specifications ###

## II.Domain Create during Sunrise Period
$R2=$E1.'<response>'.r1().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>testing.ngo</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData><extension><launch:creData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>2393-9323-E08C-03B1</launch:applicationID></launch:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('jd1234'),'registrant');
$cs->add($dri->local_object('contact')->srid('sh8013'),'admin');
$cs->add($dri->local_object('contact')->srid('sh8013'),'tech');

# extension
my $smd=<<'EOF';
<smd:signedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0" id="signedMark">
<smd:id>1-2</smd:id>
<smd:issuerInfo issuerID="2">
<smd:org>Example Inc.</smd:org>
<smd:email>support@example.tld</smd:email>
<smd:url>http://www.example.tld</smd:url>
<smd:voice x="1234">+1.7035555555</smd:voice>
</smd:issuerInfo>
<smd:notBefore>2009-08-16T09:00:00.0Z</smd:notBefore>
<smd:notAfter>2010-08-16T09:00:00.0Z</smd:notAfter>
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
<mark:cc>US</mark:cc></mark:addr>
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
<mark:regDate>2009-08-16T09:00:00.0Z</mark:regDate>
<mark:exDate>2015-08-16T09:00:00.0Z</mark:exDate>
</mark:trademark>
</mark:mark>
<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
<SignedInfo>
<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
<Reference URI="#signedMark">
<Transforms>
<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
</Transforms>
<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
<DigestValue>miF4M2aTd1Y3tKOzJtiyl2VpzAnVPnV1Hq7Zax+yzrA=</DigestValue>
</Reference>
</SignedInfo>
<SignatureValue>
	MELpHTWEVfG1JcsG1/a//o54OnlJ5A864+X5JwfqgGBBeZSzGHNzwzTKFzIyyyfn
  lGxVwNMoBV5aSvkF7oEKMNVzfcl/P0czNQZ/LJ83p3Ol27/iUNsqgCaGf9Zupw+M
  XT4Q2lOrIw+qSx5g7q9T83siMLvkD5uEYlU5dPqgsObLTW8/doTQrA14RcxgY4kG
  a4+t5B1cT+5VaghTOPb8uUSEDKjnOsGdy8p24wgyK9n8h0CTSS2ZQ6Zq/RmQeT7D
  sbceUHheQ+mkQWIljpMQqsiBjw5XXh4jkEgfAzrb6gkYEF+X8ReuPZuOYC4QjIET
  yx8ifN4KE3GIbMXeF4LDsA==
</SignatureValue>
<KeyInfo>
<KeyValue>
      <RSAKeyValue>
       <Modulus>
        o/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/swWinuMgEWgVQFrz0xA04pEhXC
        FVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5upDqa51Flk0TMaMkIQjs7aUKC
        mA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou75bOVnIos+HifrAtrIv4qEqwL
        L4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5sPMCNxqaXmIXmQipS+DuEBqM
        M8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7vL4GgDYqhJYWV61DnXgx/Jd6C
        WxvsnDF6scscQzUTEl+hyw==
       </Modulus>
       <Exponent>
        AQAB
       </Exponent>
      </RSAKeyValue>
     </KeyValue>
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
chomp $smd;

my $ext=$parser->parse_string($smd);
my $root=$ext->getDocumentElement();

$lp={phase=>'sunrise','signed_marks'=>[$root]};
$rc=$dri->domain_create('testing.ngo',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase>'.$smd.'</launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build [Sunrise Period]');
is($rc->is_success(),1,'domain_create is_success');

## A.For End date Sunrise
is($dri->get_info('name'),'testing.ngo','domain_info get_info(name)');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2010-08-10T15:38:26','domain_create get_info(crDate)');
$exdate=$dri->get_info('exDate');
is(''.$exdate,'2012-08-10T15:38:26','domain_create get_info(exDate)');
$lpres=$dri->get_info('lp');
is($lpres->{'phase'},'sunrise','domain_info get_info(phase)');
is($lpres->{'application_id'},'2393-9323-E08C-03B1','domain_info get_info(application_id)');


## III.Domain Info during Sunrise Period
## this extension includes and OTPIONAL includeMark boolean attribute
$lp = {phase => 'sunrise','application_id'=>'123','include_mark'=>'true'};
my $markxml = '<mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>1234-2</mark:id><mark:markName>Example One</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>US</mark:cc></mark:addr></mark:holder><mark:jurisdiction>US</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:label>example-one</mark:label><mark:label>exampleone</mark:label><mark:goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-16T09:00:00.0Z</mark:regDate><mark:exDate>2015-08-16T09:00:00.0Z</mark:exDate></mark:trademark></mark:mark>';
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:roid>R123-REP</domain:roid><domain:status s="pendingCreate"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>123</launch:applicationID><launch:status s="pendingValidation"/>'.$markxml.'</launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('testing.ngo',{lp => $lp});
is ($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">testing.ngo</domain:name></domain:info></info><extension><launch:info xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" includeMark="true"><launch:phase>sunrise</launch:phase><launch:applicationID>123</launch:applicationID></launch:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build_xml');
is($dri->get_info('name'),'testing.ngo','domain_info get_info(domain name)');
is($dri->get_info('roid'),'R123-REP','domain_info get_info(domain roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['pendingCreate'],'domain_info get_info(status) list');
is($s->is_active(),0,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'sh8013','domain_info get_info(contact) tech srid');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');
is($dri->get_info('crID'),'ClientY','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2012-04-03T22:00:00','domain_info get_info(crDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
# extension info...
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'sunrise','domain_info get_info(phase) ');
is($lpres->{'application_id'},'123','domain_info get_info(application_id) ');
is($lpres->{'status'},'pendingValidation','domain_info get_info(launch_status) ');
# test some mark params...
my @marks = @{$lpres->{'marks'}};
my $m = shift @marks;
is($m->{type},'trademark','domain_info get_info(mark type)');
is($m->{id},'1234-2','domain_info get_info(mark id)');
is($m->{mark_name},'Example One','domain_info get_info(mark name)');


## IV.Domain Create during Landrush/Claims Period
# sample request for a label that is present on the DNL
$lp={phase=>'claims',notices=>[{id=>'49FD46E6C4B45C55D4AC','not_after_date'=>DateTime->new({year=>2012,month=>06,day=>19,hour=>10,second=>10}),'accepted_date'=>DateTime->new({year=>2012,month=>06,day=>19,hour=>9,minute=>01,second=>30})}]};
$rc=$dri->domain_create('testing.ngo',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><launch:notice><launch:noticeID>49FD46E6C4B45C55D4AC</launch:noticeID><launch:notAfter>2012-06-19T10:00:10Z</launch:notAfter><launch:acceptedDate>2012-06-19T09:01:30Z</launch:acceptedDate></launch:notice></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build [Landrush/Claims Period] - label presented on the DNL');
is($rc->is_success(),1,'domain_create is_success');

# sample request for a label that is not present on the DNL
$lp={phase=>'landrush'};
$R2='';
$rc=$dri->domain_create('testing.ngo',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:period unit="y">2</domain:period><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>landrush</launch:phase></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build [Landrush/Claims Period] - label not presented on the DNL');
is($rc->is_success(),1,'domain_create is_success');

## V.Domain Info during Landrush/Claims Period
#The following extension to the Domain Info command can be used to retrieve information about a
#landrush/claims application. Both the phase type and domain application ID must be submitted.

# test for sample request for a claims application
$lp={phase=>'claims','application_id'=>'123'};
$R2='';
$rc=$dri->domain_info('testing.ngo',{lp => $lp});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">testing.ngo</domain:name></domain:info></info><extension><launch:info xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><launch:applicationID>123</launch:applicationID></launch:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build [Landrush/Claims Period] - sample request for a claims application');
is($rc->is_success(),1,'domain_info is_success');

# test sample request for a landrush application
$lp={phase=>'landrush','application_id'=>'123'};
$R2='';
$rc=$dri->domain_info('testing.ngo',{lp=>$lp});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">testing.ngo</domain:name></domain:info></info><extension><launch:info xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>landrush</launch:phase><launch:applicationID>123</launch:applicationID></launch:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build [Landrush/Claims Period] - sample request for a landrush application');
is($rc->is_success(),1,'domain_info is_success');


## VI.Domain Check during Claims Period
$lp={phase=>'claims'}; # accept an optional attribute type
$R2=$E1.'<response>'.r().'<extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="0">testing1.ngo</launch:name></launch:cd><launch:cd><launch:name exists="1">testing2.ngo</launch:name><launch:claimKey>abc123</launch:claimKey></launch:cd></launch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('testing1.ngo','testing2.ngo',{lp=>$lp});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing1.ngo</domain:name><domain:name>testing2.ngo</domain:name></domain:check></check><extension><launch:check xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>claims</launch:phase></launch:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build [during Claims Period]');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist','domain','testing1.ngo'),0,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','testing2.ngo'),1,'domain_check_multi get_info(exist) 2/2');
$lpres=$dri->get_info('lp','domain','testing2.ngo');
is($lpres->{'claim_key'},'abc123','domain_check_multi get_info(claim_key)');


## VII.Domain Create During GA/Claims Period
$lp={phase=>'open'};
$R2='';
$rc=$dri->domain_create('testing.ngo',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:period unit="y">2</domain:period><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>open</launch:phase></launch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build [During GA/Claims Period]');
is($rc->is_success(),1,'domain_create is_success');


## X. Poll Queue

# example poll message for a Launch Application that has transitioned to the pendingAllocation state
$R2=$E1.'<response>'.r2().'<msgQ count="5" id="12345"><qDate>2013-04-04T22:01:00.0Z</qDate><msg>Application pendingAllocation.</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testing.ngo</domain:name><domain:roid>D123-LRMS</domain:roid><domain:clID>ClientX</domain:clID></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>123</launch:applicationID><launch:status s="pendingAllocation"/></launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is($dri->get_info('last_id'),'12345','message_retrive get_info(last_id)');
$lp=$dri->get_info('lp','message','12345');
is($lp->{'phase'},'sunrise','message_retrieve get_info lp->{phase}');
is($lp->{'application_id'},'123','message_retrieve get_info lp->{application_id}');
is($lp->{'status'},'pendingAllocation','message_retrieve get_info lp->{status}');

# example <domain:panData> poll message for an allocated Launch Application
$R2=$E1.'<response>'.r2().'<msgQ count="5" id="12345"><qDate>2013-04-04T22:01:00.0Z</qDate><msg>Application successfully allocated.</msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name paResult="1">testing.ngo</domain:name><domain:paTRID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></domain:paTRID><domain:paDate>2013-04-04T22:00:00.0Z</domain:paDate></domain:panData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase><launch:applicationID>abc123</launch:applicationID><launch:status s="allocated"/></launch:infData></extension><trID><clTRID>BCD-23456</clTRID><svTRID>65432-WXY</svTRID></trID></response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success');
is($dri->get_info('last_id'),'12345','message_retrive get_info(last_id)');
$lp=$dri->get_info('lp','message','12345');
is($lp->{'phase'},'sunrise','message_retrieve get_info lp->{phase}');
is($lp->{'application_id'},'abc123','message_retrieve get_info lp->{application_id}');
is($lp->{'status'},'allocated','message_retrieve get_info lp->{status}');

exit 0;
