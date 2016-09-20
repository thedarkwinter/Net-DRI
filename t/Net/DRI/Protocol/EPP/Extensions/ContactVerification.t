#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 14;
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
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['ContactVerification','-VeriSign::NameStore']});


$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:cd><contact:id avail="0">sh8013</contact:id></contact:cd><contact:cd><contact:id avail="0">sah8013</contact:id></contact:cd><contact:cd><contact:id avail="0">8013sah</contact:id></contact:cd></contact:chkData></resData><extension><vericontact:chkData xmlns:vericontact="urn:ietf:params:xml:ns:vericontact-1.0"><vericontact:distinction id="sh8013" type="verified"/><vericontact:distinction id="sah8013" type="blocked"/><vericontact:distinction id="8013sah" type="unverified"/></vericontact:chkData></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } qw/sh8013 sah8013 8013sah/);
is_deeply($rc->get_data('contact', 'sh8013', 'restriction'), { type => 'verified' }, 'contact_check 1');
is_deeply($rc->get_data('contact', 'sah8013', 'restriction'), { type => 'blocked' }, 'contact_check 2');
is_deeply($rc->get_data('contact', '8013sah', 'restriction'), { type => 'unverified' }, 'contact_check 3');



$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="int"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>2015-02-03T12:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>2015-02-20T09:00:00.0Z</contact:upDate><contact:trDate>2015-10-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><vericontact:infData xmlns:vericontact="urn:ietf:params:xml:ns:vericontact-1.0"><vericontact:status>pass</vericontact:status><vericontact:history><vericontact:record><vericontact:date>2015-02-06T12:00:00.0Z</vericontact:date><vericontact:op>PASS</vericontact:op><vericontact:clID>ClientX</vericontact:clID></vericontact:record><vericontact:record><vericontact:date>2001-02-03T15:00:00.0Z</vericontact:date><vericontact:op>PENDINGVERIFY</vericontact:op><vericontact:clID>ClientX</vericontact:clID></vericontact:record><vericontact:record><vericontact:date>2015-02-03T12:00:00.0Z</vericontact:date><vericontact:op>UNVERIFIED</vericontact:op><vericontact:clID>ClientX</vericontact:clID></vericontact:record></vericontact:history></vericontact:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('sh8013'));
my $rr=$rc->get_data('contact','sh8013','restriction');
is($rr->{status}, 'pass', 'contact_info restriction status');
my @h=@{$rr->{history}};
is(scalar @h, 3, 'contact_info restriction history count');
is(''.$h[0]->{date}, '2015-02-06T12:00:00', 'contact_info restriction history 1 date');
is($h[0]->{op}, 'PASS', 'contact_info restriction history 1 op');
is($h[0]->{clID}, 'ClientX', 'contact_info restriction history 1 clID');
is(''.$h[1]->{date}, '2001-02-03T15:00:00', 'contact_info restriction history 2 date');
is($h[1]->{op}, 'PENDINGVERIFY', 'contact_info restriction history 2 op');
is($h[1]->{clID}, 'ClientX', 'contact_info restriction history 2 clID');
is(''.$h[2]->{date}, '2015-02-03T12:00:00', 'contact_info restriction history 3 date');
is($h[2]->{op}, 'UNVERIFIED', 'contact_info restriction history 3 op');
is($h[2]->{clID}, 'ClientX', 'contact_info restriction history 3 clID');


exit 0;
