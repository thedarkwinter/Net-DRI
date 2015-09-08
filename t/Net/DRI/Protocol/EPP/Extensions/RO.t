#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use utf8;

use Test::More tests => 43;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('RO');
$dri->target('RO')->add_current_profile('p1', 'epp', { f_send=> \&mysend, f_recv=> \&myrecv });

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->{registries}->{RO}->{driver};
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RO',{}],'RO - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success'); # Code 2101 (Unimplemented Command) - Seems okay for keepalive use ONLY though...
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

####################################################################################################
####### Domain Commands ########

### 1.0 Domain Create w/ reservation + terms
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-1.ro</domain:name><domain:crDate>2012-09-19T08:08:20Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2; 
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C646896'),'registrant');
$cs->add($dri->local_object('contact')->srid(''),'tech');
my $domain_terms = {'legal_use' => 'yes', 'reg_rules' => 'yes'};
my $reserve_domain = {'reserve' => '1'};
$rc=$dri->domain_create('test-5btc8khh-1.ro',{domain_terms=>$domain_terms,reserve_domain=>$reserve_domain,pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,auth=>{pw=>'111aA1@11'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-1.ro</domain:name><domain:period unit="y">1</domain:period><domain:registrant>C646896</domain:registrant><domain:contact type="tech"/><domain:authInfo><domain:pw>111aA1@11</domain:pw></domain:authInfo></domain:create></create><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:create><rotld:domain><rotld:agreement legal_use="yes" registration_rules="yes"/><rotld:reserve/></rotld:domain></rotld:create></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create res & terms build_xml');
is($rc->is_success(),1,'domain_create res & terms is_success');

### 1.1 Domain Create w/o reservation w/ terms
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-hizd3lof.ro</domain:name><domain:crDate>2012-09-19T08:08:20Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2; 
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C618518'),'registrant');
$dh=$dri->local_object('hosts');
$dh->add('a.ns.1.test-4oakyw-3.ro',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('a.ns.1.test-4oakyw-3.ro',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns1.example.com',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns1.example.net');
$dh->add('a.ns.1.test-hizd3lof.ro',['192.168.166.131'],['8010:0:0:0:8:800:c002:a714'],1);
$domain_terms = {'legal_use' => 'yes', 'reg_rules' => 'yes'};
$reserve_domain = {'reserve' => '0'};
$rc=$dri->domain_create('test-hizd3lof.ro',{domain_terms=>$domain_terms,reserve_domain=>$reserve_domain,pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'111aA1@11'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-hizd3lof.ro</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>a.ns.1.test-4oakyw-3.ro</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.com</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>a.ns.1.test-hizd3lof.ro</domain:hostName><domain:hostAddr ip="v4">192.168.166.131</domain:hostAddr><domain:hostAddr ip="v6">8010:0:0:0:8:800:c002:a714</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>C618518</domain:registrant><domain:authInfo><domain:pw>111aA1@11</domain:pw></domain:authInfo></domain:create></create><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:create><rotld:domain><rotld:agreement legal_use="yes" registration_rules="yes"/></rotld:domain></rotld:create></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create ns & terms_only build_xml');
# Test below disabled as registry supports both object & host_as_attr. Set "$self->{info}->{host_as_attr}=0;" before running this test and disable the one above it. 
#is($R1,$E1.'<command><create><domain:create xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-hizd3lof.ro</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>a.ns.1.test-4oakyw-3.ro</domain:hostObj><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>a.ns.1.test-hizd3lof.ro</domain:hostObj></domain:ns><domain:registrant>C618518</domain:registrant><domain:authInfo><domain:pw>111aA1@11</domain:pw></domain:authInfo></domain:create></create><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:create><rotld:domain><rotld:agreement legal_use="yes" registration_rules="yes"/></rotld:domain></rotld:create></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create ns & terms_only object_method build_xml');
is($rc->is_success(),1,'domain_create ns & terms_only is_success');

### 1.1.1 Domain Create w/o reservation w/ terms w/ IDN
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-gbdppjee-ăîșțâ.ro</domain:name><domain:crDate>2015-05-27T08:24:52Z</domain:crDate></domain:creData></resData><extension><idn:mapping xmlns:idn="http://www.rotld.ro/xml/epp/idn-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/idn-1.0 idn-1.0.xsd"><idn:name><idn:ace>xn--test-gbdppjee--ohb5qsnr6odb.ro</idn:ace><idn:unicode>test-gbdppjee-ăîșțâ.ro</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2; 
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C1192942'),'registrant');
$cs->add($dri->local_object('contact')->srid(''),'tech');
$dh=$dri->local_object('hosts');
$dh->add('xn--0la.xn--n-oxa.xn--fda.xn--test-gbdppjee--ohb5qsnr6odb.ro',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$domain_terms = {'legal_use' => 'yes', 'reg_rules' => 'yes'};
$reserve_domain = {'reserve' => '0'};
$rc=$dri->domain_create('xn--test-gbdppjee--ohb5qsnr6odb.ro',{domain_terms=>$domain_terms,reserve_domain=>$reserve_domain,pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'Parol@1'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>xn--test-gbdppjee--ohb5qsnr6odb.ro</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>xn--0la.xn--n-oxa.xn--fda.xn--test-gbdppjee--ohb5qsnr6odb.ro</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>C1192942</domain:registrant><domain:contact type="tech"/><domain:authInfo><domain:pw>Parol@1</domain:pw></domain:authInfo></domain:create></create><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:create><rotld:domain><rotld:agreement legal_use="yes" registration_rules="yes"/></rotld:domain></rotld:create></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create ns & terms & idn build_xml');
is($rc->is_success(),1,'domain_create ns & terms & idn is_success');

### 1.2 Domain Trade Start (Obtaining an Authorization Key)
$R2=$E1.'<response>'.r().'<resData><domain:trdData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-ia8gq5cs.ro</domain:name><domain:trStatus /><domain:reID/><domain:reDate>2013-07-26T00:00:00Z</domain:reDate><domain:acID/><domain:acDate/><domain:exDate>2013-08-09T00:00:00Z</domain:exDate></domain:trdData></resData><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trdData><rotld:domain><rotld:request><rotld:authorization_key>2f4MmCXsrRHE</rotld:authorization_key></rotld:request></rotld:domain></rotld:trdData></rotld:ext></extension>'.$TRID.'</response>'.$E2; 
$rc=$dri->domain_trade_start('test-ia8gq5cs.ro');
is($R1,$E1.'<command><trade op="request"><domain:trade xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-ia8gq5cs.ro</domain:name></domain:trade></trade><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trade><rotld:domain><rotld:request/></rotld:domain></rotld:trade></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_trade obtain_auth_key build_xml');
is($rc->is_success(),1,'domain_trade obtain_auth_key is_success');
is($dri->get_info('authorization_key'),'2f4MmCXsrRHE','domain_trade get_info(authorization_key)');

### 1.3 Domain Trade Start (Initiating the trade operation)
$R2=$E1.'<response>'.r().'<resData><domain:trdData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-ia8gq5cs.ro</domain:name><domain:trStatus /><domain:reID /><domain:reDate /><domain:acID /><domain:acDate /><domain:exDate /></domain:trdData></resData><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trdData><rotld:domain><rotld:request><rotld:tid>11474</rotld:tid></rotld:request></rotld:domain></rotld:trdData></rotld:ext></extension>'.$TRID.'</response>'.$E2; 
my $trade_auth_info = {'authorization_key' => '2f4MmCXsrRHE', 'c_registrant' => 'C765673', 'domain_password' => '1!1!aA'};
$rc=$dri->domain_trade_start('test-ia8gq5cs.ro',{trade_auth_info=>$trade_auth_info});
is($R1,$E1.'<command><trade op="request"><domain:trade xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-ia8gq5cs.ro</domain:name></domain:trade></trade><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trade><rotld:domain><rotld:request><rotld:authorization_key>2f4MmCXsrRHE</rotld:authorization_key><rotld:c_registrant>C765673</rotld:c_registrant><rotld:domain_password>1!1!aA</rotld:domain_password></rotld:request></rotld:domain></rotld:trade></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_trade initialize_op build_xml');
is($rc->is_success(),1,'domain_trade initialize_op is_success');
is($dri->get_info('tid'),'11474','domain_trade get_info(tid)');

### 1.4 Domain Trade Approve (Approving Domain Trade)
$R2='';
$rc=$dri->domain_trade_approve('test-ia8gq5cs.ro',{tid=>'11474'});
is($R1,$E1.'<command><trade op="approve"><domain:trade xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-ia8gq5cs.ro</domain:name></domain:trade></trade><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trade><rotld:domain><rotld:approve><rotld:tid>11474</rotld:tid></rotld:approve></rotld:domain></rotld:trade></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_trade approve_req build_xml');
is($rc->is_success(),1,'domain_trade approve_req is_success');

### 1.5 Domain Trade Query
$R2=$E1.'<response>'.r().'<resData><domain:trdData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-1.ro</domain:name><domain:trStatus>0</domain:trStatus><domain:reID>C675996</domain:reID><domain:reDate>2012-08-07T00:00:00Z</domain:reDate><domain:acID /><domain:acDate /><domain:exDate>2012-09-21T00:00:00Z</domain:exDate></domain:trdData></resData><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trdData><rotld:domain><rotld:query><rotld:registry_confirm>0</rotld:registry_confirm><rotld:registrar_confirm>0</rotld:registrar_confirm><rotld:close_date/><rotld:tid>106</rotld:tid></rotld:query></rotld:domain></rotld:trdData></rotld:ext></extension>'.$TRID.'</response>'.$E2; 
$rc=$dri->domain_trade_query('test-5btc8khh-1.ro',{tid=>'106'});
is($R1,$E1.'<command><trade op="query"><domain:trade xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-1.ro</domain:name></domain:trade></trade><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:trade><rotld:domain><rotld:query><rotld:tid>106</rotld:tid></rotld:query></rotld:domain></rotld:trade></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_trade_query build_xml');
is($rc->is_success(),1,'domain_trade_query is_success');
is($dri->get_info('registry_confirm'),'0','domain_trade_query get_info(registry_confirm)');
is($dri->get_info('registrar_confirm'),'0','domain_trade_query get_info(registrar_confirm)');
is($dri->get_info('tid'),'106','domain_trade_query get_info(tid)');
is($dri->get_info('close_date'),undef,'domain_trade_query get_info(close_date)'); # Value is undef on purpose according to spec

### 1.6 Domain Transfer
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('test-5btc8khh-1.ro',{authorization_key=>'fFjMmUZJQyzvXB53'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-1.ro</domain:name></domain:transfer></transfer><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:transfer><rotld:domain><rotld:authorization_key>fFjMmUZJQyzvXB53</rotld:authorization_key></rotld:domain></rotld:transfer></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build_xml');
is($rc->is_success(),1,'domain_transfer_start is_success');

### 1.7 Domain Update (With Activation)
$R2='';
my $toc=$dri->local_object('changes');
my $hosts=$dri->local_object('hosts');
$hosts->add('a.ns.1.test-4oakyw-3.ro',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$hosts->add('ns1.update-example.net',[''],[''],1);
$hosts->add('a.ns.1.test-6lijl3yd.ro',['192.168.16.131'],[''],1);
$hosts->add('a.ns.1.update.test-6lijl3yd.ro',['192.168.166.131'],[''],1);
$toc->add('ns',$hosts);
$toc->set('activate_domain','1'); # 'true/false' = 1/0
$rc=$dri->domain_update('test-6lijl3yd.ro',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-6lijl3yd.ro</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>a.ns.1.test-4oakyw-3.ro</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.update-example.net</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>a.ns.1.test-6lijl3yd.ro</domain:hostName><domain:hostAddr ip="v4">192.168.16.131</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>a.ns.1.update.test-6lijl3yd.ro</domain:hostName><domain:hostAddr ip="v4">192.168.166.131</domain:hostAddr></domain:hostAttr></domain:ns></domain:add></domain:update></update><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:update><rotld:domain><rotld:activate/></rotld:domain></rotld:update></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update add_hosts + activation build_xml');
# Test below disabled as registry supports both object & host_as_attr. Set "$self->{info}->{host_as_attr}=0;" before running this test and disable the one above it. 
#is_string($R1,$E1.'<command><update><domain:update xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-6lijl3yd.ro</domain:name><domain:add><domain:ns><domain:hostObj>a.ns.1.test-4oakyw-3.ro</domain:hostObj><domain:hostObj>ns1.update-example.net</domain:hostObj><domain:hostObj>a.ns.1.test-6lijl3yd.ro</domain:hostObj><domain:hostObj>a.ns.1.update.test-6lijl3yd.ro</domain:hostObj></domain:ns></domain:add></domain:update></update><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:update><rotld:domain><rotld:activate/></rotld:domain></rotld:update></rotld:ext></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update add_hosts + activation object_method build_xml');
is($rc->is_success(), 1, 'domain_update add_hosts + activation is success');

### 1.8 Domain Renew 
$R2='';
my $du = DateTime::Duration->new(years => 1);
my $exp = DateTime->new(year => 2015,month => 05,day => 01);
$rc = $dri->domain_renew('test-5btc8khh-6.ro',{duration=>$du,current_expiration=>$exp} );
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>test-5btc8khh-6.ro</domain:name><domain:curExpDate>2015-05-01</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build_xml');
is($rc->is_success(), 1, 'domain_renew is success');

### 1.9 Domain Info
$R2='';
$rc = $dri->domain_info('test-5btc8khh-7.ro');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name hosts="all">test-5btc8khh-7.ro</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build_xml');
is($rc->is_success(), 1, 'domain_info is success');

### 2.0 Domain Check with IDN
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="0">test-a8r7bs6j-ăîșțâ.ro</domain:name><domain:reason>Not Available</domain:reason></domain:cd></domain:chkData></resData><extension><idn:mapping xmlns:idn="http://www.rotld.ro/xml/epp/idn-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/idn-1.0 idn-1.0.xsd"><idn:name><idn:ace>xn--test-a8r7bs6j--ohb5qsnr6odb.ro</idn:ace><idn:unicode>test-a8r7bs6j-ăîșțâ.ro</idn:unicode></idn:name></idn:mapping><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:check_renew_availability renewable="0"><rotld:reason>OPERATION NOT SUPPORTED FOR YOUR REGISTRAR TYPE</rotld:reason></rotld:check_renew_availability></rotld:ext></extension>'.$TRID.'</response>'.$E2; 
$rc = $dri->domain_check('xn--test-9gxjiy7m--ohb5qsnr6odb.ro');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>xn--test-9gxjiy7m--ohb5qsnr6odb.ro</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check idn build_xml');
is($dri->get_info('ace'),'xn--test-a8r7bs6j--ohb5qsnr6odb.ro','domain_check_extension idn get_info(ace)');
is($dri->get_info('unicode'),'test-a8r7bs6j-ăîșțâ.ro','domain_check_extension idn get_info(unicode)');
is_deeply($dri->get_info('renew_availability'),{ renewable => '0', reason => 'OPERATION NOT SUPPORTED FOR YOUR REGISTRAR TYPE'},'domain_check_extension idn get_info(renew_availability) structure');
is($rc->is_success(), 1, 'domain_check idn is success');

### 2.0 Domain Check
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">romatime.ro</domain:name></domain:cd></domain:chkData></resData><extension><idn:mapping xmlns:idn="http://www.rotld.ro/xml/epp/idn-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/idn-1.0 idn-1.0.xsd" /><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:check_renew_availability renewable="0"><rotld:reason>OPERATION NOT SUPPORTED FOR YOUR REGISTRAR TYPE</rotld:reason></rotld:check_renew_availability></rotld:ext></extension>'.$TRID.'</response>'.$E2; 
$rc = $dri->domain_check('romatime.ro');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="http://www.rotld.ro/xml/epp/domain-1.0" xsi:schemaLocation="http://www.rotld.ro/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>romatime.ro</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check dna build_xml');
is_deeply($dri->get_info('renew_availability'),{ renewable => '0', reason => 'OPERATION NOT SUPPORTED FOR YOUR REGISTRAR TYPE'},'domain_check_extension dna get_info(renew_availability) structure');
is($rc->is_success(), 1, 'domain_check dna is success');

####################################################################################################
####### Host Commands [No extensions or change from EPP 1.0] ########

### 2.0 Host Create [Disabled as only .RO nameservers are allowed as host objects....]
#$R2='';
#$rc=$dri->host_create($dri->local_object('hosts')->add('ns.1.test-t4s3zmg.ro',['1.2.3.4'],['2a03:5e80:0:4::133e']));
#is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns.1.test-t4s3zmg.ro</host:name><host:addr ip="v4">1.2.3.4</host:addr><host:addr ip="v6">2a03:5e80:0:4::133e</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build_xml');
#is($rc->is_success(), 1, 'host_create is success');

####################################################################################################
####### Contact Commands ########

### 3.0 Contact Create /w Extension
$co=$dri->local_object('contact')->srid('AUTO');
$co->name('TESTER');
$co->org('');
$co->street(['Address #1','Address #2','Address #3']);
$co->city('City');
$co->sp('Province');
$co->pc('234356');
$co->cc('RO');
$co->voice('+40.2345345');
$co->fax('+40.0741028699');
$co->email('bogdan@rotld.ro');
$co->vat('22222222222'); # VAT Number of a legal entity or ID number of an invidivual
$co->orgno('11111111111'); # 'Registration' number of the entity
$co->type('c'); # Type of contact [p / ap / nc / c / gi / pi / o]
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AUTO</contact:id><contact:postalInfo type="int"><contact:name>TESTER</contact:name><contact:org/><contact:addr><contact:street>Address #1</contact:street><contact:street>Address #2</contact:street><contact:street>Address #3</contact:street><contact:city>City</contact:city><contact:sp>Province</contact:sp><contact:pc>234356</contact:pc><contact:cc>RO</contact:cc></contact:addr></contact:postalInfo><contact:voice>+40.2345345</contact:voice><contact:fax>+40.0741028699</contact:fax><contact:email>bogdan@rotld.ro</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><rotld:ext xmlns:rotld="http://www.rotld.ro/xml/epp/rotld-1.0"><rotld:create><rotld:contact><rotld:cnp_fiscal_code>22222222222</rotld:cnp_fiscal_code><rotld:registration_number>11111111111</rotld:registration_number><rotld:person_type>c</rotld:person_type></rotld:contact></rotld:create></rotld:ext></extension><clTRID>ABC-12345</clTRID></command></epp>','contact_create with_extension build_xml');
is($rc->is_success(),1,'contact_create with_extension is_success');

exit 0;
