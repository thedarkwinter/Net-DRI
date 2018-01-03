#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 15;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('Neustar::Narwhal',{clid => 'ClientX'});
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$ok,$cs,$st,$p,$c1,$c2,$d,$unspec);

####################################################################################################
## CO Extensions

# domain create for
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.co</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('example202.co',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},unspec=>{reservation_domain=>'yes'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.co</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>ReservationDomain=yes</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');


# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns="urn:ietf:params:xml:ns:domain-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>EXAMPLE1.CO</domain:name><domain:roid>D20342671-US</domain:roid><domain:status s="clientHold"/><domain:registrant>COUS-7135</domain:registrant><domain:contact type="admin">TEST123</domain:contact><domain:contact type="billing">TEST123</domain:contact><domain:contact type="tech">TEST123</domain:contact><domain:ns><domain:hostObj>NS1.TEST.CO</domain:hostObj><domain:hostObj>NS2.TEST.CO</domain:hostObj><domain:hostObj>NS3.TEST.CO</domain:hostObj></domain:ns><domain:clID>NEUSTAR</domain:clID><domain:crID>NEUSTAR</domain:crID><domain:crDate>2009-06-09T15:55:37.0Z</domain:crDate><domain:upID>NEUSTAR</domain:upID><domain:upDate>2009-09-16T12:51:30.0Z</domain:upDate><domain:exDate>2014-06-08T23:59:59.0Z</domain:exDate><domain:authInfo><domain:pw>abcdef123</domain:pw></domain:authInfo></domain:infData></resData><extension><neulevel:extension xmlns="urn:ietf:params:xml:ns:neulevel-1.0" xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>DomainSuspendedIndicator=expired</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_info('example1.co');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('domain_suspended_indicator'),'expired','domain_info get_info (domain_suspended_indicator)');

# domain renew - note that this can be also done using the restore request and restore report extension commands described in 3915 for the restoration of a domain name in redemption, which is an extension of the domain update command.
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.co</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example204.co',{current_expiration => DateTime->new(year=>2000,month=>4,day=>3), unspec=>{restore_reason_code=>'2', restore_comment=>'Testing-123', true_data=>'Y', valid_use=>'Y'}});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.co</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate></domain:renew></renew><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>RestoreReasonCode=2 RestoreComment=Testing-123 TrueData=Y ValidUse=Y</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_renew get_info(exDate) value');

exit(0);
