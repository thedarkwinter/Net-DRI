#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 6;
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
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['ICANN::RegistrarExpirationDate','-VeriSign::NameStore']});


my ($rc, $date);

$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" ><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.com');
$date=$rc->get_data('domain','example.com','registrar_expiration_date');
is(''.$date,'2004-04-03T22:00:00','get_data registrar_expiration_date info after domain_info');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example.com</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-06T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-11T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" ><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('example.com',{auth=>{pw=>'2fooBAR'}});
$date=$rc->get_data('domain','example.com','registrar_expiration_date');
is(''.$date,'2004-04-03T22:00:00','get_data registrar_expiration_date info after domain_transfer_query');


$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('notexample.com',{pure_create => 1,
                                          duration    => $dri->local_object('duration', years => 2),
                                          ns          => $dri->local_object('hosts')->set(['ns1.example.net'],['ns2.example.net']),
                                          contact     => $cs,
                                          auth        => {pw=>'2fooBAR'},
                                          registrar_expiration_date => $dri->local_object('datetime', time_zone => 'UTC', year => 2004, month => 4, day => 3, hour => 22),
                                         });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>notexample.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rrExDate-1.0 rrExDate-1.0.xsd"><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');


$rc=$dri->domain_renew('notexample.com',{duration => $dri->local_object('duration', years => 5),
                                         current_expiration => $dri->local_object('datetime', year => 2000, month => 4, day => 3),
                                         registrar_expiration_date => $dri->local_object('datetime', time_zone => 'UTC', year => 2004, month => 4, day => 3, hour => 22),
                                        });
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>notexample.com</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rrExDate-1.0 rrExDate-1.0.xsd"><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');


$rc=$dri->domain_transfer_start('notexample.com',{auth => {pw=>'2fooBAR',roid=>"JD1234-REP"},
                                                  duration => $dri->local_object('duration', years=>1),
                                                  registrar_expiration_date => $dri->local_object('datetime', time_zone => 'UTC', year => 2004, month => 4, day => 3, hour => 22),
                                                 });
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>notexample.com</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rrExDate-1.0 rrExDate-1.0.xsd"><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');


$R2='';
my $toc=$dri->local_object('changes');
$toc->set('registrar_expiration_date', $dri->local_object('datetime', time_zone => 'UTC', year => 2004, month => 4, day => 3, hour => 22));
$rc=$dri->domain_update('notexample.com', $toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>notexample.com</domain:name></domain:update></update><extension><rrExDate:rrExDateData xmlns:rrExDate="urn:ietf:params:xml:ns:rrExDate-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rrExDate-1.0 rrExDate-1.0.xsd"><rrExDate:exDate>2004-04-03T22:00:00.0Z</rrExDate:exDate></rrExDate:rrExDateData></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');


exit 0;
