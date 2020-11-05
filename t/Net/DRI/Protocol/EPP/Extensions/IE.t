#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 4;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 0});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CIRA::IE');
$dri->target('CIRA::IE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$co,$h,$toc);
use Data::Dumper; # TODO: delete when all implemented and tested :)

####################################################################################################
## Fury RGP 1.0 EPP Extension

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>testing.ie</domain:name><domain:roid>10-Fury</domain:roid><domain:status s="inactive"/><domain:status s="pendingDelete"/><domain:status s="serverHold"/><domain:status s="serverRenewProhibited"/><domain:status s="serverTransferProhibited"/><domain:status s="serverUpdateProhibited"/><domain:clID>AB002</domain:clID><domain:crDate>2018-11-05T20:59:37.964Z</domain:crDate><domain:upDate>2018-11-06T15:00:35.668Z</domain:upDate><domain:exDate>2020-11-05T20:59:37.964Z</domain:exDate></domain:infData></resData><extension><rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:rgpStatus s="redemptionPeriod"/></rgp:infData><fury-rgp:rgpInfo xmlns:fury-rgp="urn:ietf:params:xml:ns:fury-rgp-1.0"><fury-rgp:rgpStatusEnd>2018-11-03T19:22:29.273Z</fury-rgp:rgpStatusEnd></fury-rgp:rgpInfo></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('testing.ie');
is($rc->get_data('domain','testing.ie','rgp_status_end'), '2018-11-03T19:22:29', 'domain_info parse rgp_status_end');

####################################################################################################
## Fury 2.0 EPP Extension

## Contact create

$co=$dri->local_object('contact');
$co->srid('testcontact1');
$co->name('John Doe');
$co->org('Test Organization');
$co->street(['123 Main Street']);
$co->city('Ottawa');
$co->sp('ON');
$co->pc('K1R 7S8');
$co->cc('CA');
$co->voice('+1.6134375335');
$co->fax('+1.6134375366');
$co->email('jdoe@example.com');
$co->auth({ pw => 'password' });
$co->lang('en');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>testcontact1</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Test Organization</contact:org><contact:addr><contact:street>123 Main Street</contact:street><contact:city>Ottawa</contact:city><contact:sp>ON</contact:sp><contact:pc>K1R 7S8</contact:pc><contact:cc>CA</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.6134375335</contact:voice><contact:fax>+1.6134375366</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><fury:create xmlns:fury="urn:ietf:params:xml:ns:fury-2.0"><fury:properties><fury:property><fury:key>LANGUAGE</fury:key><fury:value>EN</fury:value></fury:property></fury:properties></fury:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'contact_create build 1');

$co=$dri->local_object('contact');
$co->srid('testcontact2');
$co->name('John Doe');
$co->org('Test Organization');
$co->street(['2 Harbour Square']);
$co->city('Dublin');
$co->sp('ON');
$co->pc('A96 D6R0');
$co->cc('IE');
$co->voice('+1.6134375335');
$co->fax('+1.6134375366');
$co->email('jdoe@example.com');
$co->auth({ pw => 'password' });
$co->lang('en');
$co->contact_type('COM');
$co->cro_number('123456');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>testcontact2</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Test Organization</contact:org><contact:addr><contact:street>2 Harbour Square</contact:street><contact:city>Dublin</contact:city><contact:sp>ON</contact:sp><contact:pc>A96 D6R0</contact:pc><contact:cc>IE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.6134375335</contact:voice><contact:fax>+1.6134375366</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><fury:create xmlns:fury="urn:ietf:params:xml:ns:fury-2.0"><fury:properties><fury:property><fury:key>IE_CONTACT_TYPE</fury:key><fury:value>COM</fury:value></fury:property><fury:property><fury:key>IE_CRO_NUMBER</fury:key><fury:value>123456</fury:value></fury:property><fury:property><fury:key>LANGUAGE</fury:key><fury:value>EN</fury:value></fury:property></fury:properties></fury:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'contact_create build 2');

$co=$dri->local_object('contact');
$co->srid('testcontact3');
$co->name('Foo Name');
$co->org('Bar Org');
$co->street(['Line 1', 'Line 2', 'Line 3']);
$co->city('Ottawa');
$co->sp('on');
$co->pc('K1N4B3');
$co->cc('ca');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.fury');
$co->auth({ pw => '2fooBAR' });
$co->disclose({ voice => 0, email => 0 });
$co->lang('en');
$co->contact_type('COM');
$co->cro_number('123456');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>testcontact3</contact:id><contact:postalInfo type="loc"><contact:name>Foo Name</contact:name><contact:org>Bar Org</contact:org><contact:addr><contact:street>Line 1</contact:street><contact:street>Line 2</contact:street><contact:street>Line 3</contact:street><contact:city>Ottawa</contact:city><contact:sp>on</contact:sp><contact:pc>K1N4B3</contact:pc><contact:cc>ca</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.fury</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><fury:create xmlns:fury="urn:ietf:params:xml:ns:fury-2.0"><fury:properties><fury:property><fury:key>IE_CONTACT_TYPE</fury:key><fury:value>COM</fury:value></fury:property><fury:property><fury:key>IE_CRO_NUMBER</fury:key><fury:value>123456</fury:value></fury:property><fury:property><fury:key>LANGUAGE</fury:key><fury:value>EN</fury:value></fury:property></fury:properties></fury:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'contact_create build 3');
exit 0;
