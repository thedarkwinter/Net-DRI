#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 18;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'clientref-123007'}});
$dri->add_registry('BE');
$dri->target('BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
my ($rc,$toc);

#########################################################################################################
## Extension: NSgroup

$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1543</svTRID></trID></response></epp>';
my $c1=$dri->local_object('hosts');
$c1->name('mynsgroup1');
$c1->add('ns1.nameserver.be');
$c1->add('ns2.nameserver.be');
$rc=$dri->nsgroup_create($c1);
is($R1,$E1.'<command><create><nsgroup:create xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns></nsgroup:create></create><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup create build');
is($rc->is_success(),1,'nsgroup create is_success');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
my $c2=$dri->local_object('hosts');
$c2->name('mynsgroup1');
$c2->add('ns1.nameserver.be');
$c2->add('ns2.nameserver.be');
$c2->add('ns3.nameserver.be');
$toc=$dri->local_object('changes');
$toc->set('ns',$c2);
$rc=$dri->nsgroup_update($c1,$toc);
is($R1,$E1.'<command><update><nsgroup:update xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns><nsgroup:ns>ns3.nameserver.be</nsgroup:ns></nsgroup:update></update><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup update build');
is($rc->is_success(),1,'nsgroup update is_success');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg><value><nsgroup:name>mynsgroup1</nsgroup:name></value></result><extension><dnsbe:ext><dnsbe:result><dnsbe:msg>Content check ok</dnsbe:msg></dnsbe:result></dnsbe:ext></extension><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_delete($c1);
is($R1,$E1.'<command><delete><nsgroup:delete xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name></nsgroup:delete></delete><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup delete build');
is($rc->is_success(),1,'nsgroup delete is_success');



$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="0">mynsgroup1</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">mynsgroup2</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_check('mynsgroup1','mynsgroup2');
is($R1,$E1.'<command><check><nsgroup:check xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:name>mynsgroup2</nsgroup:name></nsgroup:check></check><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup check_multi is_success');
is($rc->is_success(),1,'nsgroup check_multi is_success');
is($dri->get_info('exist','nsgroup','mynsgroup1'),1,'nsgroup check_multi get_info(exist) 1/2');
is($dri->get_info('exist','nsgroup','mynsgroup2'),0,'nsgroup check_multi get_info(exist) 2/2');
is($dri->get_info('action','nsgroup','mynsgroup1'),'check','nsgroup check_multi get_info(action) 1/2');
is($dri->get_info('action','nsgroup','mynsgroup2'),'check','nsgroup check_multi get_info(action) 2/2');


$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xmlns:agent="http://www.dns.be/xml/epp/agent-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd http://www.dns.be/xml/epp/agent-1.0 agent-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><nsgroup:infData><nsgroup:name>mynsgroup1</nsgroup:name><nsgroup:ns>ns1.nameserver.be</nsgroup:ns><nsgroup:ns>ns2.nameserver.be</nsgroup:ns></nsgroup:infData></resData><trID><clTRID>clientref-123007</clTRID><svTRID>dnsbe-1545</svTRID></trID></response></epp>';
$rc=$dri->nsgroup_info($c1);
is($R1,$E1.'<command><info><nsgroup:info xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>mynsgroup1</nsgroup:name></nsgroup:info></info><clTRID>clientref-123007</clTRID></command>'.$E2,'nsgroup info build');
is($rc->is_success(),1,'nsgroup info is_success');
is_deeply($dri->get_info('self'),$c1,'nsgroup info get_info(self)');
is($dri->get_info('action'),'info','nsgroup info get_info(action)');
is($dri->get_info('exist'),1,'nsgroup info get_info(exist)');
is($dri->get_info('exist','nsgroup','mynsgroup1'),1,'nsgroup info get_info(exist) +cache');


exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
