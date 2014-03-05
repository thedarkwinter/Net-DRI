#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 18;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CentralNic');
$dri->target('CentralNic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

####################################################################################################
## DNS TTL extension

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.eu.com</domain:name><domain:roid>CNIC-DO302520</domain:roid><domain:status s="ok"/><domain:registrant>C11480</domain:registrant><domain:contact type="tech">C11480</domain:contact><domain:clID>C11480</domain:clID><domain:ns><domain:hostObj>ns0.example.com</domain:hostObj><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:crDate>1995-01-01T00:00:00.0Z</domain:crDate><domain:exDate>2020-01-01T23:59:59.0Z</domain:exDate><domain:upDate>2005-05-14T11:15:19.0Z</domain:upDate></domain:infData></resData><extension><ttl:infData xmlns:ttl="urn:centralnic:params:xml:ns:ttl-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:ttl-1.0 ttl-1.0.xsd"><ttl:secs>3600</ttl:secs></ttl:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.eu.com');
$s=$dri->get_info('ttl');
isa_ok($s,'DateTime::Duration','TTL extension: ttl key');
is($s->in_units('seconds'),3600,'TTL extension: value');

$R2='';
my $cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('C11480'),'registrant');
$cs->set($dri->local_object('contact')->srid('C11480'),'tech');
$rc=$dri->domain_create('example2.eu.com',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},ttl=>DateTime::Duration->new(seconds => 300)});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.eu.com</domain:name><domain:registrant>C11480</domain:registrant><domain:contact type="tech">C11480</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><ttl:create xmlns:ttl="urn:centralnic:params:xml:ns:ttl-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:ttl-1.0 ttl-1.0.xsd"><ttl:secs>300</ttl:secs></ttl:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'TTL extension: domain_create build with DateTime::Duration');


$R2='';
$rc=$dri->domain_create('example3.eu.com',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},ttl=>600});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.eu.com</domain:name><domain:registrant>C11480</domain:registrant><domain:contact type="tech">C11480</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><ttl:create xmlns:ttl="urn:centralnic:params:xml:ns:ttl-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:ttl-1.0 ttl-1.0.xsd"><ttl:secs>600</ttl:secs></ttl:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'TTL extension: domain_create build with integer');

$R2='';
my $toc=$dri->local_object('changes');
$toc->set('ttl',300);
$rc=$dri->domain_update('example4.eu.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.eu.com</domain:name></domain:update></update><extension><ttl:update xmlns:ttl="urn:centralnic:params:xml:ns:ttl-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:ttl-1.0 ttl-1.0.xsd"><ttl:secs>300</ttl:secs></ttl:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'TTL extension: domain_update build');

####################################################################################################
## Web Forwarding extension

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example5.eu.com</domain:name><domain:roid>CNIC-DO302520</domain:roid><domain:status s="ok"/><domain:registrant>C11480</domain:registrant><domain:contact type="tech">C11480</domain:contact><domain:clID>C11480</domain:clID><domain:crDate>1995-01-01T00:00:00.0Z</domain:crDate><domain:exDate>2020-01-01T23:59:59.0Z</domain:exDate><domain:upDate>2005-05-14T11:15:19.0Z</domain:upDate></domain:infData></resData><extension><wf:infData xmlns:wf="urn:centralnic:params:xml:ns:wf-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:wf-1.0 wf-1.0.xsd"><wf:url>http://www.example.com/</wf:url></wf:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example5.eu.com');
$s=$dri->get_info('web_forwarding');
is($s,'http://www.example.com/','WebForwarding extension: value');

$R2='';
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('C11480'),'registrant');
$cs->set($dri->local_object('contact')->srid('C11480'),'tech');
$rc=$dri->domain_create('example6.eu.com',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},web_forwarding=>'http://www.example.com/'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example6.eu.com</domain:name><domain:registrant>C11480</domain:registrant><domain:contact type="tech">C11480</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><wf:create xmlns:wf="urn:centralnic:params:xml:ns:wf-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:wf-1.0 wf-1.0.xsd"><wf:url>http://www.example.com/</wf:url></wf:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'WebForwarding extension: domain_create build');

$R2='';
$toc=$dri->local_object('changes');
$toc->set('web_forwarding','http://www.example.com/');
$rc=$dri->domain_update('example7.eu.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example7.eu.com</domain:name></domain:update></update><extension><wf:update xmlns:wf="urn:centralnic:params:xml:ns:wf-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:wf-1.0 wf-1.0.xsd"><wf:url>http://www.example.com/</wf:url></wf:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'WebForwarding extension: domain_update build');

$R2='';
$toc=$dri->local_object('changes');
$toc->set('web_forwarding','');
$rc=$dri->domain_update('example8.eu.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example8.eu.com</domain:name></domain:update></update><extension><wf:update xmlns:wf="urn:centralnic:params:xml:ns:wf-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:wf-1.0 wf-1.0.xsd"><wf:url/></wf:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'WebForwarding extension: domain_update build with empty url');

####################################################################################################
## Release extension


$R2=$E1.'<response>'.r(1001,'Command completed successfully.').'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.eu.com</domain:name><domain:trStatus>approved</domain:trStatus></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_release('example9.eu.com',{clID=>'H12345'});
is_string($R1,$E1.'<command><transfer op="release"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.eu.com</domain:name><domain:clID>H12345</domain:clID></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'Release extension: domain_release build');
is($rc->is_success(),1,'Release extension: domain_release is_success');
is($rc->is_pending(),1,'Release extension: domain_release is_pending');
is($dri->get_info('trStatus'),'approved','Release extension: domain_release get_info(trStatus)');

####################################################################################################
## Pricing extension

$R2=$E1.'<response>'.r(1000,'Command completed successfully.').'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example.uk.com</domain:name></domain:cd></domain:chkData></resData><extension><pricing:chkData xmlns:pricing="urn:centralnic:params:xml:ns:pricing-1.0"><pricing:currency>GBP</pricing:currency><pricing:action>create</pricing:action><pricing:period unit="y">1</pricing:period><pricing:price>32.50</pricing:price></pricing:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.uk.com',{pricing=>{currency=>'GBP',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.uk.com</domain:name></domain:check></check><extension><pricing:check xmlns:pricing="urn:centralnic:params:xml:ns:pricing-1.0" xsi:schemaLocation="urn:centralnic:params:xml:ns:pricing-1.0 pricing-1.0.xsd"><pricing:currency>GBP</pricing:currency><pricing:action>create</pricing:action><pricing:period unit="y">1</pricing:period></pricing:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Pricing extension: domain_check build');
$d=$rc->get_data('pricing');
is($d->{currency},'GBP','Pricing extension: domain_check parse currency');
is($d->{action},'create','Pricing extension: domain_check parse action');
is($d->{duration}->years(),1,'Pricing extension: domain_check parse duration');
is($d->{price},32.50,'Pricing extension: domain_check parse price');

####################################################################################################
exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
