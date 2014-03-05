#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 43;

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


####################################################################################################
## Messages
my $s;

## a domain based message
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="6830"><qDate>2008-09-18T21:29:28.179+02:00</qDate><msg>Transfer code e-mail bounced</msg></msgQ><resData><dnsbe:pollRes xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:action>BOUNCED</dnsbe:action><dnsbe:domainname>test.be</dnsbe:domainname><dnsbe:email>john@test.be</dnsbe:email><dnsbe:returncode>1159</dnsbe:returncode><dnsbe:type>TRANSFER</dnsbe:type></dnsbe:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

## This is a *very* convoluted way to access data, it is only done so to test everything is there
$s=$rc->get_data('message','session','last_id');
is($s,6830,'notification get_data(message,session,last_id)');
$s=$rc->get_data('message',$s,'name');
is($s,'test.be','notification get_data(message,ID,name)');
is($rc->get_data('domain',$s,'object_type'),$rc->get_data('object_type'),'notification get_data(domain,X,Y)=get_data(Y)');
is($rc->get_data('exist'),1,'notification get_data(exist)');
is($rc->get_data('returncode'),1159,'notification get_data(returncode)');
is($rc->get_data('action'),'BOUNCED','notification get_data(action)');
is($rc->get_data('type'),'TRANSFER','notification get_data(type)');
is($rc->get_data('email'),'john@test.be','notification get_data(email)');
is($rc->get_data('id'),6830,'notification get_data(id)');

## a contact based message
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="6830"><qDate>2008-09-18T21:29:28.179+02:00</qDate><msg>Transfer code e-mail bounced</msg></msgQ><resData><dnsbe:pollRes xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:action>APPROVED</dnsbe:action><dnsbe:contact>c54321</dnsbe:contact><dnsbe:date>2012-10-10T10:11:12.000Z</dnsbe:date><dnsbe:returncode>1502</dnsbe:returncode><dnsbe:type>MONITORED_UPD_CONTACT</dnsbe:type></dnsbe:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

$s=$rc->get_data('message','session','last_id');
is($s,6830,'notification contact get_data(message,session,last_id)');
$s=$rc->get_data('message',$s,'name');
is($s,'c54321','notification contact get_data(message,ID,srid)');
is($rc->get_data('contact',$s,'object_type'),$rc->get_data('object_type'),'notification contact get_data(contact,X,Y)=get_data(Y)');
is($rc->get_data('exist'),1,'notification contact get_data(exist)');
is($rc->get_data('returncode'),1502,'notification contact get_data(returncode)');
is($rc->get_data('action'),'APPROVED','notification contact get_data(action)');
is($rc->get_data('type'),'MONITORED_UPD_CONTACT','notification contact get_data(type)');
is($rc->get_data('date'),'2012-10-10T10:11:12','notification contact get_data(date)');
is($rc->get_data('id'),6830,'notification contact get_data(id)');

## watermark
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="4682495"><qDate>2011-10-31T23:25:17.071Z</qDate><msg>Watermark Reached</msg></msgQ><resData><dnsbe:pollRes xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:action>REACHED</dnsbe:action><dnsbe:level>1000.00</dnsbe:level><dnsbe:returncode>1000</dnsbe:returncode><dnsbe:type>WATERMARK</dnsbe:type></dnsbe:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

$s=$rc->get_data('message','session','last_id');
is($rc->get_data('message',$s,'action'),'REACHED','notification watermark get_data(action)');
is($rc->get_data('message',$s,'type'),'WATERMARK','notification watermark get_data(watermark)');
is($rc->get_data('message',$s,'returncode'),1000,'notification watermark get_data(returncode)');
is($rc->get_data('message',$s,'level'),'1000.00','notification watermark get_data(level)');

####################################################################################################
## request_auth

$rc = $dri->domain_request_authcode('test.be', {url => 'http://test.com'});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created authinfo');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/dnsbe-1.0 dnsbe-1.0.xsd"><dnsbe:command><dnsbe:requestAuthCode><dnsbe:domainName>test.be</dnsbe:domainName><dnsbe:url>http://test.com</dnsbe:url></dnsbe:requestAuthCode><dnsbe:clTRID>clientref-123007</dnsbe:clTRID></dnsbe:command></dnsbe:ext></extension></epp>','Domain Request Authcode XML correct');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
