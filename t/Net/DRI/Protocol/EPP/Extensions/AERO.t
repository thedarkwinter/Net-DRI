#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 5;
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
$dri->add_registry('AERO');
$dri->target('AERO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co);

####################################################################################################
## Contacts

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>R-123</contact:clID><contact:crID>R-123</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>R-123</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><aero:infData xmlns:aero="urn:afilias:params:xml:ns:ext:aero-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:aero-1.0 aero-1.0.xsd"><aero:ensInfo><aero:registrantGroup>Airport</aero:registrantGroup><aero:ensO>sita</aero:ensO><aero:requestType>manual</aero:requestType><aero:registrationType>ADA ADB BXN DLM ESB ISE IST NAV TZX</aero:registrationType><aero:credentialsType>credentials type</aero:credentialsType><aero:credentialsValue>credentials value</aero:credentialsValue><aero:codeValue>code value</aero:codeValue><aero:uniqueIdentifier>unique identifier</aero:uniqueIdentifier><aero:lastCheckedDate>2006-01-01T18:54:36.0Z</aero:lastCheckedDate></aero:ensInfo></aero:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
my $ens=$dri->get_info('self')->ens();
is(ref($ens),'HASH','contact_info parse 1');
is(''.$ens->{last_checked_date},'2006-01-01T18:54:36','contact_info parse 2');
delete($ens->{last_checked_date});
is_deeply($ens,{registrant_group=>'Airport',ens_o=>'sita',request_type=>'manual',registration_type=>'ADA ADB BXN DLM ESB ISE IST NAV TZX',credentials_type=>'credentials type',credentials_value=>'credentials value',code_value=>'code value',unique_identifier=>'unique identifier'},'contact_info parse 3');

####################################################################################################
## Domains

$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$cs->set($c2,'billing');
$rc=$dri->domain_create('whatever.aero',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},ens=>{auth_id=>'ENS-C1',auth_key=>'my secret'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>whatever.aero</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><aero:create xmlns:aero="urn:afilias:params:xml:ns:ext:aero-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:aero-1.0 aero-1.0.xsd"><aero:ensAuthID>ENS-C1</aero:ensAuthID><aero:ensAuthKey>my secret</aero:ensAuthKey></aero:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');


$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>whatever.aero</domain:name><domain:roid>BARCA-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.barca.cat</domain:host><domain:host>ns2.barca.cat</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2006-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>2006-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2007-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2006-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><aero:infData xmlns:aero="urn:afilias:params:xml:ns:ext:aero-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:aero-1.0 aero-1.0.xsd"><aero:ensAuthID>ENS-C1</aero:ensAuthID></aero:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$rc=$dri->domain_info('whatever.aero',{auth=>{pw=>'2fooBAR'}});
is_deeply($dri->get_info('ens'),{auth_id=>'ENS-C1'},'domain_info parse');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
