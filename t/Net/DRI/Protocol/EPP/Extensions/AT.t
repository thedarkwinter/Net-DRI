#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 36;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('AT');
$dri->target('AT')->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c);

####################################################################################################
## Registry Messages


$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="2265" id="374185914"><qDate>2008-02-04T09:23:04.63Z</qDate><msg>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.at]</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="response-copy" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.at]</desc><data><entry name="objecttype">domain</entry><entry name="command">transfer-execute</entry><entry name="objectname">mydomain.at</entry><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="2304"><msg>Object status prohibits operation</msg></result><msgQ count="734" id="374047143"/><extension><conditions xmlns="http://www.nic.at/xsd/at-ext-result-1.0" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-result-1.0 at-ext-result-1.0.xsd"><condition code="NC20077" severity="error"><msg>Registry::NICAT::Exception::Policy::Domain::Locked</msg><details>Domain mydomain.at: domain is locked.</details></condition></conditions></extension><trID><clTRID>NICAT-1234-4341234246535343</clTRID><svTRID>2008020412454356454273-9-nicat</svTRID></trID></response></epp></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 374185914, 'message get_info last_id 1');
is($dri->get_info('last_id', 'message', 'session'), 374185914,'message get_info last_id 2');
is($dri->get_info('id', 'message', 374185914), 374185914,'message get_info id');
is('' . $dri->get_info('qdate', 'message', 374185914), '2008-02-04T09:23:04','message get_info qdate');
is($dri->get_info('lang', 'message', 374185914), 'en', 'message get_info lang');
is($dri->get_info('roid', 'message', 374185914), undef,'message get_info roid');

is($dri->get_info('content', 'message', 374185914), 'EPP response to a '.
'transaction executed on your behalf: objecttype [domain] ' .
	'command [transfer-execute] objectname [mydomain.at]',
	'message get_info content');
is($dri->get_info('action', 'message', 374185914), 'transfer-execute','message get_info action');
is($dri->get_info('object_type', 'message', 374185914), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 374185914), 'mydomain.at','message get_info object_id');

my $conds = $dri->get_info('conditions', 'message', 374185914);
is($conds->[0]->{msg}, 'Registry::NICAT::Exception::Policy::Domain::Locked','message condition message');
is($conds->[0]->{code}, 'NC20077', 'message condition code');
is($conds->[0]->{severity}, 'error', 'message condition severity');
is($conds->[0]->{details}, 'Domain mydomain.at: domain is locked.','message condition details');

$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="375338309"><qDate>2008-02-06T10:18:19.70Z</qDate><msg>Reg losing: blafasel.at</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="domain-transferred-away" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>Reg losing: blafasel.at</desc><data><entry name="domain">blafasel.at</entry></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 375338309, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 375338309), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 375338309), 'blafasel.at','message get_info object_id');

is($dri->get_info('action', 'message', 375338309), 'domain-transferred-away','message get_info action');
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="3" id="375424692"><qDate>2008-02-06T13:37:59.63Z</qDate><msg>ATTENTION: domain weingeist.at is marked to be locked SKW - lock customer request.</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="domain-info-lock-customer" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>ATTENTION: domain weingeist.at is marked to be locked SKW - lock customer request.</desc><data><entry name="domain">weingeist.at</entry></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 375424692, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 375424692), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 375424692), 'weingeist.at','message get_info object_id');
is($dri->get_info('action', 'message', 375424692), 'domain-info-lock-customer','message get_info action');


$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="18" id="390336246"><qDate>2008-03-14T11:42:23.64Z</qDate><msg>Transfer process cancelled for domain: (transfer-request with client-id [NICAT-1234-1242342543566334] and server-id [20080307124235423353F9-4-nicat])</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="domain-transfer-aborted" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>Transfer process cancelled for domain: (transfer-request with client-id [NICAT-1234-1242342543566334] and server-id [20080307124235423353F9-4-nicat])</desc><reftrID><clTRID>NICAT-1234-1242342543566334</clTRID><svTRID>20080307124235423353F9-4-nicat</svTRID></reftrID><data><entry name="domain"/></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 390336246, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 390336246), 'domain', 'message get_info object_type');
is($dri->get_info('object_id', 'message', 390336246), undef, 'message get_info object_id');
is($dri->get_info('action', 'message', 390336246), 'domain-transfer-aborted', 'message get_info action');

$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="523423542"><qDate>2008-06-19T07:24:58.85Z</qDate><msg>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [neingeist.at]</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="response-copy" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [neingeist.at]</desc><data><entry name="objecttype">domain</entry><entry name="command">transfer-execute</entry><entry name="objectname">neingeist.at</entry><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>neingeist.at</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>Reg123</domain:reID><domain:reDate>2009-01-01T01:23:51.00Z</domain:reDate><domain:acID>Reg123</domain:acID><domain:acDate>2009-01-01T01:01:01.00Z</domain:acDate></domain:trnData></resData><extension><at-ext-domain:keydate xmlns:at-ext-domain="http://www.nic.at/xsd/at-ext-domain-1.0" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-domain-1.0 at-ext-domain-1.0.xsd">0423</at-ext-domain:keydate></extension><trID><clTRID>ABCD-123</clTRID><svTRID>123-ABC</svTRID></trID></response></epp></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 523423542, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 523423542), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 523423542), 'neingeist.at','message get_info object_id');
is($dri->get_info('action', 'message', 523423542), 'transfer-execute','message get_info action');
is($dri->get_info('keydate', 'message', 523423542), '0423','message get_info keydate');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
