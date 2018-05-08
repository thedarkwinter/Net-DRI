#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;

use Test::More tests => 11;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$toc);

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('Neustar::Narwhal');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});

#####################
## KeyValue Extension

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><kv:infData xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.menu');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.menu','domain_info get_info name');
my $kv = $dri->get_info('keyvalue');
is_deeply($kv,{ bn => { 'entityType' => 'Australian Private Company', 'abn' => '18 092 242 209' } },'domain_info get_info keyvalue');

# domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},keyvalue => $kv });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><kv:create xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:kv-1.0 kv-1.0.xsd"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create idn_variants build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

#doman update
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
$toc=$dri->local_object('changes');
$toc->set('keyvalue',$kv);
$rc=$dri->domain_update('example3.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name></domain:update></update><extension><kv:update xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:kv-1.0 kv-1.0.xsd"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update variants build_xml');

# domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>test.travel</domain:name><domain:exDate>2019-10-24T00:13:53.26Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('test.travel',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2018,month=>10,day=>24), keyvalue => { 'UIN' => { 'UIN' => '1111'} } });
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.travel</domain:name><domain:curExpDate>2018-10-24</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><extension><kv:renew xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:kv-1.0 kv-1.0.xsd"><kv:kvlist name="UIN"><kv:item key="UIN">1111</kv:item></kv:kvlist></kv:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build_xml');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
my $d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2019-10-24T00:13:53','domain_renew get_info(exDate) value');

exit 0;
