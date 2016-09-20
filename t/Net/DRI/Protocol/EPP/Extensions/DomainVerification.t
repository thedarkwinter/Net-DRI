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
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['DomainVerification','-VeriSign::NameStore']});


$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example.com</domain:name></domain:cd><domain:cd><domain:name avail="0">example.net</domain:name></domain:cd></domain:chkData></resData><extension><veridomain:chkData xmlns:veridomain="urn:ietf:params:xml:ns:veridomain-1.0"><veridomain:distinction name="example.com" type="reserved"/><veridomain:distinction name="example.net" type="prohibited"/></veridomain:chkData></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->domain_check(qw/example.com example.net/);
is_deeply($rc->get_data('domain', 'example.com', 'restriction'), { type => 'reserved' }, 'domain_check 1');
is_deeply($rc->get_data('domain', 'example.net', 'restriction'), { type => 'prohibited' }, 'domain_check 2');


$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2015-02-06T04:01:21.0Z</domain:crDate><domain:exDate>2018-02-06T04:01:21.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><veridomain:infData xmlns:veridomain="urn:ietf:params:xml:ns:veridomain-1.0"><veridomain:status>pass</veridomain:status><veridomain:history><veridomain:record><veridomain:date>2015-02-06T12:00:00.0Z</veridomain:date><veridomain:op>PASS</veridomain:op><veridomain:clID>ClientX</veridomain:clID></veridomain:record><veridomain:record><veridomain:date>2001-02-03T15:00:00.0Z</veridomain:date><veridomain:op>PENDINGVERIFY</veridomain:op><veridomain:clID>ClientX</veridomain:clID></veridomain:record><veridomain:record><veridomain:date>2015-02-03T12:00:00.0Z</veridomain:date><veridomain:op>UNVERIFIED</veridomain:op><veridomain:clID>ClientX</veridomain:clID></veridomain:record></veridomain:history></veridomain:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.com');
my $rr=$rc->get_data('domain','example.com','restriction');
is($rr->{status}, 'pass', 'domain_info restriction status');
my @h=@{$rr->{history}};
is(scalar @h, 3, 'domain_info restriction history count');
is(''.$h[0]->{date}, '2015-02-06T12:00:00', 'domain_info restriction history 1 date');
is($h[0]->{op}, 'PASS', 'domain_info restriction history 1 op');
is($h[0]->{clID}, 'ClientX', 'domain_info restriction history 1 clID');
is(''.$h[1]->{date}, '2001-02-03T15:00:00', 'domain_info restriction history 2 date');
is($h[1]->{op}, 'PENDINGVERIFY', 'domain_info restriction history 2 op');
is($h[1]->{clID}, 'ClientX', 'domain_info restriction history 2 clID');
is(''.$h[2]->{date}, '2015-02-03T12:00:00', 'domain_info restriction history 3 date');
is($h[2]->{op}, 'UNVERIFIED', 'domain_info restriction history 3 op');
is($h[2]->{clID}, 'ClientX', 'domain_info restriction history 3 clID');


exit 0;
