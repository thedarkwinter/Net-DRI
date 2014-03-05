#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use MIME::Base64;
use DateTime;
use DateTime::Duration;

use Test::More tests => 82;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:tmch-1.0 tmch-1.0">';
our $E2='</tmch>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('Deloitte');
$dri->target('Deloitte')->add_current_profile('p1','tmch',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($dh,@c);
my ($s,$d,$smark,$mark,$cs,$holder,$holder2,$agent,$tparty,$l1,$l2,$d1,$chg,@docs,@labels);

## Session commands

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"><greeting><svID>TMCH server</svID><svDate>2013-01-15T12:01:02Z</svDate></greeting></tmch>';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>Eadsfsdk-010132</clTRID><svTRID>TMCH-000000001</svTRID></trID></response></tmch>';
$rc=$dri->process('session','login',['ClientX','foo-BAR2']);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><svTRID>TMCH-000000001</svTRID></trID></response></tmch>';
$rc=$dri->process('session','logout');
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
## Mark Commands

# check
$R2=$E1 .'<response>'  . r() .  '<resData><chkData><cd><id avail="0">00000712423-1</id><reason>Not available</reason></cd></chkData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_check('00000712423-1');
is($R1,$E1.'<command><check><id>00000712423-1</id></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_check build');
is($rc->is_success(), 1, 'mark_check is_success');
is($dri->get_info('action'),'check','mark_check get_info(action)');
is($dri->get_info('exist'),1,'mark_check get_info(exist)');
is($dri->get_info('exist_reason'),'Not available','mark_check reason');

# info default (trademark)
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000712423-1</id><status s="new"/><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T09:00:00.0Z</regDate><exDate>2015-08-16T09:00:00.0Z</exDate></trademark></mark><document><id>14531423SADF</id><docType>Other</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType></document><label><aLabel>my-name</aLabel><uLabel>my-name</uLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>myname</aLabel><uLabel>myname</uLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label><crDate>2013-02-10T22:00:00Z</crDate><upDate>2013-03-11T08:01:38Z</upDate><exDate>2018-03-11T08:01:38Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('00000712423-1');
is($R1,$E1.'<command><info><id>00000712423-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$s = $dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(status)');
is_deeply([$s->list_status()],['new'],'mark_info get_info(status) is new');
$mark = $dri->get_info('mark');
is($mark->{'type'},'trademark','mark_info get_info(mark) type');
is($mark->{'mark_name'},'Example One','mark_info get_info(mark) mark_name');
is_deeply($mark->{'class'},[35,36],'mark_info get_info(mark) class');
$cs = $mark->{'contact'};
isa_ok($cs,'Net::DRI::Data::ContactSet','mark_info get_info(cs)');
$holder = $cs->get('holder_owner');
isa_ok($holder,'Net::DRI::Data::Contact','mark_info get_info(holder)');
is($holder->org(),'Example Inc.','mark_info get_info(holder)');
@labels = @{$dri->get_info('labels')};
$l1 = $labels[0];
isa_ok($l1,'HASH','mark_info get_info(label)');
is($l1->{a_label},'my-name','mark_info get_info(label) alabel');
@docs = @{$dri->get_info('documents')};
$d1 = $docs[0];
isa_ok($d1,'HASH','mark_info get_info(document)');
is($d1->{file_type},'jpg','mark_info get_info(document) pdf');

# info default (court)
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000712423-1</id><status s="new"/><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><court><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00.0Z</proDate><cc>US</cc><courtName>P.R. supreme court</courtName></court></mark><document><id>14531423SADF</id><docType>Other</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType></document><label><aLabel>my-name</aLabel><uLabel>my-name</uLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><crDate>2013-02-10T22:00:00Z</crDate><upDate>2013-03-11T08:01:38Z</upDate><exDate>2018-03-11T08:01:38Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('00000712423-1');
is($R1,$E1.'<command><info><id>00000712423-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$mark = $dri->get_info('mark');
is($mark->{'type'},'court','mark_info get_info(mark) type');
is($mark->{'court_name'},'P.R. supreme court','mark_info get_info(mark) court_name');

# info default (statueOrTreaty)
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000712423-1</id><status s="new"/><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><treatyOrStatute><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><protection><ruling>US</ruling><cc>US</cc><region>US</region></protection><goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00.0Z</proDate><title>My Mark Title</title><execDate>2010-01-05T09:00:00.0Z</execDate></treatyOrStatute></mark><document><id>14531423SADF</id><docType>Other</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType></document><label><aLabel>my-name</aLabel><uLabel>my-name</uLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><crDate>2013-02-10T22:00:00Z</crDate><upDate>2013-03-11T08:01:38Z</upDate><exDate>2018-03-11T08:01:38Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('00000712423-1');
is($R1,$E1.'<command><info><id>00000712423-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$mark = $dri->get_info('mark');
is($mark->{'type'},'treaty_statute','mark_info get_info(mark) type');
is($mark->{'mark_name'},'Example One','mark_info get_info(mark) mark_name');
is($mark->{'title'},'My Mark Title','mark_info get_info(mark) title');
my $p1 = shift @{$mark->{'protection'}};
is_deeply($p1,{'cc'=>'US','region'=>'US','ruling'=>['US']},'mark_info get_info(mark) protection' );

# info smd
$R2=$E1 .'<response>'  . r() .  '<resData><smdData><id>00000712423-1</id><smd:signedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0" id="signedMark"><smd:id>000000000023234-2</smd:id><smd:issuerInfo issuerID="2"><smd:org>Example Inc.</smd:org><smd:email>support@example.tld</smd:email><smd:url>http://www.example.tld</smd:url><smd:voice x="1234">+1.7035555555</smd:voice></smd:issuerInfo><smd:notBefore>2009-08-16T09:00:00.0Z</smd:notBefore><smd:notAfter>2010-08-16T09:00:00.0Z</smd:notAfter><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T09:00:00.0Z</regDate><exDate>2015-08-16T09:00:00.0Z</exDate></trademark></mark><Signature xmlns="http://www.w3.org/2000/09/xmldsig#"> <SignedInfo>  <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>  <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>  <Reference URI="#signedMark">   <Transforms>    <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>   </Transforms>   <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>   <DigestValue>+H77j3e1Vxl35nOLtwKlwotWYI1ZNr2rmFfiOFvL3uc=</DigestValue>  </Reference> </SignedInfo><SignatureValue>ViaGZelg9Nm/PfJEN4lFathJxO/v1NwIWHPN1rgFxkil+YpOO1+TMkf9bluymAdgzJEAd+NUnEDYkk0CddL81oOyra5OAtPscxJFVkyg7AKu7H7pM0+0vznrVjE9LQ5db110R1QBriqLHrjdc6NJxGVXjEq2m14Ut4TWmqglMSVu9n/iUEX4HrCHPRlOkkMrepTy63mqufAsrkNNxZYIJpC/V9nVgSXNTNzf84QS/LnF6xdKnYL67gEWkZTbziYj5N7Fxg3M78H+SCo8D8aBsdYyVLYKPrP/EQaPlxw+fxPT61IxSEIW/5Rvzr7XjZC7rlAh4gC9NCk9C2urUyrpEg==</SignatureValue><KeyInfo><KeyValue><RSAKeyValue><Modulus>o/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/swWinuMgEWgVQFrz0xA04pEhXCFVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5upDqa51Flk0TMaMkIQjs7aUKCmA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou75bOVnIos+HifrAtrIv4qEqwLL4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5sPMCNxqaXmIXmQipS+DuEBqMM8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7vL4GgDYqhJYWV61DnXgx/Jd6CWxvsnDF6scscQzUTEl+hyw==</Modulus><Exponent>AQAB</Exponent></RSAKeyValue></KeyValue><X509Data><X509Certificate>MIIESTCCAzGgAwIBAgIBAjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0EwHhcNMTMwMjA4MDAwMDAwWhcNMTgwMjA3MjM1OTU5WjBsMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRcwFQYDVQQKEw5WYWxpZGF0b3IgVE1DSDEhMB8GA1UEAxMYVmFsaWRhdG9yIFRNQ0ggVEVTVCBDRVJUMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo/cwvXhbVYl0RDWWvoyeZpETVZVVcMCovUVNg/swWinuMgEWgVQFrz0xA04pEhXCFVv4evbUpekJ5buqU1gmQyOsCKQlhOHTdPjvkC5upDqa51Flk0TMaMkIQjs7aUKCmA4RG4tTTGK/EjR1ix8/D0gHYVRldy1YPrMP+ou75bOVnIos+HifrAtrIv4qEqwLL4FTZAUpaCa2BmgXfy2CSRQbxD5Or1gcSa3vurh5sPMCNxqaXmIXmQipS+DuEBqMM8tldaN7RYojUEKrGVsNk5i9y2/7sjn1zyyUPf7vL4GgDYqhJYWV61DnXgx/Jd6CWxvsnDF6scscQzUTEl+hywIDAQABo4H/MIH8MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFPZEcIQcD/Bj2IFz/LERuo2ADJviMIGMBgNVHSMEgYQwgYGAFO0/7kEh3FuEKS+Q/kYHaD/W6wihoWakZDBiMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFDASBgNVBAcTC0xvcyBBbmdlbGVzMRMwEQYDVQQKEwpJQ0FOTiBUTUNIMRswGQYDVQQDExJJQ0FOTiBUTUNIIFRFU1QgQ0GCAQEwDgYDVR0PAQH/BAQDAgeAMC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuaWNhbm4ub3JnL3RtY2guY3JsMA0GCSqGSIb3DQEBCwUAA4IBAQB2qSy7ui+43cebKUKwWPrzz9y/IkrMeJGKjo40n+9uekaw3DJ5EqiOf/qZ4pjBD++oR6BJCb6NQuQKwnoAz5lE4Ssuy5+i93oT3HfyVc4gNMIoHm1PS19l7DBKrbwbzAea/0jKWVzrvmV7TBfjxD3AQo1RbU5dBr6IjbdLFlnO5x0G0mrG7x5OUPuurihyiURpFDpwH8KAH1wMcCpXGXFRtGKkwydgyVYAty7otkl/z3bZkCVT34gPvF70sR6+QxUy8u0LzF5A/beYaZpxSYG31amLAdXitTWFipaIGea9lEGFM0L9+Bg7XzNn4nVLXokyEB3bgS4scG6QznX23FGk</X509Certificate></X509Data></KeyInfo></Signature></smd:signedMark></smdData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info_smd('00000712423-1');
is($R1,$E1.'<command><info type="smd"><id>00000712423-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info_smd build');
is($rc->is_success(), 1, 'mark_info_smd is_success');
is($dri->get_info('action'),'info','mark_info_smd get_info(action)');
$smark = $dri->get_info('signed_mark');
isa_ok($smark->{'mark'}->{'contact'},'Net::DRI::Data::ContactSet','mark_info_smd get_info(contact)');
is($smark->{'id'},'000000000023234-2','mark_info_smd get_info(signedMark) signed_mark_id');
is($smark->{'mark'}->{'id'},'00000712423-1','mark_info_smd get_info(signedMark) mark_id');
is($smark->{'creation_date'},'2009-08-16T09:00:00','mark_info_smd get_info(signedMark) creation_date');
my $ii = $smark->{'issuer'};
is($ii->{id},'2','mark_info_smd get_info(signed_mark) issuer id');
my $sig = $smark->{'signature'};
is($sig->{value},'ViaGZelg9Nm/PfJEN4lFathJxO/v1NwIWHPN1rgFxkil+YpOO1+TMkf9bluymAdgzJEAd+NUnEDYkk0CddL81oOyra5OAtPscxJFVkyg7AKu7H7pM0+0vznrVjE9LQ5db110R1QBriqLHrjdc6NJxGVXjEq2m14Ut4TWmqglMSVu9n/iUEX4HrCHPRlOkkMrepTy63mqufAsrkNNxZYIJpC/V9nVgSXNTNzf84QS/LnF6xdKnYL67gEWkZTbziYj5N7Fxg3M78H+SCo8D8aBsdYyVLYKPrP/EQaPlxw+fxPT61IxSEIW/5Rvzr7XjZC7rlAh4gC9NCk9C2urUyrpEg==','mark_info_smd get_info(signedMark) Signature value');

# info enc
$R2=$E1 .'<response>'  . r() .  '<resData><smdData><id>00000712423-1</id><smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">ICAgICAgICAgICAgICAgIDxzbWQ6c2lnbmVkTWFyayB4bWxuczpzbWQ9InVybjppZXRmOnBhcmFtczp4bWw6bnM6c2lnbmVkTWFyay0xLjAiCiAgICAgICAgICAgICAgICAgICAgICAgIGlkPSJzaWduZWRNYXJrIj4KICAgICAgICAgICAgICAgICAgICA8c21kOmlkPjAwMDAwMDAwMDAyMzIzNC0wMTwvc21kOmlkPgogICAgICAgICAgICAgICAgICAgIDxzbWQ6aXNzdWVySW5mbyBpc3N1ZXJJRD0iMSI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6b3JnPkV4YW1wbGUgSW5jLjwvc21kOm9yZz4KICAgICAgICAgICAgICAgICAgICAgICAgPHNtZDplbWFpbD5zdXBwb3J0QGV4YW1wbGUudGxkPC9zbWQ6ZW1haWw+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6dXJsPmh0dHA6Ly93d3cuZXhhbXBsZS50bGQ8L3NtZDp1cmw+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6dm9pY2UgeD0iMTIzNCI+KzEuNzAzNTU1NTU1NTwvc21kOnZvaWNlPgogICAgICAgICAgICAgICAgICAgIDwvc21kOmlzc3VlckluZm8+CiAgICAgICAgICAgICAgICAgICAgPHNtZDpub3RCZWZvcmU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvc21kOm5vdEJlZm9yZT4KICAgICAgICAgICAgICAgICAgICA8c21kOm5vdEFmdGVyPjIwMTAtMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RBZnRlcj4KICAgICAgICAgICAgICAgICAgICA8bWFyazptYXJrIHhtbG5zOm1hcms9InVybjppZXRmOnBhcmFtczp4bWw6bnM6bWFyay0xLjAiPgogICAgICAgICAgICAgICAgICAgIDxtYXJrOnRyYWRlbWFyaz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6aWQ+MDAwNzEyNDIzLTAxPC9tYXJrOmlkPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazptYXJrTmFtZT5FeGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6aG9sZGVyIGVudGl0bGVtZW50PSJvd25lciI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9tYXJrOm9yZz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOmFkZHI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6c3RyZWV0PjEyMyBFeGFtcGxlIERyLjwvbWFyazpzdHJlZXQ+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6c3RyZWV0PlN1aXRlIDEwMDwvbWFyazpzdHJlZXQ+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6Y2l0eT5SZXN0b248L21hcms6Y2l0eT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpzcD5WQTwvbWFyazpzcD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpwYz4yMDE5MDwvbWFyazpwYz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpjYz5VUzwvbWFyazpjYz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvbWFyazphZGRyPgogICAgICAgICAgICAgICAgICAgICAgICA8L21hcms6aG9sZGVyPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpqdXJpc2RpY3Rpb24+VVM8L21hcms6anVyaXNkaWN0aW9uPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpjbGFzcz4zNTwvbWFyazpjbGFzcz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+CiAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOmdvb2RzQW5kU2VydmljZXM+RGlyaWdlbmRhcyBldCBlaXVzbW9kaQogICAgICAgICAgICAgICAgICAgICAgICAgICAgZmVhdHVyaW5nIGluZnJpbmdvIGluIGFpcmZhcmUgZXQgY2FydGFtIHNlcnZpY2lhLgogICAgICAgICAgICAgICAgICAgICAgICA8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6cmVnTnVtPjIzNDIzNTwvbWFyazpyZWdOdW0+CiAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOnJlZ0RhdGU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpyZWdEYXRlPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpleERhdGU+MjAxNS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpleERhdGU+CiAgICAgICAgICAgICAgICAgICAgPC9tYXJrOnRyYWRlbWFyaz4KICAgICAgICAgICAgICAgICAgICA8L21hcms6bWFyaz4KICAgICAgICAgICAgICAgICAgICA8U2lnbmF0dXJlIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFNpZ25lZEluZm8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2Fub25pY2FsaXphdGlvbk1ldGhvZAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2lnbmF0dXJlTWV0aG9kCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGRzaWctbW9yZSNyc2Etc2hhMjU2Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8UmVmZXJlbmNlIFVSST0iI3NpZ25lZE1hcmsiPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxUcmFuc2Zvcm1zPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8VHJhbnNmb3JtCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNlbnZlbG9wZWQtc2lnbmF0dXJlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9UcmFuc2Zvcm1zPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxEaWdlc3RNZXRob2QKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8RGlnZXN0VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICtINzdqM2UxVnhsMzVuT0x0d0tsd290V1lJMVpOcjJybUZmaU9GdkwzdWM9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9EaWdlc3RWYWx1ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvUmVmZXJlbmNlPgogICAgICAgICAgICAgICAgICAgICAgICA8L1NpZ25lZEluZm8+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTaWduYXR1cmVWYWx1ZT4KIFZpYUdaZWxnOU5tL1BmSkVONGxGYXRoSnhPL3YxTndJV0hQTjFyZ0Z4a2lsK1lwT08xK1RNa2Y5Ymx1eW1BZGcKIHpKRUFkK05VbkVEWWtrMENkZEw4MW9PeXJhNU9BdFBzY3hKRlZreWc3QUt1N0g3cE0wKzB2em5yVmpFOUxRNWQKIGIxMTBSMVFCcmlxTEhyamRjNk5KeEdWWGpFcTJtMTRVdDRUV21xZ2xNU1Z1OW4vaVVFWDRIckNIUFJsT2trTXIKIGVwVHk2M21xdWZBc3JrTk54WllJSnBDL1Y5blZnU1hOVE56Zjg0UVMvTG5GNnhkS25ZTDY3Z0VXa1pUYnppWWoKIDVON0Z4ZzNNNzhIK1NDbzhEOGFCc2RZeVZMWUtQclAvRVFhUGx4dytmeFBUNjFJeFNFSVcvNVJ2enI3WGpaQzcKIHJsQWg0Z0M5TkNrOUMydXJVeXJwRWc9PQogICAgICAgICAgICAgICAgICAgICAgICA8L1NpZ25hdHVyZVZhbHVlPgogICAgICAgICAgICAgICAgICAgICAgICA8S2V5SW5mbz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxLZXlWYWx1ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8UlNBS2V5VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxNb2R1bHVzPgogby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVUVlpWVmNNQ292VVZOZy9zd1dpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQwogRlZ2NGV2YlVwZWtKNWJ1cVUxZ21ReU9zQ0tRbGhPSFRkUGp2a0M1dXBEcWE1MUZsazBUTWFNa0lRanM3YVVLQwogbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291NzViT1ZuSW9zK0hpZnJBdHJJdjRxRXF3TAogTDRGVFpBVXBhQ2EyQm1nWGZ5MkNTUlFieEQ1T3IxZ2NTYTN2dXJoNXNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTQogTTh0bGRhTjdSWW9qVUVLckdWc05rNWk5eTIvN3NqbjF6eXlVUGY3dkw0R2dEWXFoSllXVjYxRG5YZ3gvSmQ2QwogV3h2c25ERjZzY3NjUXpVVEVsK2h5dz09CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvTW9kdWx1cz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPEV4cG9uZW50PgogQVFBQgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L0V4cG9uZW50PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvUlNBS2V5VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L0tleVZhbHVlPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPFg1MDlEYXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxYNTA5Q2VydGlmaWNhdGU+CiBNSUlFU1RDQ0F6R2dBd0lCQWdJQkFqQU5CZ2txaGtpRzl3MEJBUXNGQURCaU1Rc3dDUVlEVlFRR0V3SlZVekVMCiBNQWtHQTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJibWRsYkdWek1STXdFUVlEVlFRS0V3cEpRMEZPCiBUaUJVVFVOSU1Sc3dHUVlEVlFRREV4SkpRMEZPVGlCVVRVTklJRlJGVTFRZ1EwRXdIaGNOTVRNd01qQTRNREF3CiBNREF3V2hjTk1UZ3dNakEzTWpNMU9UVTVXakJzTVFzd0NRWURWUVFHRXdKVlV6RUxNQWtHQTFVRUNCTUNRMEV4CiBGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJjd0ZRWURWUVFLRXc1V1lXeHBaR0YwYjNJZ1ZFMURTREVoCiBNQjhHQTFVRUF4TVlWbUZzYVdSaGRHOXlJRlJOUTBnZ1ZFVlRWQ0JEUlZKVU1JSUJJakFOQmdrcWhraUc5dzBCCiBBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZWY01Db3ZVVk5nL3N3CiBXaW51TWdFV2dWUUZyejB4QTA0cEVoWENGVnY0ZXZiVXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1CiBwRHFhNTFGbGswVE1hTWtJUWpzN2FVS0NtQTRSRzR0VFRHSy9FalIxaXg4L0QwZ0hZVlJsZHkxWVByTVArb3U3CiA1Yk9WbklvcytIaWZyQXRySXY0cUVxd0xMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4RDVPcjFnY1NhM3Z1cmg1CiBzUE1DTnhxYVhtSVhtUWlwUytEdUVCcU1NOHRsZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2CiBMNEdnRFlxaEpZV1Y2MURuWGd4L0pkNkNXeHZzbkRGNnNjc2NRelVURWwraHl3SURBUUFCbzRIL01JSDhNQXdHCiBBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRlBaRWNJUWNEL0JqMklGei9MRVJ1bzJBREp2aU1JR01CZ05WCiBIU01FZ1lRd2dZR0FGTzAvN2tFaDNGdUVLUytRL2tZSGFEL1c2d2lob1dha1pEQmlNUXN3Q1FZRFZRUUdFd0pWCiBVekVMTUFrR0ExVUVDQk1DUTBFeEZEQVNCZ05WQkFjVEMweHZjeUJCYm1kbGJHVnpNUk13RVFZRFZRUUtFd3BKCiBRMEZPVGlCVVRVTklNUnN3R1FZRFZRUURFeEpKUTBGT1RpQlVUVU5JSUZSRlUxUWdRMEdDQVFFd0RnWURWUjBQCiBBUUgvQkFRREFnZUFNQzRHQTFVZEh3UW5NQ1V3STZBaG9CK0dIV2gwZEhBNkx5OWpjbXd1YVdOaGJtNHViM0puCiBMM1J0WTJndVkzSnNNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUIycVN5N3VpKzQzY2ViS1VLd1dQcnp6OXkvCiBJa3JNZUpHS2pvNDBuKzl1ZWthdzNESjVFcWlPZi9xWjRwakJEKytvUjZCSkNiNk5RdVFLd25vQXo1bEU0U3N1CiB5NStpOTNvVDNIZnlWYzRnTk1Jb0htMVBTMTlsN0RCS3Jid2J6QWVhLzBqS1dWenJ2bVY3VEJmanhEM0FRbzFSCiBiVTVkQnI2SWpiZExGbG5PNXgwRzBtckc3eDVPVVB1dXJpaHlpVVJwRkRwd0g4S0FIMXdNY0NwWEdYRlJ0R0trCiB3eWRneVZZQXR5N290a2wvejNiWmtDVlQzNGdQdkY3MHNSNitReFV5OHUwTHpGNUEvYmVZYVpweFNZRzMxYW1MCiBBZFhpdFRXRmlwYUlHZWE5bEVHRk0wTDkrQmc3WHpObjRuVkxYb2t5RUIzYmdTNHNjRzZRem5YMjNGR2sKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L1g1MDlDZXJ0aWZpY2F0ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvWDUwOURhdGE+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvS2V5SW5mbz4KICAgICAgICAgICAgICAgICAgICA8L1NpZ25hdHVyZT4KICAgICAgICAgICAgICAgIDwvc21kOnNpZ25lZE1hcms+Cg==</smd:encodedSignedMark></smdData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info_enc('00000712423-1');
is($R1,$E1.'<command><info type="enc"><id>00000712423-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info_enc build');
is($rc->is_success(), 1, 'mark_info_enc is_success');
is($dri->get_info('action'),'info','mark_info_enc get_info(action)');
$mark = $dri->get_info('mark');
is($mark->{'mark_name'},'Example One','mark_info_enc get_info(mark) mark_name');
$smark = $dri->get_info('signed_mark');
is($smark->{'mark'}->{'mark_name'},'Example One','mark_info_enc get_info(encoded_signed_mark) mark_name');
my $enc = $dri->get_info('encoded_signed_mark');
is($enc,'ICAgICAgICAgICAgICAgIDxzbWQ6c2lnbmVkTWFyayB4bWxuczpzbWQ9InVybjppZXRmOnBhcmFtczp4bWw6bnM6c2lnbmVkTWFyay0xLjAiCiAgICAgICAgICAgICAgICAgICAgICAgIGlkPSJzaWduZWRNYXJrIj4KICAgICAgICAgICAgICAgICAgICA8c21kOmlkPjAwMDAwMDAwMDAyMzIzNC0wMTwvc21kOmlkPgogICAgICAgICAgICAgICAgICAgIDxzbWQ6aXNzdWVySW5mbyBpc3N1ZXJJRD0iMSI+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6b3JnPkV4YW1wbGUgSW5jLjwvc21kOm9yZz4KICAgICAgICAgICAgICAgICAgICAgICAgPHNtZDplbWFpbD5zdXBwb3J0QGV4YW1wbGUudGxkPC9zbWQ6ZW1haWw+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6dXJsPmh0dHA6Ly93d3cuZXhhbXBsZS50bGQ8L3NtZDp1cmw+CiAgICAgICAgICAgICAgICAgICAgICAgIDxzbWQ6dm9pY2UgeD0iMTIzNCI+KzEuNzAzNTU1NTU1NTwvc21kOnZvaWNlPgogICAgICAgICAgICAgICAgICAgIDwvc21kOmlzc3VlckluZm8+CiAgICAgICAgICAgICAgICAgICAgPHNtZDpub3RCZWZvcmU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvc21kOm5vdEJlZm9yZT4KICAgICAgICAgICAgICAgICAgICA8c21kOm5vdEFmdGVyPjIwMTAtMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RBZnRlcj4KICAgICAgICAgICAgICAgICAgICA8bWFyazptYXJrIHhtbG5zOm1hcms9InVybjppZXRmOnBhcmFtczp4bWw6bnM6bWFyay0xLjAiPgogICAgICAgICAgICAgICAgICAgIDxtYXJrOnRyYWRlbWFyaz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6aWQ+MDAwNzEyNDIzLTAxPC9tYXJrOmlkPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazptYXJrTmFtZT5FeGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6aG9sZGVyIGVudGl0bGVtZW50PSJvd25lciI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9tYXJrOm9yZz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOmFkZHI+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6c3RyZWV0PjEyMyBFeGFtcGxlIERyLjwvbWFyazpzdHJlZXQ+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6c3RyZWV0PlN1aXRlIDEwMDwvbWFyazpzdHJlZXQ+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6Y2l0eT5SZXN0b248L21hcms6Y2l0eT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpzcD5WQTwvbWFyazpzcD4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpwYz4yMDE5MDwvbWFyazpwYz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpjYz5VUzwvbWFyazpjYz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvbWFyazphZGRyPgogICAgICAgICAgICAgICAgICAgICAgICA8L21hcms6aG9sZGVyPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpqdXJpc2RpY3Rpb24+VVM8L21hcms6anVyaXNkaWN0aW9uPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpjbGFzcz4zNTwvbWFyazpjbGFzcz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+CiAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOmdvb2RzQW5kU2VydmljZXM+RGlyaWdlbmRhcyBldCBlaXVzbW9kaQogICAgICAgICAgICAgICAgICAgICAgICAgICAgZmVhdHVyaW5nIGluZnJpbmdvIGluIGFpcmZhcmUgZXQgY2FydGFtIHNlcnZpY2lhLgogICAgICAgICAgICAgICAgICAgICAgICA8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz4KICAgICAgICAgICAgICAgICAgICAgICAgPG1hcms6cmVnTnVtPjIzNDIzNTwvbWFyazpyZWdOdW0+CiAgICAgICAgICAgICAgICAgICAgICAgIDxtYXJrOnJlZ0RhdGU+MjAwOS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpyZWdEYXRlPgogICAgICAgICAgICAgICAgICAgICAgICA8bWFyazpleERhdGU+MjAxNS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpleERhdGU+CiAgICAgICAgICAgICAgICAgICAgPC9tYXJrOnRyYWRlbWFyaz4KICAgICAgICAgICAgICAgICAgICA8L21hcms6bWFyaz4KICAgICAgICAgICAgICAgICAgICA8U2lnbmF0dXJlIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjIj4KICAgICAgICAgICAgICAgICAgICAgICAgPFNpZ25lZEluZm8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8Q2Fub25pY2FsaXphdGlvbk1ldGhvZAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8U2lnbmF0dXJlTWV0aG9kCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGRzaWctbW9yZSNyc2Etc2hhMjU2Ii8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8UmVmZXJlbmNlIFVSST0iI3NpZ25lZE1hcmsiPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxUcmFuc2Zvcm1zPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8VHJhbnNmb3JtCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNlbnZlbG9wZWQtc2lnbmF0dXJlIi8+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9UcmFuc2Zvcm1zPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxEaWdlc3RNZXRob2QKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8RGlnZXN0VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICtINzdqM2UxVnhsMzVuT0x0d0tsd290V1lJMVpOcjJybUZmaU9GdkwzdWM9CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPC9EaWdlc3RWYWx1ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvUmVmZXJlbmNlPgogICAgICAgICAgICAgICAgICAgICAgICA8L1NpZ25lZEluZm8+CiAgICAgICAgICAgICAgICAgICAgICAgIDxTaWduYXR1cmVWYWx1ZT4KIFZpYUdaZWxnOU5tL1BmSkVONGxGYXRoSnhPL3YxTndJV0hQTjFyZ0Z4a2lsK1lwT08xK1RNa2Y5Ymx1eW1BZGcKIHpKRUFkK05VbkVEWWtrMENkZEw4MW9PeXJhNU9BdFBzY3hKRlZreWc3QUt1N0g3cE0wKzB2em5yVmpFOUxRNWQKIGIxMTBSMVFCcmlxTEhyamRjNk5KeEdWWGpFcTJtMTRVdDRUV21xZ2xNU1Z1OW4vaVVFWDRIckNIUFJsT2trTXIKIGVwVHk2M21xdWZBc3JrTk54WllJSnBDL1Y5blZnU1hOVE56Zjg0UVMvTG5GNnhkS25ZTDY3Z0VXa1pUYnppWWoKIDVON0Z4ZzNNNzhIK1NDbzhEOGFCc2RZeVZMWUtQclAvRVFhUGx4dytmeFBUNjFJeFNFSVcvNVJ2enI3WGpaQzcKIHJsQWg0Z0M5TkNrOUMydXJVeXJwRWc9PQogICAgICAgICAgICAgICAgICAgICAgICA8L1NpZ25hdHVyZVZhbHVlPgogICAgICAgICAgICAgICAgICAgICAgICA8S2V5SW5mbz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxLZXlWYWx1ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8UlNBS2V5VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxNb2R1bHVzPgogby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVUVlpWVmNNQ292VVZOZy9zd1dpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQwogRlZ2NGV2YlVwZWtKNWJ1cVUxZ21ReU9zQ0tRbGhPSFRkUGp2a0M1dXBEcWE1MUZsazBUTWFNa0lRanM3YVVLQwogbUE0Ukc0dFRUR0svRWpSMWl4OC9EMGdIWVZSbGR5MVlQck1QK291NzViT1ZuSW9zK0hpZnJBdHJJdjRxRXF3TAogTDRGVFpBVXBhQ2EyQm1nWGZ5MkNTUlFieEQ1T3IxZ2NTYTN2dXJoNXNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTQogTTh0bGRhTjdSWW9qVUVLckdWc05rNWk5eTIvN3NqbjF6eXlVUGY3dkw0R2dEWXFoSllXVjYxRG5YZ3gvSmQ2QwogV3h2c25ERjZzY3NjUXpVVEVsK2h5dz09CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvTW9kdWx1cz4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPEV4cG9uZW50PgogQVFBQgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L0V4cG9uZW50PgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvUlNBS2V5VmFsdWU+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L0tleVZhbHVlPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgPFg1MDlEYXRhPgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDxYNTA5Q2VydGlmaWNhdGU+CiBNSUlFU1RDQ0F6R2dBd0lCQWdJQkFqQU5CZ2txaGtpRzl3MEJBUXNGQURCaU1Rc3dDUVlEVlFRR0V3SlZVekVMCiBNQWtHQTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJibWRsYkdWek1STXdFUVlEVlFRS0V3cEpRMEZPCiBUaUJVVFVOSU1Sc3dHUVlEVlFRREV4SkpRMEZPVGlCVVRVTklJRlJGVTFRZ1EwRXdIaGNOTVRNd01qQTRNREF3CiBNREF3V2hjTk1UZ3dNakEzTWpNMU9UVTVXakJzTVFzd0NRWURWUVFHRXdKVlV6RUxNQWtHQTFVRUNCTUNRMEV4CiBGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJjd0ZRWURWUVFLRXc1V1lXeHBaR0YwYjNJZ1ZFMURTREVoCiBNQjhHQTFVRUF4TVlWbUZzYVdSaGRHOXlJRlJOUTBnZ1ZFVlRWQ0JEUlZKVU1JSUJJakFOQmdrcWhraUc5dzBCCiBBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFvL2N3dlhoYlZZbDBSRFdXdm95ZVpwRVRWWlZWY01Db3ZVVk5nL3N3CiBXaW51TWdFV2dWUUZyejB4QTA0cEVoWENGVnY0ZXZiVXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1CiBwRHFhNTFGbGswVE1hTWtJUWpzN2FVS0NtQTRSRzR0VFRHSy9FalIxaXg4L0QwZ0hZVlJsZHkxWVByTVArb3U3CiA1Yk9WbklvcytIaWZyQXRySXY0cUVxd0xMNEZUWkFVcGFDYTJCbWdYZnkyQ1NSUWJ4RDVPcjFnY1NhM3Z1cmg1CiBzUE1DTnhxYVhtSVhtUWlwUytEdUVCcU1NOHRsZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2CiBMNEdnRFlxaEpZV1Y2MURuWGd4L0pkNkNXeHZzbkRGNnNjc2NRelVURWwraHl3SURBUUFCbzRIL01JSDhNQXdHCiBBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRlBaRWNJUWNEL0JqMklGei9MRVJ1bzJBREp2aU1JR01CZ05WCiBIU01FZ1lRd2dZR0FGTzAvN2tFaDNGdUVLUytRL2tZSGFEL1c2d2lob1dha1pEQmlNUXN3Q1FZRFZRUUdFd0pWCiBVekVMTUFrR0ExVUVDQk1DUTBFeEZEQVNCZ05WQkFjVEMweHZjeUJCYm1kbGJHVnpNUk13RVFZRFZRUUtFd3BKCiBRMEZPVGlCVVRVTklNUnN3R1FZRFZRUURFeEpKUTBGT1RpQlVUVU5JSUZSRlUxUWdRMEdDQVFFd0RnWURWUjBQCiBBUUgvQkFRREFnZUFNQzRHQTFVZEh3UW5NQ1V3STZBaG9CK0dIV2gwZEhBNkx5OWpjbXd1YVdOaGJtNHViM0puCiBMM1J0WTJndVkzSnNNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUIycVN5N3VpKzQzY2ViS1VLd1dQcnp6OXkvCiBJa3JNZUpHS2pvNDBuKzl1ZWthdzNESjVFcWlPZi9xWjRwakJEKytvUjZCSkNiNk5RdVFLd25vQXo1bEU0U3N1CiB5NStpOTNvVDNIZnlWYzRnTk1Jb0htMVBTMTlsN0RCS3Jid2J6QWVhLzBqS1dWenJ2bVY3VEJmanhEM0FRbzFSCiBiVTVkQnI2SWpiZExGbG5PNXgwRzBtckc3eDVPVVB1dXJpaHlpVVJwRkRwd0g4S0FIMXdNY0NwWEdYRlJ0R0trCiB3eWRneVZZQXR5N290a2wvejNiWmtDVlQzNGdQdkY3MHNSNitReFV5OHUwTHpGNUEvYmVZYVpweFNZRzMxYW1MCiBBZFhpdFRXRmlwYUlHZWE5bEVHRk0wTDkrQmc3WHpObjRuVkxYb2t5RUIzYmdTNHNjRzZRem5YMjNGR2sKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8L1g1MDlDZXJ0aWZpY2F0ZT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIDwvWDUwOURhdGE+CiAgICAgICAgICAgICAgICAgICAgICAgIDwvS2V5SW5mbz4KICAgICAgICAgICAgICAgICAgICA8L1NpZ25hdHVyZT4KICAgICAgICAgICAgICAgIDwvc21kOnNpZ25lZE1hcms+Cg==','mark_info_enc get_info(encodedSignedMark) base64');


# create TM
$R2=$E1 .'<response>'  . r() .  '<resData><creData><id>0000061234-1</id><crDate>2012-10-01T22:00:00Z</crDate></creData></resData>'.$TRID .'</response>'.$E2;

$cs = $dri->local_object('contactset');
$holder = $dri->local_object('contact');
$holder->org('Example Inc.');
$holder->street(['123 Example Dr.','Suite 100']);
$holder->city('Reston');
$holder->sp('VA');
$holder->pc('20190');
$holder->cc('US');
$cs->add($holder,'holder_owner');

# NOTE: Labels here are added to the TMCH command and built in the tmch namespace, NOT the mark namespase. This is correct for Deloitte but may be incorrect for others in future ?
$l1 = { a_label => 'exampleone', smd_inclusion => 1, claims_notify => 1 };
$l2 = { a_label => 'exampl-eone', smd_inclusion => 0, claims_notify => 1 };
@labels = ($l1,$l2);

$d1 = { doc_type => 'tmOther', file_type => 'jpg', file_name => 'C:\\ddafs\\file.png', file_content => 'YnJvbAo='};
@docs = ($d1);

$d = DateTime::Duration->new(years=>5);

# Create Court Mark
$mark = { id => '0000061234-1', type => 'court', mark_name => 'Example One', court_name => 'P.R. supreme court', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', cc => 'US', reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) };
$mark->{contact} = $cs;

$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><court><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00Z</proDate><cc>US</cc><courtName>P.R. supreme court</courtName></court></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\ddafs\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>exampl-eone</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build');

# Create Statute
$mark = { id => '0000061234-1', type => 'statue_treaty', mark_name => 'Example One', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', protection => [ {cc => 'US'},{cc=>'UK'} ],  reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) ,execution_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9),title=>'My Mark Title'};
$mark->{contact} = $cs;

$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><treatyOrStatute><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><protection><cc>US</cc></protection><protection><cc>UK</cc></protection><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00Z</proDate><title>My Mark Title</title><execDate>2009-08-16T09:00:00Z</execDate></treatyOrStatute></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\ddafs\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>exampl-eone</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build');


# Create TradeMark
$mark = { id => '0000061234-1', type => 'trademark', mark_name => 'Example One', class=> [35,36], goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.',jurisdiction => 'US', registration_number => 'VD 234 235', registration_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9),expiration_date => DateTime->new(year =>2015,month=>8,day=>16,hour=>9) };
$holder2 = $holder->clone()->name('John Smith')->voice('+44.12341234')->fax('+44.123452234');
$agent = $holder->clone()->name('Agent Smith')->voice('+44.12341234')->email('test@web.site');
$tparty = $holder->clone()->name('Morpheus')->org('Nebuchadnezzar')->voice('+44.12341234')->email('test@web.site');
$cs->add($holder2,'holder_assignee');
$cs->add($agent,'contact_agent');
$cs->add($tparty,'contact_thirdparty');
$mark->{contact} = $cs;

$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><holder entitlement="assignee"><name>John Smith</name><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr><voice>+44.12341234</voice><fax>+44.123452234</fax></holder><contact type="agent"><name>Agent Smith</name><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr><voice>+44.12341234</voice><email>test@web.site</email></contact><contact type="thirdparty"><name>Morpheus</name><org>Nebuchadnezzar</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr><voice>+44.12341234</voice><email>test@web.site</email></contact><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><regNum>VD 234 235</regNum><regDate>2009-08-16T09:00:00Z</regDate><exDate>2015-08-16T09:00:00Z</exDate></trademark></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\ddafs\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>exampl-eone</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build');
is($rc->is_success(), 1, 'mark_create is_success');
is($dri->get_info('action'),'create','mark_create get_info(action)');
is($dri->get_info('crDate'),'2012-10-01T22:00:00','mark_create get_info(crDate)');

# update
$R2=$E1 .'<response>'  . r() .  ''.$TRID .'</response>'.$E2;
$chg = $dri->local_object('changes');
$mark->{'goods_services'} = 'more good and services';
$cs = $dri->local_object('contactset');
$cs->add($holder,'holder_owner');
$mark->{'contact'} = $cs;
$chg->set('mark',$mark);
my @addlabels = ({a_label=>'m-y-label',  smd_inclusion => 0, claims_notify => 0}, {a_label=>'m-y-l-a-b-e-l',  smd_inclusion => 0, claims_notify => 1});
$chg->add('labels',\@addlabels);
my @remlabels = ( {a_label=>'my-label', smd_inclusion => 0, claims_notify => 0});
my @adddocs = ( { doc_type => 'tmOther', file_type => 'pdf', file_name => 'test.pdf', file_contect => 'acdsdc' } );
$chg->add('documents',\@adddocs);
$rc = $dri->mark_update($mark->{'id'},$chg);
is($R1,$E1.'<command><update><id>0000061234-1</id><add><document><docType>tmOther</docType><fileName>test.pdf</fileName><fileType>pdf</fileType></document><label><aLabel>m-y-label</aLabel><smdInclusion enable="0"/><claimsNotify enable="0"/></label><label><aLabel>m-y-l-a-b-e-l</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></add><chg><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>more good and services</goodsAndServices><regNum>VD 234 235</regNum><regDate>2009-08-16T09:00:00Z</regDate><exDate>2015-08-16T09:00:00Z</exDate></trademark></mark></chg></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update build');
is($rc->is_success(), 1, 'mark_update is_success');


# renew - NOT YET IMPLEMENTED BY THE SERVER SO THIS IS THEORITICAL
$R2=$E1 .'<response>'  . r() .  '<resData><renData><id>00000712423-1</id><exDate>2013-10-01T22:00:00Z</exDate></renData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_renew('00000712423-1',{duration=>DateTime::Duration->new(years=>1),  current_expiration => DateTime->new(year=>2012,month=>10,day=>1)});
is($R1,$E1.'<command><renew><id>00000712423-1</id><curExpDate>2012-10-01</curExpDate><period unit="y">1</period></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_renew build');
is($rc->is_success(), 1, 'mark_renew is_success');
is($dri->get_info('action'),'renew','mark_renew get_info(action)');
is($dri->get_info('exDate'),'2013-10-01T22:00:00','mark_renew get_info(exDate)');


####################################################################################################
## Poll Commands - See Protocol/TMCH/Core/RegistryMessage.pm for codes etc

# Mark renewal - # I think this will change
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="1"><qDate>2013-01-21T12:01:01.999Z</qDate><msg>Mark mark renewal approved.</msg></msgQ><resData><renData><id>00000712423-1</id><markName>My Mark</markName><exDate>2016-01-21T12:00:00.000Z</exDate></renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_retrive build');
is($dri->get_info('last_id'),1,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),1,'message get_info last_id 2');
is($dri->get_info('action','message',1),'renewed','message get_info [renewed] action');
is($dri->get_info('content','message',1),'Mark mark renewal approved.','message get_info content');
is($dri->get_info('object_id','message',1),'00000712423-1','message get_info object_id');
is($dri->get_info('exDate','message',1),'2016-01-21T12:00:00','message get_info exDate');

# Watermark
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="2"><qDate>2013-01-21T12:01:01.999Z</qDate><msg>Watermark of USD 2500 passed</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),2,'message get_info [watermark] last_id');
is($dri->get_info('content','message',2),'Watermark of USD 2500 passed','message get_info [watermark] content');

# Verified
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="3"><qDate>2013-06-14 15:24:08</qDate><msg>123 Mark has been verified and approved</msg></msgQ><resData><renData><id>00123000011906-1</id><markName>MYMARKE</markName><exDate>2014-06-10 00:00:00</exDate></renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),3,'message get_info [verified] last_id');
is($dri->get_info('action','message',3),'verified','message get_info [verified] action');
is($dri->get_info('action_code','message',3),123,'message get_info [verified] action');
is($dri->get_info('action_text','message',3),'Mark has been verified and approved','message get_info [verified] action');
is($dri->get_info('status','message',3),'verified','message get_info [verified] status');
is($dri->get_info('object_id','message',3),'00123000011906-1','message get_info [verified] object_id');
is($dri->get_info('mark_name','message',3),'MYMARKE','message get_info [verified] mark_name');

exit 0;
