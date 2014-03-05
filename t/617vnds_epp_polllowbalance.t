#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 11;

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

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="12345"><qDate>2004-03-25T18:20:07.0078Z</qDate><msg>Low Account Balance (SRS)</msg></msgQ><resData><lowbalance-poll:pollData xmlns:lowbalance-poll="http://www.verisign.com/epp/lowbalance-poll-1.0" xsi:schemaLocation="http://www.verisign.com/epp/lowbalance-poll-1.0 lowbalance-poll-1.0.xsd"><lowbalance-poll:registrarName>Test Registar</lowbalance-poll:registrarName><lowbalance-poll:creditLimit>1000</lowbalance-poll:creditLimit><lowbalance-poll:creditThreshold type="PERCENT">10</lowbalance-poll:creditThreshold><lowbalance-poll:availableCredit>80</lowbalance-poll:availableCredit></lowbalance-poll:pollData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id');
is(''.$dri->get_info('qdate','message',12345),'2004-03-25T18:20:07','message get_info qdate');
is($dri->get_info('content','message',12345),'Low Account Balance (SRS)','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');
is($dri->get_info('object_type','message',12345),'session','message get_info object_type');
is($dri->get_info('action','message',12345),'lowbalance_notification','message get_info rgp_notification');
is($dri->get_info('registrar_name','message',12345),'Test Registar','message get_info registrar_name');
is($dri->get_info('credit_limit','message',12345),1000,'message get_info credit_limit');
is($dri->get_info('credit_threshold_type','message',12345),'PERCENT','message get_info credit_threshold_type');
is($dri->get_info('credit_threshold','message',12345),10,'message get_info credit_threshold');
is($dri->get_info('available_credit','message',12345),80,'message get_info available_credit');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
