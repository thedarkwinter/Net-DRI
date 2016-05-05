#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 7;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}});
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['CNNIC::Bundling','-VeriSign::NameStore','-VeriSign::IDNLanguage']});


my $rc;


$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--fsq270a.com</domain:name><domain:roid>58812678-domain</domain:roid><domain:status s="ok"/><domain:registrant>123</domain:registrant><domain:contact type="admin">123</domain:contact><domain:contact type="tech">123</domain:contact><domain:ns><domain:hostObj>ns1.example.cn</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2011-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2012-04-03T22:00:00.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><b-dn:infData xmlns:b-dn="urn:ietf:params:xml:ns:b-dn-1.0"><b-dn:bundle><b-dn:rdn uLabel="实例.example">xn--fsq270a.example</b-dn:rdn><b-dn:bdn uLabel="實例.example">xn--fsqz41a.example</b-dn:bdn></b-dn:bundle></b-dn:infData></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_info('xn--fsq270a.com');
is_deeply($rc->get_data('domain','xn--fsq270a.com','rdn'),{alabel => 'xn--fsq270a.example', ulabel => '实例.example'},'domain_info reply rdn');
is_deeply($rc->get_data('domain','xn--fsq270a.com','bdn'),{alabel => 'xn--fsqz41a.example', ulabel => '實例.example'},'domain_info reply bdn');



$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--fsq270a.com</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><b-dn:creData xmlns:b-dn="urn:ietf:params:xml:ns:b-dn-1.0"><b-dn:bundle><b-dn:rdn uLabel="实例.example">xn--fsq270a.example</b-dn:rdn><b-dn:bdn uLabel="實例.example">xn--fsqz41a.example</b-dn:bdn></b-dn:bundle></b-dn:creData></extension>'.$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('123');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'tech');
$rc=$dri->domain_create('xn--fsq270a.com',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'2fooBAR'},ulabel=>'实例.com'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--fsq270a.com</domain:name><domain:period unit="y">2</domain:period><domain:registrant>123</domain:registrant><domain:contact type="admin">123</domain:contact><domain:contact type="tech">123</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><b-dn:create xmlns:b-dn="urn:ietf:params:xml:ns:b-dn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:b-dn-1.0 b-dn-1.0.xsd"><b-dn:rdn uLabel="实例.com">xn--fsq270a.com</b-dn:rdn></b-dn:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is_deeply($rc->get_data('domain','xn--fsq270a.com','rdn'),{alabel => 'xn--fsq270a.example', ulabel => '实例.example'},'domain_create reply rdn');
is_deeply($rc->get_data('domain','xn--fsq270a.com','bdn'),{alabel => 'xn--fsqz41a.example', ulabel => '實例.example'},'domain_create reply bdn');



$R2=$E1.'<response>'.r().'<extension><b-dn:delData xmlns:b-dn="urn:ietf:params:xml:ns:b-dn-1.0"><b-dn:bundle><b-dn:rdn uLabel="实例.example">xn--fsq270a.example</b-dn:rdn><b-dn:bdn uLabel="實例.example">xn--fsqz41a.example</b-dn:bdn></b-dn:bundle></b-dn:delData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('xn--fsq270a.com');
is_deeply($rc->get_data('domain','xn--fsq270a.com','rdn'),{alabel => 'xn--fsq270a.example', ulabel => '实例.example'},'domain_delete reply rdn');
is_deeply($rc->get_data('domain','xn--fsq270a.com','bdn'),{alabel => 'xn--fsqz41a.example', ulabel => '實例.example'},'domain_delete reply bdn');



exit 0;
