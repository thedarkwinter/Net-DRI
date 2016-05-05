#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 13;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['ServiceMessage','-VeriSign::NameStore']});

my ($rc,$lastid,$data);



$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="137526"><qDate>2013-11-27T04:04:51.0Z</qDate><msg lang="en-US">Transfer Approved.</msg> </msgQ><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.example</domain:name><domain:trStatus>clientApproved</domain:trStatus><domain:reID>reg1</domain:reID><domain:reDate>2013-11-27T04:03:29.0Z</domain:reDate><domain:acID>reg2</domain:acID><domain:acDate>2013-11-27T04:04:51.0Z</domain:acDate></domain:trnData><message xmlns="http://tld-box.at/xmlns/resdata-1.1" type="TransferApproved"><desc>Inbound transfer of test.example was APPROVED. Subordinate hosts ns1.test.example, ns2.test.example were also transferred.</desc><data><entry name="host">ns1.test.example</entry><entry name="host">ns2.test.example</entry></data></message></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
is($lastid,137526,'message get_info last_id');
$data=$rc->get_data('message',$lastid,'servicemessage');
is($data->{type},'TransferApproved','example 1 type');
is($data->{description},'Inbound transfer of test.example was APPROVED. Subordinate hosts ns1.test.example, ns2.test.example were also transferred.','example 1 description');
is_deeply($data->{entries},{host=>[qw/ns1.test.example ns2.test.example/]},'example 1 entries');



$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="2267"><qDate>2016-02-25T13:46:36.879301Z</qDate><msg>The following domains have expired as of 2016-02-25: test-expire1.example, test-expire2.example</msg> </msgQ><resData><message xmlns="http://tld-box.at/xmlns/resdata-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="HasExpired"><desc>The following domains have expired as of 2016-02-25: test-expire1.example, test-expire2.example</desc><data><entry name="date">2016-02-25</entry><entry name="domain">test-expire1.example</entry><entry name="domain">test-expire2.example</entry></data></message></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'servicemessage');
is($data->{type},'HasExpired','example 2 type');
is($data->{description},'The following domains have expired as of 2016-02-25: test-expire1.example, test-expire2.example','example 2 description');
is_deeply($data->{entries},{date => '2016-02-25', domain => [qw/test-expire1.example test-expire2.example/]},'example 2 entries');



$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="88" id="1816"><qDate>2014-10-21T14:31:54.524131Z</qDate><msg>EPP response to command with client-id [05908A94-592F-11E4-ABEA-51CFAB10F032] and server-id [20141021143201978589AD-secondary-tldbox]</msg></msgQ><resData><message xmlns="http://tld-box.at/xmlns/resdata-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="ResponseRecovery"><desc>EPP response to command with client-id [05908A94-592F-11E4-ABEA-51CFAB10F032] and server-id [20141021143201978589AD-secondary-tldbox]</desc><data><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="8" id="1975"/><resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns="urn:ietf:params:xml:ns:domain-1.0"><domain:name>test-connection-interrupt.example</domain:name><domain:crDate>2014-10-21T14:32:01.984360Z</domain:crDate><domain:exDate>2015-10-21T14:32:01.984360Z</domain:exDate></domain:creData></resData><trID><clTRID>05908A94-592F-11E4-ABEA-51CFAB10F032</clTRID><svTRID>20141021143201978589AD-secondary-tldbox</svTRID></trID></response></epp></data></message></resData>'.$TRID.'</response>'.$E2; 
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'servicemessage');
is($data->{type},'ResponseRecovery','example 3 type');
is($data->{description},'EPP response to command with client-id [05908A94-592F-11E4-ABEA-51CFAB10F032] and server-id [20141021143201978589AD-secondary-tldbox]','example 3 description');
is($data->{unspecified},'<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="8" id="1975"/><resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns="urn:ietf:params:xml:ns:domain-1.0"><domain:name>test-connection-interrupt.example</domain:name><domain:crDate>2014-10-21T14:32:01.984360Z</domain:crDate><domain:exDate>2015-10-21T14:32:01.984360Z</domain:exDate></domain:creData></resData><trID><clTRID>05908A94-592F-11E4-ABEA-51CFAB10F032</clTRID><svTRID>20141021143201978589AD-secondary-tldbox</svTRID></trID></response></epp>','example 3 unspecified');



$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="16031"><qDate>2014-12-28T13:48:22.097813Z</qDate><msg>Status(es) added to domain [test---0039888rbx-vvgobook5xl4.tldbox]: serverUpdateProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z)), serverTransferProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z))</msg></msgQ><resData><message xmlns="http://tld-box.at/xmlns/resdata-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="DelegationStatusSet"><desc>Status(es) added to domain [test-freeze.example]: serverUpdateProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z)), serverTransferProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z))</desc><data><entry name="domain">test-freeze.example</entry><entry name="status">serverUpdateProhibited</entry><entry name="comment">testcase comment freeze (2014-12-28T13:48:22.097813Z)</entry><entry name="status">serverTransferProhibited</entry><entry name="comment">testcase comment freeze (2014-12-28T13:48:22.097813Z)</entry></data></message></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'servicemessage');
is($data->{type},'DelegationStatusSet','example 4 type');
is($data->{description},'Status(es) added to domain [test-freeze.example]: serverUpdateProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z)), serverTransferProhibited (testcase comment freeze (2014-12-28T13:48:22.097813Z))','example 4 description');
is_deeply($data->{entries},{ domain => 'test-freeze.example', status => [qw/serverUpdateProhibited serverTransferProhibited/], comment => ['testcase comment freeze (2014-12-28T13:48:22.097813Z)', 'testcase comment freeze (2014-12-28T13:48:22.097813Z)'] },'example 4 entries');

exit 0;
