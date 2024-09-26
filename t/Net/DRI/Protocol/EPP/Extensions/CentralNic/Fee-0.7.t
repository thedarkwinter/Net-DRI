#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 61;
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
#$dri->add_registry('CentralNic');
#$dri->target('CentralNic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->add_registry('NGTLD',{provider=>'centralnic'});
$dri->target('centralnic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2,@fees);

####################################################################################################
## Fee extension version 0.7 http://tools.ietf.org/html/draft-brown-epp-fees-04
## Fee-0.7 (In use by Afilias)
## We use a greeting here to switch the namespace version here to -0.7 testing
$R2=$E1.'<greeting><svID>SUPER EPP Server epp.charlestonroadregistry.com</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.7','Fee 0.7 loaded correctly');
####################################################################################################


## Check: single domain - minimum data
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">check-claims-landrush.space</domain:name></domain:cd><domain:cd><domain:name avail="1">check-claims-landrush.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.7"><fee:cd><fee:name>check-claims-landrush.space</fee:name><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period><fee:fee description="Application Fee" refundable="0">150.00</fee:fee><fee:fee description="Registration Fee" refundable="1">500.00</fee:fee><fee:class>premium-tier1</fee:class></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('check-claims-landrush.space',{fee=>{action=>'create', duration=>DateTime::Duration->new(years=>2), 'currency' => 'EUR', 'phase'=>'claims', 'sub_phase'=>'landrush'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>check-claims-landrush.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:domain><fee:name>check-claims-landrush.space</fee:name><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'check-claims-landrush.space','Fee extension: domain_check single parse domain');
is($d->{premium},1,'Fee extension: domain_check single parse premium');
is($d->{currency},'EUR','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),2,'Fee extension: domain_check single parse duration');
is($d->{fee_application_fee},'150.00','Fee extension: domain_check single parse fee (fee_application_fee)');
is($d->{fee_registration_fee},'500.00','Fee extension: domain_check single parse fee (fee_registration_fee)');
is($d->{fee},'650.00','Fee extension: domain_check single parse fee');
is($d->{phase},'claims','Fee extension: domain_check single parse phase');
is($d->{sub_phase},'landrush','Fee extension: domain_check single parse sub_phase');

# domain_check_price
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">check-sunrise.space</domain:name></domain:cd><domain:cd><domain:name avail="1">check-sunrise.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.7"><fee:cd><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Registration fee" refundable="1" grace-period="P5D">5000.00</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">renew</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Renewal fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">transfer</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Transfer fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">restore</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Transfer fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('check-sunrise.space',{action=>'create', duration=>DateTime::Duration->new(years=>1), 'currency' => 'USD', 'phase'=>'sunrise'});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>check-sunrise.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:domain><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:domain><fee:domain><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">renew</fee:command><fee:period unit="y">1</fee:period></fee:domain><fee:domain><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">transfer</fee:command><fee:period unit="y">1</fee:period></fee:domain><fee:domain><fee:name>check-sunrise.space</fee:name><fee:currency>USD</fee:currency><fee:command phase="sunrise">restore</fee:command><fee:period unit="y">1</fee:period></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_price build');
is($dri->get_info('action'),'check','domain_check_price get_info(action)');
is($dri->get_info('exist'),0,'domain_check_price get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'check-sunrise.space','Fee extension: domain_check_price single parse domain');
is($d->{premium},1,'Fee extension: domain_check_price single parse premium');
is($d->{currency},'USD','Fee extension: domain_check_price single parse currency');
is($d->{action},'create','Fee extension: domain_check_price single parse action');
is($d->{duration}->years(),1,'Fee extension: domain_check_price single parse duration');
is($d->{fee_registration_fee},'5000.00','Fee extension: domain_check_price single parse fee (fee_registration_fee)');
is($d->{fee},'5000.00','Fee extension: domain_check_price single parse fee');
is($d->{phase},'sunrise','Fee extension: domain_check_price single parse phase');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'premium','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'5000.00','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),'9.95','domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),'9.95','domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),'9.95','domain_check get_info (restore_price) undef');

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foo.space</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok" /><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.foo.space</domain:host><domain:host>ns2.foo.space</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><fee:infData xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee refundable="1" grace-period="P5D" applied="immediate">10.00</fee:fee><fee:class>premium-tier1</fee:class></fee:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('foo.space',{fee=>{currency=>'USD',phase=>'sunrise',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">foo.space</domain:name></domain:info></info><extension><fee:info xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_info build');
$rc=$dri->domain_info('foo.space');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'foo.space','domain_info get_info (name)');
@fees = @{$dri->get_info('fee')};
$d = $fees[0];
is($d->{currency},'USD','Fee extension: domain_info parse currency');
is($d->{action},'create','Fee extension: domain_info parse action');
is($d->{phase},'sunrise','Fee extension: domain_info parse phase');
is($d->{duration}->years(),1,'Fee extension: domain_info parse duration');
is($d->{fee},'10.00','Fee extension: domain_info parse fee');
is($d->{description},'Refundable(Grace=>P5D)(Applied=>immediate)','Fee extension: domain_info parse human-readable description');
is($d->{class},'premium-tier1','Fee extension: domain_info parse classe');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'premium-tier1','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'10.00','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),undef,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

## domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.space</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:period unit="y">1</fee:period><fee:fee>5.00</fee:fee><fee:balance>-5.00</fee:balance><fee:creditLimit>1000.00</fee:creditLimit></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('exdomain.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.bar'],['ns2.example.bar']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.bar</domain:hostObj><domain:hostObj>ns2.example.bar</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},'5.00','Fee extension: domain_create parse fee');
is($d->{balance},'-5.00','Fee extension: domain_create parse balance');
is($d->{credit_limit},'1000.00','Fee extension: domain_create parse credit limit');

####################################################################################################
exit 0;
