#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 32;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my ($rc,$toc);

#########################################################################################################

## Extension: NSGroup

########################################################################################################
## DNSBE uses version 1.0, while Eurid uses 1.1 (with their own namespace declarations)
## So we test both versions here. 1.1 is at the bottom!
my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'clientref-123007'}});
$dri->add_registry('DNSBelgium::BE');
$dri->target('DNSBelgium::BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1543</svTRID></trID></response></epp>';
my $c1=$dri->local_object('hosts');
$c1->name('mynsgroup1');
$c1->add('ns1.nameserver.be');
$c1->add('ns2.nameserver.be');
$rc=$dri->nsgroup_create($c1);
is($R1,$E1.'<command><create><nsgroup:create xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns></nsgroup:create></create><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 create build');
is($rc->is_success(),1,'nsgroup-1.0 create is_success');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
my $c2=$dri->local_object('hosts');
$c2->name('mynsgroup1');
$c2->add('ns1.nameserver.be');
$c2->add('ns2.nameserver.be');
$c2->add('ns3.nameserver.be');
$toc=$dri->local_object('changes');
$toc->set('ns',$c2);
$rc=$dri->nsgroup_update($c1,$toc);
is($R1,$E1.'<command><update><nsgroup:update xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns><nsgroup:ns>ns3.nameserver.be</nsgroup:ns></nsgroup:update></update><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 update build');
is($rc->is_success(),1,'nsgroup-1.0 update is_success');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_delete($c1);
is($R1,$E1.'<command><delete><nsgroup:delete xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name></nsgroup:delete></delete><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 delete build');
is($rc->is_success(),1,'nsgroup-1.0 delete is_success');



$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="0">mynsgroup1</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">mynsgroup2</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_check('mynsgroup1','mynsgroup2');
is($R1,$E1.'<command><check><nsgroup:check xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:name>mynsgroup2</nsgroup:name></nsgroup:check></check><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 check_multi is_success');
is($rc->is_success(),1,'nsgroup-1.0 check_multi is_success');
is($dri->get_info('exist','nsgroup','mynsgroup1'),1,'nsgroup-1.0 check_multi get_info(exist) 1/2');
is($dri->get_info('exist','nsgroup','mynsgroup2'),0,'nsgroup-1.0 check_multi get_info(exist) 2/2');
is($dri->get_info('action','nsgroup','mynsgroup1'),'check','nsgroup-1.0 check_multi get_info(action) 1/2');
is($dri->get_info('action','nsgroup','mynsgroup2'),'check','nsgroup-1.0 check_multi get_info(action) 2/2');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:infData><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns></nsgroup:infData></resData><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_info($c1);
is($R1,$E1.'<command><info><nsgroup:info xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name></nsgroup:info></info><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 info build');
is($rc->is_success(),1,'nsgroup-1.0 info is_success');
is_deeply($dri->get_info('self'),$c1,'nsgroup-1.0 info get_info(self)');
is($dri->get_info('action'),'info','nsgroup-1.0 info get_info(action)');
is($dri->get_info('exist'),1,'nsgroup-1.0 info get_info(exist)');
is($dri->get_info('exist','nsgroup','mynsgroup1'),1,'nsgroup-1.0 info get_info(exist) +cache');




########################################################################################################
## DNSBE uses version 1.0, while Eurid uses 1.1 (with their own namespace declarations)
## 1.0 is at the top, this is 1.1
$TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

## Process greetings to select namespace versions
# We need secDNS and domain-ext to select correct versions in the test file
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2016-11-17T14:30:12.230Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarFinance-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarHitPoints-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrationLimit-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.0</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.1</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dnsQuality-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/homoglyph-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'nsgroup'}->[0],'http://www.eurid.eu/xml/epp/nsgroup-1.1','nsgroup-1.1 for server announcing 1.1');

########################################################################################################
### NSGROUP_CHECK
## Note, the tests are still from 2.1.1 (nsgroup-1.1)
## Therefore, I have string replaced the schema versions in these tests
## domain-ext-2.1 adds the delayed flag

$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="true">nsg-a-1349684934</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="false">my-ns-group</nsgroup:name><nsgroup:reason lang="en">in use</nsgroup:reason></nsgroup:cd></nsgroup:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->nsgroup_check('nsg-a-1349684934','my-ns-group');
is($R1,$E1.'<command><check><nsgroup:check xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.1 nsgroup-1.1.xsd"><nsgroup:name>nsg-a-1349684934</nsgroup:name><nsgroup:name>my-ns-group</nsgroup:name></nsgroup:check></check><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.1 check_multi build_xml');
is($rc->is_success(),1,'nsgroup-1.1 check_multi is_success');
is($dri->get_info('exist','nsgroup','nsg-a-1349684934'),0,'nsgroup-1.1 check_multi get_info(exist) 1/2');
is($dri->get_info('exist','nsgroup','my-ns-group'),1,'nsgroup-1.1 check_multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','nsgroup','my-ns-group'),'in use','nsgroup-1.1 check_multi get_info(exist_reason) 2/2');

### NSGROUP_CREATE
# use punycode!
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$c1=$dri->local_object('hosts');
$c1->name('nsgroup-1349428719');
$c1->add('ns1.some-domain.eu');
$c1->add('ns2.some-domain.eu');
$rc=$dri->nsgroup_create($c1);
is($R1,$E1.'<command><create><nsgroup:create xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.1 nsgroup-1.1.xsd"><nsgroup:name>nsgroup-1349428719</nsgroup:name><nsgroup:ns>ns1.some-domain.eu</nsgroup:ns><nsgroup:ns>ns2.some-domain.eu</nsgroup:ns></nsgroup:create></create><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 create build');
is($rc->is_success(),1,'nsgroup-1.0 create is_success');

### NSGROUP_DELETE
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$c1=$dri->local_object('hosts');
$c1->name('nsgroup-phenix');
$rc=$dri->nsgroup_delete($c1);
is($R1,$E1.'<command><delete><nsgroup:delete xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.1 nsgroup-1.1.xsd"><nsgroup:name>nsgroup-phenix</nsgroup:name></nsgroup:delete></delete><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 create build');
is($rc->is_success(),1,'nsgroup-1.0 create is_success');

### NSGROUP_INFO
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:infData><nsgroup:name>nsg-a-1349684934</nsgroup:name><nsgroup:ns>ns1.some-domain.eu</nsgroup:ns><nsgroup:ns>ns.xn--e1afmkfd.eu</nsgroup:ns></nsgroup:infData></resData><extension><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>ns.xn--e1afmkfd.eu</idn:ace><idn:unicode>ns.пример.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$c1=$dri->local_object('hosts');
$c1->name('nsg-a-1349684934');
$rc=$dri->nsgroup_info($c1, {auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is($R1,$E1.'<command><info><nsgroup:info xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.1 nsgroup-1.1.xsd"><nsgroup:name>nsg-a-1349684934</nsgroup:name><nsgroup:authInfo><nsgroup:pw>XXXX-2MRN-MRAP-MXVR</nsgroup:pw></nsgroup:authInfo></nsgroup:info></info><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 create build');
is($rc->is_success(),1,'nsgroup-1.0 create is_success');

### NSGROUP_UPDATE
# use punycode!
$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result>'.$TRID.'</response>'.$E2;
$c1=$dri->local_object('hosts');
$c1->name('nsgroup-1349428719');
$c2=$dri->local_object('hosts');
$c2->name('nsgroup-1349428719');
$c2->add('ns1.some-other-domain.eu');
$c2->add('ns2.some-other-domain.eu');
$toc=$dri->local_object('changes');
$toc->set('ns',$c2);
$rc=$dri->nsgroup_update($c1,$toc);
is($R1,$E1.'<command><update><nsgroup:update xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.1 nsgroup-1.1.xsd"><nsgroup:name>nsgroup-1349428719</nsgroup:name><nsgroup:ns>ns1.some-other-domain.eu</nsgroup:ns><nsgroup:ns>ns2.some-other-domain.eu</nsgroup:ns></nsgroup:update></update><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup-1.0 create build');
is($rc->is_success(),1,'nsgroup-1.0 create is_success');

exit 0;
