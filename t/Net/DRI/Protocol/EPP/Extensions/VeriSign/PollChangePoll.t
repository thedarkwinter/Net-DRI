#!/usr/bin/perl

# Verisign starting using the ChangePoll extension in late 2019.
# Since this is one of the first examples in the wild, I will adda a couple of tests

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 22;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc, $lastid, $s, $d, $data);

## This poll message includes the host data, and the chagePoll notification "before" deleting the object

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="17" id="12345"><qDate>2019-12-17T16:00:00Z</qDate><msg>Unused objects policy</msg></msgQ><resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>NS1.FRED.COM</host:name><host:roid>ROID123</host:roid><host:status s="ok" /><host:addr ip="v4">200.201.202.203</host:addr><host:clID>ClientX</host:clID><host:crID>ClientX</host:crID><host:crDate>2000-01-01T00:00:00Z</host:crDate><host:upID>ClientX</host:upID><host:upDate>2015-03-20T15:00:26Z</host:upDate></host:infData></resData><extension><changePoll:changeData xmlns:changePoll="urn:ietf:params:xml:ns:changePoll-1.0" state="before"><changePoll:operation op="purge">delete</changePoll:operation><changePoll:date>2019-12-17T16:00:00Z</changePoll:date><changePoll:svTRID>5432888-XYZ</changePoll:svTRID><changePoll:who>regy_batch</changePoll:who><changePoll:reason>Unused objects policy</changePoll:reason></changePoll:changeData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

# details of the poll
$lastid=$dri->get_info('last_id');
is($dri->get_info('last_id'),$lastid,'message get_info last_id');
is(''.$dri->get_info('qdate','message',$lastid),'2019-12-17T16:00:00','message get_info qdate');
is($dri->get_info('content','message',$lastid),'Unused objects policy','message get_info msg');
is($dri->get_info('lang','message',$lastid),'en','message get_info lang');
is($dri->get_info('object_type','message',$lastid),'host','message get_info object_type');
is($dri->get_info('action','message',$lastid),'info','message get_info action');
# details of the host
is($dri->get_info('name','message',$lastid),'ns1.fred.com','message get_info action');
is($dri->get_info('roid','message',$lastid),'ROID123','message get_info(roid)');
$s=$dri->get_info('status','message',$lastid);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info(status)');
is_deeply([$s->list_status()],['ok'],'message get_info(status) list');
$s=$dri->get_info('self','message',$lastid);
isa_ok($s,'Net::DRI::Data::Hosts','message get_info(self)');
my ($name,$ip4,$ip6)=$s->get_details(1);
is($name,'ns1.fred.com','message self name');
is_deeply($ip4,['200.201.202.203'],'message self ip4');
is_deeply($ip6,[],'message self ip6');
is($dri->get_info('clID','message',$lastid),'ClientX','message get_info(clID)');
$d=$dri->get_info('crDate','message',$lastid);
isa_ok($d,'DateTime','message get_info(crDate)');
# changepoll data
$data=$rc->get_data('message',$lastid,'change');
is($data->{state},'before','message get_info(change) state');
is_deeply($data->{operation},['delete','purge'],'message get_info(change) operation');
is($data->{date}->iso8601(),'2019-12-17T16:00:00','message get_info(change) date');
is($data->{svTRID},'5432888-XYZ','message get_info(change) svtrid');
is($data->{who},'regy_batch','message get_info(change) who');
is($data->{reason},'Unused objects policy','message get_info(change) reason');

exit 0;
