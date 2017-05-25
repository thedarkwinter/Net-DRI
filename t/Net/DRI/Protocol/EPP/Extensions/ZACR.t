#!/usr/bin/perl

use strict;
use warnings;
use Net::DRI;
use Test::More tests => 66;
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
$dri->add_current_registry('ZACR', {client_id => 'examplerar'});
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

# for the mark processing
my $po=$dri->target('ZACR')->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();
my ($doc,$root,$rh,$lp,$enc);

my ($rc,$dh,$cs,$ch1,$ch2);


####################################################################################################
#### Parse Greeting and Load extensions correctly
$R2='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:greeting><epp:svID>DNS EPP Server</epp:svID><epp:svDate>2017-05-25T13:29:41.602+02:00</epp:svDate><epp:svcMenu><epp:version>1.0</epp:version><epp:lang>en</epp:lang><epp:objURI>urn:ietf:params:xml:ns:domain-1.0</epp:objURI><epp:objURI>urn:ietf:params:xml:ns:contact-1.0</epp:objURI><epp:svcExtension><epp:extURI>urn:ietf:params:xml:ns:secDNS-1.1</epp:extURI><epp:extURI>http://co.za/epp/extensions/cozacontact-1-0</epp:extURI><epp:extURI>http://co.za/epp/extensions/cozadomain-1-0</epp:extURI><epp:extURI>urn:ietf:params:xml:ns:launch-1.0</epp:extURI><epp:extURI>http://www.unitedtld.com/epp/charge-1.0</epp:extURI></epp:svcExtension></epp:svcMenu><epp:dcp><epp:access><epp:personal xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xsd:string" /></epp:access><epp:statement><epp:purpose><epp:admin xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xsd:string" /></epp:purpose><epp:recipient><epp:same xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xsd:string" /></epp:recipient><epp:retention><epp:business xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xsd:string" /></epp:retention></epp:statement><epp:expiry><epp:relative>P365DT0H0M0S</epp:relative></epp:expiry></epp:dcp></epp:greeting></epp:epp>';

$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'DNS EPP Server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2017-05-25T13:29:41','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:contact-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','http://co.za/epp/extensions/cozacontact-1-0','http://co.za/epp/extensions/cozadomain-1-0','urn:ietf:params:xml:ns:launch-1.0','http://www.unitedtld.com/epp/charge-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','http://co.za/epp/extensions/cozacontact-1-0','http://co.za/epp/extensions/cozadomain-1-0','urn:ietf:params:xml:ns:launch-1.0','http://www.unitedtld.com/epp/charge-1.0'],'session noop get_data(session,server,extensions_selected)');


####################################################################################################
#### COZADOMAIN extension

$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0"><epp:response><epp:result code="1000"><epp:msg>Domain Info Command completed successfully</epp:msg></epp:result><epp:resData><domain:infData><domain:name>exampledomain.co.za</domain:name><domain:roid>DOM_26I-COZA</domain:roid><domain:status s="ok">Domain Creation</domain:status><domain:registrant>rant1</domain:registrant><domain:ns><domain:hostAttr><domain:hostName>ns1.otherdomain.co.za</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.otherdomain.co.za</domain:hostName></domain:hostAttr></domain:ns><domain:clID>testrar1</domain:clID><domain:crID>testrar1</domain:crID><domain:crDate>2011-01-19T09:16:10Z</domain:crDate><domain:upID>testrar1</domain:upID><domain:upDate>2011-01-19T09:16:10Z</domain:upDate><domain:exDate>2013-01-18T09:16:10Z</domain:exDate><domain:authInfo><domain:pw>coza</domain:pw></domain:authInfo></domain:infData></epp:resData><epp:extension><cozadomain:infData><cozadomain:autorenew>true</cozadomain:autorenew></cozadomain:infData></epp:extension><epp:trID><epp:clTRID>CLTRID-12954285819-DV2N</epp:clTRID><epp:svTRID>DNS-EPP-12D9D8F7A69-8E651</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc=$dri->domain_info('exampledomain.co.za');
is($rc->get_data('auto_renew'),1,'get_data auto_renew');

$R2='';
$rc=$dri->domain_update('exampledomain.co.za',$dri->local_object('changes')->set('auto_renew',0));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampledomain.co.za</domain:name></domain:update></update><extension><cozadomain:update xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozadomain-1-0 coza-domain-1.0.xsd"><cozadomain:chg><cozadomain:autorenew>false</cozadomain:autorenew></cozadomain:chg></cozadomain:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update auto_renew');

$R2='';
$rc=$dri->domain_update('exampledomain.co.za',$dri->local_object('changes')->set('cancel_action','PendingSuspension'));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exampledomain.co.za</domain:name></domain:update></update><extension><cozadomain:update xmlns:cozadomain="http://co.za/epp/extensions/cozadomain-1-0" xsi:schemaLocation="http://co.za/epp/extensions/cozadomain-1-0 coza-domain-1.0.xsd" cancelPendingAction="PendingSuspension"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update cancel_action');

####################################################################################################
#### COZACONTACT extension

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


####################################################################################################
# Price charge extension (https://www.registry.net.za/content2.php?wiki=1&contentid=155&title=Price+Charge+Extension)

# Domain check
# 3.1: Sunrise Response With Extension
$R2='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:response><epp:result code="1000"><epp:msg>Domain Check Command completed successfully</epp:msg></epp:result><epp:resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><domain:cd><domain:name avail="1">premium.joburg</domain:name><domain:reason>Domain reserved. Reason: Premium</domain:reason></domain:cd></domain:chkData></epp:resData><epp:extension><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><charge:cd><charge:name>premium.joburg</charge:name><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="transfer">100.0000</charge:amount><charge:amount command="create">100.0000</charge:amount><charge:amount command="renew">100.0000</charge:amount><charge:amount command="update" name="restore">100.0000</charge:amount></charge:set></charge:cd></charge:chkData></epp:extension><epp:trID><epp:svTRID>DNS-EPP-146F120B378-C0E40</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc = $dri->domain_check('premium.joburg');
is($rc->is_success(),1,'domain_check Sunrise is_success');
is($dri->get_info('action'),'check','domain_check get_info (Sunrise action)');
is($dri->get_info('exist'),0,'domain_check get_info (Sunrise exist)');
$ch1 = $dri->get_info('charge')->[0];
is($ch1->{type},'price','domain_check get_info (Sunrise charge type)');
is($ch1->{category},'premium','domain_check get_info (Sunrise charge category)');
is($ch1->{category_name},'AAAA','domain_check get_info (Sunrise charge category name)');
is($ch1->{transfer},'100.0000','domain_check get_info (Sunrise charge transfer)');
is($ch1->{create},'100.0000','domain_check get_info (Sunrise charge create)');
is($ch1->{renew},'100.0000','domain_check get_info (Sunrise charge renew)');
is($ch1->{restore},'100.0000','domain_check get_info (Sunrise charge restore)');
# 3.2: Landrush Response With Extension
$R2='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:response><epp:result code="1000"><epp:msg>Domain Check Command completed successfully</epp:msg></epp:result><epp:resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><domain:cd><domain:name avail="1">standard.joburg</domain:name></domain:cd></domain:chkData></epp:resData><epp:extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><launch:phase name="landrush">claims</launch:phase><launch:cd><launch:name exists="0">standard.joburg</launch:name></launch:cd></launch:chkData><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><charge:cd><charge:name>standard.joburg</charge:name><charge:set><charge:category>standard</charge:category><charge:type>price</charge:type><charge:amount command="transfer">100.0000</charge:amount><charge:amount command="create">100.0000</charge:amount><charge:amount command="renew">100.0000</charge:amount><charge:amount command="update" name="restore">100.0000</charge:amount></charge:set></charge:cd></charge:chkData></epp:extension><epp:trID><epp:svTRID>DNS-EPP-146F121B086-7AAB0</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc = $dri->domain_check('standard.joburg');
is($rc->is_success(),1,'domain_check Landrush is_success');
is($dri->get_info('action'),'check','domain_check get_info (Landrush action)');
is($dri->get_info('exist'),0,'domain_check get_info (Landrush exist)');
$ch1 = $dri->get_info('charge')->[0];
is($ch1->{type},'price','domain_check get_info (Landrush charge type)');
is($ch1->{category},'standard','domain_check get_info (Landrush charge category)');
is($ch1->{transfer},'100.0000','domain_check get_info (Landrush charge transfer)');
is($ch1->{create},'100.0000','domain_check get_info (Landrush charge create)');
is($ch1->{renew},'100.0000','domain_check get_info (Landrush charge renew)');
is($ch1->{restore},'100.0000','domain_check get_info (Landrush charge restore)');
# 3.3: General Abailability Response With Extension
$R2='<epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:response><epp:result code="1000"><epp:msg>Domain Check Command completed successfully</epp:msg></epp:result><epp:resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">exampledomain.joburg</domain:name></domain:cd></domain:chkData></epp:resData><epp:extension><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><charge:cd><charge:name>exampledomain.joburg</charge:name><charge:set><charge:category name="AAAA">standard</charge:category><charge:type>price</charge:type><charge:amount command="transfer">100.0000</charge:amount><charge:amount command="create">100.0000</charge:amount><charge:amount command="renew">100.0000</charge:amount><charge:amount command="update" name="restore">100.0000</charge:amount></charge:set></charge:cd></charge:chkData></epp:extension><epp:trID><epp:svTRID>DNS-EPP-13F292B5803-BF73J</epp:svTRID></epp:trID></epp:response></epp:epp>';
$rc = $dri->domain_check('exampledomain.joburg');
is($rc->is_success(),1,'domain_check GA is_success');
is($dri->get_info('action'),'check','domain_check get_info (GA action)');
is($dri->get_info('exist'),0,'domain_check get_info (GA exist)');
$ch1 = $dri->get_info('charge')->[0];
is($ch1->{type},'price','domain_check get_info (GA charge type)');
is($ch1->{category},'standard','domain_check get_info (GA charge category)');
is($ch1->{transfer},'100.0000','domain_check get_info (GA charge transfer)');
is($ch1->{create},'100.0000','domain_check get_info (GA charge create)');
is($ch1->{renew},'100.0000','domain_check get_info (GA charge renew)');
is($ch1->{restore},'100.0000','domain_check get_info (GA charge restore)');

# Domain info
# 4.1: Sunrise Response With Extension

# Domain create
# 5.1: Sunrise Response With Extension
$R2='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:response><epp:result code="1001"><epp:msg>Command completed successfully; validation pending</epp:msg></epp:result><epp:resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><domain:name>premium.joburg</domain:name><domain:crDate>2014-01-01T19:27:10Z</domain:crDate></domain:creData></epp:resData><epp:extension><charge:creData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="transfer">100.0000</charge:amount><charge:amount command="create">100.0000</charge:amount><charge:amount command="renew">100.0000</charge:amount><charge:amount command="update" name="restore">100.0000</charge:amount></charge:set></charge:creData><launch:creData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>0123456</launch:applicationID></launch:creData></epp:extension><epp:trID><epp:svTRID>DNS-EPP-146EE3EC6E4-A3F53</epp:svTRID></epp:trID></epp:response></epp:epp>';
$dh=$dri->local_object('hosts');
$dh->add('ns1.otherdomain.gtld');
$dh->add('ns2.otherdomain.gtld');
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('012345'),'registrant');
$cs->add($dri->local_object('contact')->srid('012345'),'admin');
$cs->add($dri->local_object('contact')->srid('012345'),'tech');
$cs->add($dri->local_object('contact')->srid('012345'),'billing');
$ch1=[{
  'category' => 'premium',
  'category_name' => 'AAAA',
  'type' => 'price',
  'create' => '123.56'}];
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
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $enc ] };
$rc=$dri->domain_create('premium.joburg',{pure_create=>1,duration=>DateTime::Duration->new(years=>3),contact=>$cs,ns=>$dh,auth=>{pw=>'2fooBAR'},lp=>$lp,'charge'=>$ch1});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.joburg</domain:name><domain:period unit="y">3</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.otherdomain.gtld</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.otherdomain.gtld</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>012345</domain:registrant><domain:contact type="admin">012345</domain:contact><domain:contact type="billing">012345</domain:contact><domain:contact type="tech">012345</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd"><launch:phase>sunrise</launch:phase>'.$enc.'</launch:create><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">123.56</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create Sunrise is_success');
is($dri->get_info('action'),'create','domain_create get_info (Sunrise action)');
#$ch1 = @{$dri->get_info('charge')};
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{create},'100.0000','domain_create get_info (Sunrise charge premium create)');
is($ch2->{category},'premium','domain_create get_info (Sunrise charge premium category)');
is($ch2->{transfer},'100.0000','domain_create get_info (Sunrise charge premium transfer)');
is($ch2->{renew},'100.0000','domain_create get_info (Sunrise charge premium renew)');
is($ch2->{restore},'100.0000','domain_create get_info (Sunrise charge premium restore)');
is($ch2->{category_name},'AAAA','domain_create get_info (Sunrise charge premium category_name)');
is($ch2->{type},'price','domain_create get_info (Sunrise charge premium type)');

# 5.2: Landrush Domain Create With Claims and Extension
$R2='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><epp:epp xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:response><epp:result code="1001"><epp:msg>Command completed successfully; validation pending</epp:msg></epp:result><epp:resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><domain:name>premium.joburg</domain:name><domain:crDate>2014-01-01T19:18:06Z</domain:crDate></domain:creData></epp:resData><epp:extension><charge:creData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><charge:set><charge:category>premium</charge:category><charge:type>price</charge:type><charge:amount command="transfer">100.0000</charge:amount><charge:amount command="create">100.0000</charge:amount><charge:amount command="renew">100.0000</charge:amount><charge:amount command="update" name="restore">100.0000</charge:amount></charge:set></charge:creData><launch:creData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><launch:phase name="landrush">claims</launch:phase><launch:applicationID>0123456</launch:applicationID></launch:creData></epp:extension><epp:trID><epp:svTRID>DNS-EPP-146EE3EC6E4-A3F53</epp:svTRID></epp:trID></epp:response></epp:epp>';
$dh=$dri->local_object('hosts');
$dh->add('ns1.premium.joburg',['194.194.10.10'],['ff02::1'],1);
$dh->add('ns1.otherdomain.gtld');
$lp = {phase => 'claims', sub_phase => 'landrush', type=>'application', notices => [ {validator_id=>'tmch', id=>'ABC4321','not_after_date'=>DateTime->new({year=>2014,month=>6,day=>1,hour=>10}),'accepted_date'=>DateTime->new({year=>2014,month=>5,day=>1,hour=>10,minute=>10}) } ]};
$rc=$dri->domain_create('premium.joburg',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'2fooBAR'},lp=>$lp,'charge'=>$ch1});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.joburg</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.premium.joburg</domain:hostName><domain:hostAddr ip="v4">194.194.10.10</domain:hostAddr><domain:hostAddr ip="v6">ff02::1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.otherdomain.gtld</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>012345</domain:registrant><domain:contact type="admin">012345</domain:contact><domain:contact type="billing">012345</domain:contact><domain:contact type="tech">012345</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><launch:create xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:launch-1.0 launch-1.0.xsd" type="application"><launch:phase name="landrush">claims</launch:phase><launch:notice><launch:noticeID validatorID="tmch">ABC4321</launch:noticeID><launch:notAfter>2014-06-01T10:00:00Z</launch:notAfter><launch:acceptedDate>2014-05-01T10:10:00Z</launch:acceptedDate></launch:notice></launch:create><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">123.56</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create Landrush is_success');
is($dri->get_info('action'),'create','domain_create get_info (Landrush action)');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{create},'100.0000','domain_create get_info (Landrush charge premium create)');
is($ch2->{category},'premium','domain_create get_info (Landrush charge premium category)');
is($ch2->{transfer},'100.0000','domain_create get_info (Landrush charge premium transfer)');
is($ch2->{renew},'100.0000','domain_create get_info (Landrush charge premium renew)');
is($ch2->{restore},'100.0000','domain_create get_info (Landrush charge premium restore)');
is($ch2->{type},'price','domain_create get_info (Landrush charge premium type)');
$lp = $dri->get_info('lp');
is($lp->{phase},'claims','domain_create get_info (lp phase)');
is($lp->{application_id},'0123456','domain_create get_info (lp application_id)');

exit 0;
