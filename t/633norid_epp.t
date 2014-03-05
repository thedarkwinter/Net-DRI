#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Duration;
use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 313;

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
$dri->add_registry('NO');
$dri->target('NO')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

## Domain commands
my %facetsh = (
    'skip-manual-review'    =>1,
    'impersonate-registrar' => 'reg9094');

my $no_facet = { facets => \%facetsh };

my $NO_FACET=
'<extension><no-ext-epp:extended xmlns:no-ext-epp="http://www.norid.no/xsd/no-ext-epp-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-epp-1.0 no-ext-epp-1.0.xsd"><no-ext-epp:facet name="impersonate-registrar">reg9094</no-ext-epp:facet><no-ext-epp:facet name="skip-manual-review">1</no-ext-epp:facet></no-ext-epp:extended></extension>';

my $ddomain = "example3.no";
my $fdomain = "facet-$ddomain";

######################
# Domain commands
#

#--- domain_check

foreach my $OP ( "", $NO_FACET) {
    my $facet;
    my $domain = $ddomain;
    if ($OP) {
       $facet = $no_facet;
       $domain = $fdomain;
    }
    $R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">'.$domain.'</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
    $rc=$dri->domain_check($domain, defined $facet ? $facet : ());
    is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>'.$domain.'</domain:name></domain:check></check>'.$OP. '<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
    is($rc->is_success(),1,'domain_check is_success');
    is($dri->get_info('action'),'check','domain_check get_info(action)');
    is($dri->get_info('exist'),0,'domain_check get_info(exist)');
    is($dri->get_info('exist','domain',$domain),0,"domain_check $domain get_info(exist) from cache");
}


#---- domain_check multi

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.no</domain:name></domain:cd><domain:cd><domain:name avail="0">example2.no</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.no','example2.no');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.no</domain:name><domain:name>example2.no</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check_multi build');
is($rc->is_success(),1,'domain_check_multi is_success');
is($dri->get_info('exist','domain','example22.no'),0,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.no'),1,'domain_check_multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','example2.no'),'In use','domain_check_multi get_info(exist_reason)');

#---- domain_info
foreach my $OP ( "", $NO_FACET) {
    my $facet;
    my $domain = $ddomain;
    if ($OP) {
       $facet =  \%facetsh;
       $domain = $fdomain;
    }
    $R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>'.$domain.'</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.no</domain:hostObj><domain:hostObj>ns2.example.no</domain:hostObj></domain:ns><domain:host>ns1.example.no</domain:host><domain:host>ns2.example.no</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;

     $rc=$dri->domain_info($domain,  { auth => {pw=>'2fooBAR'}, facets => $facet });

    is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">'.$domain.'</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info>' . $OP . '<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');

    is($dri->get_info('action'),'info','domain_info get_info(action)');

    is($dri->get_info('exist'),1,'domain_info get_info(exist)');
    is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info(roid)');
    $s=$dri->get_info('status');
    isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
    is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
    is($s->is_active(),1,'domain_info get_info(status) is_active');
    $s=$dri->get_info('contact');
    isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
    is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
    is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
    is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
    is($s->get('tech')->srid(),'sh8013','domain_info get_info(contact) tech srid');
    $dh=$dri->get_info('subordinate_hosts');
    isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(subordinate_hosts)');
    @c=$dh->get_names();
    is_deeply(\@c,['ns1.example.no','ns2.example.no'],'domain_info get_info(host) get_names');
    $dh=$dri->get_info('ns');
    isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
    @c=$dh->get_names();
    is_deeply(\@c,['ns1.example.no','ns2.example.no'],'domain_info get_info(ns) get_names');
    is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');
    is($dri->get_info('crID'),'ClientY','domain_info get_info(crID)');
    $d=$dri->get_info('crDate');
    isa_ok($d,'DateTime','domain_info get_info(crDate)');
    is("".$d,'1999-04-03T22:00:00','domain_info get_info(crDate) value');
    is($dri->get_info('upID'),'ClientX','domain_info get_info(upID)');
    $d=$dri->get_info('upDate');
    isa_ok($d,'DateTime','domain_info get_info(upDate)');
    is("".$d,'1999-12-03T09:00:00','domain_info get_info(upDate) value');
    $d=$dri->get_info('exDate');
    isa_ok($d,'DateTime','domain_info get_info(exDate)');
    is("".$d,'2005-04-03T22:00:00','domain_info get_info(exDate) value');
    $d=$dri->get_info('trDate');
    isa_ok($d,'DateTime','domain_info get_info(trDate)');
    is("".$d,'2000-04-08T09:00:00','domain_info get_info(trDate) value');
    is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
}

#---  domain_info without auth

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example200.no</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:clID>ClientX</domain:clID></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example200.no');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example200.no</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build without auth');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info(roid)');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');

#---  domain_info  without auth and with applicantDataset (no-ext-domain-1.1):

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example200-dataset.no</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:clID>ClientX</domain:clID></domain:infData></resData><extension><no-ext-domain:infData xmlns="http://www.norid.no/xsd/no-ext-domain-1.1" xmlns:no-ext-domain="http://www.norid.no/xsd/no-ext-domain-1.1"><no-ext-domain:applicantDataset><no-ext-domain:versionNumber>1.0</no-ext-domain:versionNumber><no-ext-domain:acceptName>Tante Sofie</no-ext-domain:acceptName><no-ext-domain:acceptDate>2012-04-10T13:55:55Z</no-ext-domain:acceptDate><no-ext-domain:updateClientID>reg0</no-ext-domain:updateClientID><no-ext-domain:updateDate>2012-04-11T14:55:55.42Z</no-ext-domain:updateDate></no-ext-domain:applicantDataset></no-ext-domain:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example200-dataset.no');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example200-dataset.no</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build without auth');

is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info(roid)');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');

$d = $dri->get_info('applicantDataset');
is(defined($d), 1 ,'domain_info get_info(applicantDataset)');
is($d->{versionNumber},'1.0','domain_info get_info(versionNumber)');
is($d->{acceptName},'Tante Sofie','domain_info get_info(acceptName)');
my $date = $d->{acceptDate};
isa_ok($date,'DateTime','domain_info get_info(acceptDate)');
is("".$date,"2012-04-10T13:55:55",'domain_info get_info(acceptDate)');
$date = $d->{updateDate};
isa_ok($date,'DateTime','domain_info get_info(updateDate)');
is("".$date,"2012-04-11T14:55:55",'domain_info get_info(acceptDate)');
is($d->{updateClientID},'reg0','domain_info get_info(updateClientID)');

#--- domain_transfer_query

$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example201.no</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-06T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-11T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2; 

$rc=$dri->domain_transfer_query('example201.no',{auth=>{pw=>'2fooBAR',roid=>'JD1234-REP'}});
is_string($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example201.no</domain:name><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($dri->get_info('action'),'transfer','domain_transfer_query get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_query get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(reDate)');
is("".$d,'2000-06-06T22:00:00','domain_transfer_query get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(acDate)');
is("".$d,'2000-06-11T22:00:00','domain_transfer_query get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_query get_info(exDate) value');


$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.no</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');

$rc=$dri->domain_create('example202.no',{pure_create=>1,duration=>DateTime::Duration->new(months=>12),ns=>$dri->local_object('hosts')->set(['ns1.example.no'],['ns2.example.no']),contact=>$cs,auth=>{pw=>'2fooBAR'}});

is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.no</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.no</domain:hostObj><domain:hostObj>ns2.example.no</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');

# applicantDataset create (no-ext-domain-1.1)
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202-dataset.no</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_create('example202-dataset.no',{pure_create=>1,duration=>DateTime::Duration->new(months=>12),ns=>$dri->local_object('hosts')->set(['ns1.example.no'],['ns2.example.no']),contact=>$cs,auth=>{pw=>'2fooBAR'}, applicantdataset=>{ acceptname => 'Peter Absalon', acceptdate => '2011-10-11T08:19:31.00Z', versionnumber => '13.10'}});

is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202-dataset.no</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.no</domain:hostObj><domain:hostObj>ns2.example.no</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><no-ext-domain:create xmlns:no-ext-domain="http://www.norid.no/xsd/no-ext-domain-1.1" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-domain-1.1 no-ext-domain-1.1.xsd"><no-ext-domain:applicantDataset><no-ext-domain:versionNumber>13.10</no-ext-domain:versionNumber><no-ext-domain:acceptName>Peter Absalon</no-ext-domain:acceptName><no-ext-domain:acceptDate>2011-10-11T08:19:31.00Z</no-ext-domain:acceptDate></no-ext-domain:applicantDataset></no-ext-domain:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');


#$d=$dri->get_info('acceptDate');

use Data::Dumper;
$Data::Dumper::Indent=1;
print "d: ", Dumper $d;

#isa_ok($d,'DateTime','domain_create get_info(acceptDate)');


$R2='';
$rc=$dri->domain_delete('example203.no',{pure_delete=>1});
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example203.no</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');


$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.no</domain:name><domain:exDate>2008-02-22T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_renew('example204.no',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2008,month=>2,day=>22)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.no</domain:name><domain:curExpDate>2008-02-22</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2008-02-22T22:00:00','domain_renew get_info(exDate) value');

$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.no</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_transfer_start('example205.no',{auth=>{pw=>'2fooBAR'},duration=>DateTime::Duration->new(years=>1), email=>'reg.test\@ttest.no'});

is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.no</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><no-ext-domain:transfer xmlns:no-ext-domain="http://www.norid.no/xsd/no-ext-domain-1.1" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-domain-1.1 no-ext-domain-1.1.xsd"><no-ext-domain:notify><no-ext-domain:email>reg.test\@ttest.no</no-ext-domain:email></no-ext-domain:notify></no-ext-domain:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start (=request) build');
is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
is("".$d,'2000-06-13T22:00:00','domain_transfer_start get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_start get_info(exDate) value');

# execute

$rc=$dri->domain_transfer_execute('example205.no',{auth=>{pw=>'2fooBAR'},duration=>DateTime::Duration->new(months=>5)});
#eval_it($dri, 'domain_transfer_execute', 'example205.no',{auth=>{pw=>'2fooBAR'},duration=>DateTime::Duration->new(months=>5)});

# hack to substitue <clTRID>ABC-12345</clTRID> because the trid-factory does not handle the extension
$R1 =~s|<clTRID>.+</clTRID>|<clTRID>ABC-12345</clTRID>|g;

is_string($R1,$E1.'<extension><command xmlns="http://www.norid.no/xsd/no-ext-epp-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-epp-1.0 no-ext-epp-1.0.xsd"><transfer op="execute"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.no</domain:name><domain:period unit="m">5</domain:period><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command></extension>'.$E2,'domain_transfer_execute build');

is($dri->get_info('action'),'transfer','domain_transfer_execute get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_execute get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_execute get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_execute get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_execute get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','domain_transfer_execute get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_execute get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_execute get_info(acDate)');
is("".$d,'2000-06-13T22:00:00','domain_transfer_execute get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_execute get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_execute get_info(exDate) value');

$R2='';
my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns2.example.no'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mak21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('publish','Payment overdue.'));
$toc->del('ns',$dri->local_object('hosts')->set('ns1.example.no'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('sh8013'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('update'));
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('auth',{pw=>'2BARfoo'});
$rc=$dri->domain_update('example206.no',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example206.no</domain:name><domain:add><domain:ns><domain:hostObj>ns2.example.no</domain:hostObj></domain:ns><domain:contact type="tech">mak21</domain:contact><domain:status lang="en" s="clientHold">Payment overdue.</domain:status></domain:add><domain:rem><domain:ns><domain:hostObj>ns1.example.no</domain:hostObj></domain:ns><domain:contact type="tech">sh8013</domain:contact><domain:status s="clientUpdateProhibited"/></domain:rem><domain:chg><domain:registrant>sh8013</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');
 
# The .no withdraw command extension
$rc=$dri->domain_withdraw('example206.no');
is($rc->is_success(),1,'domain_withdraw is_success');

##################################################################################################################
## Host commands

$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns2.example2.no</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns2.example2.no');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.no</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('action'),'check','host_check get_info(action)');
is($dri->get_info('exist'),1,'host_check get_info(exist)');
is($dri->get_info('exist','host','ns2.example2.no'),1,'host_check get_info(exist) from cache');
is($dri->get_info('exist_reason'),'In use','host_check reason');


$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="1">ns10.example2.no</host:name></host:cd><host:cd><host:name avail="0">ns20.example2.no</host:name><host:reason>In use</host:reason></host:cd><host:cd><host:name avail="1">ns30.example2.no</host:name></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;

$rc=$dri->host_check('ns10.example2.no','ns20.example2.no','ns30.example2.no');
is_string($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns10.example2.no</host:name><host:name>ns20.example2.no</host:name><host:name>ns30.example2.no</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check multi build');
is($rc->is_success(),1,'host_check multi is_success');
is($dri->get_info('exist','host','ns10.example2.no'),0,'host_check multi get_info(exist) 1/3');
is($dri->get_info('exist','host','ns20.example2.no'),1,'host_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','host',,'ns20.example2.no'),'In use','host_check multi get_info(exist_reason)');
is($dri->get_info('exist','host','ns30.example2.no'),0,'host_check multi get_info(exist) 3/3');

$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.no</host:name><host:roid>NS1_EXAMPLE1-REP</host:roid><host:status s="linked"/><host:status s="clientUpdateProhibited"/><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:clID>ClientY</host:clID><host:crID>ClientX</host:crID><host:crDate>1999-04-03T22:00:00.0Z</host:crDate><host:upID>ClientX</host:upID><host:upDate>1999-12-03T09:00:00.0Z</host:upDate><host:trDate>2000-04-08T09:00:00.0Z</host:trDate></host:infData></resData><extension><infData xmlns="http://www.norid.no/xsd/no-ext-host-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-host-1.0 no-ext-host-1.0.xsd"><contact>PEO183P</contact></infData></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->host_info('ns100.example2.no');

is_string($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.no</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('action'),'info','host_info get_info(action)');
is($dri->get_info('exist'),1,'host_info get_info(exist)');
is($dri->get_info('roid'),'NS1_EXAMPLE1-REP','host_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','host_info get_info(status)');
is_deeply([$s->list_status()],['clientUpdateProhibited','linked'],'host_info get_info(status) list');
is($s->is_linked(),1,'host_info get_info(status) is_linked');
is($s->can_update(),0,'host_info get_info(status) can_update');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','host_info get_info(self)');
my ($name,$ip4,$ip6)=$s->get_details(1);
is($name,'ns100.example2.no','host_info self name');
is_deeply($ip4,['193.0.2.2','193.0.2.29'],'host_info self ip4');
is($dri->get_info('clID'),'ClientY','host_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','host_info get_info(crID)');
is($dri->get_info('upID'),'ClientX','host_info get_info(upID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_info get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','host_info get_info(upDate)');
is($d.'','1999-12-03T09:00:00','host_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','host_info get_info(trDate)');
is($d.'','2000-04-08T09:00:00','host_info get_info(trDate) value');
is_deeply($dri->get_info('contact'),['PEO183P'],'host_info get_info(contact)');
$R2=$E1.'<response>'.r().'<resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.no</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_create($dri->local_object('hosts')->add('ns101.example1.no',['193.0.2.2','193.0.2.29'],[]), {contact=>'PEO183P'});
is_string($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.no</host:name><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr></host:create></create><extension><no-ext-host:create xmlns:no-ext-host="http://www.norid.no/xsd/no-ext-host-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-host-1.0 no-ext-host-1.0.xsd"><no-ext-host:contact>PEO183P</no-ext-host:contact></no-ext-host:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($dri->get_info('action'),'create','host_create get_info(action)');
is($dri->get_info('exist'),1,'host_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_create get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_create get_info(crDate) value');

$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->host_delete('ns102.example1.no');
is_string($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns102.example1.no</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'host_delete build');
is($rc->is_success(),1,'host_delete is_success');
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;

## host update
$toc=$dri->local_object('changes');
$toc->add('ip',$dri->local_object('hosts')->add('ns1.example1.no',['193.0.2.22'],[]));
$toc->add('status',$dri->local_object('status')->no('update'));
$toc->del('ip',$dri->local_object('hosts')->add('ns1.example1.no',[],['2000:0:0:0:8:800:200C:417A']));
$toc->set('name','ns104.example2.no');
# .NO contact extension:
$toc->add('contact', 'OS103P');
$toc->del('contact', 'PEO183P');
$rc=$dri->host_update('ns103.example1.no',$toc);
is_string($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns103.example1.no</host:name><host:add><host:addr ip="v4">193.0.2.22</host:addr><host:status s="clientUpdateProhibited"/></host:add><host:rem><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:rem><host:chg><host:name>ns104.example2.no</host:name></host:chg></host:update></update><extension><no-ext-host:update xmlns:no-ext-host="http://www.norid.no/xsd/no-ext-host-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-host-1.0 no-ext-host-1.0.xsd"><no-ext-host:add><no-ext-host:contact>OS103P</no-ext-host:contact></no-ext-host:add><no-ext-host:rem><no-ext-host:contact>PEO183P</no-ext-host:contact></no-ext-host:rem></no-ext-host:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

#########################################################################################################
## Contact commands

my $co;
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">PEO183P</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('PEO183P'); #->auth({pw=>'2fooBAR'});
$rc=$dri->contact_check($co);
is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>PEO183P</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build'); 
is($rc->is_success(),1,'contact_check is_success');
is($dri->get_info('action'),'check','contact_check get_info(action)');
is($dri->get_info('exist'),0,'contact_check get_info(exist)');
is($dri->get_info('exist','contact','PEO183P'),0,'contact_check get_info(exist) from cache');

# contact check is not supported by the registry, bot a local DRI check should work
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">sh8001</contact:id></contact:cd><contact:cd><contact:id avail="0">sh8002</contact:id><contact:reason>In use</contact:reason></contact:cd><contact:cd><contact:id avail="1">sh8003</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('sh8001','sh8002','sh8003'));
is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8001</contact:id><contact:id>sh8002</contact:id><contact:id>sh8003</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');
is($dri->get_info('exist','contact','sh8001'),0,'contact_check multi get_info(exist) 1/3');
is($dri->get_info('exist','contact','sh8002'),1,'contact_check multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','contact','sh8002'),'In use','contact_check multi get_info(exist_reason)');
is($dri->get_info('exist','contact','sh8003'),0,'contact_check multi get_info(exist) 3/3');


$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+47.7035555555</contact:voice><contact:fax>+47.7035555556</contact:fax><contact:email>jdoe@example.no</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'sh8013','contact_info get_info(self) srid');
is($co->roid(),'SH8013-REP','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited','linked'],'contact_info get_info(status) list_status');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'John Doe','contact_info get_info(self) name');
is($co->org(),'Example Inc.','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['123 Example Dr.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Dulles','contact_info get_info(self) city');
is($co->sp(),'VA','contact_info get_info(self) sp');
is($co->pc(),'20166-6503','contact_info get_info(self) pc');
is($co->cc(),'US','contact_info get_info(self) cc');
is($co->voice(),'+47.7035555555x1234','contact_info get_info(self) voice');
is($co->fax(),'+47.7035555556','contact_info get_info(self) fax');
is($co->email(),'jdoe@example.no','contact_info get_info(self) email');
is($dri->get_info('clID'),'ClientY','contact_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'ClientX','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','contact_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','contact_info get_info(trDate) value');
is_deeply($co->auth(),{pw=>'2fooBAR'},'contact_info get_info(self) auth');
is_deeply($co->disclose(),{voice=>0,email=>0},'contact_info get_info(self) disclose');

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>JD12P</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;

#
# create a contact person
$co=$dri->local_object('contact')->new();
$co->name('John Doe');
#$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+47.7035555555x1234');
$co->fax('+47.7035555556');
$co->email('jdoe@example.no');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
# .NO extensions
$co->type('person');
$co->xemail(['xtra1@example.no', 'xtra2@example.no']);
$co->mobilephone('+47.123456780');
#eval_it($dri, 'contact_create', $co);
$rc=$dri->contact_create($co);

is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+47.7035555555</contact:voice><contact:fax>+47.7035555556</contact:fax><contact:email>jdoe@example.no</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><no-ext-contact:create xmlns:no-ext-contact="http://www.norid.no/xsd/no-ext-contact-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-contact-1.0 no-ext-contact-1.0.xsd"><no-ext-contact:type>person</no-ext-contact:type><no-ext-contact:mobilePhone>+47.123456780</no-ext-contact:mobilePhone><no-ext-contact:email>xtra1@example.no</no-ext-contact:email><no-ext-contact:email>xtra2@example.no</no-ext-contact:email></no-ext-contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build person');

is($dri->get_info('id'),'JD12P','contact_create person with registry contact:id get_info(id)');
is($dri->get_info('exist'),undef,'contact_create person with registry contact:id get_info(exist)');
is($dri->get_info('id','contact','JD12P'),'JD12P','contact_create person with registry contact:id get_info(JD12P,id)');
is($dri->get_info('exist','contact','JD12P'),1,'contact_create person with registry contact:id get_info(JD12P,exist)');

#
# create a contact organization
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>JD12O</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;

$co=$dri->local_object('contact')->new();
$co->name('John Doe');
#$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+47.7035555555x1234');
$co->fax('+47.7035555556');
$co->email('jdoe@example.no');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
# .NO extensions
$co->type('organization');
$co->identity({type=>'organizationNumber', value=>'932080506'});
$co->xemail(['xtra1@example.no', 'xtra2@example.no']);
$co->mobilephone('+47.123456780');
#eval_it($dri, 'contact_create', $co);
$rc=$dri->contact_create($co);

is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+47.7035555555</contact:voice><contact:fax>+47.7035555556</contact:fax><contact:email>jdoe@example.no</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><no-ext-contact:create xmlns:no-ext-contact="http://www.norid.no/xsd/no-ext-contact-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-contact-1.0 no-ext-contact-1.0.xsd"><no-ext-contact:type>organization</no-ext-contact:type><no-ext-contact:identity type="organizationNumber">932080506</no-ext-contact:identity><no-ext-contact:mobilePhone>+47.123456780</no-ext-contact:mobilePhone><no-ext-contact:email>xtra1@example.no</no-ext-contact:email><no-ext-contact:email>xtra2@example.no</no-ext-contact:email></no-ext-contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build organization');

is($dri->get_info('id'),'JD12O','contact_create organization with registry contact:id get_info(id)');
is($dri->get_info('exist'),undef,'contact_create organization with registry contact:id get_info(exist)');
is($dri->get_info('id','contact','JD12O'),'JD12O','contact_create organization with registry contact:id get_info(JD12P,id)');
is($dri->get_info('exist','contact','JD12O'),1,'contact_create organization with registry contact:id get_info(JD12O,exist)');

# create a contact role

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>JD12R</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;

$co=$dri->local_object('contact')->new();
$co->name('John Doe');
#$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+47.7035555555x1234');
$co->fax('+47.7035555556');
$co->email('jdoe@example.no');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
# .NO extensions
$co->type('role');
$co->rolecontact(['JD12P', 'JD13P']);
$co->xemail(['xtra1@example.no', 'xtra2@example.no']);
$co->mobilephone('+47.123456780');
$co->xdisclose({mobilePhone=>0});
$rc=$dri->contact_create($co);
#eval_it($dri, 'contact_create', $co);

is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>auto</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+47.7035555555</contact:voice><contact:fax>+47.7035555556</contact:fax><contact:email>jdoe@example.no</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><no-ext-contact:create xmlns:no-ext-contact="http://www.norid.no/xsd/no-ext-contact-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-contact-1.0 no-ext-contact-1.0.xsd"><no-ext-contact:type>role</no-ext-contact:type><no-ext-contact:mobilePhone>+47.123456780</no-ext-contact:mobilePhone><no-ext-contact:email>xtra1@example.no</no-ext-contact:email><no-ext-contact:email>xtra2@example.no</no-ext-contact:email><no-ext-contact:roleContact>JD12P</no-ext-contact:roleContact><no-ext-contact:roleContact>JD13P</no-ext-contact:roleContact><no-ext-contact:disclose flag="0"><no-ext-contact:mobilePhone/></no-ext-contact:disclose></no-ext-contact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build role');

is($dri->get_info('id'),'JD12R','contact_create organization with registry contact:id get_info(id)');
is($dri->get_info('exist'),undef,'contact_create organization with registry contact:id get_info(exist)');
is($dri->get_info('id','contact','JD12R'),'JD12R','contact_create organization with registry contact:id get_info(JD12P,id)');
is($dri->get_info('exist','contact','JD12R'),1,'contact_create organization with registry contact:id get_info(JD12R,exist)');

## Some registries do not permit the registrar to set the contact:id, and will just set one
## Here is how to deal with this case
## Note that contact:id is mandatory in EPP, and hence we will always send one 
## (handled transparently by Contact::*::init()
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>NEWREGID</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co->srid('sh8015');
$rc=$dri->contact_create($co);
is($dri->get_info('id'),'NEWREGID','contact_create with registry contact:id get_info(id)');
is($dri->get_info('exist'),undef,'contact_create with registry contact:id get_info(exist)');
is($dri->get_info('id','contact','NEWREGID'),'NEWREGID','contact_create with registry contact:id get_info(NEWREGID,id)');
is($dri->get_info('exist','contact','NEWREGID'),1,'contact_create with registry contact:id get_info(NEWREGID,exist)');


$R2='';
$co=$dri->local_object('contact')->srid('sh8016')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_delete($co);
is_string($R1,$E1.'<command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8016</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');


$R2='';
$co=$dri->local_object('contact')->srid('sh8018')->auth({pw=>'2fooBAR'});
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
my $co2=$dri->local_object('contact');
$co2->org('');
$co2->street(['124 Example Dr.','Suite 200']);
$co2->city('Dulles');
$co2->sp('VA');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+47.7034444444');
$co2->fax('');
$co2->auth({pw=>'2fooBAR'});
$co2->disclose({voice=>1,email=>1});
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8018</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="loc"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+47.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## Session commands
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');


$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');


$R2=$E1.'<greeting><svID>Example EPP server epp.example.no</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Example EPP server epp.example.no','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2000-06-08T22:00:00','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','fr'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:obj1','urn:ietf:params:xml:ns:obj2','urn:ietf:params:xml:ns:obj3'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['http://custom/obj1ext-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['http://custom/obj1ext-1.0'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');

$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword=>'bar-FOO2'}]);
is_string($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

####################################################################################################
## Registry Messages, normal

$R2=$E1.'<response>'.r().'<msgQ count="5" id="12345"/>'.$TRID.'</response>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->get_info('count','message','info'),5,'message count');
is($dri->get_info('id','message','info'),12345,'message id');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>1999-04-04T22:01:00.0Z</qDate><msg>Pending action completed successfully.</msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name paResult="1">example.no</domain:name><domain:paTRID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></domain:paTRID><domain:paDate>1999-04-04T22:00:00.0Z</domain:paDate></domain:panData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();

is($dri->get_info('last_id'),12345,'message get_info last_id 1');
is($dri->get_info('last_id','message','session'),12345,'message get_info last_id 2');
is($dri->get_info('id','message',12345),12345,'message get_info id');
is(''.$dri->get_info('qdate','message',12345),'1999-04-04T22:01:00','message get_info qdate');
is($dri->get_info('content','message',12345),'Pending action completed successfully.','message get_info msg');
is($dri->get_info('lang','message',12345),'en','message get_info lang');


is($dri->message_waiting(),1,'message_waiting');
is($dri->message_count(),5,'message_count');

$R2=$E1.'<response>'.r(1300,'Command completed successfully; no messages').$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),undef,'message get_info last_id (no message)');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="2"><qDate>2006-09-25T09:09:11.0Z</qDate><msg>Come to the registry office for some beer on friday</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),2,'message get_info last_id (pure text message)');
is($dri->message_count(),1,'message_count (pure text message)');
is(''.$dri->get_info('qdate','message',2),'2006-09-25T09:09:11','message get_info qdate (pure text message)');
is($dri->get_info('content','message',2),'Come to the registry office for some beer on friday','message get_info msg (pure text message)');
is($dri->get_info('lang','message',2),'en','message get_info lang (pure text message)');


####################################################################################################
## Registry Messages with .NO specific layout

$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="2265" id="374185914"><qDate>2008-02-04T09:23:04.63Z</qDate><msg>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.no]</msg></msgQ><resData><message xmlns="http://www.norid.no/xsd/no-ext-result-1.0" type="response-copy" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd"><desc>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.no]</desc><data><entry name="objecttype">domain</entry><entry name="command">transfer-execute</entry><entry name="objectname">mydomain.no</entry><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="2304"><msg>Object status prohibits operation</msg></result><msgQ count="734" id="374047143"/><extension><conditions xmlns="http://www.norid.no/xsd/no-ext-result-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd"><condition code="NC20077" severity="error"><msg>Registry::NORID::Exception::Policy::Domain::Locked</msg><details>Domain mydomain.no: domain is locked.</details></condition></conditions></extension><trID><clTRID>NORID-1234-4341234246535343</clTRID><svTRID>2008020412454356454273-9-NORID</svTRID></trID></response></epp></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 374185914, 'message get_info last_id 1');
is($dri->get_info('last_id', 'message', 'session'), 374185914,'message get_info last_id 2');
is($dri->get_info('id', 'message', 374185914), 374185914,'message get_info id');
is('' . $dri->get_info('qdate', 'message', 374185914), '2008-02-04T09:23:04','message get_info qdate');
is($dri->get_info('lang', 'message', 374185914), 'en', 'message get_info lang');
is($dri->get_info('roid', 'message', 374185914), undef,'message get_info roid');

is($dri->get_info('content', 'message', 374185914), 'EPP response to a '.
'transaction executed on your behalf: objecttype [domain] ' .
	'command [transfer-execute] objectname [mydomain.no]',
	'message get_info content');
is($dri->get_info('action', 'message', 374185914), 'transfer-execute','message get_info action');
is($dri->get_info('object_type', 'message', 374185914), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 374185914), 'mydomain.no','message get_info object_id');

my $conds = $dri->get_info('conditions', 'message', 374185914);
is($conds->[0]->{msg}, 'Registry::NORID::Exception::Policy::Domain::Locked','message condition message');
is($conds->[0]->{code}, 'NC20077', 'message condition code');
is($conds->[0]->{severity}, 'error', 'message condition severity');
is($conds->[0]->{details}, 'Domain mydomain.no: domain is locked.','message condition details');

$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="375338309"><qDate>2008-02-06T10:18:19.70Z</qDate><msg>Reg losing: blafasel.no</msg></msgQ><resData><message xmlns="http://www.norid.no/xsd/no-ext-result-1.0" type="domain-transferred-away" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd"><desc>Reg losing: blafasel.no</desc><data><entry name="domain">blafasel.no</entry></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 375338309, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 375338309), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 375338309), 'blafasel.no','message get_info object_id');

is($dri->get_info('action', 'message', 375338309), 'domain-transferred-away','message get_info action');
$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="3" id="375424692"><qDate>2008-02-06T13:37:59.63Z</qDate><msg>ATTENTION: domain weingeist.no is marked to be locked SKW - lock customer request.</msg></msgQ><resData><message xmlns="http://www.norid.no/xsd/no-ext-result-1.0" type="domain-info-lock-customer" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd"><desc>ATTENTION: domain weingeist.no is marked to be locked SKW - lock customer request.</desc><data><entry name="domain">weingeist.no</entry></data></message></resData>' . $TRID . '</response>' . $E2;
$rc = $dri->message_retrieve();
is($rc->is_success(), 1, 'message polled successfully');
is($dri->get_info('last_id'), 375424692, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 375424692), 'domain','message get_info object_type');
is($dri->get_info('object_id', 'message', 375424692), 'weingeist.no','message get_info object_id');
is($dri->get_info('action', 'message', 375424692), 'domain-info-lock-customer','message get_info action');


$R2=$E1.'<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="134443"><qDate>2008-07-03T10:00:07.00Z</qDate><msg>EPP response to command with clTRID [NORID-3748-1215079064192782] and svTRID [200807031157442264480D-reg9091-NORID]</msg></msgQ><resData><message type="epp-late-response" xmlns="http://www.norid.no/xsd/no-ext-result-1.0" xsi:schemaLocation="http://www.norid.no/xsd/no-ext-result-1.0 no-ext-result-1.0.xsd"><desc>EPP response to command with clTRID [NORID-3748-1215079064192782] and svTRID [200807031157442264480D-reg9091-NORID]</desc><data><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><msgQ count="1" id="132939"/><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>trond-transfer.no</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>reg9091</domain:reID><domain:reDate>2008-07-03T09:57:48.00Z</domain:reDate><domain:acID>reg9091</domain:acID><domain:acDate>2008-08-02T09:57:48.00Z</domain:acDate></domain:trnData></resData><trID><clTRID>NORID-3748-1215079064192782</clTRID><svTRID>200807031157442264480D-reg9091-NORID</svTRID></trID></response></epp></data></message></resData><trID><clTRID>NORID-6828-1215085198022632</clTRID><svTRID>2008070313395805604613-reg9091-NORID</svTRID></trID></response>'.$E2;
$rc=$dri->message_retrieve();
my @t=$rc->trid();
is($t[0],'NORID-6828-1215085198022632','Correct parse of outer trID/clTRID block');
is($t[1],'2008070313395805604613-reg9091-NORID','Correct parse of outer trID/svTRID block');
$rc=$rc->next();
is($rc,undef,'Correct parse of trID, without touching any trID node inside response');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}

#
# Neat function to use to dump stuf on errors, see use above
# 

sub eval_it {
    my $dri = shift;    
    my $f   = shift;
    my $p1   = shift;
    my $p2   = shift;

    my $ok=eval {
	$dri->$f($p1, $p2);
	1;
    };
    if (! $ok) { 
	my $err=$@;
	print "\n\nAn EXCEPTION happened !\n";
	if (ref $err) {
	    print "FAILURE: Error descriptions: ", ref $err, "\n";
	    $err->print();
	    print "\n";
	    dump_conditions($dri);
	} else {
	    print "FAILURE: No extra info: ";
	    print $err;
	}
    } else {
	print "\n\nSUCCESS";
    }
    print "\n";
}

