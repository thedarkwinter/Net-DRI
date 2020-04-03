#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;
require "$FindBin::Bin/../util.pl";

my $test = Net::DRI::Test->new_epp(['ChangePoll']);
my $dri = $test->dri();

use Test::More tests => 38;

####################################################################################################

my $rc;

# §3.1.2 example 1
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="201" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry initiated update of domain.</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2014-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="before"><changePoll:operation>update</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>URS Admin</changePoll:who><changePoll:caseId type="urs">urs123</changePoll:caseId><changePoll:reason>URS Lock</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
my $lastid=$dri->get_info('last_id');
my $data=$rc->get_data('message',$lastid,'change');
is($data->{state},'before','example 1 state');
is($data->{operation},'update','example 1 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 1 date');
is($data->{svTRID},'12345-XYZ','example 1 svtrid');
is($data->{who},'URS Admin','example 1 who');
is_deeply($data->{case},{ type => 'urs', id => 'urs123'},'example 1 case');
is($data->{reason},'URS Lock','example 1 reason');

# §3.1.2 example 2
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="202" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry initiated update of domain.</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="serverUpdateProhibited"/><domain:status s="serverDeleteProhibited"/><domain:status s="serverTransferProhibited"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientZ</domain:upID><domain:upDate>2013-10-22T14:25:57.0Z</domain:upDate><domain:exDate>2014-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="after"><changePoll:operation>update</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>URS Admin</changePoll:who><changePoll:caseId type="urs">urs123</changePoll:caseId><changePoll:reason>URS Lock</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 2 state');
is($data->{operation},'update','example 2 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 2 date');
is($data->{svTRID},'12345-XYZ','example 2 svtrid');
is($data->{who},'URS Admin','example 2 who');
is_deeply($data->{case},{ type => 'urs', id => 'urs123'},'example 2 case');
is($data->{reason},'URS Lock','example 2 reason');



# §3.1.2 example 3
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="201" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry initiated Sync of Domain Expiration Date</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientZ</domain:upID><domain:upDate>2013-10-22T14:25:57.0Z</domain:upDate><domain:exDate>2014-04-03T22:00:00.0Z</domain:exDate></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation op="sync">custom</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>CSR</changePoll:who><changePoll:reason lang="en">Customer sync request</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 3 state');
is_deeply($data->{operation},['custom', 'sync'],'example 3 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 3 date');
is($data->{svTRID},'12345-XYZ','example 3 svtrid');
is($data->{who},'CSR','example 3 who');
is_deeply($data->{reason},{ lang => 'en', msg => 'Customer sync request' },'example 3 reason');



# §3.1.2 example 4
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="200" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry initiated delete of domain resulting in immediate purge.</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:clID>ClientX</domain:clID></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation op="purge">delete</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>ClientZ</changePoll:who><changePoll:reason>Court order</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 4 state');
is_deeply($data->{operation},['delete','purge'],'example 4 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 4 date');
is($data->{svTRID},'12345-XYZ','example 4 svtrid');
is($data->{who},'ClientZ','example 4 who');
is($data->{reason},'Court order','example 4 reason');



# §3.1.2 example 5
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="200" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry purged domain with pendingDelete status.</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="pendingDelete"/><domain:clID>ClientX</domain:clID></domain:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>autoPurge</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>Batch</changePoll:who><changePoll:reason>Past pendingDelete 5 day period</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 5 state');
is($data->{operation},'autoPurge','example 5 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 5 date');
is($data->{svTRID},'12345-XYZ','example 5 svtrid');
is($data->{who},'Batch','example 5 who');
is($data->{reason},'Past pendingDelete 5 day period','example 5 reason');



# §3.1.2 example 6
$test->set_result(1301, 'Command completed successfully; ack to dequeue');
$test->set_response('<msgQ id="201" count="1"><qDate>2013-10-22T14:25:57.0Z</qDate><msg>Registry initiated update of host.</msg></msgQ><resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>ns1.domain.example</host:name><host:roid>NS1_EXAMPLE1-REP</host:roid><host:status s="linked"/><host:status s="serverUpdateProhibited"/><host:status s="serverDeleteProhibited"/><host:addr ip="v4">192.0.2.2</host:addr><host:addr ip="v6">1080:0:0:0:8:800:200C:417A</host:addr><host:clID>ClientX</host:clID><host:crID>ClientY</host:crID><host:crDate>2012-04-03T22:00:00.0Z</host:crDate><host:upID>ClientY</host:upID><host:upDate>2013-10-22T14:25:57.0Z</host:upDate></host:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0"><changePoll:operation>update</changePoll:operation><changePoll:date>2013-10-22T14:25:57.0Z</changePoll:date><changePoll:svTRID>12345-XYZ</changePoll:svTRID><changePoll:who>ClientZ</changePoll:who><changePoll:reason>Host Lock</changePoll:reason></changePoll:changeData></extension>');
$rc=$dri->message_retrieve();
$lastid=$dri->get_info('last_id');
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'after','example 6 state');
is($data->{operation},'update','example 6 operation');
is($data->{date}->iso8601(),'2013-10-22T14:25:57','example 6 date');
is($data->{svTRID},'12345-XYZ','example 6 svtrid');
is($data->{who},'ClientZ','example 6 who');
is($data->{reason},'Host Lock','example 6 reason');


exit 0;
