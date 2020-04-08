#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 95;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'clientref-123007'}});
$dri->add_registry('DNSBelgium::BE');
$dri->target('DNSBelgium::BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
my ($rc,$toc,$d);

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

## bounced - registry can't email registrant contact
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="441"><qDate>2018-06-12T10:00:00.000Z</qDate><msg>E-mail bounced</msg></msgQ><resData><dnsbe:pollRes xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:type>EMAIL</dnsbe:type><dnsbe:action>BOUNCED</dnsbe:action><dnsbe:email>jdoe@example.com</dnsbe:email><dnsbe:returncode>2000</dnsbe:returncode><dnsbe:detailedcode>5.1.1</dnsbe:detailedcode><dnsbe:date>2018-06-12T09:00:00.000Z</dnsbe:date></dnsbe:pollRes></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

$s=$rc->get_data('message','session','last_id');
is($rc->get_data('message',$s,'action'),'BOUNCED','notification bounced get_data(action)');
is($rc->get_data('message',$s,'type'),'EMAIL','notification bounced get_data(type)');
is($rc->get_data('message',$s,'email'),'jdoe@example.com','notification bounced get_data(email)');
is($rc->get_data('message',$s,'returncode'),2000,'notification bounced get_data(returncode)');
is($rc->get_data('message',$s,'detailedcode'),'5.1.1','notification bounced get_data(detailedcode)');
is($rc->get_data('message',$s,'date'),'2018-06-12T09:00:00','notification bounced get_data(date)');

####################################################################################################
## request_auth

$rc = $dri->domain_request_authcode('test.be', {url => 'http://test.com'});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created authinfo');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:command><dnsbe:requestAuthCode><dnsbe:domainName>test.be</dnsbe:domainName><dnsbe:url>http://test.com</dnsbe:url></dnsbe:requestAuthCode><dnsbe:clTRID>clientref-123007</dnsbe:clTRID></dnsbe:command></dnsbe:ext></extension></epp>','Domain Request Authcode XML correct');


####################################################################################################
## version 2.0
## based on:
## https://docs.dnsbelgium.be/be/epp/infodomain.html
##
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>dns-domain-22.be</domain:name><domain:roid>15601-DNSBE</domain:roid><domain:status s="clientTransferProhibited"/><domain:status s="serverTransferProhibited"/><domain:registrant>c26511</domain:registrant><domain:contact type="billing">c80</domain:contact><domain:contact type="tech">c182</domain:contact><domain:clID>t1-dns-be</domain:clID><domain:crID>t1-dns-be</domain:crID><domain:crDate>2008-11-19T15:05:24.000Z</domain:crDate><domain:upID>t1-dns-be</domain:upID><domain:upDate>2008-12-10T09:54:36.000Z</domain:upDate><domain:exDate>2009-11-19T16:00:01.000Z</domain:exDate><domain:trDate>2008-11-19T16:00:01.000Z</domain:trDate></domain:infData></resData><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:infData><dnsbe:domain><dnsbe:onhold>false</dnsbe:onhold><dnsbe:quarantined>false</dnsbe:quarantined></dnsbe:domain></dnsbe:infData></dnsbe:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('dns-domain-22.be');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">dns-domain-22.be</domain:name></domain:info></info><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:info><dnsbe:domain version="2.0"/></dnsbe:info></dnsbe:ext></extension><clTRID>clientref-123007</clTRID></command>'.$E2,'domain_info build version 2.0');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'dns-domain-22.be','domain_info version 2.0 get_info(name)');
is($dri->get_info('roid'),'15601-DNSBE','domain_info version 2.0 get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info version 2.0 get_info(status)');
is_deeply([$s->list_status()],['clientTransferProhibited','serverTransferProhibited'],'domain_info version 2.0 get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info version 2.0 get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_info version 2.0 get_info(contact) types');
is($s->get('registrant')->srid(),'c26511','domain_info version 2.0 get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c80','domain_info version 2.0 get_info(contact) billing srid');
is($s->get('tech')->srid(),'c182','domain_info version 2.0 get_info(contact) tech srid');
is($dri->get_info('clID'),'t1-dns-be','domain_info version 2.0 get_info(clID)');
is($dri->get_info('crID'),'t1-dns-be','domain_info version 2.0 get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(crDate)');
is("".$d,'2008-11-19T15:05:24','domain_info version 2.0 get_info(crDate) value');
is($dri->get_info('upID'),'t1-dns-be','domain_info version 2.0 get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(upDate)');
is("".$d,'2008-12-10T09:54:36','domain_info version 2.0 get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(exDate)');
is("".$d,'2009-11-19T16:00:01','domain_info version 2.0 get_info(exDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(trDate)');
is("".$d,'2008-11-19T16:00:01','domain_info version 2.0 get_info(trDate) value');
# version 2.0 of domain info command (dnsbe:ext)
is($dri->get_info('onhold'),'false','domain_info version 2.0 get_info(onhold)');
is($dri->get_info('quarantined'),'false','domain_info version 2.0 get_info(quarantined)');

# domain name in use, belongs to the querying registrar and is scheduled for deletion
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>dom-0-1182527393111.be</domain:name><domain:roid>390-DNSBE</domain:roid><domain:status s="ok"/><domain:registrant>c340</domain:registrant><domain:contact type="billing">c100003</domain:contact><domain:contact type="onsite">c339</domain:contact><domain:clID>a100000</domain:clID><domain:crID>a100000</domain:crID><domain:crDate>2007-06-22T15:49:55.000Z</domain:crDate><domain:upID>a100000</domain:upID><domain:upDate>2007-06-22T15:49:55.000Z</domain:upDate><domain:exDate>2008-06-22T15:49:55.000Z</domain:exDate></domain:infData></resData><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:infData><dnsbe:domain><dnsbe:nsgroup>nsg-1182527394333</dnsbe:nsgroup><dnsbe:onhold>false</dnsbe:onhold><dnsbe:quarantined>false</dnsbe:quarantined><dnsbe:deletionDate>2007-06-22T21:00:00.000Z</dnsbe:deletionDate></dnsbe:domain></dnsbe:infData></dnsbe:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('dom-0-1182527393111.be');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name hosts="all">dom-0-1182527393111.be</domain:name></domain:info></info><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:info><dnsbe:domain version="2.0"/></dnsbe:info></dnsbe:ext></extension><clTRID>clientref-123007</clTRID></command>'.$E2,'domain_info build version 2.0');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'dom-0-1182527393111.be','domain_info version 2.0 get_info(name)');
is($dri->get_info('roid'),'390-DNSBE','domain_info version 2.0 get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info version 2.0 get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info version 2.0 get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info version 2.0 get_info(contact)');
is($s->get('registrant')->srid(),'c340','domain_info version 2.0 get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c100003','domain_info version 2.0 get_info(contact) billing srid');
is($s->get('onsite')->srid(),'c339','domain_info version 2.0 get_info(contact) onsite srid');
is($dri->get_info('clID'),'a100000','domain_info version 2.0 get_info(clID)');
is($dri->get_info('crID'),'a100000','domain_info version 2.0 get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(crDate)');
is("".$d,'2007-06-22T15:49:55','domain_info version 2.0 get_info(crDate) value');
is($dri->get_info('upID'),'a100000','domain_info version 2.0 get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(upDate)');
is("".$d,'2007-06-22T15:49:55','domain_info version 2.0 get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(exDate)');
is("".$d,'2008-06-22T15:49:55','domain_info version 2.0 get_info(exDate) value');
# version 2.0 of domain info command (dnsbe:ext)
is($dri->get_info('nsgroup'),'nsg-1182527394333','domain_info version 2.0 get_info(nsgroup)');
is($dri->get_info('onhold'),'false','domain_info version 2.0 get_info(onhold)');
is($dri->get_info('quarantined'),'false','domain_info version 2.0 get_info(quarantined)');
# test as string
is($dri->get_info('deletionDate'),'2007-06-22T21:00:00','domain_info version 2.0 get_info(deletionDate)');
# test as date object
$d=$dri->get_info('deletionDate');
isa_ok($d,'DateTime','domain_info version 2.0 get_info(deletionDate)');
is("".$d,'2007-06-22T21:00:00','domain_info version 2.0 get_info(deletionDate) value');


####################################################################################################
## based on:
## https://docs.dnsbelgium.be/be/epp/checkdomain.html
##
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="true">semaphore.be</domain:name></domain:cd><domain:cd><domain:name avail="false">greatdomain.be</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="true">secureshopping.be</domain:name></domain:cd><domain:cd><domain:name avail="false">dns-domain-22.be</domain:name></domain:cd><domain:cd><domain:name avail="false">xn--dn-kia.be</domain:name></domain:cd><domain:cd><domain:name avail="true">xn--belgi-rsa.be</domain:name></domain:cd></domain:chkData></resData><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:chkData><dnsbe:domain><dnsbe:cd><dnsbe:name>greatdomain.be</dnsbe:name><dnsbe:availableDate>2010-04-12T16:00:00.000Z</dnsbe:availableDate></dnsbe:cd><dnsbe:cd><dnsbe:name>secureshopping.be</dnsbe:name><dnsbe:availableDate>2009-01-14T13:00:00.000Z</dnsbe:availableDate></dnsbe:cd><dnsbe:cd><dnsbe:name>dns-domain-22.be</dnsbe:name><dnsbe:status s="clientTransferProhibited"/><dnsbe:status s="serverTransferProhibited"/></dnsbe:cd><dnsbe:cd><dnsbe:name>xn--dn-kia.be</dnsbe:name><dnsbe:status s="serverTransferProhibited"/></dnsbe:cd></dnsbe:domain></dnsbe:chkData></dnsbe:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('semaphore.be','greatdomain.be','secureshopping.be','dns-domain-22.be','xn--dn-kia.be','xn--belgi-rsa.be');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>semaphore.be</domain:name><domain:name>greatdomain.be</domain:name><domain:name>secureshopping.be</domain:name><domain:name>dns-domain-22.be</domain:name><domain:name>xn--dn-kia.be</domain:name><domain:name>xn--belgi-rsa.be</domain:name></domain:check></check><extension><dnsbe:ext xmlns:dnsbe="http://www.dns.be/xml/epp/dnsbe-1.0"><dnsbe:check><dnsbe:domain version="2.0"/></dnsbe:check></dnsbe:ext></extension><clTRID>clientref-123007</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','semaphore.be'),0,'domain_check multi get_info(exist) 1/6');
is($dri->get_info('exist','domain','greatdomain.be'),1,'domain_check multi get_info(exist) 2/6');
is($dri->get_info('exist_reason','domain','greatdomain.be'),'in use','domain_check multi get_info(exist_reason) 2/6');
is($dri->get_info('availableDate','domain','greatdomain.be'),'2010-04-12T16:00:00','domain_check multi get_info(availableDate) 2/6');
is($dri->get_info('exist','domain','secureshopping.be'),0,'domain_check multi get_info(exist) 3/6');
is($dri->get_info('availableDate','domain','secureshopping.be'),'2009-01-14T13:00:00','domain_check multi get_info(exist_reason) 3/6');
is($dri->get_info('exist','domain','dns-domain-22.be'),1,'domain_check multi get_info(exist) 4/6');
$s=$dri->get_info('status','domain','dns-domain-22.be');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status) 4/6');
is_deeply([$s->list_status()],['clientTransferProhibited','serverTransferProhibited'],'domain_info get_info(status) list 4/6');
is($dri->get_info('exist','domain','xn--dn-kia.be'),1,'domain_check multi get_info(exist) 5/6');
$s=$dri->get_info('status','domain','xn--dn-kia.be');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status) 5/6');
is_deeply([$s->list_status()],['serverTransferProhibited'],'domain_info get_info(status) list 5/6');
is($dri->get_info('exist','domain','xn--belgi-rsa.be'),0,'domain_check multi get_info(exist) 6/6');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
