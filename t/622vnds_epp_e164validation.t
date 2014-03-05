#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Test::More tests => 6;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };

use Net::DRI::DRD::VNDS;
{
 no strict;
 no warnings;
 sub Net::DRI::DRD::VNDS::tlds { return ('e164.arpa'); };
 sub Net::DRI::DRD::VNDS::verify_name_domain { return ''; };
}

$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['E164Validation']});

my ($rc,$e,$toc);

#########################################################################################################
## Extension: E164Validation (RFC5076)

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>5.1.5.1.8.6.2.4.4.1.4.e164.arpa</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><e164val:infData xmlns:e164val="urn:ietf:params:xml:ns:e164val-1.0"><e164val:inf id="EK77"><e164val:validationInfo><valex:simpleVal xmlns:valex="urn:ietf:params:xml:ns:e164valex-1.1"><valex:methodID>Validation-X</valex:methodID><valex:validationEntityID>VE-NMQ</valex:validationEntityID><valex:registrarID>Client-X</valex:registrarID><valex:executionDate>2004-04-08</valex:executionDate><valex:expirationDate>2004-10-07</valex:expirationDate></valex:simpleVal></e164val:validationInfo></e164val:inf></e164val:infData></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_info('5.1.5.1.8.6.2.4.4.1.4.e164.arpa',{auth=>{pw=>'2fooBAR'}});
is($dri->get_info('exist'),1,'domain_info get_info(exist) +E164Validation');
$e=$dri->get_info('e164_validation_information');
is_deeply($e,[['EK77','urn:ietf:params:xml:ns:e164valex-1.1',{method_id=>'Validation-X',validation_entity_id=>'VE-NMQ',registrar_id=>'Client-X',execution_date=>'2004-04-08T00:00:00',expiration_date=>'2004-10-07T00:00:00'}]],'domain_info get_info(validation_information) +E164Validation');

$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('5.1.5.1.8.6.2.4.4.1.4.e164.arpa',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']),contact=>$cs,auth=>{pw=>'2fooBAR'},e164_validation_information=>[['EK77','urn:ietf:params:xml:ns:e164valex-1.1',{method_id=>'Validation-X',validation_entity_id=>'VE-NMQ',registrar_id=>'Client-X',execution_date=>DateTime->new(year=>2004,month=>4,day=>8),expiration_date=>DateTime->new(year=>2004,month=>10,day=>7)}]]});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>5.1.5.1.8.6.2.4.4.1.4.e164.arpa</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><e164val:create xmlns:e164val="urn:ietf:params:xml:ns:e164val-1.0"><e164val:add id="EK77"><e164val:validationInfo><valex:simpleVal xmlns:valex="urn:ietf:params:xml:ns:e164valex-1.1"><valex:methodID>Validation-X</valex:methodID><valex:validationEntityID>VE-NMQ</valex:validationEntityID><valex:registrarID>Client-X</valex:registrarID><valex:executionDate>2004-04-08</valex:executionDate><valex:expirationDate>2004-10-07</valex:expirationDate></valex:simpleVal></e164val:validationInfo></e164val:add></e164val:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build +E164Validation');

$rc=$dri->domain_renew('5.1.5.1.8.6.2.4.4.1.4.e164.arpa',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2005,month=>4,day=>9),e164_validation_information=>[['CAB176','urn:ietf:params:xml:ns:e164valex-1.1',{method_id=>'Validation-X',validation_entity_id=>'VE-NMQ',registrar_id=>'Client-X',execution_date=>'2005-03-30',expiration_date=>'2005-09-29'}]]});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>5.1.5.1.8.6.2.4.4.1.4.e164.arpa</domain:name><domain:curExpDate>2005-04-09</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><extension><e164val:renew xmlns:e164val="urn:ietf:params:xml:ns:e164val-1.0"><e164val:add id="CAB176"><e164val:validationInfo><valex:simpleVal xmlns:valex="urn:ietf:params:xml:ns:e164valex-1.1"><valex:methodID>Validation-X</valex:methodID><valex:validationEntityID>VE-NMQ</valex:validationEntityID><valex:registrarID>Client-X</valex:registrarID><valex:executionDate>2005-03-30</valex:executionDate><valex:expirationDate>2005-09-29</valex:expirationDate></valex:simpleVal></e164val:validationInfo></e164val:add></e164val:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build +E164Validation');

$rc=$dri->domain_transfer_start('5.1.5.1.8.6.2.4.4.1.4.e164.arpa',{auth=>{pw=>'2fooBAR',roid=>"HB1973-ZUE"},e164_validation_information=>[['LJ1126','urn:ietf:params:xml:ns:e164valex-1.1',{method_id=>'Validation-Y',validation_entity_id=>'VE2-LMQ',registrar_id=>'Client-Y',execution_date=>'2005-01-22',expiration_date=>'2005-07-21'}]]});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>5.1.5.1.8.6.2.4.4.1.4.e164.arpa</domain:name><domain:authInfo><domain:pw roid="HB1973-ZUE">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><e164val:transfer xmlns:e164val="urn:ietf:params:xml:ns:e164val-1.0"><e164val:add id="LJ1126"><e164val:validationInfo><valex:simpleVal xmlns:valex="urn:ietf:params:xml:ns:e164valex-1.1"><valex:methodID>Validation-Y</valex:methodID><valex:validationEntityID>VE2-LMQ</valex:validationEntityID><valex:registrarID>Client-Y</valex:registrarID><valex:executionDate>2005-01-22</valex:executionDate><valex:expirationDate>2005-07-21</valex:expirationDate></valex:simpleVal></e164val:validationInfo></e164val:add></e164val:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build +E164Validation');

$R2='';
$toc=$dri->local_object('changes');
$toc->add('e164_validation_information',[['EK2510','urn:ietf:params:xml:ns:e164valex-1.1',{method_id=>'Validation-X',validation_entity_id=>'VE-NMQ',registrar_id=>'Client-X',execution_date=>'2004-10-02',expiration_date=>'2005-04-01'}]]);
$toc->del('e164_validation_information',['EK77']);
$rc=$dri->domain_update('5.1.5.1.8.6.2.4.4.1.4.e164.arpa',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>5.1.5.1.8.6.2.4.4.1.4.e164.arpa</domain:name></domain:update></update><extension><e164val:update xmlns:e164val="urn:ietf:params:xml:ns:e164val-1.0"><e164val:add id="EK2510"><e164val:validationInfo><valex:simpleVal xmlns:valex="urn:ietf:params:xml:ns:e164valex-1.1"><valex:methodID>Validation-X</valex:methodID><valex:validationEntityID>VE-NMQ</valex:validationEntityID><valex:registrarID>Client-X</valex:registrarID><valex:executionDate>2004-10-02</valex:executionDate><valex:expirationDate>2005-04-01</valex:expirationDate></valex:simpleVal></e164val:validationInfo></e164val:add><e164val:rem id="EK77"/></e164val:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +E164Validation');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
