#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 10;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }


my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('COZA',{client_id=>'examplerar'});
$dri->target('COZA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0"><epp:response><epp:result code="1000"><epp:msg>Domain Info Command completed successfully</epp:msg></epp:result><epp:resData><domain:infData><domain:name>exampledomain.co.za</domain:name><domain:roid>DOM_26I-COZA</domain:roid><domain:status s="ok">Domain Creation</domain:status><domain:registrant>rant1</domain:registrant><domain:ns><domain:hostAttr><domain:hostName>ns1.otherdomain.co.za</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.otherdomain.co.za</domain:hostName></domain:hostAttr></domain:ns><domain:clID>testrar1</domain:clID><domain:crID>testrar1</domain:crID><domain:crDate>2011-01-19T09:16:10Z</domain:crDate><domain:upID>testrar1</domain:upID><domain:upDate>2011-01-19T09:16:10Z</domain:upDate><domain:exDate>2013-01-18T09:16:10Z</domain:exDate><domain:authInfo><domain:pw>coza</domain:pw></domain:authInfo></domain:infData></epp:resData><epp:extension><cozadomain:infData><cozadomain:autorenew>true</cozadomain:autorenew></cozadomain:infData></epp:extension><epp:trID><epp:clTRID>CLTRID-12954285819-DV2N</epp:clTRID><epp:svTRID>DNS-EPP-12D9D8F7A69-8E651</epp:svTRID></epp:trID></epp:response></epp:epp>';

my $rc=$dri->domain_info('exampledomain.co.za');
is($rc->get_data('auto_renew'),1,'get_data auto_renew');

$R2='';
$rc=$dri->domain_update('exampledomain.co.za',$dri->local_object('changes')->set('auto_renew',0));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampledomain.co.za</domain:name></domain:update></update><extension><cozadomain:update xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozadomain-1-0 coza-domain-1.0.xsd"><cozadomain:chg><cozadomain:autorenew>false</cozadomain:autorenew></cozadomain:chg></cozadomain:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update auto_renew');

$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0"><epp:response><epp:result code="1000"><epp:msg>Domain Info Command completed successfully</epp:msg></epp:result><epp:resData><domain:infData><domain:name>exampledomain.co.za</domain:name><domain:roid>DOM_32-COZA</domain:roid><domain:ns><domain:hostAttr><domain:hostName>ns1.otherdomain.co.za</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.otherdomain.co.za</domain:hostName></domain:hostAttr></domain:ns><domain:clID>testrar1</domain:clID></domain:infData></epp:resData><epp:extension><cozadomain:infData><cozadomain:autorenew>true</cozadomain:autorenew><cozadomain:transferQuoteRes><cozadomain:name>testdomain.test.dnservices.co.za</cozadomain:name><cozadomain:cost>49.93</cozadomain:cost></cozadomain:transferQuoteRes></cozadomain:infData></epp:extension><epp:trID><epp:clTRID>CLTRID-12985441252-6XGZ</epp:clTRID><epp:svTRID>DNS-EPP-12E5742E54A-89263</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc=$dri->domain_info('exampledomain.co.za',{transfer_cost=>1});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">exampledomain.co.za</domain:name></domain:info></info><extension><cozadomain:info xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozadomain-1-0 coza-domain-1.0.xsd"><cozadomain:transferQuote>true</cozadomain:transferQuote></cozadomain:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info with transfer_cost');
is($rc->get_data('transfer_cost'),49.93,'get_data transfer_cost');

$R2='';
$rc=$dri->domain_update('exampledomain.co.za',$dri->local_object('changes')->set('cancel_action','PendingSuspension'));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampledomain.co.za</domain:name></domain:update></update><extension><cozadomain:update xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozadomain-1-0 coza-domain-1.0.xsd" cancelPendingAction="PendingSuspension"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update cancel_action');

$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:cozacontact="http://co.za/epp/extensions/cozacontact-1-0"><epp:response><epp:result code="1000"><epp:msg>Contact Info Command completed successfully</epp:msg></epp:result><epp:resData><contact:infData><contact:id>testCont</contact:id><contact:roid>CTC_2-COZA</contact:roid><contact:status s="ok"/><contact:status s="linked"/><contact:postalInfo type="loc"><contact:name>Test Contact</contact:name><contact:org/><contact:addr><contact:street>22 Elm street</contact:street><contact:street>Amityville</contact:street><contact:city>Registrant Ville</contact:city><contact:sp>Gauteng</contact:sp><contact:pc>90210</contact:pc><contact:cc>ZA</contact:cc></contact:addr></contact:postalInfo><contact:voice>+27.115551234</contact:voice><contact:fax>+86.5551234</contact:fax><contact:email>test@example.com</contact:email><contact:clID>testrar1</contact:clID><contact:crID>testrar1</contact:crID><contact:crDate>2011-02-07T12:39:43Z</contact:crDate><contact:upID>testrar1</contact:upID><contact:upDate>2011-02-07T12:39:43Z</contact:upDate><contact:authInfo><contact:pw>$6$aAnnlSS/$A.2l54WhjrEJ7Lg4LIGqkIv5XDAlqSzN3Z3DHM9t0HeumMZ60yFsHdYsEjpHpceSPVhgsCN8eOq75qv1dvpkv.</contact:pw></contact:authInfo></contact:infData></epp:resData><epp:extension><cozacontact:infData><cozacontact:domain level="Contact">exampledomain1.co.za</cozacontact:domain><cozacontact:domain level="Contact">exampledomain2.co.za</cozacontact:domain></cozacontact:infData></epp:extension><epp:trID><epp:clTRID>CLTRID-12983588349-9OFC</epp:clTRID><epp:svTRID>DNS-EPP-12E4C3796FC-1562C</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc=$dri->contact_info($dri->local_object('contact')->srid('testCont'),{domain_listing => 1});
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>testCont</contact:id></contact:info></info><extension><cozacontact:info xmlns:cozacontact="http://co.za/epp/extensions/cozacontact-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozacontact-1-0 coza-contact-1.0.xsd"><cozacontact:domainListing>true</cozacontact:domainListing></cozacontact:info></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_info domain_listing');
is_deeply($rc->get_data('domain_listing'),{contact=>[qw/exampledomain1.co.za exampledomain2.co.za/]},'contact_info domain_listing result');


$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:cozacontact="http://co.za/epp/extensions/cozacontact-1-0"><epp:response><epp:result code="1000"><epp:msg>Contact Info Command completed successfully</epp:msg></epp:result><epp:resData><contact:infData><contact:id>examplerar</contact:id><contact:roid>CTC_1-COZA</contact:roid><contact:status s="ok"/><contact:voice/><contact:fax/><contact:email>examplerar@example.com</contact:email><contact:clID/><contact:crID/><contact:crDate>2011-02-07T11:02:55Z</contact:crDate><contact:authInfo><contact:pw>$6$p3lfdtTt$Yj/CA86ESI1FCOJxPIlelobSQednvgl6eCb8HfVA3x6y2T5EH9XL/sL.eIuhyw70a6ButV6wHmVEVoQhCMauW0</contact:pw></contact:authInfo></contact:infData></epp:resData><epp:extension><cozacontact:infData><cozacontact:balance>1100.00</cozacontact:balance></cozacontact:infData></epp:extension><epp:trID><epp:clTRID>CLTRID-12990554643-KE8R</epp:clTRID><epp:svTRID>DNS-EPP-12E75BD4F95-948A5</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc=$dri->registrar_balance();
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>examplerar</contact:id></contact:info></info><extension><cozacontact:info xmlns:cozacontact="http://co.za/epp/extensions/cozacontact-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozacontact-1-0 coza-contact-1.0.xsd"><cozacontact:balance>true</cozacontact:balance></cozacontact:info></extension><clTRID>ABC-12345</clTRID></command></epp>','registrar_balance');
is($rc->get_data('registrar',$dri->info('client_id'),'balance'),1100,'registrar_balance parse');

$R2='';
$rc=$dri->contact_update($dri->local_object('contact')->srid('testCont2'),$dri->local_object('changes')->set('cancel_action','PendingUpdate'));
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>testCont2</contact:id></contact:update></update><extension><cozacontact:update xmlns:cozacontact="http://co.za/epp/extensions/cozacontact-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozacontact-1-0 coza-contact-1.0.xsd" cancelPendingAction="PendingUpdate"/></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update cancel_action');

exit 0;
