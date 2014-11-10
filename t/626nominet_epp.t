#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;
use Test::More tests => 170;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('Nominet');
$dri->target('Nominet')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co,$cs,$ns);


####################################################################################################
## Session Commands
# no-op
$R2 = $E1 . '<greeting><svID>Nominet EPP server testbed-epp.nominet.org.uk</svID><svDate>2013-02-20T13:07:10Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>http://www.nominet.org.uk/epp/xml/nom-abuse-feed-1.0</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-domain-2.0</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-domain-2.1</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-domain-2.2</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-dss-1.0</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-notifications-2.0</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-notifications-2.1</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-reseller-1.0</objURI><objURI>http://www.nominet.org.uk/epp/xml/nom-tag-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.1</extURI><extURI>http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-contact-id-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-fork-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-handshake-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-list-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-locks-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-notifications-1.2</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-notifications-1.1</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-notifications-1.2</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-release-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-unrenew-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-warning-1.1</extURI><extURI>http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/></recipient><retention><indefinite/></retention></statement></dcp></greeting>' . $E2;
$rc = $dri->process('session', 'noop', []);
is($R1, $E1 . '<hello/>' . $E2, 'session noop build (hello command)');
is($rc->is_success(), 1, 'session noop is_success');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:host-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_selected'),['http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0','http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2','http://www.nominet.org.uk/epp/xml/std-contact-id-1.0','http://www.nominet.org.uk/epp/xml/std-fork-1.0','http://www.nominet.org.uk/epp/xml/std-handshake-1.0','http://www.nominet.org.uk/epp/xml/std-list-1.0','http://www.nominet.org.uk/epp/xml/std-locks-1.0','http://www.nominet.org.uk/epp/xml/std-notifications-1.2','http://www.nominet.org.uk/epp/xml/std-release-1.0','http://www.nominet.org.uk/epp/xml/std-unrenew-1.0','http://www.nominet.org.uk/epp/xml/std-warning-1.1','http://www.nominet.org.uk/epp/xml/nom-abuse-feed-1.0','http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0','urn:ietf:params:xml:ns:secDNS-1.1'],'session noop get_data(session,server,extensions_selected)');

# login
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response>' . $E2;
$rc=$dri->process('session','login',['ClientX','foo-BAR2']);
is($rc->is_success(), 1, 'session login is_success');
is($R1,$E1 . '<command>' . '<login><clID>ClientX</clID><pw>foo-BAR2</pw><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-contact-id-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-fork-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-handshake-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-list-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-locks-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-notifications-1.2</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-release-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-unrenew-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/std-warning-1.1</extURI><extURI>http://www.nominet.org.uk/epp/xml/nom-abuse-feed-1.0</extURI><extURI>http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command></epp>','session login build_xml');

## Host Commands
# check
$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns2.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns2.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.com</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('exist'),1,'host_check get_info(exist)');

# info
$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.co.uk.</host:name><host:roid>123-UK</host:roid><host:status s="ok"/><host:addr ip="v4">111.22.33.44</host:addr><host:clID>NOMIQ</host:clID><host:crID>NOMIQ</host:crID><host:crDate>2013-02-21T13:49:36</host:crDate></host:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('ns2.example2.co.uk');
is($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.co.uk</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
$ns = $dri->get_info('self');
isa_ok($ns,'Net::DRI::Data::Hosts','host_info get_info(self)');
my ($nsname,$ips) = $ns->get_details(1);
is($nsname,'ns2.example2.co.uk','host_info get_info(name)');
is_deeply($ips,['111.22.33.44'],'host_info get_info(name)');


####################################################################################################
## Contact Commands
# info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CONT123</contact:id><contact:roid>123123123-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Tetname</contact:name><contact:org>Testorg</contact:org><contact:addr><contact:street>1 London Road</contact:street><contact:city>London</contact:city><contact:pc>SW1 1WS</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.207123123</contact:voice><contact:email>test@testdom.co.uk</contact:email><contact:clID>CLientX</contact:clID><contact:crID>EPP-NOMINET-1234</contact:crID><contact:crDate>2013-02-21T00:00:44</contact:crDate></contact:infData></resData><extension><contact-nom-ext:infData xmlns:contact-nom-ext="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0 contact-nom-ext-1.0.xsd"><contact-nom-ext:type>LTD</contact-nom-ext:type><contact-nom-ext:opt-out>N</contact-nom-ext:opt-out></contact-nom-ext:infData><warning:truncated-field field-name="contact:crID" xmlns:warning="http://www.nominet.org.uk/epp/xml/std-warning-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-warning-1.1 std-warning-1.1.xsd">Full entry is EPP-NOMINET-16823-1361453444484973.</warning:truncated-field><warning:truncated-field field-name="contact:clID" xmlns:warning="http://www.nominet.org.uk/epp/xml/std-warning-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-warning-1.1 std-warning-1.1.xsd">Full entry is EPP-NOMINET-16823-0000000000000000.</warning:truncated-field></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('CONT123'));
is($rc->is_success(), 1, 'contact_info is_success');
my $cn = $dri->get_info('self');
isa_ok($cn,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($cn->name(),'Tetname','contact_info (name)');
is($cn->type(),'LTD','contact_info (type)');

# create
my $c = $dri->local_object('contact')->srid('CONT1');
$c->name('Testname');
$c->org('Testorg');
$c->street(['1 London Road']);
$c->city('London');
$c->pc('SW1 1WS');
$c->cc('GB');
$c->voice('+44.20701020203');
$c->fax('+44.20701020206');
$c->email('testadmin@testdomain.co.uk');
$c->type('LTD');
$c->co_no('12344321');
$c->opt_out('N');
$c->trad_name('Awesome Stuff');
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response>' . $E2;
$rc = $dri->contact_create($c);
is($rc->is_success(), 1, 'contact create is_success');
is($R1,$E1 . '<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CONT1</contact:id><contact:postalInfo type="loc"><contact:name>Testname</contact:name><contact:org>Testorg</contact:org><contact:addr><contact:street>1 London Road</contact:street><contact:city>London</contact:city><contact:pc>SW1 1WS</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.20701020203</contact:voice><contact:fax>+44.20701020206</contact:fax><contact:email>testadmin@testdomain.co.uk</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><contact-nom-ext:create xmlns:contact-nom-ext="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0 contact-nom-ext-1.0.xsd"><contact-nom-ext:trad-name>Awesome Stuff</contact-nom-ext:trad-name><contact-nom-ext:type>LTD</contact-nom-ext:type><contact-nom-ext:co-no>12344321</contact-nom-ext:co-no><contact-nom-ext:opt-out>N</contact-nom-ext:opt-out></contact-nom-ext:create></extension>'.'<clTRID>ABC-12345</clTRID></command></epp>','contact create build_xml');

# update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response>' . $E2;
my $c2 = $dri->local_object('contact')->srid('CONT1');
$c2->name('Testname');
$c2->org('Testorg');
$c2->street(['1 London Road']);
$c2->city('London');
$c2->pc('SW9 9WS');
$c2->cc('GB');
$c2->voice('+44.20701020203');
$c2->fax('+44.20701020206');
$c2->email('testadmin@testdomain.co.uk');
$c2->type('LTD');
$c2->co_no('12344321');
$c2->opt_out('N');
$c2->trad_name('Still Awestome');

my $toc=$dri->local_object('changes');
$toc->set('info',$c2);
$rc=$dri->contact_update($c,$toc);
is($rc->is_success(), 1, 'contact update is_success');
is($R1,$E1 . '<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CONT1</contact:id><contact:chg><contact:postalInfo type="loc"><contact:name>Testname</contact:name><contact:org>Testorg</contact:org><contact:addr><contact:street>1 London Road</contact:street><contact:city>London</contact:city><contact:pc>SW9 9WS</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.20701020203</contact:voice><contact:fax>+44.20701020206</contact:fax><contact:email>testadmin@testdomain.co.uk</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:chg></contact:update></update><extension><contact-nom-ext:update xmlns:contact-nom-ext="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0 contact-nom-ext-1.0.xsd"><contact-nom-ext:trad-name>Still Awestome</contact-nom-ext:trad-name><contact-nom-ext:type>LTD</contact-nom-ext:type><contact-nom-ext:co-no>12344321</contact-nom-ext:co-no><contact-nom-ext:opt-out>N</contact-nom-ext:opt-out></contact-nom-ext:update></extension>'.'<clTRID>ABC-12345</clTRID></command></epp>','contact create build_xml');

# fork
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response>' . $E2;
$rc = $dri->contact_fork($c,{newContactId => 'CONT555', domains => ['testdom1.co.uk','testdom2.co.uk']});
is($rc->is_success(), 1, 'contact fork is_success');
is($R1,$E1 . '<command><update><f:fork xmlns:f="http://www.nominet.org.uk/epp/xml/std-fork-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-fork-1.0 std-fork-1.0.xsd"><f:contactID>CONT1</f:contactID><f:newContactId>CONT555</f:newContactId><f:domainName>testdom1.co.uk</f:domainName><f:domainName>testdom2.co.uk</f:domainName></f:fork></update><clTRID>ABC-12345</clTRID></command></epp>','contact fork build_xml');

#lock (whois_optout)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->contact_lock($dri->local_object('contact')->srid('CONT1'),{type=> 'opt-out'});
is($rc->is_success(),1,'contact_lock is_success');
is_string($R1,$E1.'<command><update><l:lock xmlns:l="http://www.nominet.org.uk/epp/xml/std-locks-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-locks-1.0 std-locks-1.0.xsd" object="contact" type="opt-out"><l:contactId>CONT1</l:contactId></l:lock></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_lock build xml');

####################################################################################################
## Domain Commands
# check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="0">example.co.uk</domain:name></domain:cd><domain:cd><domain:name avail="1">example2.co.uk</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.co.uk','example2.co.uk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:name>example2.co.uk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example.co.uk'),1,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.co.uk'),0,'domain_check multi get_info(exist) 2/2');

# info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name><domain:roid>123453-UK</domain:roid><domain:registrant>CONT123</domain:registrant><domain:clID>ClientX</domain:clID><domain:crID>EPP-NOMINET-2000</domain:crID><domain:crDate>2013-02-21T13:48:58</domain:crDate><domain:exDate>2014-02-21T13:48:58</domain:exDate></domain:infData></resData><extension><domain-nom-ext:infData xmlns:domain-nom-ext="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2 domain-nom-ext-1.2.xsd"><domain-nom-ext:reg-status>Registered until expiry date.</domain-nom-ext:reg-status></domain-nom-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('testdom1.co.uk');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">testdom1.co.uk</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build xml');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('reg-status'),'Registered until expiry date.','domain_info get_info(reg-status)');

# create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name><domain:crDate>2013-02-21T13:48:58</domain:crDate><domain:exDate>2014-02-21T13:48:58</domain:exDate></domain:creData></resData><extension><warning:ignored-field field-name="domain:authInfo" xmlns:warning="http://www.nominet.org.uk/epp/xml/std-warning-1.1" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-warning-1.1 std-warning-1.1.xsd">Field \'authInfo\' found; this field has been ignored.</warning:ignored-field></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset')->add($dri->local_object('contact')->srid('CONT123'),'registrant');
$ns=$dri->local_object('hosts')->add('ns0.whatever.co.uk',['1.2.3.4']);
$rc=$dri->domain_create('testdom1.co.uk', {
    pure_create=>1,
    duration=>DateTime::Duration->new(years=>1),
    ns=>$dh,
    contact=>$cs,
    'recur-bill'=>'bc',
    'auto-period'=>'3',
  });
is($rc->is_success(),1,'domain_create is_success');
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name><domain:period unit="y">1</domain:period><domain:registrant>CONT123</domain:registrant><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><domain-nom-ext:create xmlns:domain-nom-ext="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2 domain-nom-ext-1.2.xsd"><domain-nom-ext:recur-bill>bc</domain-nom-ext:recur-bill><domain-nom-ext:auto-period>3</domain-nom-ext:auto-period></domain-nom-ext:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build xml');

# update
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$toc->set('renew-not-required','n');
$toc->set('auto-bill',0);
$toc->set('registrant',$dri->local_object('contact')->srid('CONT987'),'registrant');
$rc=$dri->domain_update('testdom1.co.uk', $toc);
is($rc->is_success(),1,'domain_update is_success');
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name><domain:chg><domain:registrant>CONT987</domain:registrant></domain:chg></domain:update></update><extension><domain-nom-ext:update xmlns:domain-nom-ext="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/domain-nom-ext-1.2 domain-nom-ext-1.2.xsd"><domain-nom-ext:auto-bill>0</domain-nom-ext:auto-bill><domain-nom-ext:renew-not-required>N</domain-nom-ext:renew-not-required></domain-nom-ext:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build xml');

# delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdom1.co.uk', {pure_delete=>1});
is($rc->is_success(),1,'domain_delete is_success');
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build xml');

# unrenew
$R2=$E1.'<response>'.r(). '<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdom1.co.uk</domain:name><domain:exDate>2013-01-02T11:56:40</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_unrenew('testdom1.co.uk');
is($rc->is_success(),1,'domain_unrenew is_success');
is_string($R1,$E1.'<command><update><u:unrenew xmlns:u="http://www.nominet.org.uk/epp/xml/std-unrenew-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-unrenew-1.0 std-unrenew-1.0.xsd"><u:domainName>testdom1.co.uk</u:domainName></u:unrenew></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_unrenew build xml');
is($dri->get_info('exDate'),'2013-01-02T11:56:40','domain_unrenew get_info(exDate)');

# list
$R2=$E1.'<response>'.r().'<resData><list:listData xmlns:list="http://www.nominet.org.uk/epp/xml/std-list-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-list-1.0 std-list-1.0.xsd" noDomains="2"><list:domainName>test1.co.uk</list:domainName><list:domainName>test2.co.uk</list:domainName></list:listData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_list({regMonth => new DateTime({year => 2012, month=>12})});
is($rc->is_success(),1,'domain_list is_success');
is_string($R1,$E1.'<command><info><l:list xmlns:l="http://www.nominet.org.uk/epp/xml/std-list-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-list-1.0 std-list-1.0.xsd"><l:month>2012-12</l:month></l:list></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_list build xml');
is($dri->get_info('total','domain_list',0),2,'domain_list get_info (domain_list_total)');
is_deeply($dri->get_info('domains','domain_list',0),['test1.co.uk','test2.co.uk'],'domain_list get_info (domain_list_domains)');

#lock - investigation
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_lock('testdom1.co.uk', {type=> 'investigation'});
is($rc->is_success(),1,'domain_lock is_success');
is_string($R1,$E1.'<command><update><l:lock xmlns:l="http://www.nominet.org.uk/epp/xml/std-locks-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-locks-1.0 std-locks-1.0.xsd" object="domain" type="investigation"><l:domainName>testdom1.co.uk</l:domainName></l:lock></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_lock build xml');

# transfer_start (release a single domain)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('testdom1.co.uk', {registrar_tag => 'NewTAG'});
is($rc->is_success(),1,'domain_release is_success');
is_string($R1,$E1.'<command><update><r:release xmlns:r="http://www.nominet.org.uk/epp/xml/std-release-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-release-1.0 std-release-1.0.xsd"><r:domainName>testdom1.co.uk</r:domainName><r:registrarTag>NewTAG</r:registrarTag></r:release></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_release build xml');

# transfer_start (release account with all domains)
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></trID></response>' . $E2;
$rc = $dri->domain_transfer_start('alldomains.co.uk',{registrar_tag => 'NewTAG','account_id' => 'CONT1'});
is($rc->is_success(), 1, 'account release is_success');
is($R1,$E1 . '<command><update><r:release xmlns:r="http://www.nominet.org.uk/epp/xml/std-release-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-release-1.0 std-release-1.0.xsd"><r:registrant>CONT1</r:registrant><r:registrarTag>NewTAG</r:registrarTag></r:release></update><clTRID>ABC-12345</clTRID></command></epp>','account release build_xml');

## For the next two, The domain is ignored as the case_id is used, however it must be set to something that looks real to avoid validation failure
# transfer_accept (handshake_accept)
$R2=$E1.'<response>'.r().'<resData><h:hanData xmlns:h="http://www.nominet.org.uk/epp/xml/std-handshake-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-handshake-1.0 std-handshake-1.0.xsd"><h:caseId>6</h:caseId><h:domainListData noDomains="2"><h:domainName>example1.co.uk</h:domainName><h:domainName>example2.co.uk</h:domainName></h:domainListData></h:hanData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_accept('null.co.uk', {case_id => '665544', registrant=> 'CONT123'});
is($rc->is_success(),1,'handshake_accept is_success');
is_string($R1,$E1.'<command><update><h:accept xmlns:h="http://www.nominet.org.uk/epp/xml/std-handshake-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-handshake-1.0 std-handshake-1.0.xsd"><h:caseId>665544</h:caseId><h:registrant>CONT123</h:registrant></h:accept></update><clTRID>ABC-12345</clTRID></command>'.$E2,'handshake_accept build xml');
is($dri->get_info('total','domain_list',0),2,'handshake_accept get_info (domain_list_total)');
is_deeply($dri->get_info('domains','domain_list',0),['example1.co.uk','example2.co.uk'],'handshake_accept get_info (domain_list_domains)');

# transfer_refuse (handshake_reject)
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_refuse('null.co.uk', {case_id => '665544'});
is($rc->is_success(),1,'handshake_reject is_success');
is_string($R1,$E1.'<command><update><h:reject xmlns:h="http://www.nominet.org.uk/epp/xml/std-handshake-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-handshake-1.0 std-handshake-1.0.xsd"><h:caseId>665544</h:caseId></h:reject></update><clTRID>ABC-12345</clTRID></command>'.$E2,'handshake_reject build xml');

# check - rights with no options
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example.uk</domain:name></domain:cd></domain:chkData></resData><extension><nom-direct-rights:chkData xmlns:nom-direct-rights="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0 nom-direct-rights-1.0.xsd"><nom-direct-rights:ror>example.sld.uk</nom-direct-rights:ror></nom-direct-rights:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.uk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.uk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check rights build');
is($rc->is_success(),1,'domain_check rights is_success');
is($dri->get_info('exist'),0,'domain_check rights get_info(exist)');
is($dri->get_info('right'),'example.sld.uk','domain_check rights get_info(right)');

# check - rights with regitrant id: use 'registrant' => '123123' as string, or contact object with only SRID
$c = $dri->local_object('contact')->srid('CONT1'); # empty contact object with srid
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example2.uk</domain:name></domain:cd></domain:chkData></resData><extension><nom-direct-rights:chkData xmlns:nom-direct-rights="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0 nom-direct-rights-1.0.xsd"><nom-direct-rights:ror>example2.sld.uk</nom-direct-rights:ror></nom-direct-rights:chkData></extension>'.$TRID.'</response>'.$E2;
#$rc=$dri->domain_check('example2.uk',{registrant => $c}); 
$rc=$dri->domain_check('example2.uk',{registrant => 'CONT1'}); 
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.uk</domain:name></domain:check></check><extension><nom-direct-rights:check xmlns:nom-direct-rights="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0 nom-direct-rights-1.0.xsd" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><nom-direct-rights:registrant>CONT1</nom-direct-rights:registrant></nom-direct-rights:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check rights build');
is($rc->is_success(),1,'domain_check rights is_success');
is($dri->get_info('exist'),0,'domain_check rights get_info(exist)');
is($dri->get_info('right'),'example2.sld.uk','domain_check rights get_info(right)');

# check - rights with postalinfo (no srid)
$c = $dri->local_object('contact')->name('Contact name')->org('Org name')->street(['10 Example Street'])->city('Oxford')->sp('Oxfordshire')->pc('OX4 4DQ')->cc('GB')->email('john.smith@example.uk');
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.uk</domain:name></domain:cd></domain:chkData></resData><extension><nom-direct-rights:chkData xmlns:nom-direct-rights="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0 nom-direct-rights-1.0.xsd"><nom-direct-rights:ror>example3.sld.uk</nom-direct-rights:ror></nom-direct-rights:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.uk',{registrant => $c}); 
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.uk</domain:name></domain:check></check><extension><nom-direct-rights:check xmlns:nom-direct-rights="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-direct-rights-1.0 nom-direct-rights-1.0.xsd" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><nom-direct-rights:postalInfo type="loc"><contact:name>Contact name</contact:name><contact:org>Org name</contact:org><contact:addr><contact:street>10 Example Street</contact:street><contact:city>Oxford</contact:city><contact:sp>Oxfordshire</contact:sp><contact:pc>OX4 4DQ</contact:pc><contact:cc>GB</contact:cc></contact:addr></nom-direct-rights:postalInfo><nom-direct-rights:email>john.smith@example.uk</nom-direct-rights:email></nom-direct-rights:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check rights build');
is($rc->is_success(),1,'domain_check rights is_success');
is($dri->get_info('exist'),0,'domain_check rights get_info(exist)');
is($dri->get_info('right'),'example3.sld.uk','domain_check rights get_info(right)');


####################################################################################################
## Reseller Commands

## FIXME, not yet implemented

####################################################################################################
## Notifications

# delete / ack
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_delete('12345');
is($rc->is_success(),1,'message_delete is_success');
is_string($R1,$E1.'<command><poll msgID="12345" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_delete build xml');

#  abuse 
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123456"><qDate>2007-09-26T07:31:30</qDate><msg>Domain Activity Notification</msg></msgQ><resData><abuse-feed:infData xmlns:abuse-feed="http://www.nominet.org.uk/epp/xml/nom-abuse-feed-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-abuse-feed-1.0 nom-abuse-feed-1.0.xsd"><abuse-feed:key>phished.co.uk</abuse-feed:key><abuse-feed:activity>phishing</abuse-feed:activity><abuse-feed:source>Netcraft</abuse-feed:source><abuse-feed:hostname>www.youve.been.phished.co.uk</abuse-feed:hostname><abuse-feed:url>http://www.youve.been.phished.co.uk/give/us/your/money.htm</abuse-feed:url><abuse-feed:date>2011-03-01T11:44:01</abuse-feed:date><abuse-feed:ip>213.135.134.24</abuse-feed:ip><abuse-feed:nameserver>ns0.crooked.dealings.net</abuse-feed:nameserver><abuse-feed:dnsAdmin>hostmaster@crooked.dealings.net</abuse-feed:dnsAdmin><abuse-feed:target>paypal</abuse-feed:target><abuse-feed:wholeDomain>Y</abuse-feed:wholeDomain></abuse-feed:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (abuse)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'abuse','message get_info(action)');
is($dri->get_info('target','message',123456),'paypal','message get_info(orig)');

# ammed account details
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2005-10-06T10:29:30Z</qDate><msg>Account Details Change Notification</msg></msgQ><resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd">2<contact:id>CMyContactID</contact:id><contact:roid>548965487-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mr Jones</contact:name><contact:org>Company.</contact:org><contact:addr><contact:street>High Street</contact:street><contact:city>Oxford</contact:city><contact:pc>OX1 1AH</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865658754</contact:voice><contact:email>example@epp-example.org.uk</contact:email><contact:clID>EXAMPLE-TAG</contact:clID><contact:crID>n/a</contact:crID><contact:crDate>2007-05-12T12:44:00Z</contact:crDate><contact:upDate>2008-06-12T06:46:00Z</contact:upDate></contact:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (info)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'info','message get_info(action)');
$cn = $dri->get_info('self','message',123456);
isa_ok($cn,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($cn->name(),'Mr Jones','message get_info(name)');

# hosts cancelled
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="123456"><qDate>2008-04-30T13:39:13Z</qDate><msg>Host cancellation notification</msg></msgQ><resData><n:hostCancData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:hostListData noHosts="2"><n:hostObj>ns0.example.co.uk.</n:hostObj><n:hostObj>ns1.example.co.uk.</n:hostObj></n:hostListData><n:domainListData noDomains="2"><n:domainName>example-a.co.uk</n:domainName><n:domainName>example-b.co.uk</n:domainName></n:domainListData></n:hostCancData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (hosts_cancelled)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'hosts_cancelled','message get_info(action)');
is_deeply($dri->get_info('domains','message',123456),[qw/example-a.co.uk example-b.co.uk/],'message get_info(domains)');
is_deeply($dri->get_info('hosts','message',123456),[qw/ns0.example.co.uk ns1.example.co.uk/],'message get_info(hosts)');

# domain cancelled
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123456"><qDate>2007-09-26T07:31:30</qDate><msg>Domain name Cancellation Notification</msg></msgQ><resData><n:cancData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:domainName>epp-example1.co.uk</n:domainName>3<n:orig>example@nominet</n:orig></n:cancData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (domain_cancelled)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('object_type','message','123456'),'domain','message get_info(object_type)');
is($dri->get_info('object_id','message','123456'),'epp-example1.co.uk','message get_info(object_id)');
is($dri->get_info('action','domain','epp-example1.co.uk'),'cancelled','message get_info(action)');
is($dri->get_info('orig','domain','epp-example1.co.uk'),'example@nominet','message get_info(cancelled_orig)');

# domain suspended
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="2" id="123456"><qDate>2008-04-30T13:39:13Z</qDate><msg>Domains Suspended Notification</msg></msgQ><resData><n:suspData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:reason>Data Quality</n:reason><n:cancelDate>2009-12-12T00:00:13Z</n:cancelDate><n:domainListData noDomains="2"><n:domainName>epp-example1.co.uk</n:domainName><n:domainName>epp-example2.co.uk</n:domainName></n:domainListData></n:suspData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (domain_suspended)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'domains_suspended','message get_info(action)');
is($dri->get_info('reason','message',123456),'Data Quality','message get_info(reason)');
is($dri->get_info('cancel_date','message',123456),'2009-12-12T00:00:13','message get_info(cancelDate)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

# referral_reject
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Referral Rejected Notification</msg></msgQ><resData><n:domainFailData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:domainName>epp-example2.ltd.uk</n:domainName><n:reason>V205 Registrant does not match domain name</n:reason></n:domainFailData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (referral_reject)');
is($dri->get_info('last_id'),12345,'message get_info last_id');
is($dri->get_info('last_id','message','session'),12345,'message get_info last_id 2');
is($dri->get_info('id','message',12345),12345,'message get_info id');
is(''.$dri->get_info('qdate','message',12345),'2007-09-26T07:31:30','message get_info qdate');
is($dri->get_info('content','message',12345),'Referral Rejected Notification','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('object_type','message','12345'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','12345'),'epp-example2.ltd.uk','message get_info id');
is($dri->get_info('action','message','12345'),'fail','message get_info action'); ## with this, we know what action has triggered this delayed message
is($dri->get_info('exist','domain','epp-example2.ltd.uk'),0,'message get_info(exist,domain,DOM)');
is($dri->get_info('reason','domain','epp-example2.ltd.uk'),'V205 Registrant does not match domain name','message get_info(reason,domain,DOM)');

# referral_accept
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123456"><qDate>2007-09-26T07:31:30</qDate><msg>Referral Accepted Notification</msg></msgQ><resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epp-example1.ltd.uk</domain:name><domain:crDate>2007-09-25T11:30:45</domain:crDate><domain:exDate>2009-09-25T11:30:45</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (referral_accept)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('object_type','message','123456'),'domain','message get_info(object_type)');
is($dri->get_info('object_id','message','123456'),'epp-example1.ltd.uk','message get_info(object_id)');
is($dri->get_info('action','domain','epp-example1.ltd.uk'),'create','message get_info(action)');

# handshake request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Registrar Change Authorisation Request</msg></msgQ><resData><n:rcData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:orig>p@epp-example.org.uk</n:orig><n:registrarTag>EXAMPLE</n:registrarTag><n:caseId>3560</n:caseId><n:domainListData noDomains="2" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:infData><domain:name>epp-example1.co.uk</domain:name><domain:roid>57486578-UK</domain:roid><domain:registrant>1245435</domain:registrant><domain:ns><domain:hostObj>ns0.epp-example.co.uk</domain:hostObj></domain:ns><domain:host>ns0.epp-example1.co.uk</domain:host>6<domain:host>ns0.epp-example1.co.uk</domain:host><domain:clID>EPP-EXAMPLE2</domain:clID></domain:infData><domain:infData><domain:name>epp-example2.co.uk</domain:name><domain:roid>57486578-UK</domain:roid><domain:registrant>1245435</domain:registrant><domain:ns><domain:hostObj>ns0.epp-example.co.uk</domain:hostObj></domain:ns><domain:clID>EPP-EXAMPLE2</domain:clID></domain:infData></n:domainListData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>CMyContactID</contact:id><contact:roid>548965487-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mr Jones</contact:name><contact:org>Company.</contact:org><contact:addr><contact:street>High Street</contact:street><contact:city>Oxford</contact:city><contact:pc>OX1 1AH</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865658754</contact:voice><contact:email>example@epp-example.org.uk</contact:email><contact:clID>EXAMPLE-TAG</contact:clID><contact:crID>n/a</contact:crID><contact:crDate>2007-05-12T12:44:00Z</contact:crDate><contact:upDate>2008-06-12T06:46:00Z</contact:upDate></contact:infData></n:rcData></resData><extension><contact-nom-ext:infData xmlns:contact-nom-ext="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/contact-nom-ext-1.0 contact-nom-ext-1.0.xsd"><contact-nom-ext:type>UNKNOWN</contact-nom-ext:type><contact-nom-ext:opt-out>N</contact-nom-ext:opt-out></contact-nom-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (handshake_request)');
is($dri->get_info('last_id'),12345,'message get_info(last_id)');
is($dri->get_info('action','message',12345),'handshake_request','message get_info(action)');
is($dri->get_info('orig','message',12345),'p@epp-example.org.uk','message get_info(orig)');
is($dri->get_info('registrar_to','message',12345),'EXAMPLE','message get_info(registrar_to)');
is($dri->get_info('registrar_from','message',12345),'EPP-EXAMPLE2','message get_info(registrar_from)');
is($dri->get_info('contact','message',12345),'CMyContactID','message get_info(contact)');
is($dri->get_info('case_id','message',12345),'3560','message get_info(case_id)');
is_deeply($dri->get_info('domains','message',12345),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

# registrar_change
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2005-10-06T10:29:30Z</qDate><msg>Registrar Change Notification</msg></msgQ><resData><n:rcData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:orig>p@automaton-example.org.uk</n:orig><n:registrarTag>EXAMPLE</n:registrarTag><n:domainListData noDomains="2" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:infData><domain:name>auto-example1.co.uk</domain:name><domain:roid>65876854-UK</domain:roid><domain:ns><domain:hostObj>ns0.epp-example.co.uk</domain:hostObj><domain:hostObj>ns1.epp-example.co.uk</domain:hostObj></domain:ns><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-exam</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:infData><domain:infData><domain:name>epp-example2.co.uk</domain:name><domain:roid>568957896-UK</domain:roid><domain:clID>EXAMPLE-TAG</domain:clID><domain:crID>example@epp-exa</domain:crID><domain:crDate>2005-06-03T12:00:00</domain:crDate><domain:exDate>2007-06-03T12:00:00</domain:exDate></domain:infData></n:domainListData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>ST96503FG</contact:id><contact:roid>5876578-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mr R Strant</contact:name><contact:org>reg company</contact:org><contact:addr><contact:street>2102 High Street</contact:street><contact:city>Oxford</contact:city><contact:sp>Oxon</contact:sp><contact:pc>OX1 1QQ</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865123456</contact:voice><contact:email>r.strant@epp-example.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@epp-exam</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></n:rcData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (registrar_change)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'registrar_change','message get_info(action)');
is($dri->get_info('orig','message',123456),'p@automaton-example.org.uk','message get_info(orig)');
is($dri->get_info('registrar_to','message',123456),'EXAMPLE','message get_info(registrar_to)');
is_deeply($dri->get_info('domains','message',123456),[qw/auto-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');
$co = $dri->get_info('contact_data','message',123456);
isa_ok($co,'Net::DRI::Data::Contact','message get_info(contact_data)');
is($co->srid(),'ST96503FG','message get_info(contact_data srid)');

# registrant change auth request
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2007-10-06T10:29:30Z</qDate><msg>Registrant Transfer Authorisation Request</msg></msgQ><resData><n:trnAuthData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:orig>p@automaton-example.org.uk</n:orig><n:caseId>3560</n:caseId><n:domainListData noDomains="2" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><n:domainName>epp-example1.co.uk</n:domainName><n:domainName>epp-example2.co.uk</n:domainName></n:domainListData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>ST68956589R4</contact:id><contact:roid>123456-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mr R. Strant</contact:name><contact:addr><contact:street>2102 High Street</contact:street><contact:city>Oxford</contact:city><contact:sp>Oxon</contact:sp><contact:pc>OX1 1QQ</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:email>example@epp-example1.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>TEST</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></n:trnAuthData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (registrant_change)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'registrant_change_auth_request','message get_info(action)');
is($dri->get_info('case_id','message',123456),'3560','message get_info(case_id)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

# registrant change 
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="4" id="123456"><qDate>2007-10-06T10:29:30Z</qDate><msg>Registrant Transfer Notification</msg></msgQ><resData><n:trnData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:orig>p@automaton-example.org.uk</n:orig><n:accountId>58658458</n:accountId>12<n:oldAccountId>596859</n:oldAccountId><n:domainListData noDomains="2" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><n:domainName>epp-example1.co.uk</n:domainName><n:domainName>epp-example2.co.uk</n:domainName></n:domainListData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>ST68956589R4</contact:id><contact:roid>123456-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Mr R. Strant</contact:name><contact:addr><contact:street>2102 High Street</contact:street><contact:city>Oxford</contact:city><contact:sp>Oxon</contact:sp><contact:pc>OX1 1QQ</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:email>example@epp-example1.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>TEST</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></n:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (registrant_change)');
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'registrant_change','message get_info(action)');
is($dri->get_info('account_from','message',123456),'596859','message get_info(account_from)');
is($dri->get_info('account_to','message',123456),'58658458','message get_info(account_to)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk epp-example2.co.uk/],'message get_info(domains)');

# domains released
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Domains Released Notification</msg></msgQ><resData><n:relData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:accountId moved="Y">12345</n:accountId><n:from>EXAMPLE1-TAG</n:from><n:registrarTag>EXAMPLE2-TAG</n:registrarTag><n:domainListData noDomains="6"><n:domainName>epp-example1.co.uk</n:domainName><n:domainName>epp-example2.co.uk</n:domainName><n:domainName>epp-example3.co.uk</n:domainName><n:domainName>epp-example4.co.uk</n:domainName><n:domainName>epp-example5.co.uk</n:domainName>4<n:domainName>epp-example6.co.uk</n:domainName></n:domainListData></n:relData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (domains_released)');
is($dri->get_info('last_id'),12345,'message get_info(last_id)');
is($dri->get_info('action','message',12345),'domains_released','message get_info(action)');
is($dri->get_info('account_id','message',12345),'12345','message get_info(account_id)');
is($dri->get_info('account_moved','message',12345),1,'message get_info(account_moved)');
is($dri->get_info('registrar_from','message',12345),'EXAMPLE1-TAG','message get_info(registrar_from)');
is($dri->get_info('registrar_to','message',12345),'EXAMPLE2-TAG','message get_info(registrar_to)');
is_deeply($dri->get_info('domains','message',12345),[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk epp-example4.co.uk epp-example5.co.uk epp-example6.co.uk/],'message get_info(domains)');

# handkshake rejected
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="12345"><qDate>2007-09-26T07:31:30</qDate><msg>Registrar Change Handshake Rejected Notification</msg></msgQ><resData><n:relData xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><n:accountId>1243654</n:accountId><n:from>EXAMPLE1-TAG</n:from><n:registrarTag>EXAMPLE2-TAG</n:registrarTag><n:domainListData noDomains="5"><n:domainName>epp-example1.co.uk</n:domainName><n:domainName>epp-example2.co.uk</n:domainName><n:domainName>epp-example3.co.uk</n:domainName><n:domainName>epp-example4.co.uk</n:domainName><n:domainName>epp-example5.co.uk</n:domainName><n:domainName>epp-example6.co.uk</n:domainName></n:domainListData></n:relData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($rc->is_success(),1,'message_retrieve is_success (handshake_rejected)');
is($dri->get_info('last_id'),12345,'message get_info(last_id)');
is($dri->get_info('action','message',12345),'handshake_rejected','message get_info(action)');
is($dri->get_info('registrar_from','message',12345),'EXAMPLE1-TAG','message get_info(registrar_from)');
is($dri->get_info('registrar_to','message',12345),'EXAMPLE2-TAG','message get_info(registrar_to)');
is_deeply($dri->get_info('domains','message',12345),[qw/epp-example1.co.uk epp-example2.co.uk epp-example3.co.uk epp-example4.co.uk epp-example5.co.uk epp-example6.co.uk/],'message get_info(domains)');

#Data Quality Workflow Process
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="123456"><qDate>2012-09-05T11:00:39Z</qDate><msg>DQ Workflow process commenced notification</msg></msgQ><resData><n:processData stage="initial" xmlns:n="http://www.nominet.org.uk/epp/xml/std-notifications-1.2" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/std-notifications-1.2 std-notifications-1.2.xsd"><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>E2CD4B4D83DB0857</contact:id><contact:roid>100590-UK</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>contact 32</contact:name><contact:org>account-name 32</contact:org><contact:addr><contact:street>street 32</contact:street><contact:city>city x</contact:city><contact:sp>n/a</contact:sp><contact:pc>NW32 1ZZ</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:email>email 32</contact:email><contact:clID>TEST</contact:clID><contact:crID>test@automaton</contact:crID><contact:crDate>2009-08-06T17:52:21</contact:crDate><contact:upID>test@automaton</contact:upID><contact:upDate>2012-09-04T11:04:40</contact:upDate></contact:infData><n:processType>DQ Workflow</n:processType><n:suspendDate>2012-09-26T10:59:11</n:suspendDate><n:cancelDate>2012-10-17T10:59:15</n:cancelDate><n:domainListData noDomains="1"><n:domainName>epp-example1.co.uk</n:domainName></n:domainListData></n:processData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),123456,'message get_info(last_id)');
is($dri->get_info('action','message',123456),'poor_quality','message get_info(action)');
is($dri->get_info('poor_quality_stage','message',123456),'initial','message get_info(poor_quality_stage)');
is($dri->get_info('poor_quality_suspend','message',123456),'2012-09-26T10:59:11','message get_info(poor_quality_suspend)');
is($dri->get_info('poor_quality_cancel','message',123456),'2012-10-17T10:59:15','message get_info(poor_quality_cancel)');
is_deeply($dri->get_info('domains','message',123456),[qw/epp-example1.co.uk/],'message get_info(domains)');
is($dri->get_info('contact','message',123456),'E2CD4B4D83DB0857','message get_info(contact id)');
$co=$dri->get_info('poor_quality_account','message',123456);
isa_ok($co,'Net::DRI::Data::Contact','message get_info(poor_quality_account)');
is($co->srid(),'E2CD4B4D83DB0857','message get_info (account roid)');
is($co->roid(),'100590-UK','message get_info (account roid)');
is($co->name(),'contact 32','message get_info (account name)');


exit 0;
