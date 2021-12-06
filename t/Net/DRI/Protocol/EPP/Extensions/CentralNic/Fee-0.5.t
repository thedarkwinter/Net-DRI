#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 101;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('NGTLD',{provider=>'nominet-mmx'});
$dri->target('nominet-mmx')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2);

####################################################################################################
## Fee extension version 0.5 http://tools.ietf.org/html/draft-brown-epp-fees-02
## Fee-0.5 (In use by CentralNic, Minds & Machines and Nominet-MMX)
## MAM is depricated very soon.
## We use a greeting here to switch the namespace version here to -0.5 testing
$R2=$E1.'<greeting><svID>Minds + Machines EPP Server epp-dub.mm-registry.com</svID><svDate>2014-06-25T10:08:59.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.5','Fee 0.5 loaded correctly');
####################################################################################################

### EPP Check Commands Variants ###

## Check: single domain - minimum data
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">exdom1.broadway</domain:name></domain:cd><domain:cd><domain:name avail="1">exdom1.broadway</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:cd><fee:name premium="false">exdom1.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Phase Fee">0.00</fee:fee><fee:fee description="Registration Fee">10.00</fee:fee></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('exdom1.broadway',{fee=>{action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom1.broadway</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom1.broadway</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'exdom1.broadway','Fee extension: domain_check single parse domain');
is($d->{premium},0,'Fee extension: domain_check single parse premium');
is($d->{currency},'USD','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),1,'Fee extension: domain_check singe parse duration');
is($d->{fee},10.00,'Fee extension: domain_check singe parse fee');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_check get_info (is_premium) no');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),10.00,'domain_check get_info (create_price)');
is($dri->get_info('renew_price'),undef,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

## Check: single domain more detail
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">exdom1.gop</domain:name></domain:cd><domain:cd><domain:name avail="1">exdom1.gop</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:cd><fee:name premium="false">exdom1.gop</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">2</fee:period><fee:fee description="Phase Fee">0.00</fee:fee><fee:fee description="Registration Fee">10.00</fee:fee></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('exdom1.gop',{fee=>{ action=>'create',phase=>'claims',sub_phase=>'landrush',currency=>'USD','duration'=>$dri->local_object('duration','years',2)}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom1.gop</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom1.gop</fee:name><fee:currency>USD</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'exdom1.gop','Fee extension: domain_check single parse domain');
is($d->{currency},'USD','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),2,'Fee extension: domain_check singe parse duration');
is($d->{fee},10.00,'Fee extension: domain_check singe parse fee');

## Check: single domain with two fee actions/commands
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">exdom2.broadway</domain:name></domain:cd><domain:cd><domain:name avail="1">exdom2.broadway</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:cd><fee:name premium="false">exdom2.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Phase Fee">0.00</fee:fee><fee:fee description="Registration Fee">10.00</fee:fee></fee:cd><fee:cd><fee:name premium="true">exdom2.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Phase Fee">0.00</fee:fee><fee:fee description="Registration Fee">1000.00</fee:fee></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('exdom2.broadway',{fee=>[{action=>'create'},{action=>'renew'}]});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom2.broadway</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom2.broadway</fee:name><fee:command>create</fee:command></fee:domain><fee:domain><fee:name>exdom2.broadway</fee:name><fee:command>renew</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
my ($d1,$d2) = @{$dri->get_info('fee')};
is($d1->{domain},'exdom2.broadway','Fee extension: domain_check single parse domain');
is($d1->{premium},0,'Fee extension: domain_check single parse premium');
is($d1->{currency},'USD','Fee extension: domain_check single parse currency');
is($d1->{action},'create','Fee extension: domain_check single parse action');
is($d1->{duration}->years(),1,'Fee extension: domain_check singe parse duration');
is($d1->{fee},10.00,'Fee extension: domain_check singe parse fee');
is($d2->{domain},'exdom2.broadway','Fee extension: domain_check single parse domain');
is($d2->{premium},1,'Fee extension: domain_check single parse premium');
is($d2->{currency},'USD','Fee extension: domain_check single parse currency');
is($d2->{action},'create','Fee extension: domain_check single parse action');
is($d2->{duration}->years(),1,'Fee extension: domain_check singe parse duration');
is($d2->{fee},1000.00,'Fee extension: domain_check singe parse fee');


## TODO
## Check: multi with one fee actions (for) both domains)
SKIP:
{
skip '*** TODO : Check: multi with one fee hash for all domains',1;
$rc=$dri->domain_check('exdom2.gop','exdom3.gop',{fee=>{action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom2.gop</domain:name><domain:name>exdom3.gop</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom2.gop</fee:name><fee:command>create</fee:command></fee:domain><fee:domain><fee:name>exdom3.gop</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
};

## Check: multi with a fee actions for each domains
$rc=$dri->domain_check('exdom4.gop','exdom5.gop',{fee=>[{domain=>'exdom4.gop',action=>'create'},{domain=>'exdom5.gop',action=>'create'}]});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom4.gop</domain:name><domain:name>exdom5.gop</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom4.gop</fee:name><fee:command>create</fee:command></fee:domain><fee:domain><fee:name>exdom5.gop</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');

# domain_check_price (defaults)

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">exdom3.broadway</domain:name></domain:cd><domain:cd><domain:name avail="1">exdom3.broadway</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:cd><fee:name premium="false">exdom3.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee>10.00</fee:fee></fee:cd><fee:cd><fee:name premium="false">exdom3.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>renew</fee:command><fee:period unit="y">1</fee:period><fee:fee>10.00</fee:fee></fee:cd><fee:cd><fee:name premium="false">exdom3.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>transfer</fee:command><fee:period unit="y">1</fee:period><fee:fee>5.00</fee:fee></fee:cd><fee:cd><fee:name premium="false">exdom3.broadway</fee:name><fee:currency>USD</fee:currency><fee:command>restore</fee:command><fee:period unit="y">1</fee:period><fee:fee>20.00</fee:fee></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('exdom3.broadway');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom3.broadway</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>exdom3.broadway</fee:name><fee:command>create</fee:command></fee:domain><fee:domain><fee:name>exdom3.broadway</fee:name><fee:command>renew</fee:command></fee:domain><fee:domain><fee:name>exdom3.broadway</fee:name><fee:command>transfer</fee:command></fee:domain><fee:domain><fee:name>exdom3.broadway</fee:name><fee:command>restore</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_price build');
is($dri->get_info('exist'),0,'domain_check_price get_info(exist)');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_check_price get_info (is_premium) no');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check_price get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check_price get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check_price get_info (price_currency)');
is($dri->get_info('create_price'),10.00,'domain_check_price get_info (create_price)');
is($dri->get_info('renew_price'),10.00,'domain_check_price get_info (renew_price)');
is($dri->get_info('transfer_price'),5,'domain_check_price get_info (transfer_price)');
is($dri->get_info('restore_price'),20,'domain_check_price get_info (restore_price)');

####################################################################################################
### EPP Info Command ###

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdom4.broadway</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok" /><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.exdomain.broadway</domain:hostObj><domain:hostObj>ns1.example.bar</domain:hostObj></domain:ns><domain:host>ns1.exdomain.broadway</domain:host><domain:host>ns2.exdomain.broadway</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><fee:infData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee>10.00</fee:fee></fee:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('exdom4.broadway',{fee=>{currency=>'USD',phase=>'sunrise',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">exdom4.broadway</domain:name></domain:info></info><extension><fee:info xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_info build');
$rc=$dri->domain_info('exdom4.broadway');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'exdom4.broadway','domain_info get_info (name)');
$d = shift @{$rc->get_data('fee')};
is($d->{currency},'USD','Fee extension: domain_info parse currency');
is($d->{action},'create','Fee extension: domain_info parse action');
is($d->{phase},'sunrise','Fee extension: domain_info parse phase');
is($d->{duration}->years(),1,'Fee extension: domain_info parse duration');
is($d->{fee},10.00,'Fee extension: domain_check parse fee');

## Transfer query
# No examples to test using the RFC as reference (only the command response).
# Used transform_parse() to add the extension for the command response
# Check registrar_commands on: EPP/Extensions/CentralNic/Fee.pm
##
### END: EPP Query Commands ###

##################################################################

### EPP Transform Commands ###
## Create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee><fee:balance>-5.00</fee:balance><fee:creditLimit>1000.00</fee:creditLimit></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('exdomain.broadway',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.bar'],['ns2.example.bar']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.bar</domain:hostObj><domain:hostObj>ns2.example.bar</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},5.00,'Fee extension: domain_create parse fee');
is($d->{balance},-5.00,'Fee extension: domain_create parse balance');
is($d->{credit_limit},1000.00,'Fee extension: domain_create parse credit limit');

## Renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData><extension><fee:renData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('exdomain.broadway',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><fee:renew xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_renew build');
is($rc->is_success(),1,'domain_renew is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_renew parse currency');
is($d->{fee},5.00,'Fee extension: domain_renew parse fee');

## Transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><fee:trnData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('exdomain.broadway',{auth => {pw=>'2fooBAR',roid=>"JD1234-REP"},duration=>DateTime::Duration->new(years=>1),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><fee:transfer xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_transfer build');
is($rc->is_success(),1,'domain_transfer is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');

## Update
$R2=$E1.'<response>'.r().'<extension><fee:updData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:updData></extension>'.$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('fee',{currency=>'USD',fee=>'5.00'});
$rc=$dri->domain_update('exdomain.broadway',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.broadway</domain:name><domain:chg><domain:registrant>sh8013</domain:registrant></domain:chg></domain:update></update><extension><fee:update xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_update build');
is($rc->is_success(),1,'domain_update is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');

####################################################################################################
## EAP
$dri->add_registry('NGTLD',{provider=>'centralnic'});
$dri->target('centralnic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">eapdom1.website</domain:name></domain:cd><domain:cd><domain:name avail="1">eapdom1.broadway</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:cd><fee:name>eapdom1.website</fee:name><fee:currency>USD</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Registration Fee" refundable="1">20.00</fee:fee><fee:fee description="Early Access Fee" refundable="0">1000.00</fee:fee></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('eapdom1.website',{fee=>{action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>eapdom1.website</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.5" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.5 fee-0.5.xsd"><fee:domain><fee:name>eapdom1.website</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'eapdom1.website','Fee extension: domain_check single parse domain');
is($d->{premium},0,'Fee extension: domain_check single parse premium');
is($d->{currency},'USD','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),1,'Fee extension: domain_check singe parse duration');
is($d->{fee},1020.00,'Fee extension: domain_check singe parse fee');
is($d->{fee_registration_fee},20.00,'Fee extension: domain_check singe parse registration_fee');
is($d->{fee_early_access_fee},1000.00,'Fee extension: domain_check singe parse early_access_fee');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_check get_info (is_premium) no');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),1020.00,'domain_check get_info (create_price)');
is($dri->get_info('eap_price'),1000.00,'domain_check get_info (eap_price)');
is($dri->get_info('renew_price'),undef,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

exit 0;
