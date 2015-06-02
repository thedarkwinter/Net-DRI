#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 13;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>2004-05-03T20:06:17.0002Z</qDate><msg>Restore Request Pending</msg></msgQ><resData><rgp-poll:pollData xmlns:rgp-poll="http://www.verisign.com/epp/rgp-poll-1.0" xsi:schemaLocation="http://www.verisign.com/epp/rgp-poll-1.0 rgp-poll-1.0.xsd"><rgp-poll:name>foobar.com</rgp-poll:name><rgp-poll:rgpStatus s="pendingDelete"/><rgp-poll:reqDate>2004-05-03T20:06:17.0002Z</rgp-poll:reqDate><rgp-poll:reportDueDate>2004-05-03T20:06:17.0002Z</rgp-poll:reportDueDate></rgp-poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id');
is(''.$dri->get_info('qdate','message',12345),'2004-05-03T20:06:17','message get_info qdate');
is($dri->get_info('content','message',12345),'Restore Request Pending','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('object_type','message',12345),'domain','message get_info object_type');
is($dri->get_info('action','message',12345),'rgp_notification','message get_info rgp_notification');
is($dri->get_info('name','message',12345),'foobar.com','message get_info name');
$s=$dri->get_info('status','message',12345);
isa_ok($s,'Net::DRI::Data::StatusList','message get_info status');
is_deeply([$s->list_status()],['pendingDelete'],'message get_info status list');
is($s->is_active(),0,'message get_info status is_active');
is($s->is_pending(),1,'message get_info status is_pending');
is(''.$dri->get_info('req_date','message',12345),'2004-05-03T20:06:17','message get_info req_date');
is(''.$dri->get_info('report_due_date','message',12345),'2004-05-03T20:06:17','message get_info report_due_date');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
