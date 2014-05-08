#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use MIME::Base64;
use DateTime;
use DateTime::Duration;

use Test::More tests => 218;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:tmch-1.1 tmch-1.1">';
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
my ($pouS,$s,$d,$smark,$mark,$mark2,$cs,$holder,$holder2,$holder3,$agent,$tparty,$l1,$l2,$l3,$l4,$l5,$d1,$c1,$c2,$cm1,$chg,@docs,@labels,@comments,@cases);

####################################################################################################
## Session commands

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.1"><greeting><svID>TMCH server v1.1</svID><svDate>2013-01-15T12:01:02Z</svDate></greeting></tmch>';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');
is_deeply($rc->get_data('session','server','version'),['1.1'],'session noop get_data(session,server,version)');

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>Eadsfsdk-010132</clTRID><svTRID>TMCH-000000001</svTRID></trID></response></tmch>';
$rc=$dri->process('session','login',['ClientX','foo-BAR2']);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

$R2='<?xml version="1.0" encoding="utf-8"?><tmch xmlns="urn:ietf:params:xml:ns:tmch-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><svTRID>TMCH-000000001</svTRID></trID></response></tmch>';
$rc=$dri->process('session','logout');
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
## Mark Check Commands

# check not avail
$R2=$E1 .'<response>'  . r() .  '<resData><chkData><cd><id avail="0">000712423-2</id><reason>Format: 000001XXXXXXXXXX-1</reason></cd></chkData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_check('000712423-2');
is($R1,$E1.'<command><check><id>000712423-2</id></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_check build');
is($rc->is_success(), 1, 'mark_check is_success');
is($dri->get_info('action'),'check','mark_check get_info(action)');
is($dri->get_info('exist'),1,'mark_check get_info(exist)');
is($dri->get_info('exist_reason'),'Format: 000001XXXXXXXXXX-1','mark_check reason');

# check avail
$R2=$E1 .'<response>'  . r() .  '<resData><chkData><cd><id avail="1">000001436269876872643629798257-1</id></cd></chkData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_check('000001436269876872643629798257-1');
is($R1,$E1.'<command><check><id>000001436269876872643629798257-1</id></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_check build');
is($rc->is_success(), 1, 'mark_check is_success');
is($dri->get_info('action'),'check','mark_check get_info(action)');
is($dri->get_info('exist'),0,'mark_check get_info(exist)');

# check multi
$R2=$E1.'<response>'.r().'<msgQ count="76" id="17" /><resData><chkData><cd><id avail="0">000712423-2</id><reason>Format: 000001XXXXXXXXXX-1</reason></cd><cd><id avail="1">000001436269876872643629798257-1</id></cd><cd><id avail="0">00000113637780801363778080-1</id><reason>Already exists</reason></cd></chkData></resData><trID><svTRID>check-1391087493</svTRID></trID></response>'.$E2;
$rc=$dri->mark_check(["000712423-2", "000001436269876872643629798257-1", "00000113637780801363778080-1"]);
is($R1,$E1.'<command><check><id>000712423-2</id><id>000001436269876872643629798257-1</id><id>00000113637780801363778080-1</id></check><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_check build multiple ids');
is($rc->is_success(),1,'mark_check multi is_success');
is($dri->get_info('action','mark','000712423-2'),'check','mark_check multi get_info(action,id1)');
is($dri->get_info('exist','mark','000712423-2'),1,'mark_check multi get_info(exist,id1)');
is($dri->get_info('exist_reason','mark','000712423-2'),'Format: 000001XXXXXXXXXX-1','mark_check multi get_info(exist_reason,id1)');
is($dri->get_info('action','mark','000001436269876872643629798257-1'),'check','mark_check multi get_info(action,id2)');
is($dri->get_info('exist','mark','000001436269876872643629798257-1'),0,'mark_check multi get_info(exist,id2)');
is($dri->get_info('action','mark','00000113637780801363778080-1'),'check','mark_check multi get_info(action,id3)');
is($dri->get_info('exist','mark','00000113637780801363778080-1'),1,'mark_check multi get_info(exist,id3)');
is($dri->get_info('exist_reason','mark','00000113637780801363778080-1'),'Already exists','mark_check multi get_info(exist_reason,id3)');

####################################################################################################
## Mark Info Commands

# info default (trademark)
#$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000712423-1</id><status s="new"/><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodifeaturing infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T09:00:00.0Z</regDate><exDate>2015-08-16T09:00:00.0Z</exDate></trademark></mark><document><id>14531423SADF</id><docType>Other</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType></document><label><aLabel>my-name</aLabel><uLabel>my-name</uLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>myname</aLabel><uLabel>myname</uLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label><crDate>2013-02-10T22:00:00Z</crDate><upDate>2013-03-11T08:01:38Z</upDate><exDate>2018-03-11T08:01:38Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>000001136757513215-1</id><status s="verified" /><pouStatus s="valid" /><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>000001136757513215-1</id><markName>Example 3</markName><holder entitlement="owner"><name>Example name</name><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>LY</cc></addr><email>test@test.test</email></holder><jurisdiction>LY</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T00:00:00Z</regDate><exDate>2015-08-16T00:00:00Z</exDate></trademark></mark><document><id>14531423SADF</id><docType>Other</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType><status s="valid" /></document><label><aLabel>example-one</aLabel><uLabel>example-one</uLabel><smdInclusion enable="0" /><claimsNotify enable="0" /></label><case><id>case-165955219104862426891240536623</id><udrp><caseNo>123</caseNo><udrpProvider>Asian Domain Name Dispute Resolution Centre</udrpProvider><caseLang>Afrikaans</caseLang></udrp><status s="new" /><label><aLabel>label5</aLabel><status s="new" /></label><label><aLabel>label3</aLabel><status s="new" /></label><label><aLabel>label2</aLabel><status s="new" /></label><label><aLabel>label1</aLabel><status s="new" /></label><label><aLabel>label4</aLabel><status s="new" /></label><upDate>2013-10-09T10:20:45.2Z</upDate></case><case><id>case-176169232111416328571942201148</id><udrp><caseNo>456</caseNo><udrpProvider>Asian Domain Name Dispute Resolution Centre</udrpProvider><caseLang>Afrikaans</caseLang></udrp><status s="new" /><label><aLabel>second1</aLabel><status s="new" /></label><upDate>2013-10-09T10:21:35.0Z</upDate></case><comment>comment 1</comment><comment>comment 2</comment><crDate>2013-05-03T11:58:53.3Z</crDate><upDate>2013-12-18T10:45:53.3Z</upDate><exDate>2014-05-03T00:00:00Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('000001136757513215-1');
is($R1,$E1.'<command><info><id>000001136757513215-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$s = $dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(status)');
is_deeply([$s->list_status()],['verified'],'mark_info get_info(status) is verified');
$pouS = $dri->get_info('pou_status');
isa_ok($pouS,'Net::DRI::Data::StatusList','mark_info get_info(pou_status)');
is_deeply([$pouS->list_status()],['valid'],'mark_info get_info(pou_status) is valid');
$mark = $dri->get_info('mark');
is($mark->{'type'},'trademark','mark_info get_info(mark) type');
is($mark->{'mark_name'},'Example 3','mark_info get_info(mark) mark_name');
is($mark->{'jurisdiction'},'LY','mark_info get_info(mark) jurisdiction');
is_deeply($mark->{'class'},[35,36],'mark_info get_info(mark) class');
is($mark->{'goods_services'},'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.','mark_info get_info(mark) goods_services');
is($mark->{'registration_number'},'234235','mark_info get_info(mark) registration_number');
is($mark->{'registration_date'},'2009-08-16T00:00:00','mark_info get_info(mark) registration_number');
$cs = $mark->{'contact'};
isa_ok($cs,'Net::DRI::Data::ContactSet','mark_info get_info(cs)');
$holder = $cs->get('holder_owner');
is($holder->org(),'Example Inc.','mark_info get_info(holder)');
isa_ok($holder,'Net::DRI::Data::Contact','mark_info get_info(holder)');
is($holder->org(),'Example Inc.','mark_info get_info(holder) org');
is($holder->email(),'test@test.test','mark_info get_info(holder) email');
@labels = @{$dri->get_info('labels')};
$l1 = $labels[0];
isa_ok($l1,'HASH','mark_info get_info(label)');
is($l1->{a_label},'example-one','mark_info get_info(label) alabel');
@cases = @{$dri->get_info('cases')};
$c1 = $cases[0];
is($c1->{id},'case-165955219104862426891240536623','mark_info get_info(case) id');
is($c1->{updated_date},'2013-10-09T10:20:45','mark_info get_info(case) updated_date');
is($c1->{udrp}->{case_number},'123','mark_info get_info(case) udrp case_number');
@labels = @{$c1->{labels}};
$l1 = $labels[0];
is($l1->{a_label},'label5','mark_info get_info(case) alabel');
@docs = @{$dri->get_info('documents')};
$d1 = $docs[0];
isa_ok($d1,'HASH','mark_info get_info(document)');
is($d1->{file_type},'jpg','mark_info get_info(document) pdf');
isa_ok($d1->{status},'Net::DRI::Data::StatusList','mark_info get_info(document) status');
is_deeply([$d1->{status}->list_status()],['valid'],'mark_info get_info(document) status is valid');
@comments = @{$dri->get_info('comments')};
is_deeply(\@comments,['comment 1','comment 2'],'mark_info get_info(comments)');

# info default (court)
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00071234-992</id><status s="new" /><pouStatus s="notSet" /><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><court><id>00071234-992</id><markName>My name</markName><holder entitlement="assignee"><name>Mr. Rep</name><org>Owner INC</org><addr><street>Jacobs Street</street><city>Bruges</city><sp>VA</sp><pc>8100</pc><cc>BE</cc></addr><voice x="1234">+1.32235523</voice><fax>+1.32235523</fax></holder><goodsAndServices>BX-1421312-IRUNF-134</goodsAndServices><refNum>12345678</refNum><proDate>2009-08-16T00:00:00Z</proDate><cc>BE</cc><courtName>Court of Brussels</courtName></court></mark><label><aLabel>my-name</aLabel><uLabel>my-name</uLabel><smdInclusion enable="0" /><claimsNotify enable="0" /></label><label><aLabel>myname</aLabel><uLabel>myname</uLabel><smdInclusion enable="0" /><claimsNotify enable="0" /></label><crDate>2013-03-22T10:42:06.0Z</crDate><upDate>2013-03-19T00:32:45.9Z</upDate><exDate>2013-03-19T00:32:45.9Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('00071234-992');
is($R1,$E1.'<command><info><id>00071234-992</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$s = $dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(status)');
is_deeply([$s->list_status()],['new'],'mark_info get_info(status) is new');
$mark = $dri->get_info('mark');
is($mark->{'type'},'court','mark_info get_info(mark) type');
is($mark->{'court_name'},'Court of Brussels','mark_info get_info(mark) court_name');
$cs = $mark->{'contact'};
isa_ok($cs,'Net::DRI::Data::ContactSet','mark_info get_info(cs)');
$holder = $cs->get('holder_assignee');
is($holder->org(),'Owner INC','mark_info get_info(holder)');

# info default (statueOrTreaty)
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000113678687551367868755-1</id><status s="new" /><pouStatus s="na" /><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><treatyOrStatute><id>00000113678687551367868755-1</id><markName>treaty</markName><holder entitlement="owner"><name>jan jansen</name><org>CHIP</org><addr><street>dvv 37</street><city>Leuven</city><sp /><pc>3000</pc><cc>BE</cc></addr><voice>+1.123</voice><fax>+2.457</fax><email>jan@j.abc</email></holder><protection><cc>US</cc><ruling>AF</ruling><ruling>AX</ruling><ruling>AL</ruling></protection><goodsAndServices>n.a.</goodsAndServices><refNum>n.a.</refNum><proDate>2000-01-01T00:00:00Z</proDate><title>n.a.</title><execDate>2000-01-01T00:00:00Z</execDate></treatyOrStatute></mark><label><aLabel>treaty</aLabel><uLabel>treaty</uLabel><smdInclusion enable="1" /><claimsNotify enable="1" /></label><crDate>2013-05-06T21:32:35.6Z</crDate><upDate>2013-05-06T21:32:35.6Z</upDate><exDate>2014-05-06T19:32:35Z</exDate></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info('00000113678687551367868755-1');
is($R1,$E1.'<command><info><id>00000113678687551367868755-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info build');
is($rc->is_success(), 1, 'mark_info is_success');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$mark = $dri->get_info('mark');
is($mark->{'type'},'treaty_statute','mark_info get_info(mark) type');
is($mark->{'mark_name'},'treaty','mark_info get_info(mark) mark_name');
is($mark->{'title'},'n.a.','mark_info get_info(mark) title');
my $p1 = shift @{$mark->{'protection'}};
is_deeply($p1,{'cc'=>'US','ruling'=>['AF','AX','AL']},'mark_info get_info(mark) protection' );

# info smd
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>0000005071387359953364-1</id><smdId>123-1</smdId><status s="verified" /><smd:signedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0" id="_7f3b6f8c-5cf1-4f6b-9187-21dd7d53c968"><smd:id>0000005071387359953364-1</smd:id><smd:issuerInfo issuerID="1"><smd:org>Deloitte</smd:org><smd:email>smd-support@deloitte.com</smd:email><smd:url>smd-support.deloitte.com</smd:url><smd:voice>+32.20000000</smd:voice></smd:issuerInfo><smd:notBefore>2013-12-18T09:45:53.364Z</smd:notBefore><smd:notAfter>2014-05-02T22:00:00.000Z</smd:notAfter><mark:mark xmlns:mark="urn:ietf:params:xml:ns:mark-1.0"><mark:trademark><mark:id>000001136757513215-1</mark:id><mark:markName>Example 3</mark:markName><mark:holder entitlement="owner"><mark:org>Example Inc.</mark:org><mark:addr><mark:street>123 Example Dr.</mark:street><mark:street>Suite 100</mark:street><mark:city>Reston</mark:city><mark:sp>VA</mark:sp><mark:pc>20190</mark:pc><mark:cc>LY</mark:cc></mark:addr></mark:holder><mark:contact type="agent"><mark:name>jan jansen</mark:name><mark:org>CHIP</mark:org><mark:addr><mark:street>dvv 37</mark:street><mark:city>Leuven</mark:city><mark:pc>3000</mark:pc><mark:cc>BE</mark:cc></mark:addr><mark:voice>+1.123</mark:voice><mark:fax>+2.457</mark:fax><mark:email>jan@ipclearinghouse.org</mark:email></mark:contact><mark:jurisdiction>LY</mark:jurisdiction><mark:class>35</mark:class><mark:class>36</mark:class><mark:goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</mark:goodsAndServices><mark:regNum>234235</mark:regNum><mark:regDate>2009-08-15T22:00:00.000Z</mark:regDate><mark:exDate>2015-08-15T22:00:00.000Z</mark:exDate></mark:trademark></mark:mark><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="_32534634-384e-40b3-9c48-812c5a92f0ee"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" /><ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" /><ds:Reference URI="#_7f3b6f8c-5cf1-4f6b-9187-21dd7d53c968"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" /><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" /></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" /><ds:DigestValue>UOUfso/KI5u9WEVqfX/jTKcEoeuUWioT4O9neFsqmZg=</ds:DigestValue></ds:Reference><ds:Reference URI="#_ebda5fd0-14e2-40fb-b973-06328b34fc74"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" /></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" /><ds:DigestValue>kedEuC5ruC2DeF9GFPQ3crkV+lW0IQCmCk7uX8uM13g=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue Id="_c3d3ad97-f335-4694-b70b-7ac578eeb816">gvN4wbzEXfJ0FvdUJ54JTdF4NKuRfuXs0BYj0DIKNMnaXD0KAFDnEb1nMFfC7mU+lugjofeuHYz/AglrVMgKCatiiGIM7GHLIaz6CfBWvQbRFAg23xJ/tOoEcmtmg8QwOLVmtwnfG2AhLfDJWCnV8PqJbGmxlt7k9jlhpPGlMYY=</ds:SignatureValue><ds:KeyInfo Id="_ebda5fd0-14e2-40fb-b973-06328b34fc74"><ds:X509Data><ds:X509Certificate>MIIFQDCCBKmgAwIBAgIEQDf7czANBgkqhkiG9w0BAQUFADA/MQsw-CQYDVQQGEwJESzEMMAoGA1UEChMDVERDMSIwIAYDVQQDExlUREMgT0NFUyBTeXN0ZW10ZXN0IENBIElJMB4XDTExMTEwMTEyMjAzM1oXDTEzMTEwMTEyNTAzM1owgYUxCzAJBgNVBAYTAkRLMSkwJwYDVQQKEyBJbmdlbiBvcmdhbmlzYXRvcmlzayB0aWxrbnl0bmluZzFLMCMGA1UEBRMcUElEOjkyMDgtMjAwMi0yLTczNTA4OTg1Nzk4MjAkBgNVBAMTHVRlc3RwZXJzb24gMjgwMjc1MTc3MiBUZXN0c2VuMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCSx/24Ymnp6hOLnEKstqKbkzKbxWAtsp6McocgCCWkIX82QGJ5N6Fqi8Ti20D0DNxjlW0RfQU/Ot25mEmVXrXpcUcQEsidHs1nFx7Bz2EEFL0gs8JzDiNQ9fpTUU/dOLZzb/qr1EcTaGtJyaRZjJOGl7jO/K83oZqptu/0DgLzuQIDAQABo4IDADCCAvwwDgYDVR0PAQH/BAQDAgP4MCsGA1UdEAQkMCKADzIwMTExMTAxMTIyMDMzWoEPMjAxMzExMDExMjUwMzNaMEYGCCsGAQUFBwEBBDowODA2BggrBgEFBQcwAYYqaHR0cDovL3Rlc3Qub2NzcC5jZXJ0aWZpa2F0LmRrL29jc3Avc3RhdHVzMIIBNwYDVR0gBIIBLjCCASowggEmBgoqgVCBKQEBAQECMIIBFjAvBggrBgEFBQcCARYjaHR0cDovL3d3dy5jZXJ0aWZpa2F0LmRrL3JlcG9zaXRvcnkwgeIGCCsGAQUFBwICMIHVMAoWA1REQzADAgEBGoHGRm9yIGFudmVuZGVsc2UgYWYgY2VydGlmaWthdGV0IGfmbGRlciBPQ0VTIHZpbGvlciwgQ1BTIG9nIE9DRVMgQ1AsIGRlciBrYW4gaGVudGVzIGZyYSB3d3cuY2VydGlmaWthdC5kay9yZXBvc2l0b3J5LiBCZW3mcmssIGF0IFREQyBlZnRlciB2aWxr5XJlbmUgaGFyIGV0IGJlZ3LmbnNldCBhbnN2YXIgaWZ0LiBwcm9mZXNzaW9uZWxsZSBwYXJ0ZXIuMBgGCWCGSAGG+EIBDQQLFglQZXJzb25XZWIwIAYDVR0RBBkwF4EVc3VwcG9ydEBjZXJ0aWZpa2F0LmRrMIGXBgNVHR8EgY8wgYwwV6BVoFOkUTBPMQswCQYDVQQGEwJESzEMMAoGA1UEChMDVERDMSIwIAYDVQQDExlUREMgT0NFUyBTeXN0ZW10ZXN0IENBIElJMQ4wDAYDVQQDEwVDUkwyOTAxoC+gLYYraHR0cDovL3Rlc3QuY3JsLm9jZXMuY2VydGlmaWthdC5kay9vY2VzLmNybDAfBgNVHSMEGDAWgBQcmAlHGkw4uRDFBClb8fROgGrMfjAdBgNVHQ4EFgQUR4fjxTv2jdk9Ztak8CBikXRbWjwwCQYDVR0TBAIwADAZBgkqhkiG9n0HQQAEDDAKGwRWNy4xAwIDqDANBgkqhkiG9w0BAQUFAAOBgQBUvfdxcBIo8vsxGvtF22WkiWFskcWjlUhKbGIyjcppfWqSnZ5iDy5T9iIGY/huT/7SgnJbjnpN6EEa6UqXUbUzdth5OP7qBQkvKnOkIyuGjftcqV8Xja4GwZos6F6NzqAXCReC2kwuuN44zrjz3fj7dA26QGpimCJWzv5zRyW3Ng==</ds:X509Certificate><ds:X509Certificate>MIIEXTCCA8agAwIBAgIEQDYX/DANBgkqhkiG9w0BAQUFADA/MQswCQYDVQQGEwJESzEMMAoGA1UEChMDVERDMSIwIAYDVQQDExlUREMgT0NFUyBTeXN0ZW10ZXN0IENBIElJMB4XDTA0MDIyMDEzNTE0OVoXDTM3MDYyMDE0MjE0OVowPzELMAkGA1UEBhMCREsxDDAKBgNVBAoTA1REQzEiMCAGA1UEAxMZVERDIE9DRVMgU3lzdGVtdGVzdCBDQSBJSTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEArawANI56sljDsnosDU+Mp4r+RKFys9c5qy8jWZyA+7PYFs4+IZcFxnbNuHi8aAcbSFOUJF0PGpNgPEtNc+XAK7p16iawNTYpMkHm2VoInNfwWEj/wGmtb4rKDT2a7auGk76q+Xdqnno4PRO8e7AKEHw7pN3kiHmZCI48PTRpRx8CAwEAAaOCAmQwggJgMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMIIBAwYDVR0gBIH7MIH4MIH1BgkpAQEBAQEBAQEwgecwLwYIKwYBBQUHAgEWI2h0dHA6Ly93d3cuY2VydGlmaWthdC5kay9yZXBvc2l0b3J5MIGzBggrBgEFBQcCAjCBpjAKFgNUREMwAwIBARqBl1REQyBUZXN0IENlcnRpZmlrYXRlciBmcmEgZGVubmUgQ0EgdWRzdGVkZXMgdW5kZXIgT0lEIDEuMS4xLjEuMS4xLjEuMS4xLjEuIFREQyBUZXN0IENlcnRpZmljYXRlcyBmcm9tIHRoaXMgQ0EgYXJlIGlzc3VlZCB1bmRlciBPSUQgMS4xLjEuMS4xLjEuMS4xLjEuMS4wEQYJYIZIAYb4QgEBBAQDAgAHMIGWBgNVHR8EgY4wgYswVqBUoFKkUDBOMQswCQYDVQQGEwJESzEMMAoGA1UEChMDVERDMSIwIAYDVQQDExlUREMgT0NFUyBTeXN0ZW10ZXN0IENBIElJMQ0wCwYDVQQDEwRDUkwxMDGgL6AthitodHRwOi8vdGVzdC5jcmwub2Nlcy5jZXJ0aWZpa2F0LmRrL29jZXMuY3JsMCsGA1UdEAQkMCKADzIwMDQwMjIwMTM1MTQ5WoEPMjAzNzA2MjAxNDIxNDlaMB8GA1UdIwQYMBaAFByYCUcaTDi5EMUEKVvx9E6Aasx+MB0GA1UdDgQWBBQcmAlHGkw4uRDFBClb8fROgGrMfjAdBgkqhkiG9n0HQQAEEDAOGwhWNi4wOjQuMAMCBJAwDQYJKoZIhvcNAQEFBQADgYEApyoAjiKq6WK5XaKWUpVskutzohv1VcCke/3JeUVtmB+byexJMC171s4RHoqcbufcI2ASVWwu84i45MaKg/nxoqojMyY19/W2wbQFEdsxUCnLa9e9tlWj0xS/AaKeUhk2MBOqv+hMdc71jOqc5JN7T2Ba6ZRIY5uXkO3IGZ3XUsw=</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature></smd:signedMark></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info_smd('0000005071387359953364-1');
is($R1,$E1.'<command><info type="smd"><id>0000005071387359953364-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info_smd build');
is($rc->is_success(), 1, 'mark_info_smd is_success');
is($dri->get_info('action'),'info','mark_info_smd get_info(action)');
is($dri->get_info('id'),'0000005071387359953364-1','mark_info_smd get_info(id)');
is($dri->get_info('smd_id'),'123-1','mark_info_smd get_info(smd_id)');
$smark = $dri->get_info('signed_mark');
isa_ok($smark->{'mark'}->{'contact'},'Net::DRI::Data::ContactSet','mark_info_smd get_info(contact)');
is($smark->{'id'},'0000005071387359953364-1','mark_info_smd get_info(signedMark) signed_mark_id');
is($smark->{'mark'}->{'id'},'000001136757513215-1','mark_info_smd get_info(signedMark) mark_id');
is($smark->{'creation_date'},'2013-12-18T09:45:53','mark_info_smd get_info(signedMark) creation_date');
my $ii = $smark->{'issuer'};
is($ii->{id},'1','mark_info_smd get_info(signed_mark) issuer id');
my $sig = $smark->{'signature'};
is($sig->{value},'gvN4wbzEXfJ0FvdUJ54JTdF4NKuRfuXs0BYj0DIKNMnaXD0KAFDnEb1nMFfC7mU+lugjofeuHYz/AglrVMgKCatiiGIM7GHLIaz6CfBWvQbRFAg23xJ/tOoEcmtmg8QwOLVmtwnfG2AhLfDJWCnV8PqJbGmxlt7k9jlhpPGlMYY=','mark_info_smd get_info(signedMark) Signature value');

# info enc
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>0000004361387359953082-1</id><status s="verified" /><smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il8yYTRjMDY3ZC0wYzRkLTQ5OGMtOWE2MC0zN2M5NjEyNTQxZDMiPjxzbWQ6aWQ+MDAwMDAwNDM2MTM4NzM1OTk1MzA4Mi0xPC9zbWQ6aWQ+PHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSIxIj48c21kOm9yZz5EZWxvaXR0ZTwvc21kOm9yZz48c21kOmVtYWlsPnNtZC1zdXBwb3J0QGRlbG9pdHRlLmNvbTwvc21kOmVtYWlsPjxzbWQ6dXJsPnNtZC1zdXBwb3J0LmRlbG9pdHRlLmNvbTwvc21kOnVybD48c21kOnZvaWNlPiszMi4yMDAwMDAwMDwvc21kOnZvaWNlPjwvc21kOmlzc3VlckluZm8+PHNtZDpub3RCZWZvcmU+MjAxMy0xMi0xOFQwOTo0NTo1My4wODJaPC9zbWQ6bm90QmVmb3JlPjxzbWQ6bm90QWZ0ZXI+MjAxNC0wNS0wMlQyMjowMDowMC4wMDBaPC9zbWQ6bm90QWZ0ZXI+PG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJhbXM6eG1sOm5zOm1hcmstMS4wIj48bWFyazp0cmFkZW1hcms+PG1hcms6aWQ+MDAwMDAxMTM2NzU3NTA2NzQtMTwvbWFyazppZD48bWFyazptYXJrTmFtZT5FeGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT48bWFyazpob2xkZXIgZW50aXRsZW1lbnQ9Im93bmVyIj48bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9tYXJrOm9yZz48bWFyazphZGRyPjxtYXJrOnN0cmVldD4xMjMgRXhhbXBsZSBEci48L21hcms6c3RyZWV0PjxtYXJrOnN0cmVldD5TdWl0ZSAxMDA8L21hcms6c3RyZWV0PjxtYXJrOmNpdHk+UmVzdG9uPC9tYXJrOmNpdHk+PG1hcms6c3A+VkE8L21hcms6c3A+PG1hcms6cGM+MjAxOTA8L21hcms6cGM+PG1hcms6Y2M+Q088L21hcms6Y2M+PC9tYXJrOmFkZHI+PC9tYXJrOmhvbGRlcj48bWFyazpjb250YWN0IHR5cGU9ImFnZW50Ij48bWFyazpuYW1lPmphbiBqYW5zZW48L21hcms6bmFtZT48bWFyazpvcmc+Q0hJUDwvbWFyazpvcmc+PG1hcms6YWRkcj48bWFyazpzdHJlZXQ+ZHZ2IDM3PC9tYXJrOnN0cmVldD48bWFyazpjaXR5PkxldXZlbjwvbWFyazpjaXR5PjxtYXJrOnBjPjMwMDA8L21hcms6cGM+PG1hcms6Y2M+QkU8L21hcms6Y2M+PC9tYXJrOmFkZHI+PG1hcms6dm9pY2U+KzEuMTIzPC9tYXJrOnZvaWNlPjxtYXJrOmZheD4rMi40NTc8L21hcms6ZmF4PjxtYXJrOmVtYWlsPmphbkBpcGNsZWFyaW5naG91c2Uub3JnPC9tYXJrOmVtYWlsPjwvbWFyazpjb250YWN0PjxtYXJrOmp1cmlzZGljdGlvbj5DTzwvbWFyazpqdXJpc2RpY3Rpb24+PG1hcms6Y2xhc3M+MzU8L21hcms6Y2xhc3M+PG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+PG1hcms6Z29vZHNBbmRTZXJ2aWNlcz5EaXJpZ2VuZGFzIGV0IGVpdXNtb2RpIGZlYXR1cmluZyBpbmZyaW5nbyBpbiBhaXJmYXJlIGV0IGNhcnRhbSBzZXJ2aWNpYS4KICAgICAgICAgICAgICAgICAgICA8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz48bWFyazpyZWdOdW0+MjM0MjM1PC9tYXJrOnJlZ051bT48bWFyazpyZWdEYXRlPjIwMDktMDgtMTVUMjI6MDA6MDAuMDAwWjwvbWFyazpyZWdEYXRlPjxtYXJrOmV4RGF0ZT4yMDE1LTA4LTE1VDIyOjAwOjAwLjAwMFo8L21hcms6ZXhEYXRlPjwvbWFyazp0cmFkZW1hcms+PC9tYXJrOm1hcms+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il80OTFiMWM0NS02MTkzLTQ1NGItOGM5Mi1mNDAzZjFlMzc0MzAiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI18yYTRjMDY3ZC0wYzRkLTQ5OGMtOWE2MC0zN2M5NjEyNTQxZDMiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPjxkczpEaWdlc3RWYWx1ZT42WDlLUlo5Z205c2VsRjN3VlN2TXM5bGZQQnlUdkEzeUpBemh3ZWg4Z3RzPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U+PGRzOlJlZmVyZW5jZSBVUkk9IiNfZjhjODE4Y2MtZTQwZi00OTI4LWIwMDctNzdiZjI5OGJmMWE4Ij48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+YnB5TDdWMGZCU0JSWEc4RTBydkE0SU9xK3pUdHFxbjJsTEhHUWNzMlVmMD08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il9lODVkZDMxYy1hMDZjLTQ2MDMtYTczOC00MzNmMzUxMTA4NjkiPlY3KzdjWUdTYlA5bCs1NExPbTBiQW1Vd05CL05WNHhiWloya0JKUGRGNTE3aHlqRHkwYnpYZzg4NytKeE1rdTNRcUQyUFBEa3RaMGEKUm5DYjJoUWJqOXB1QndKdVFOTEs1U3doZ3ZVcno3clJXcm5GM2Zpb0UxMVpYY1U5TEp4TGl2SVV0eWcrdkl3UDF1eEFPVy80RjlTdApwR1I1TFgrQ3YzMFBZanpPQ2YwPTwvZHM6U2lnbmF0dXJlVmFsdWU+PGRzOktleUluZm8gSWQ9Il9mOGM4MThjYy1lNDBmLTQ5MjgtYjAwNy03N2JmMjk4YmYxYTgiPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZRRENDQkttZ0F3SUJBZ0lFUURmN2N6QU5CZ2txaGtpRzl3MEJBUVVGQURBL01Rc3dDUVlEVlFRR0V3SkVTekVNTUFvR0ExVUUKQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wSUVOQklFbEpNQjRYRFRFeE1URXdNVEV5TWpBegpNMW9YRFRFek1URXdNVEV5TlRBek0xb3dnWVV4Q3pBSkJnTlZCQVlUQWtSTE1Ta3dKd1lEVlFRS0V5QkpibWRsYmlCdmNtZGhibWx6CllYUnZjbWx6YXlCMGFXeHJibmwwYm1sdVp6RkxNQ01HQTFVRUJSTWNVRWxFT2preU1EZ3RNakF3TWkweUxUY3pOVEE0T1RnMU56azQKTWpBa0JnTlZCQU1USFZSbGMzUndaWEp6YjI0Z01qZ3dNamMxTVRjM01pQlVaWE4wYzJWdU1JR2ZNQTBHQ1NxR1NJYjNEUUVCQVFVQQpBNEdOQURDQmlRS0JnUUNTeC8yNFltbnA2aE9MbkVLc3RxS2JrektieFdBdHNwNk1jb2NnQ0NXa0lYODJRR0o1TjZGcWk4VGkyMEQwCkROeGpsVzBSZlFVL090MjVtRW1WWHJYcGNVY1FFc2lkSHMxbkZ4N0J6MkVFRkwwZ3M4SnpEaU5ROWZwVFVVL2RPTFp6Yi9xcjFFY1QKYUd0SnlhUlpqSk9HbDdqTy9LODNvWnFwdHUvMERnTHp1UUlEQVFBQm80SURBRENDQXZ3d0RnWURWUjBQQVFIL0JBUURBZ1A0TUNzRwpBMVVkRUFRa01DS0FEekl3TVRFeE1UQXhNVEl5TURNeldvRVBNakF4TXpFeE1ERXhNalV3TXpOYU1FWUdDQ3NHQVFVRkJ3RUJCRG93Ck9EQTJCZ2dyQmdFRkJRY3dBWVlxYUhSMGNEb3ZMM1JsYzNRdWIyTnpjQzVqWlhKMGFXWnBhMkYwTG1SckwyOWpjM0F2YzNSaGRIVnoKTUlJQk53WURWUjBnQklJQkxqQ0NBU293Z2dFbUJnb3FnVkNCS1FFQkFRRUNNSUlCRmpBdkJnZ3JCZ0VGQlFjQ0FSWWphSFIwY0RvdgpMM2QzZHk1alpYSjBhV1pwYTJGMExtUnJMM0psY0c5emFYUnZjbmt3Z2VJR0NDc0dBUVVGQndJQ01JSFZNQW9XQTFSRVF6QURBZ0VCCkdvSEdSbTl5SUdGdWRtVnVaR1ZzYzJVZ1lXWWdZMlZ5ZEdsbWFXdGhkR1YwSUdmbWJHUmxjaUJQUTBWVElIWnBiR3ZsY2l3Z1ExQlQKSUc5bklFOURSVk1nUTFBc0lHUmxjaUJyWVc0Z2FHVnVkR1Z6SUdaeVlTQjNkM2N1WTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMApiM0o1TGlCQ1pXM21jbXNzSUdGMElGUkVReUJsWm5SbGNpQjJhV3hyNVhKbGJtVWdhR0Z5SUdWMElHSmxaM0xtYm5ObGRDQmhibk4yCllYSWdhV1owTGlCd2NtOW1aWE56YVc5dVpXeHNaU0J3WVhKMFpYSXVNQmdHQ1dDR1NBR0crRUlCRFFRTEZnbFFaWEp6YjI1WFpXSXcKSUFZRFZSMFJCQmt3RjRFVmMzVndjRzl5ZEVCalpYSjBhV1pwYTJGMExtUnJNSUdYQmdOVkhSOEVnWTh3Z1l3d1Y2QlZvRk9rVVRCUApNUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wCklFTkJJRWxKTVE0d0RBWURWUVFERXdWRFVrd3lPVEF4b0MrZ0xZWXJhSFIwY0RvdkwzUmxjM1F1WTNKc0xtOWpaWE11WTJWeWRHbG0KYVd0aGRDNWtheTl2WTJWekxtTnliREFmQmdOVkhTTUVHREFXZ0JRY21BbEhHa3c0dVJERkJDbGI4ZlJPZ0dyTWZqQWRCZ05WSFE0RQpGZ1FVUjRmanhUdjJqZGs5WnRhazhDQmlrWFJiV2p3d0NRWURWUjBUQkFJd0FEQVpCZ2txaGtpRzluMEhRUUFFRERBS0d3UldOeTR4CkF3SURxREFOQmdrcWhraUc5dzBCQVFVRkFBT0JnUUJVdmZkeGNCSW84dnN4R3Z0RjIyV2tpV0Zza2NXamxVaEtiR0l5amNwcGZXcVMKblo1aUR5NVQ5aUlHWS9odVQvN1Nnbkpiam5wTjZFRWE2VXFYVWJVemR0aDVPUDdxQlFrdktuT2tJeXVHamZ0Y3FWOFhqYTRHd1pvcwo2RjZOenFBWENSZUMya3d1dU40NHpyanozZmo3ZEEyNlFHcGltQ0pXenY1elJ5VzNOZz09PC9kczpYNTA5Q2VydGlmaWNhdGU+PGRzOlg1MDlDZXJ0aWZpY2F0ZT5NSUlFWFRDQ0E4YWdBd0lCQWdJRVFEWVgvREFOQmdrcWhraUc5dzBCQVFVRkFEQS9NUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFCkNoTURWRVJETVNJd0lBWURWUVFERXhsVVJFTWdUME5GVXlCVGVYTjBaVzEwWlhOMElFTkJJRWxKTUI0WERUQTBNREl5TURFek5URTAKT1ZvWERUTTNNRFl5TURFME1qRTBPVm93UHpFTE1Ba0dBMVVFQmhNQ1JFc3hEREFLQmdOVkJBb1RBMVJFUXpFaU1DQUdBMVVFQXhNWgpWRVJESUU5RFJWTWdVM2x6ZEdWdGRHVnpkQ0JEUVNCSlNUQ0JuekFOQmdrcWhraUc5dzBCQVFFRkFBT0JqUUF3Z1lrQ2dZRUFyYXdBCk5JNTZzbGpEc25vc0RVK01wNHIrUktGeXM5YzVxeThqV1p5QSs3UFlGczQrSVpjRnhuYk51SGk4YUFjYlNGT1VKRjBQR3BOZ1BFdE4KYytYQUs3cDE2aWF3TlRZcE1rSG0yVm9Jbk5md1dFai93R210YjRyS0RUMmE3YXVHazc2cStYZHFubm80UFJPOGU3QUtFSHc3cE4zawppSG1aQ0k0OFBUUnBSeDhDQXdFQUFhT0NBbVF3Z2dKZ01BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0RnWURWUjBQQVFIL0JBUURBZ0VHCk1JSUJBd1lEVlIwZ0JJSDdNSUg0TUlIMUJna3BBUUVCQVFFQkFRRXdnZWN3THdZSUt3WUJCUVVIQWdFV0kyaDBkSEE2THk5M2QzY3UKWTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMGIzSjVNSUd6QmdnckJnRUZCUWNDQWpDQnBqQUtGZ05VUkVNd0F3SUJBUnFCbDFSRQpReUJVWlhOMElFTmxjblJwWm1scllYUmxjaUJtY21FZ1pHVnVibVVnUTBFZ2RXUnpkR1ZrWlhNZ2RXNWtaWElnVDBsRUlERXVNUzR4CkxqRXVNUzR4TGpFdU1TNHhMakV1SUZSRVF5QlVaWE4wSUVObGNuUnBabWxqWVhSbGN5Qm1jbTl0SUhSb2FYTWdRMEVnWVhKbElHbHoKYzNWbFpDQjFibVJsY2lCUFNVUWdNUzR4TGpFdU1TNHhMakV1TVM0eExqRXVNUzR3RVFZSllJWklBWWI0UWdFQkJBUURBZ0FITUlHVwpCZ05WSFI4RWdZNHdnWXN3VnFCVW9GS2tVREJPTVFzd0NRWURWUVFHRXdKRVN6RU1NQW9HQTFVRUNoTURWRVJETVNJd0lBWURWUVFECkV4bFVSRU1nVDBORlV5QlRlWE4wWlcxMFpYTjBJRU5CSUVsSk1RMHdDd1lEVlFRREV3UkRVa3d4TURHZ0w2QXRoaXRvZEhSd09pOHYKZEdWemRDNWpjbXd1YjJObGN5NWpaWEowYVdacGEyRjBMbVJyTDI5alpYTXVZM0pzTUNzR0ExVWRFQVFrTUNLQUR6SXdNRFF3TWpJdwpNVE0xTVRRNVdvRVBNakF6TnpBMk1qQXhOREl4TkRsYU1COEdBMVVkSXdRWU1CYUFGQnlZQ1VjYVREaTVFTVVFS1Z2eDlFNkFhc3grCk1CMEdBMVVkRGdRV0JCUWNtQWxIR2t3NHVSREZCQ2xiOGZST2dHck1makFkQmdrcWhraUc5bjBIUVFBRUVEQU9Hd2hXTmk0d09qUXUKTUFNQ0JKQXdEUVlKS29aSWh2Y05BUUVGQlFBRGdZRUFweW9BamlLcTZXSzVYYUtXVXBWc2t1dHpvaHYxVmNDa2UvM0plVVZ0bUIrYgp5ZXhKTUMxNzFzNFJIb3FjYnVmY0kyQVNWV3d1ODRpNDVNYUtnL254b3Fvak15WTE5L1cyd2JRRkVkc3hVQ25MYTllOXRsV2oweFMvCkFhS2VVaGsyTUJPcXYraE1kYzcxak9xYzVKTjdUMkJhNlpSSVk1dVhrTzNJR1ozWFVzdz08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48L3NtZDpzaWduZWRNYXJrPg==</smd:encodedSignedMark></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info_enc('0000004361387359953082-1');
is($R1,$E1.'<command><info type="enc"><id>0000004361387359953082-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info_enc build');
is($rc->is_success(), 1, 'mark_info_enc is_success');
is($dri->get_info('action'),'info','mark_info_enc get_info(action)');
$mark = $dri->get_info('mark');
is($mark->{'mark_name'},'Example One','mark_info_enc get_info(mark) mark_name');
$smark = $dri->get_info('signed_mark');
is($smark->{'mark'}->{'mark_name'},'Example One','mark_info_enc get_info(encoded_signed_mark) mark_name');
my $enc = $dri->get_info('encoded_signed_mark');
is($enc,'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il8yYTRjMDY3ZC0wYzRkLTQ5OGMtOWE2MC0zN2M5NjEyNTQxZDMiPjxzbWQ6aWQ+MDAwMDAwNDM2MTM4NzM1OTk1MzA4Mi0xPC9zbWQ6aWQ+PHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSIxIj48c21kOm9yZz5EZWxvaXR0ZTwvc21kOm9yZz48c21kOmVtYWlsPnNtZC1zdXBwb3J0QGRlbG9pdHRlLmNvbTwvc21kOmVtYWlsPjxzbWQ6dXJsPnNtZC1zdXBwb3J0LmRlbG9pdHRlLmNvbTwvc21kOnVybD48c21kOnZvaWNlPiszMi4yMDAwMDAwMDwvc21kOnZvaWNlPjwvc21kOmlzc3VlckluZm8+PHNtZDpub3RCZWZvcmU+MjAxMy0xMi0xOFQwOTo0NTo1My4wODJaPC9zbWQ6bm90QmVmb3JlPjxzbWQ6bm90QWZ0ZXI+MjAxNC0wNS0wMlQyMjowMDowMC4wMDBaPC9zbWQ6bm90QWZ0ZXI+PG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJhbXM6eG1sOm5zOm1hcmstMS4wIj48bWFyazp0cmFkZW1hcms+PG1hcms6aWQ+MDAwMDAxMTM2NzU3NTA2NzQtMTwvbWFyazppZD48bWFyazptYXJrTmFtZT5FeGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT48bWFyazpob2xkZXIgZW50aXRsZW1lbnQ9Im93bmVyIj48bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9tYXJrOm9yZz48bWFyazphZGRyPjxtYXJrOnN0cmVldD4xMjMgRXhhbXBsZSBEci48L21hcms6c3RyZWV0PjxtYXJrOnN0cmVldD5TdWl0ZSAxMDA8L21hcms6c3RyZWV0PjxtYXJrOmNpdHk+UmVzdG9uPC9tYXJrOmNpdHk+PG1hcms6c3A+VkE8L21hcms6c3A+PG1hcms6cGM+MjAxOTA8L21hcms6cGM+PG1hcms6Y2M+Q088L21hcms6Y2M+PC9tYXJrOmFkZHI+PC9tYXJrOmhvbGRlcj48bWFyazpjb250YWN0IHR5cGU9ImFnZW50Ij48bWFyazpuYW1lPmphbiBqYW5zZW48L21hcms6bmFtZT48bWFyazpvcmc+Q0hJUDwvbWFyazpvcmc+PG1hcms6YWRkcj48bWFyazpzdHJlZXQ+ZHZ2IDM3PC9tYXJrOnN0cmVldD48bWFyazpjaXR5PkxldXZlbjwvbWFyazpjaXR5PjxtYXJrOnBjPjMwMDA8L21hcms6cGM+PG1hcms6Y2M+QkU8L21hcms6Y2M+PC9tYXJrOmFkZHI+PG1hcms6dm9pY2U+KzEuMTIzPC9tYXJrOnZvaWNlPjxtYXJrOmZheD4rMi40NTc8L21hcms6ZmF4PjxtYXJrOmVtYWlsPmphbkBpcGNsZWFyaW5naG91c2Uub3JnPC9tYXJrOmVtYWlsPjwvbWFyazpjb250YWN0PjxtYXJrOmp1cmlzZGljdGlvbj5DTzwvbWFyazpqdXJpc2RpY3Rpb24+PG1hcms6Y2xhc3M+MzU8L21hcms6Y2xhc3M+PG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+PG1hcms6Z29vZHNBbmRTZXJ2aWNlcz5EaXJpZ2VuZGFzIGV0IGVpdXNtb2RpIGZlYXR1cmluZyBpbmZyaW5nbyBpbiBhaXJmYXJlIGV0IGNhcnRhbSBzZXJ2aWNpYS4KICAgICAgICAgICAgICAgICAgICA8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz48bWFyazpyZWdOdW0+MjM0MjM1PC9tYXJrOnJlZ051bT48bWFyazpyZWdEYXRlPjIwMDktMDgtMTVUMjI6MDA6MDAuMDAwWjwvbWFyazpyZWdEYXRlPjxtYXJrOmV4RGF0ZT4yMDE1LTA4LTE1VDIyOjAwOjAwLjAwMFo8L21hcms6ZXhEYXRlPjwvbWFyazp0cmFkZW1hcms+PC9tYXJrOm1hcms+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il80OTFiMWM0NS02MTkzLTQ1NGItOGM5Mi1mNDAzZjFlMzc0MzAiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI18yYTRjMDY3ZC0wYzRkLTQ5OGMtOWE2MC0zN2M5NjEyNTQxZDMiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPjxkczpEaWdlc3RWYWx1ZT42WDlLUlo5Z205c2VsRjN3VlN2TXM5bGZQQnlUdkEzeUpBemh3ZWg4Z3RzPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U+PGRzOlJlZmVyZW5jZSBVUkk9IiNfZjhjODE4Y2MtZTQwZi00OTI4LWIwMDctNzdiZjI5OGJmMWE4Ij48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+YnB5TDdWMGZCU0JSWEc4RTBydkE0SU9xK3pUdHFxbjJsTEhHUWNzMlVmMD08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il9lODVkZDMxYy1hMDZjLTQ2MDMtYTczOC00MzNmMzUxMTA4NjkiPlY3KzdjWUdTYlA5bCs1NExPbTBiQW1Vd05CL05WNHhiWloya0JKUGRGNTE3aHlqRHkwYnpYZzg4NytKeE1rdTNRcUQyUFBEa3RaMGEKUm5DYjJoUWJqOXB1QndKdVFOTEs1U3doZ3ZVcno3clJXcm5GM2Zpb0UxMVpYY1U5TEp4TGl2SVV0eWcrdkl3UDF1eEFPVy80RjlTdApwR1I1TFgrQ3YzMFBZanpPQ2YwPTwvZHM6U2lnbmF0dXJlVmFsdWU+PGRzOktleUluZm8gSWQ9Il9mOGM4MThjYy1lNDBmLTQ5MjgtYjAwNy03N2JmMjk4YmYxYTgiPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZRRENDQkttZ0F3SUJBZ0lFUURmN2N6QU5CZ2txaGtpRzl3MEJBUVVGQURBL01Rc3dDUVlEVlFRR0V3SkVTekVNTUFvR0ExVUUKQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wSUVOQklFbEpNQjRYRFRFeE1URXdNVEV5TWpBegpNMW9YRFRFek1URXdNVEV5TlRBek0xb3dnWVV4Q3pBSkJnTlZCQVlUQWtSTE1Ta3dKd1lEVlFRS0V5QkpibWRsYmlCdmNtZGhibWx6CllYUnZjbWx6YXlCMGFXeHJibmwwYm1sdVp6RkxNQ01HQTFVRUJSTWNVRWxFT2preU1EZ3RNakF3TWkweUxUY3pOVEE0T1RnMU56azQKTWpBa0JnTlZCQU1USFZSbGMzUndaWEp6YjI0Z01qZ3dNamMxTVRjM01pQlVaWE4wYzJWdU1JR2ZNQTBHQ1NxR1NJYjNEUUVCQVFVQQpBNEdOQURDQmlRS0JnUUNTeC8yNFltbnA2aE9MbkVLc3RxS2JrektieFdBdHNwNk1jb2NnQ0NXa0lYODJRR0o1TjZGcWk4VGkyMEQwCkROeGpsVzBSZlFVL090MjVtRW1WWHJYcGNVY1FFc2lkSHMxbkZ4N0J6MkVFRkwwZ3M4SnpEaU5ROWZwVFVVL2RPTFp6Yi9xcjFFY1QKYUd0SnlhUlpqSk9HbDdqTy9LODNvWnFwdHUvMERnTHp1UUlEQVFBQm80SURBRENDQXZ3d0RnWURWUjBQQVFIL0JBUURBZ1A0TUNzRwpBMVVkRUFRa01DS0FEekl3TVRFeE1UQXhNVEl5TURNeldvRVBNakF4TXpFeE1ERXhNalV3TXpOYU1FWUdDQ3NHQVFVRkJ3RUJCRG93Ck9EQTJCZ2dyQmdFRkJRY3dBWVlxYUhSMGNEb3ZMM1JsYzNRdWIyTnpjQzVqWlhKMGFXWnBhMkYwTG1SckwyOWpjM0F2YzNSaGRIVnoKTUlJQk53WURWUjBnQklJQkxqQ0NBU293Z2dFbUJnb3FnVkNCS1FFQkFRRUNNSUlCRmpBdkJnZ3JCZ0VGQlFjQ0FSWWphSFIwY0RvdgpMM2QzZHk1alpYSjBhV1pwYTJGMExtUnJMM0psY0c5emFYUnZjbmt3Z2VJR0NDc0dBUVVGQndJQ01JSFZNQW9XQTFSRVF6QURBZ0VCCkdvSEdSbTl5SUdGdWRtVnVaR1ZzYzJVZ1lXWWdZMlZ5ZEdsbWFXdGhkR1YwSUdmbWJHUmxjaUJQUTBWVElIWnBiR3ZsY2l3Z1ExQlQKSUc5bklFOURSVk1nUTFBc0lHUmxjaUJyWVc0Z2FHVnVkR1Z6SUdaeVlTQjNkM2N1WTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMApiM0o1TGlCQ1pXM21jbXNzSUdGMElGUkVReUJsWm5SbGNpQjJhV3hyNVhKbGJtVWdhR0Z5SUdWMElHSmxaM0xtYm5ObGRDQmhibk4yCllYSWdhV1owTGlCd2NtOW1aWE56YVc5dVpXeHNaU0J3WVhKMFpYSXVNQmdHQ1dDR1NBR0crRUlCRFFRTEZnbFFaWEp6YjI1WFpXSXcKSUFZRFZSMFJCQmt3RjRFVmMzVndjRzl5ZEVCalpYSjBhV1pwYTJGMExtUnJNSUdYQmdOVkhSOEVnWTh3Z1l3d1Y2QlZvRk9rVVRCUApNUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wCklFTkJJRWxKTVE0d0RBWURWUVFERXdWRFVrd3lPVEF4b0MrZ0xZWXJhSFIwY0RvdkwzUmxjM1F1WTNKc0xtOWpaWE11WTJWeWRHbG0KYVd0aGRDNWtheTl2WTJWekxtTnliREFmQmdOVkhTTUVHREFXZ0JRY21BbEhHa3c0dVJERkJDbGI4ZlJPZ0dyTWZqQWRCZ05WSFE0RQpGZ1FVUjRmanhUdjJqZGs5WnRhazhDQmlrWFJiV2p3d0NRWURWUjBUQkFJd0FEQVpCZ2txaGtpRzluMEhRUUFFRERBS0d3UldOeTR4CkF3SURxREFOQmdrcWhraUc5dzBCQVFVRkFBT0JnUUJVdmZkeGNCSW84dnN4R3Z0RjIyV2tpV0Zza2NXamxVaEtiR0l5amNwcGZXcVMKblo1aUR5NVQ5aUlHWS9odVQvN1Nnbkpiam5wTjZFRWE2VXFYVWJVemR0aDVPUDdxQlFrdktuT2tJeXVHamZ0Y3FWOFhqYTRHd1pvcwo2RjZOenFBWENSZUMya3d1dU40NHpyanozZmo3ZEEyNlFHcGltQ0pXenY1elJ5VzNOZz09PC9kczpYNTA5Q2VydGlmaWNhdGU+PGRzOlg1MDlDZXJ0aWZpY2F0ZT5NSUlFWFRDQ0E4YWdBd0lCQWdJRVFEWVgvREFOQmdrcWhraUc5dzBCQVFVRkFEQS9NUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFCkNoTURWRVJETVNJd0lBWURWUVFERXhsVVJFTWdUME5GVXlCVGVYTjBaVzEwWlhOMElFTkJJRWxKTUI0WERUQTBNREl5TURFek5URTAKT1ZvWERUTTNNRFl5TURFME1qRTBPVm93UHpFTE1Ba0dBMVVFQmhNQ1JFc3hEREFLQmdOVkJBb1RBMVJFUXpFaU1DQUdBMVVFQXhNWgpWRVJESUU5RFJWTWdVM2x6ZEdWdGRHVnpkQ0JEUVNCSlNUQ0JuekFOQmdrcWhraUc5dzBCQVFFRkFBT0JqUUF3Z1lrQ2dZRUFyYXdBCk5JNTZzbGpEc25vc0RVK01wNHIrUktGeXM5YzVxeThqV1p5QSs3UFlGczQrSVpjRnhuYk51SGk4YUFjYlNGT1VKRjBQR3BOZ1BFdE4KYytYQUs3cDE2aWF3TlRZcE1rSG0yVm9Jbk5md1dFai93R210YjRyS0RUMmE3YXVHazc2cStYZHFubm80UFJPOGU3QUtFSHc3cE4zawppSG1aQ0k0OFBUUnBSeDhDQXdFQUFhT0NBbVF3Z2dKZ01BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0RnWURWUjBQQVFIL0JBUURBZ0VHCk1JSUJBd1lEVlIwZ0JJSDdNSUg0TUlIMUJna3BBUUVCQVFFQkFRRXdnZWN3THdZSUt3WUJCUVVIQWdFV0kyaDBkSEE2THk5M2QzY3UKWTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMGIzSjVNSUd6QmdnckJnRUZCUWNDQWpDQnBqQUtGZ05VUkVNd0F3SUJBUnFCbDFSRQpReUJVWlhOMElFTmxjblJwWm1scllYUmxjaUJtY21FZ1pHVnVibVVnUTBFZ2RXUnpkR1ZrWlhNZ2RXNWtaWElnVDBsRUlERXVNUzR4CkxqRXVNUzR4TGpFdU1TNHhMakV1SUZSRVF5QlVaWE4wSUVObGNuUnBabWxqWVhSbGN5Qm1jbTl0SUhSb2FYTWdRMEVnWVhKbElHbHoKYzNWbFpDQjFibVJsY2lCUFNVUWdNUzR4TGpFdU1TNHhMakV1TVM0eExqRXVNUzR3RVFZSllJWklBWWI0UWdFQkJBUURBZ0FITUlHVwpCZ05WSFI4RWdZNHdnWXN3VnFCVW9GS2tVREJPTVFzd0NRWURWUVFHRXdKRVN6RU1NQW9HQTFVRUNoTURWRVJETVNJd0lBWURWUVFECkV4bFVSRU1nVDBORlV5QlRlWE4wWlcxMFpYTjBJRU5CSUVsSk1RMHdDd1lEVlFRREV3UkRVa3d4TURHZ0w2QXRoaXRvZEhSd09pOHYKZEdWemRDNWpjbXd1YjJObGN5NWpaWEowYVdacGEyRjBMbVJyTDI5alpYTXVZM0pzTUNzR0ExVWRFQVFrTUNLQUR6SXdNRFF3TWpJdwpNVE0xTVRRNVdvRVBNakF6TnpBMk1qQXhOREl4TkRsYU1COEdBMVVkSXdRWU1CYUFGQnlZQ1VjYVREaTVFTVVFS1Z2eDlFNkFhc3grCk1CMEdBMVVkRGdRV0JCUWNtQWxIR2t3NHVSREZCQ2xiOGZST2dHck1makFkQmdrcWhraUc5bjBIUVFBRUVEQU9Hd2hXTmk0d09qUXUKTUFNQ0JKQXdEUVlKS29aSWh2Y05BUUVGQlFBRGdZRUFweW9BamlLcTZXSzVYYUtXVXBWc2t1dHpvaHYxVmNDa2UvM0plVVZ0bUIrYgp5ZXhKTUMxNzFzNFJIb3FjYnVmY0kyQVNWV3d1ODRpNDVNYUtnL254b3Fvak15WTE5L1cyd2JRRkVkc3hVQ25MYTllOXRsV2oweFMvCkFhS2VVaGsyTUJPcXYraE1kYzcxak9xYzVKTjdUMkJhNlpSSVk1dVhrTzNJR1ozWFVzdz08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48L3NtZDpzaWduZWRNYXJrPg==','mark_info_enc get_info(encodedSignedMark) base64');

# info file
$R2=$E1 .'<response>'  . r() .  '<resData><infData><id>00000113675751323-1</id><status s="verified" /><smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">Marks: Example One
smdID: 0000004951387359953170-1
U-labels: example-one
notBefore: 2013-12-18T09:45:53.0Z
notAfter: 2014-05-02T22:00:00.0Z
-----BEGIN ENCODED SMD-----
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWduZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRNYXJrLTEuMCIgaWQ9Il8xMmE1MTA1Yy1hMTQ1LTQ0MzQtOWUyYi04NmJjZDk5NzkxNWMiPjxzbWQ6aWQ+MDAwMDAwNDk1MTM4NzM1OTk1MzE3MC0xPC9zbWQ6aWQ+PHNtZDppc3N1ZXJJbmZvIGlzc3VlcklEPSIxIj48c21kOm9yZz5EZWxvaXR0ZTwvc21kOm9yZz48c21kOmVtYWlsPnNtZC1zdXBwb3J0QGRlbG9pdHRlLmNvbTwvc21kOmVtYWlsPjxzbWQ6dXJsPnNtZC1zdXBwb3J0LmRlbG9pdHRlLmNvbTwvc21kOnVybD48c21kOnZvaWNlPiszMi4yMDAwMDAwMDwvc21kOnZvaWNlPjwvc21kOmlzc3VlckluZm8+PHNtZDpub3RCZWZvcmU+MjAxMy0xMi0xOFQwOTo0NTo1My4xNzBaPC9zbWQ6bm90QmVmb3JlPjxzbWQ6bm90QWZ0ZXI+MjAxNC0wNS0wMlQyMjowMDowMC4wMDBaPC9zbWQ6bm90QWZ0ZXI+PG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJhbXM6eG1sOm5zOm1hcmstMS4wIj48bWFyazp0cmFkZW1hcms+PG1hcms6aWQ+MDAwMDAxMTM2NzU3NTEzMjMtMTwvbWFyazppZD48bWFyazptYXJrTmFtZT5FeGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT48bWFyazpob2xkZXIgZW50aXRsZW1lbnQ9Im93bmVyIj48bWFyazpvcmc+RXhhbXBsZSBJbmMuPC9tYXJrOm9yZz48bWFyazphZGRyPjxtYXJrOnN0cmVldD4xMjMgRXhhbXBsZSBEci48L21hcms6c3RyZWV0PjxtYXJrOnN0cmVldD5TdWl0ZSAxMDA8L21hcms6c3RyZWV0PjxtYXJrOmNpdHk+UmVzdG9uPC9tYXJrOmNpdHk+PG1hcms6c3A+VkE8L21hcms6c3A+PG1hcms6cGM+MjAxOTA8L21hcms6cGM+PG1hcms6Y2M+TFk8L21hcms6Y2M+PC9tYXJrOmFkZHI+PC9tYXJrOmhvbGRlcj48bWFyazpjb250YWN0IHR5cGU9ImFnZW50Ij48bWFyazpuYW1lPmphbiBqYW5zZW48L21hcms6bmFtZT48bWFyazpvcmc+Q0hJUDwvbWFyazpvcmc+PG1hcms6YWRkcj48bWFyazpzdHJlZXQ+ZHZ2IDM3PC9tYXJrOnN0cmVldD48bWFyazpjaXR5PkxldXZlbjwvbWFyazpjaXR5PjxtYXJrOnBjPjMwMDA8L21hcms6cGM+PG1hcms6Y2M+QkU8L21hcms6Y2M+PC9tYXJrOmFkZHI+PG1hcms6dm9pY2U+KzEuMTIzPC9tYXJrOnZvaWNlPjxtYXJrOmZheD4rMi40NTc8L21hcms6ZmF4PjxtYXJrOmVtYWlsPmphbkBpcGNsZWFyaW5naG91c2Uub3JnPC9tYXJrOmVtYWlsPjwvbWFyazpjb250YWN0PjxtYXJrOmp1cmlzZGljdGlvbj5MWTwvbWFyazpqdXJpc2RpY3Rpb24+PG1hcms6Y2xhc3M+MzU8L21hcms6Y2xhc3M+PG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+PG1hcms6Z29vZHNBbmRTZXJ2aWNlcz5EaXJpZ2VuZGFzIGV0IGVpdXNtb2RpIGZlYXR1cmluZyBpbmZyaW5nbyBpbiBhaXJmYXJlIGV0IGNhcnRhbSBzZXJ2aWNpYS4KICAgICAgICAgICAgICAgICAgICA8L21hcms6Z29vZHNBbmRTZXJ2aWNlcz48bWFyazpyZWdOdW0+MjM0MjM1PC9tYXJrOnJlZ051bT48bWFyazpyZWdEYXRlPjIwMDktMDgtMTVUMjI6MDA6MDAuMDAwWjwvbWFyazpyZWdEYXRlPjxtYXJrOmV4RGF0ZT4yMDE1LTA4LTE1VDIyOjAwOjAwLjAwMFo8L21hcms6ZXhEYXRlPjwvbWFyazp0cmFkZW1hcms+PC9tYXJrOm1hcms+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIgSWQ9Il9jYmQxY2UwYS1hM2NlLTQ1NmUtYmY3YS00MmQwNDRjMTg4NjMiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI18xMmE1MTA1Yy1hMTQ1LTQ0MzQtOWUyYi04NmJjZDk5NzkxNWMiPjxkczpUcmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPjxkczpEaWdlc3RWYWx1ZT41YUF6bUp1V0VvQW9td2tKUWNobW1LKzlNck9hM0orSFQzUyt1aGhnK3pFPTwvZHM6RGlnZXN0VmFsdWU+PC9kczpSZWZlcmVuY2U+PGRzOlJlZmVyZW5jZSBVUkk9IiNfYzQ4M2M2YjAtNTJiMi00ZDQwLTk1NWUtYzA4NzNjMmQ0MTRiIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+bGVNYktJU3p1dy9BSjhYc0xuemJ5eldEQ0trOERSVzZtdVJPWW43UzJmOD08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWUgSWQ9Il9hODY3M2YxMC0yMjE5LTRhYmEtODU0Zi02MjljMTg0MzRmNGEiPmd0ZjBXWDR6cW1hNkN3VzRWMlJIc0REWlN1MlVwZXM2VTVObzdrRksxWlNoa2JqVnhWMnJEVytHVVBqWWNRcXVIdWhiT0FTWkxITksKVFowVnlPKzFnL3BUWmQ0RXpVclM0QVdvSTNhUEl1cjB6QmNVeThzZ3dEcHQ1U0F5SlhHWjJOQnR6a1B1R01hd0I1SFp5UGRSZzhCNApkZXcrMFV2dlVkNjd6c3M0RDRNPTwvZHM6U2lnbmF0dXJlVmFsdWU+PGRzOktleUluZm8gSWQ9Il9jNDgzYzZiMC01MmIyLTRkNDAtOTU1ZS1jMDg3M2MyZDQxNGIiPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUZRRENDQkttZ0F3SUJBZ0lFUURmN2N6QU5CZ2txaGtpRzl3MEJBUVVGQURBL01Rc3dDUVlEVlFRR0V3SkVTekVNTUFvR0ExVUUKQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wSUVOQklFbEpNQjRYRFRFeE1URXdNVEV5TWpBegpNMW9YRFRFek1URXdNVEV5TlRBek0xb3dnWVV4Q3pBSkJnTlZCQVlUQWtSTE1Ta3dKd1lEVlFRS0V5QkpibWRsYmlCdmNtZGhibWx6CllYUnZjbWx6YXlCMGFXeHJibmwwYm1sdVp6RkxNQ01HQTFVRUJSTWNVRWxFT2preU1EZ3RNakF3TWkweUxUY3pOVEE0T1RnMU56azQKTWpBa0JnTlZCQU1USFZSbGMzUndaWEp6YjI0Z01qZ3dNamMxTVRjM01pQlVaWE4wYzJWdU1JR2ZNQTBHQ1NxR1NJYjNEUUVCQVFVQQpBNEdOQURDQmlRS0JnUUNTeC8yNFltbnA2aE9MbkVLc3RxS2JrektieFdBdHNwNk1jb2NnQ0NXa0lYODJRR0o1TjZGcWk4VGkyMEQwCkROeGpsVzBSZlFVL090MjVtRW1WWHJYcGNVY1FFc2lkSHMxbkZ4N0J6MkVFRkwwZ3M4SnpEaU5ROWZwVFVVL2RPTFp6Yi9xcjFFY1QKYUd0SnlhUlpqSk9HbDdqTy9LODNvWnFwdHUvMERnTHp1UUlEQVFBQm80SURBRENDQXZ3d0RnWURWUjBQQVFIL0JBUURBZ1A0TUNzRwpBMVVkRUFRa01DS0FEekl3TVRFeE1UQXhNVEl5TURNeldvRVBNakF4TXpFeE1ERXhNalV3TXpOYU1FWUdDQ3NHQVFVRkJ3RUJCRG93Ck9EQTJCZ2dyQmdFRkJRY3dBWVlxYUhSMGNEb3ZMM1JsYzNRdWIyTnpjQzVqWlhKMGFXWnBhMkYwTG1SckwyOWpjM0F2YzNSaGRIVnoKTUlJQk53WURWUjBnQklJQkxqQ0NBU293Z2dFbUJnb3FnVkNCS1FFQkFRRUNNSUlCRmpBdkJnZ3JCZ0VGQlFjQ0FSWWphSFIwY0RvdgpMM2QzZHk1alpYSjBhV1pwYTJGMExtUnJMM0psY0c5emFYUnZjbmt3Z2VJR0NDc0dBUVVGQndJQ01JSFZNQW9XQTFSRVF6QURBZ0VCCkdvSEdSbTl5SUdGdWRtVnVaR1ZzYzJVZ1lXWWdZMlZ5ZEdsbWFXdGhkR1YwSUdmbWJHUmxjaUJQUTBWVElIWnBiR3ZsY2l3Z1ExQlQKSUc5bklFOURSVk1nUTFBc0lHUmxjaUJyWVc0Z2FHVnVkR1Z6SUdaeVlTQjNkM2N1WTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMApiM0o1TGlCQ1pXM21jbXNzSUdGMElGUkVReUJsWm5SbGNpQjJhV3hyNVhKbGJtVWdhR0Z5SUdWMElHSmxaM0xtYm5ObGRDQmhibk4yCllYSWdhV1owTGlCd2NtOW1aWE56YVc5dVpXeHNaU0J3WVhKMFpYSXVNQmdHQ1dDR1NBR0crRUlCRFFRTEZnbFFaWEp6YjI1WFpXSXcKSUFZRFZSMFJCQmt3RjRFVmMzVndjRzl5ZEVCalpYSjBhV1pwYTJGMExtUnJNSUdYQmdOVkhSOEVnWTh3Z1l3d1Y2QlZvRk9rVVRCUApNUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFQ2hNRFZFUkRNU0l3SUFZRFZRUURFeGxVUkVNZ1QwTkZVeUJUZVhOMFpXMTBaWE4wCklFTkJJRWxKTVE0d0RBWURWUVFERXdWRFVrd3lPVEF4b0MrZ0xZWXJhSFIwY0RvdkwzUmxjM1F1WTNKc0xtOWpaWE11WTJWeWRHbG0KYVd0aGRDNWtheTl2WTJWekxtTnliREFmQmdOVkhTTUVHREFXZ0JRY21BbEhHa3c0dVJERkJDbGI4ZlJPZ0dyTWZqQWRCZ05WSFE0RQpGZ1FVUjRmanhUdjJqZGs5WnRhazhDQmlrWFJiV2p3d0NRWURWUjBUQkFJd0FEQVpCZ2txaGtpRzluMEhRUUFFRERBS0d3UldOeTR4CkF3SURxREFOQmdrcWhraUc5dzBCQVFVRkFBT0JnUUJVdmZkeGNCSW84dnN4R3Z0RjIyV2tpV0Zza2NXamxVaEtiR0l5amNwcGZXcVMKblo1aUR5NVQ5aUlHWS9odVQvN1Nnbkpiam5wTjZFRWE2VXFYVWJVemR0aDVPUDdxQlFrdktuT2tJeXVHamZ0Y3FWOFhqYTRHd1pvcwo2RjZOenFBWENSZUMya3d1dU40NHpyanozZmo3ZEEyNlFHcGltQ0pXenY1elJ5VzNOZz09PC9kczpYNTA5Q2VydGlmaWNhdGU+PGRzOlg1MDlDZXJ0aWZpY2F0ZT5NSUlFWFRDQ0E4YWdBd0lCQWdJRVFEWVgvREFOQmdrcWhraUc5dzBCQVFVRkFEQS9NUXN3Q1FZRFZRUUdFd0pFU3pFTU1Bb0dBMVVFCkNoTURWRVJETVNJd0lBWURWUVFERXhsVVJFTWdUME5GVXlCVGVYTjBaVzEwWlhOMElFTkJJRWxKTUI0WERUQTBNREl5TURFek5URTAKT1ZvWERUTTNNRFl5TURFME1qRTBPVm93UHpFTE1Ba0dBMVVFQmhNQ1JFc3hEREFLQmdOVkJBb1RBMVJFUXpFaU1DQUdBMVVFQXhNWgpWRVJESUU5RFJWTWdVM2x6ZEdWdGRHVnpkQ0JEUVNCSlNUQ0JuekFOQmdrcWhraUc5dzBCQVFFRkFBT0JqUUF3Z1lrQ2dZRUFyYXdBCk5JNTZzbGpEc25vc0RVK01wNHIrUktGeXM5YzVxeThqV1p5QSs3UFlGczQrSVpjRnhuYk51SGk4YUFjYlNGT1VKRjBQR3BOZ1BFdE4KYytYQUs3cDE2aWF3TlRZcE1rSG0yVm9Jbk5md1dFai93R210YjRyS0RUMmE3YXVHazc2cStYZHFubm80UFJPOGU3QUtFSHc3cE4zawppSG1aQ0k0OFBUUnBSeDhDQXdFQUFhT0NBbVF3Z2dKZ01BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0RnWURWUjBQQVFIL0JBUURBZ0VHCk1JSUJBd1lEVlIwZ0JJSDdNSUg0TUlIMUJna3BBUUVCQVFFQkFRRXdnZWN3THdZSUt3WUJCUVVIQWdFV0kyaDBkSEE2THk5M2QzY3UKWTJWeWRHbG1hV3RoZEM1a2F5OXlaWEJ2YzJsMGIzSjVNSUd6QmdnckJnRUZCUWNDQWpDQnBqQUtGZ05VUkVNd0F3SUJBUnFCbDFSRQpReUJVWlhOMElFTmxjblJwWm1scllYUmxjaUJtY21FZ1pHVnVibVVnUTBFZ2RXUnpkR1ZrWlhNZ2RXNWtaWElnVDBsRUlERXVNUzR4CkxqRXVNUzR4TGpFdU1TNHhMakV1SUZSRVF5QlVaWE4wSUVObGNuUnBabWxqWVhSbGN5Qm1jbTl0SUhSb2FYTWdRMEVnWVhKbElHbHoKYzNWbFpDQjFibVJsY2lCUFNVUWdNUzR4TGpFdU1TNHhMakV1TVM0eExqRXVNUzR3RVFZSllJWklBWWI0UWdFQkJBUURBZ0FITUlHVwpCZ05WSFI4RWdZNHdnWXN3VnFCVW9GS2tVREJPTVFzd0NRWURWUVFHRXdKRVN6RU1NQW9HQTFVRUNoTURWRVJETVNJd0lBWURWUVFECkV4bFVSRU1nVDBORlV5QlRlWE4wWlcxMFpYTjBJRU5CSUVsSk1RMHdDd1lEVlFRREV3UkRVa3d4TURHZ0w2QXRoaXRvZEhSd09pOHYKZEdWemRDNWpjbXd1YjJObGN5NWpaWEowYVdacGEyRjBMbVJyTDI5alpYTXVZM0pzTUNzR0ExVWRFQVFrTUNLQUR6SXdNRFF3TWpJdwpNVE0xTVRRNVdvRVBNakF6TnpBMk1qQXhOREl4TkRsYU1COEdBMVVkSXdRWU1CYUFGQnlZQ1VjYVREaTVFTVVFS1Z2eDlFNkFhc3grCk1CMEdBMVVkRGdRV0JCUWNtQWxIR2t3NHVSREZCQ2xiOGZST2dHck1makFkQmdrcWhraUc5bjBIUVFBRUVEQU9Hd2hXTmk0d09qUXUKTUFNQ0JKQXdEUVlKS29aSWh2Y05BUUVGQlFBRGdZRUFweW9BamlLcTZXSzVYYUtXVXBWc2t1dHpvaHYxVmNDa2UvM0plVVZ0bUIrYgp5ZXhKTUMxNzFzNFJIb3FjYnVmY0kyQVNWV3d1ODRpNDVNYUtnL254b3Fvak15WTE5L1cyd2JRRkVkc3hVQ25MYTllOXRsV2oweFMvCkFhS2VVaGsyTUJPcXYraE1kYzcxak9xYzVKTjdUMkJhNlpSSVk1dVhrTzNJR1ozWFVzdz08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48L3NtZDpzaWduZWRNYXJrPg==
-----END ENCODED SMD-----
</smd:encodedSignedMark></infData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_info_file('00000113675751323-1');
is($R1,$E1.'<command><info type="file"><id>00000113675751323-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info_enc build');
is($rc->is_success(), 1, 'mark_info_enc is_success');

# info with cases
$R2=$E1.'<response>'.r().'<resData><infData><id>000001136757513215-1</id><status s="verified" /><pouStatus s="valid" /><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>000001136757513215-1</id><markName>Example 3</markName><holder entitlement="owner"><name>Example name</name><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>LY</cc></addr><email>test@test.test</email></holder><jurisdiction>LY</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T00:00:00Z</regDate><exDate>2015-08-16T00:00:00Z</exDate></trademark></mark><label><aLabel>example-one</aLabel><uLabel>example-one</uLabel><smdInclusion enable="0" /><claimsNotify enable="0" /></label><case><id>case-165955219104862426891240536623</id><court><refNum>987654321</refNum><cc>BE</cc><courtName>Bla</courtName><caseLang>Spanish</caseLang></court><status s="new" /><label><aLabel>label5</aLabel><status s="new" /></label><label><aLabel>label3</aLabel><status s="new" /></label><label><aLabel>label2</aLabel><status s="new" /></label><label><aLabel>label1</aLabel><status s="new" /></label><label><aLabel>label4</aLabel><status s="new" /></label><comment>this is a comment</comment><upDate>2013-10-09T10:20:45.2Z</upDate></case><case><id>case-176169232111416328571942201148</id><udrp><caseNo>456</caseNo><udrpProvider>Asian Domain Name Dispute Resolution Centre</udrpProvider><caseLang>Afrikaans</caseLang></udrp><status s="new" /><label><aLabel>second1</aLabel><status s="new" /></label><upDate>2013-10-09T10:21:35.0Z</upDate></case><crDate>2013-05-03T11:58:53.3Z</crDate><upDate>2013-12-18T10:45:53.3Z</upDate><exDate>2014-05-03T00:00:00Z</exDate></infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->mark_info('000001136757513215-1');
is($R1,$E1.'<command><info><id>000001136757513215-1</id></info><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_info (retrieve case data) build');
is($rc->is_success(),1,'mark_info (retrieve case data) is_success');
is($dri->get_info('exist'),1,'mark_info get_info(exist)');
is($dri->get_info('action'),'info','mark_info get_info(action)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(status)');
is_deeply([$s->list_status()],['verified'],'mark_info get_info(status) is verified');
$pouS=$dri->get_info('pou_status');
isa_ok($pouS,'Net::DRI::Data::StatusList','mark_info get_info(pou_status)');
is_deeply([$pouS->list_status()],['valid'],'mark_info get_info(pou_status) is valid');
$mark=$dri->get_info('mark');
is($mark->{'type'},'trademark','mark_info get_info(mark) type');
is($mark->{'id'},'000001136757513215-1','mark_info get_info(id) org');
is($mark->{'mark_name'},'Example 3','mark_info get_info(mark) mark_name');
$cs=$mark->{'contact'};
isa_ok($cs,'Net::DRI::Data::ContactSet','mark_info get_info(cs)');
$holder=$cs->get('holder_owner');
is($holder->name(),'Example name','mark_info get_info(holder) name');
is($holder->org(),'Example Inc.','mark_info get_info(holder) org');
is_deeply(scalar $holder->street(),['123 Example Dr.','Suite 100'],'mark_info get_info(holder) street');
is($holder->city(),'Reston','mark_info get_info(holder) city');
is($holder->sp(),'VA','mark_info get_info(holder) sp');
is($holder->pc(),'20190','mark_info get_info(holder) pc');
is($holder->cc(),'LY','mark_info get_info(holder) cc');
is($holder->email(),'test@test.test','mark_info get_info(holder) email');
is($mark->{'jurisdiction'},'LY','mark_info get_info(holder) jurisdiction');
is_deeply($mark->{'class'},[35,36],'mark_info get_info(holder) class');
is($mark->{'goods_services'},'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.','mark_info get_info(holder) goods_services');
is($mark->{'registration_number'},'234235','mark_info get_info(holder) regNum');
is($mark->{'registration_date'},'2009-08-16T00:00:00','mark_info get_info(mark) regDate');
is($mark->{'expiration_date'},'2015-08-16T00:00:00','mark_info get_info(mark) exDate');
@labels=@{$dri->get_info('labels')};
$l1=$labels[0];
isa_ok($l1,'HASH','mark_info get_info(label)');
is($l1->{'a_label'},'example-one','mark_info get_info(label) aLabel');
is($l1->{'u_label'},'example-one','mark_info get_info(label) uLabel');
is($l1->{'smd_inclusion'},'0','mark_info get_info(label) smdInclusion');
is($l1->{'claims_notify'},'0','mark_info get_info(label) claimsNotify');
##cases:start - tests
@cases=@{$dri->get_info('cases')};
#get_info(case1)
$c1=$cases[0];
isa_ok($c1,'HASH','mark_info get_info(case)');
is($c1->{'id'},'case-165955219104862426891240536623','mark_info get_info(case1) id');
is($c1->{'court'}->{'reference_number'},'987654321','mark_info get_info(case1) caseNo');
is($c1->{'court'}->{'cc'},'BE','mark_info get_info(case1) udrpProvider');
is($c1->{'court'}->{'language'},'Spanish','mark_info get_info(case1) language');
is($c1->{'court'}->{'name'},'Bla','mark_info get_info(case1) language');
$s=$c1->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) status is verified');
@comments=@{$c1->{'comments'}};
is_deeply($c1->{comments},['this is a comment'],'mark_info get_info(case1) comments');
@labels=@{$c1->{'labels'}};
$l1=$labels[0];
isa_ok($l1,'HASH','mark_info get_info(case1) label1');
is($l1->{'a_label'},'label5','mark_info get_info(case1) label1-aLabel');
$s=$l1->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) label1-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) label1-status is verified');
$l2=$labels[1];
isa_ok($l2,'HASH','mark_info get_info(case1) label2');
is($l2->{'a_label'},'label3','mark_info get_info(case1) label2-aLabel');
$s=$l2->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) label2-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) label2-status is verified');
$l3=$labels[2];
isa_ok($l3,'HASH','mark_info get_info(case1) label3');
is($l3->{'a_label'},'label2','mark_info get_info(case1) label3-aLabel');
$s=$l3->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) label2-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) label2-status is verified');
$l4=$labels[3];
isa_ok($l4,'HASH','mark_info get_info(case1) label4');
is($l4->{'a_label'},'label1','mark_info get_info(case1) label4-aLabel');
$s=$l4->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) label4-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) label4-status is verified');
$l5=$labels[4];
isa_ok($l5,'HASH','mark_info get_info(case1) label5');
is($l5->{'a_label'},'label4','mark_info get_info(case1) label5-aLabel');
$s=$l5->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case1) label5-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case1) label5-status is verified');
#get_info(case2)
$c2=$cases[1];
isa_ok($c2,'HASH','mark_info get_info(case)');
is($c2->{'id'},'case-176169232111416328571942201148','mark_info get_info(case2) id');
is($c2->{'udrp'}->{'case_number'},'456','mark_info get_info(case2) caseNo');
is($c2->{'udrp'}->{'provider'},'Asian Domain Name Dispute Resolution Centre','mark_info get_info(case2) udrpProvider');
is($c2->{'udrp'}->{'language'},'Afrikaans','mark_info get_info(case2) language');
$s=$c2->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case2) status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case2) status is verified');
@labels=@{$c2->{'labels'}};
$l1=$labels[0];
isa_ok($l1,'HASH','mark_info get_info(label)');
is($l1->{'a_label'},'second1','mark_info get_info(case2) label1-aLabel');
$s=$l1->{'status'};
isa_ok($s,'Net::DRI::Data::StatusList','mark_info get_info(case2) label1-status');
is_deeply([$s->list_status()],['new'],'mark_info get_info(case2) label1-status is verified');
##cases:end - tests
is($dri->get_info('crDate'),'2013-05-03T11:58:53','mark_info get_info(crDate)');
is($dri->get_info('upDate'),'2013-12-18T10:45:53','mark_info get_info(upDate)');
is($dri->get_info('exDate'),'2014-05-03T00:00:00','mark_info get_info(exDate)');

####################################################################################################
## Mark Create Commands

# create TM
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
$l2 = { a_label => 'example-one', smd_inclusion => 0, claims_notify => 1 };
@labels = ($l1,$l2);

$d1 = { doc_type => 'tmOther', file_type => 'jpg', file_name => 'C:\\ddafs\\file.png', file_content => 'YnJvbAo='};
@docs = ($d1);

$d = DateTime::Duration->new(years=>5);

# Create Court Mark
$mark = { id => '0000061234-1', type => 'court', mark_name => 'Example One', court_name => 'P.R. supreme court', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', cc => 'US', reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) };
$mark->{contact} = $cs;

$R2=$E1 .'<response>'  . r() .  '<resData><creData><id>0000061234-1</id><crDate>2012-10-01T22:00:00Z</crDate><balance><amount currency="USD">56588.2500</amount><statusPoints>1414</statusPoints></balance></creData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><court><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00Z</proDate><cc>US</cc><courtName>P.R. supreme court</courtName></court></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>example-one</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build (court)');

# Create Statute
$mark = { id => '00000712423-1', type => 'statue_treaty', mark_name => 'Example One', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', protection => [ { ruling => ['US'],cc => 'US'} ],  reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) ,execution_date => DateTime->new(year =>2010,month=>1,day=>5,hour=>9),title=>'My Mark Title'};
$mark->{contact} = $cs;

$R2=$E1 .'<response>'  . r() .  '<resData><creData><id>00000712423-1</id><crDate>2012-10-01T22:00:00Z</crDate><balance><amount currency="USD">56588.2500</amount><statusPoints>1414</statusPoints></balance></creData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><treatyOrStatute><id>00000712423-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><protection><cc>US</cc><ruling>US</ruling></protection><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00Z</proDate><title>My Mark Title</title><execDate>2010-01-05T09:00:00Z</execDate></treatyOrStatute></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>example-one</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build (statute))');

# Create TradeMark - note: I belive max contacs is now 2 ?
$mark = { id => '0000061234-1', type => 'trademark', mark_name => 'Example One', class=> [35,36], goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.',jurisdiction => 'US', registration_number => '234235', registration_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9),expiration_date => DateTime->new(year =>2015,month=>8,day=>16,hour=>9) };
$holder2 = $holder->clone()->name('John Smith')->voice('+44.12341234')->fax('+44.123452234');
#$agent = $holder->clone()->name('Agent Smith')->voice('+44.12341234')->email('test@web.site');
#$tparty = $holder->clone()->name('Morpheus')->org('Nebuchadnezzar')->voice('+44.12341234')->email('test@web.site');
$cs->add($holder2,'holder_assignee');
#$cs->add($agent,'contact_agent');
#$cs->add($tparty,'contact_thirdparty');
$mark->{contact} = $cs;

$R2=$E1 .'<response>'  . r() .  '<resData><creData><id>0000061234-1</id><crDate>2012-10-01T22:00:00Z</crDate><balance><amount currency="USD">56588.2500</amount><statusPoints>1414</statusPoints></balance></creData></resData>'.$TRID .'</response>'.$E2;
$rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
is($R1,$E1.'<command><create><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><trademark><id>0000061234-1</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><holder entitlement="assignee"><name>John Smith</name><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr><voice>+44.12341234</voice><fax>+44.123452234</fax></holder><jurisdiction>US</jurisdiction><class>35</class><class>36</class><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><regNum>234235</regNum><regDate>2009-08-16T09:00:00Z</regDate><exDate>2015-08-16T09:00:00Z</exDate></trademark></mark><period unit="y">5</period><document><docType>tmOther</docType><fileName>C:\\ddafs\\file.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>exampleone</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label><label><aLabel>example-one</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></create><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_create build (trademark)');
is($rc->is_success(), 1, 'mark_create is_success');
is($dri->get_info('action'),'create','mark_create get_info(action)');
is($dri->get_info('crDate'),'2012-10-01T22:00:00','mark_create get_info(crDate)');

## Balance is returned after chargeable transactions (create,transfer,renew)
is_deeply($dri->get_info('balance'),{'amount'=>'56588.2500','currency'=>'USD','status_points'=>'1414'},'mark_create get_info(balance)');


####################################################################################################
## Mark Update Commands

## update: mark settings
$cs = $dri->local_object('contactset');
$holder3 = $dri->local_object('contact');
$holder3->org('Example Inc.');
$holder3->street(['123 Example Dr.','Suite 100']);
$holder3->city('Reston');
$holder3->sp('VA');
$holder3->pc('20190');
$holder3->cc('US');
$R2=$E1 .'<response>'  . r() .  ''.$TRID .'</response>'.$E2;
$mark2 = { id => '000712423-2', type => 'statue_treaty', mark_name => 'Example One', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', protection => [ { ruling => ['US','PR'],cc => 'US',region => 'Puerto Rico'} ],  reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) ,execution_date => DateTime->new(year =>2010,month=>1,day=>5,hour=>9),title=>'My Mark Title'};
$chg = $dri->local_object('changes');
$mark2->{'goods_services'}='Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.';
$cs->add($holder3,'holder_owner');
$mark2->{'contact'}=$cs;
$chg->set('mark',$mark2);
my @addlabels=({a_label=>'my-name', smd_inclusion => 0, claims_notify => 1});
$chg->add('labels',\@addlabels);
my @remlabels=({a_label=>'my-name', smd_inclusion => 1, claims_notify => 1});
$chg->del('labels',\@remlabels);
my @adddocs=({doc_type=>'tmOther', file_type=>'jpg', file_name=>'C:\\ddafs\\file2.png', file_content=>'YnJvbAo='});
$chg->add('documents',\@adddocs);
$rc=$dri->mark_update($mark2->{'id'},$chg);
is($R1,$E1.'<command><update><id>000712423-2</id><add><document><docType>tmOther</docType><fileName>C:\\ddafs\\file2.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>my-name</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></add><rem><label><aLabel>my-name</aLabel><smdInclusion enable="1"/><claimsNotify enable="1"/></label></rem><chg><mark xmlns="urn:ietf:params:xml:ns:mark-1.0"><treatyOrStatute><id>000712423-2</id><markName>Example One</markName><holder entitlement="owner"><org>Example Inc.</org><addr><street>123 Example Dr.</street><street>Suite 100</street><city>Reston</city><sp>VA</sp><pc>20190</pc><cc>US</cc></addr></holder><protection><cc>US</cc><region>Puerto Rico</region><ruling>US</ruling><ruling>PR</ruling></protection><goodsAndServices>Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.</goodsAndServices><refNum>234235</refNum><proDate>2009-08-16T09:00:00Z</proDate><title>My Mark Title</title><execDate>2010-01-05T09:00:00Z</execDate></treatyOrStatute></mark></chg></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (update mark settings) build');
is($rc->is_success(),1,'mark_update (mark settings) is_success');

## update: adding a label
$R2=$E1.'<response>'.r().'<msgQ count="76" id="17" /><trID><svTRID>update-1391086383-5308</svTRID></trID></response>'.$E2;
$chg=$dri->local_object('changes');
@addlabels=({a_label=>'exampleone', smd_inclusion => 0, claims_notify => 1});
$chg->add('labels',\@addlabels);
$rc=$dri->mark_update('0000011363778801363778080-1',$chg);
is($R1,$E1.'<command><update><id>0000011363778801363778080-1</id><add><label><aLabel>exampleone</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></add></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (adding a label) build');
is($rc->is_success(),1,'mark_update (adding a label) is_success');

## update: changing label flags
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
my @chglabels=({a_label=>'exampleone', smd_inclusion => 0, claims_notify => 1});
$chg->set('labels',\@chglabels);
$rc=$dri->mark_update('0000011363778801363778080-1',$chg);
is($R1,$E1.'<command><update><id>0000011363778801363778080-1</id><chg><label><aLabel>exampleone</aLabel><smdInclusion enable="0"/><claimsNotify enable="1"/></label></chg></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (changing label flags) build');
is($rc->is_success(),1,'mark_update (changing label flags) is_success');
# end:update

## Cases
## 8.1: adding a udrp case
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
my @addlabels2=({a_label=>'a'},{a_label=>'b'});
my @adddocs2=({doc_type=>'courtCaseDocument', file_type=>'jpg', file_name=>'02-2013-TMCHdefect1.jpg', file_content=>'YnJvbAo='});
my $udrp={case_number=>'987654321', provider=>'National Arbitration Forum', language=>'Spanish'};
my @addcases=({id=>'case-00000123466989999999',udrp=>$udrp,documents=>\@adddocs2,labels=>\@addlabels2});
$chg->add('cases',\@addcases);
$rc=$dri->mark_update('000001132-1',$chg);
is($R1,$E1.'<command><update><id>000001132-1</id><add><case><id>case-00000123466989999999</id><udrp><caseNo>987654321</caseNo><udrpProvider>National Arbitration Forum</udrpProvider><caseLang>Spanish</caseLang></udrp><document><docType>courtCaseDocument</docType><fileName>02-2013-TMCHdefect1.jpg</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>a</aLabel></label><label><aLabel>b</aLabel></label></case></add></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (add udrp case) build');
is($rc->is_success(),1,'mark_update (add udrp case) is_success');

## 8.2: adding a court case
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
my $court={reference_number=>'987654321',cc=>'BE',name=>'Bla',language=>'Spanish'};
@adddocs=({doc_type=>'courtCaseDocument', file_type=>'jpg', file_name=>'02-2013-TMCHdefect2.jpg', file_content=>'YnJvbAo='});
@addlabels=({a_label=>'a'},{a_label=>'b'});
@addcases=({id=>'case-00000123466989979999',court=>$court,documents=>\@adddocs,labels=>\@addlabels});
$chg->add('cases',\@addcases);
$rc=$dri->mark_update('000001132-1',$chg);
is($R1,$E1.'<command><update><id>000001132-1</id><add><case><id>case-00000123466989979999</id><court><refNum>987654321</refNum><cc>BE</cc><courtName>Bla</courtName><caseLang>Spanish</caseLang></court><document><docType>courtCaseDocument</docType><fileName>02-2013-TMCHdefect2.jpg</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>a</aLabel></label><label><aLabel>b</aLabel></label></case></add></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (adding a court case) build');
is($rc->is_success(),1,'mark_update (adding a court case) is_success');

## 8.3: managing labels linked to a case
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
@addlabels=({a_label=>'x'});
@addcases=({id=>'case-00000123466989979998',labels=>\@addlabels});
$chg->add('cases',\@addcases);
$rc=$dri->mark_update('000001132-1',$chg);
is($R1,$E1.'<command><update><id>000001132-1</id><add><case><id>case-00000123466989979998</id><label><aLabel>x</aLabel></label></case></add></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (managing labels linked to a case) build');
is($rc->is_success(),1,'mark_update (managing labels linked to a case) is_success');

## 8.4: managing documents linked to a case
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
@adddocs=({doc_type=>'tmOther', file_type=>'jpg', file_name=>'C:\\ddafs\\file2.png', file_content=>'YnJvbAo='});
@addlabels=({a_label=>'my-name-three'});
@addcases=({id=>'case-00000123456',documents=>\@adddocs,labels=>\@addlabels});
$chg->add('cases',\@addcases);
$rc=$dri->mark_update('0000011363778801363778080-1',$chg);
is($R1,$E1.'<command><update><id>0000011363778801363778080-1</id><add><case><id>case-00000123456</id><document><docType>tmOther</docType><fileName>C:\\ddafs\\file2.png</fileName><fileType>jpg</fileType><fileContent>YnJvbAo=</fileContent></document><label><aLabel>my-name-three</aLabel></label></case></add></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (managing documents linked to a case) build');
is($rc->is_success(),1,'mark_update (managing documents linked to a case) is_success');

## 8.5: changing a case
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$chg=$dri->local_object('changes');
my $chgudrp={case_number=>'987654321', provider=>'NAF', language=>'Spanish'};
my @chgcases=({id=>'case-00000123456',udrp=>$chgudrp});
$chg->set('cases',\@chgcases);
$rc=$dri->mark_update('0000011363778801363778080-1',$chg);
is($R1,$E1.'<command><update><id>0000011363778801363778080-1</id><chg><case><id>case-00000123456</id><udrp><caseNo>987654321</caseNo><udrpProvider>NAF</udrpProvider><caseLang>Spanish</caseLang></udrp></case></chg></update><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_update (changing a case) build');
is($rc->is_success(),1,'mark_update (changing a case) is_success');


####################################################################################################
## Mark Renew Commands

# renew
$R2=$E1.'<response>'.r().'<msgQ count="76" id="17" /><resData><renData><id>00000126-1</id><exDate>2017-08-08T00:00:00Z</exDate><balance><amount currency="USD">56588.2500</amount><statusPoints>1414</statusPoints></balance></renData></resData><trID><svTRID>renew-1391087231-5310</svTRID></trID></response>'.$E2;
$rc=$dri->mark_renew('00000126-1',{duration=>DateTime::Duration->new(years=>3),current_expiration=>DateTime->new(year=>2014,month=>01,day=>02)});
is($R1,$E1.'<command><renew><id>00000126-1</id><curExpDate>2014-01-02</curExpDate><period unit="y">3</period></renew><clTRID>ABC-12345</clTRID></command>'.$E2, 'mark_renew build');
is($rc->is_success(), 1, 'mark_renew is_success');
is($dri->get_info('action'),'renew','mark_renew get_info(action)');
is($dri->get_info('exDate'),'2017-08-08T00:00:00','mark_renew get_info(exDate)');


####################################################################################################
## Mar Transfer Commands

# Mark Transfer Start
# If successful, returns 'new_id' which will have your accountid at the beggining instead of previous agent
$R2=$E1.'<response>'.r().'<msgQ count="75" id="19" /><resData><trnData><newId>000005553456789876543211113333-1</newId><trnDate>2014-01-30T15:27:14.3Z</trnDate><balance><amount currency="USD">56565.2500</amount><statusPoints>1414</statusPoints></balance></trnData></resData><trID><svTRID>create-1391092034-5317</svTRID></trID></response>'.$E2;
$rc=$dri->mark_transfer_start('000001123456789876543211113333-1', {auth=>{pw=>'qwertyasdfgh'}});
is($R1,$E1.'<command><transfer op="execute"><id>000001123456789876543211113333-1</id><authCode>qwertyasdfgh</authCode></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'mark_transfer_start build');
is($rc->is_success(),1,'mark_transfer_start is_success');
is($dri->get_info('id'),'000001123456789876543211113333-1','mark_transfer_start get_info(id)');
is($dri->get_info('new_id'),'000005553456789876543211113333-1','mark_transfer_start get_info(new_id)');

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
is($dri->get_info('action_code','message',3),123,'message get_info [verified] action_code');
is($dri->get_info('action_text','message',3),'Mark has been verified and approved','message get_info [verified] action_text');
is($dri->get_info('status','message',3),'verified','message get_info [verified] status');
is($dri->get_info('object_id','message',3),'00123000011906-1','message get_info [verified] object_id');
is($dri->get_info('mark_name','message',3),'MYMARKE','message get_info [verified] mark_name');

# Claims notification
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="4"><qDate>2013-06-14 15:24:08</qDate><msg>220 The domain name [brand.claims] was registered during Claims period at 2014-05-01T00:00:00.0Z</msg></msgQ><resData><infData><id>00123000011906-1</id><status s="verified" /></infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),4,'message get_info [domain_registered_claims] last_id');
is($dri->get_info('action','message',4),'domain_registered_claims','message get_info [domain_registered_claims] action');
is($dri->get_info('action_code','message',4),220,'message get_info [domain_registered_claims] action_code');
is($dri->get_info('action_text','message',4),'The domain name [brand.claims] was registered during Claims period at 2014-05-01T00:00:00.0Z','message get_info [domain_registered_claims] action_text');
is($dri->get_info('object_id','message',4),'00123000011906-1','message get_info [domain_registered_claims] object_id');
is($dri->get_info('status','message',4),'verified','message get_info [domain_registered_claims] status');

exit 0;