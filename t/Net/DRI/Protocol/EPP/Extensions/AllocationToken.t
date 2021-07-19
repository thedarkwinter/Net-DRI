#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 7;
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
$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['AllocationToken','-VeriSign::NameStore','-VeriSign::WhoisInfo']});

####################################################################################################


$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
my $rc=$dri->domain_check('example.com',{ allocation_token => 'abc123'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name></domain:check></check><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd">abc123</allocationToken:allocationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check allocation_token build 1');



$rc=$dri->domain_check('example.com','example2.com',{ allocation_token => 'abc123'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com</domain:name><domain:name>example2.com</domain:name></domain:check></check><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd">abc123</allocationToken:allocationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check allocation_token build 2');



$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="pendingCreate"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0">abc123</allocationToken:allocationToken></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.com', { allocation_token => 1 });
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.com</domain:name></domain:info></info><extension><allocationToken:info xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info allocation_token build');
is($rc->get_data('allocation_token'),'abc123','domain_info get_data(allocation_token)');



$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('example123.com',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},allocation_token => 'abc123'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example123.com</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd">abc123</allocationToken:allocationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create allocation_token build');



{
 no warnings;
 *Net::DRI::DRD::VNDS::verify_duration_transfer=sub { return 0; };
}
$rc=$dri->domain_transfer_start('example205.com',{auth=>{pw=>'2fooBAR'},duration=>DateTime::Duration->new(years=>1),allocation_token => 'abc123'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.com</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd">abc123</allocationToken:allocationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer allocation_token build');



my $toc=$dri->local_object('changes');
$toc->set('auth',{pw=>'2BARfoo'});
$toc->set('allocation_token', 'abc123');
$rc=$dri->domain_update('example206.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example206.com</domain:name><domain:chg><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><allocationToken:allocationToken xmlns:allocationToken="urn:ietf:params:xml:ns:allocationToken-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:allocationToken-1.0 allocationToken-1.0.xsd">abc123</allocationToken:allocationToken></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update allocation_token build');



exit 0;
