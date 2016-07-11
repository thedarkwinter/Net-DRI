#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 5;
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
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['ResellerInfo','-VeriSign::NameStore']});


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg lang="en-US">Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2015-02-06T04:01:21.0Z</domain:crDate><domain:exDate>2018-02-06T04:01:21.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:rgpStatus s="addPeriod"/></rgp:infData><resellerext:infData xmlns:resellerext="urn:ietf:params:xml:ns:resellerext-1.0"><resellerext:id>myreseller</resellerext:id><resellerext:name>example</resellerext:name></resellerext:infData></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->domain_info('example.com');
my $rk=$rc->get_data('domain','example.com','reseller');
is($rk,'myreseller','get_data reseller info after domain_info');

my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$cs->set($c2,'billing');
$R2='';
$rc=$dri->domain_create('reseller.com',{pure_create=>1,duration=>DateTime::Duration->new(years=>3),ns=>$dri->local_object('hosts')->set(['ns1.example.com']),contact=>$cs,auth=>{pw=>'fooBAR',roid=>'ddddd-dddd'}, reseller => 'myreseller'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>reseller.com</domain:name><domain:period unit="y">3</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw roid="ddddd-dddd">fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><resellerext:create xmlns:resellerext="urn:ietf:params:xml:ns:resellerext-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:resellerext-1.0 resellerext-1.0.xsd"><resellerext:id>myreseller</resellerext:id></resellerext:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');



$R2='';
my $toc=$dri->local_object('changes');
$toc->add('reseller', 'myreseller');
$rc=$dri->domain_update('example.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name></domain:update></update><extension><resellerext:update xmlns:resellerext="urn:ietf:params:xml:ns:resellerext-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:resellerext-1.0 resellerext-1.0.xsd"><resellerext:add><resellerext:id>myreseller</resellerext:id></resellerext:add></resellerext:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update add build');

$toc=$dri->local_object('changes');
$toc->del('reseller', 'myreseller');
$rc=$dri->domain_update('example.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name></domain:update></update><extension><resellerext:update xmlns:resellerext="urn:ietf:params:xml:ns:resellerext-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:resellerext-1.0 resellerext-1.0.xsd"><resellerext:rem><resellerext:id>myreseller</resellerext:id></resellerext:rem></resellerext:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update rem build');

$toc=$dri->local_object('changes');
$toc->set('reseller', 'myreseller');
$rc=$dri->domain_update('example.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name></domain:update></update><extension><resellerext:update xmlns:resellerext="urn:ietf:params:xml:ns:resellerext-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:resellerext-1.0 resellerext-1.0.xsd"><resellerext:chg><resellerext:id>myreseller</resellerext:id></resellerext:chg></resellerext:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update chg build');

exit 0;
