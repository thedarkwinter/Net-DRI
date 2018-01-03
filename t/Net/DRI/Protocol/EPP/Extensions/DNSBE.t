#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 25;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl=>10,trid_factory => sub { return 'clientref-123007'}});
$dri->add_registry('DNSBelgium::BE');
$dri->target('DNSBelgium::BE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
my ($rc,$toc);

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
