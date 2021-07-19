#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 7;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('NGTLD',{provider=>'centralnic'});
$dri->target('centralnic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$csadd,$csdel,$c1,$c2);

####################################################################################################

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example1.feedback</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok" /><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><auxcontact:infData xmlns:auxcontact="urn:ietf:params:xml:ns:auxcontact-0.1"><auxcontact:contact type="abuse">sh8013</auxcontact:contact><auxcontact:contact type="dns-operator">ClientZ</auxcontact:contact></auxcontact:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example1.feedback');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'example1.feedback','domain_info get_info (name)');
$cs = $dri->get_info('contact');
is($cs->get('abuse')->srid(),'sh8013','domain_info get_info (aux contact) abuse');
is($cs->get('dns-operator')->srid(),'ClientZ','domain_info get_info (aux contact) abuse');

## domain create
$R2='';
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$cs->set($dri->local_object('contact')->srid('sh8013'),'abuse');
$cs->set($dri->local_object('contact')->srid('ClientZ'),'dns-operator');
$rc=$dri->domain_create('example2.feedback',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.feedback</domain:name><domain:period unit="y">2</domain:period><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><auxcontact:create xmlns:auxcontact="urn:ietf:params:xml:ns:auxcontact-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:auxcontact-0.1 auxcontact-0.1.xsd"><auxcontact:contact type="abuse">sh8013</auxcontact:contact><auxcontact:contact type="dns-operator">ClientZ</auxcontact:contact></auxcontact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

## domain update
$R2='';
$toc=Net::DRI::Data::Changes->new();
$csadd = $dri->local_object('contactset');
$csadd->set($dri->local_object('contact')->srid('ClientXYZ'),'dns-operator');
$csdel = $dri->local_object('contactset');
$csdel->set($dri->local_object('contact')->srid('ClientZ'),'dns-operator');
$toc->add('contact',$csadd);
$toc->del('contact',$csdel);
$rc=$dri->domain_update('example3.feedback',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.feedback</domain:name></domain:update></update><extension><auxcontact:update xmlns:auxcontact="urn:ietf:params:xml:ns:auxcontact-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:auxcontact-0.1 auxcontact-0.1.xsd"><auxcontact:add><auxcontact:contact type="dns-operator">ClientXYZ</auxcontact:contact></auxcontact:add><auxcontact:rem><auxcontact:contact type="dns-operator">ClientZ</auxcontact:contact></auxcontact:rem></auxcontact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

####################################################################################################
exit 0;
