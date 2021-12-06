#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 119;
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
$dri->add_current_registry('CentralNic::CentralNic');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2);

####################################################################################################
## Fee extension version 0.4 http://tools.ietf.org/html/draft-brown-epp-fees-01
## Fee-0.4 (In use by GMO, no longer by CentralNic but these tests are based on them)
## We use a greeting here to switch the namespace version here to -0.4 for initial testing
$R2=$E1.'<greeting><svID>CentralNic EPP server EPP-OTE.CENTRALNIC.COM</svID><svDate>2014-06-25T10:44:01.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.4</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.4','Fee 0.4 loaded correctly');
####################################################################################################

### EPP Query Commands ###
## Check: single domain
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">example.website</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example.website</fee:domain><fee:currency>EUR</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">2</fee:period><fee:fee>2.50</fee:fee></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.website',{fee=>{currency=>'EUR',action=>'transfer',duration=>$dri->local_object('duration','years',2)}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.website</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example.website</fee:domain><fee:currency>EUR</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">2</fee:period></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),1,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'example.website','Fee extension: domain_check single parse domain');
is($d->{currency},'EUR','Fee extension: domain_check single parse currency');
is($d->{action},'transfer','Fee extension: domain_check single parse action');
is($d->{duration}->years(),2,'Fee extension: domain_check singe parse duration');
is($d->{fee},'2.50','Fee extension: domain_check singe parse fee');
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">example.bar</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example.bar</fee:domain><fee:currency>EUR</fee:currency><fee:action phase="claims" subphase="landrush">create</fee:action><fee:period unit="y">2</fee:period><fee:fee>5.00</fee:fee></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example.bar',{fee=>{currency=>'EUR',action=>'create',phase=>'claims',sub_phase=>'landrush',duration=>$dri->local_object('duration','years',2)}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.bar</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example.bar</fee:domain><fee:currency>EUR</fee:currency><fee:action phase="claims" subphase="landrush">create</fee:action><fee:period unit="y">2</fee:period></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),1,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'example.bar','Fee extension: domain_check single parse domain');
is($d->{currency},'EUR','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{phase},'claims','Fee extension: domain_check single parse phase');
is($d->{sub_phase},'landrush','Fee extension: domain_check single parse sub_phase');
is($d->{duration}->years(),2,'Fee extension: domain_check singe parse duration');
is($d->{fee},'5.00','Fee extension: domain_check singe parse fee');
# using the standardised methods
is($dri->get_info('is_premium'),undef,'domain_check get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),2,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'EUR','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'5.00','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),undef,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

## Check: multiple domains
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example1.space</domain:name></domain:cd><domain:cd><domain:name avail="0">example2.bar</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="0">example3.website</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example1.space</fee:domain><fee:currency>USD</fee:currency><fee:action phase="sunrise">create</fee:action><fee:period unit="y">1</fee:period><fee:fee>10.00</fee:fee></fee:chkData><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example2.bar</fee:domain><fee:currency>EUR</fee:currency><fee:action phase="claims" subphase="landrush">create</fee:action><fee:period unit="y">2</fee:period><fee:fee>5.00</fee:fee></fee:chkData><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example3.website</fee:domain><fee:currency>EUR</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">2</fee:period><fee:fee>2.50</fee:fee></fee:chkData></extension>'.$TRID.'</response>'.$E2;
my @fees = (
  {domain=>'example1.space',currency=>'USD',action=>'create',phase=>'sunrise',duration=>$dri->local_object('duration','years',1)},
  {domain=>'example2.bar',currency=>'EUR',action=>'create',phase=>'claims',sub_phase=>'landrush',duration=>$dri->local_object('duration','years',2)},
  {domain=>'example3.website',currency=>'EUR',action=>'transfer',duration=>$dri->local_object('duration','years',2)}
);
$rc=$dri->domain_check('example1.space','example2.bar','example3.website',{fee=>\@fees});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example1.space</domain:name><domain:name>example2.bar</domain:name><domain:name>example3.website</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example1.space</fee:domain><fee:currency>USD</fee:currency><fee:action phase="sunrise">create</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example2.bar</fee:domain><fee:currency>EUR</fee:currency><fee:action phase="claims" subphase="landrush">create</fee:action><fee:period unit="y">2</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example3.website</fee:domain><fee:currency>EUR</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">2</fee:period></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('action'),'check','domain_check multi get_info (action)');
is($dri->get_info('exist','domain','example1.space'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.bar'),1,'domain_check multi get_info(exist) 2/3');
is($dri->get_info('exist','domain','example3.website'),1,'domain_check multi get_info(exist) 3/3');
$d = shift @{$dri->get_info('fee','domain','example1.space')};
is($d->{domain},'example1.space','domain_check multi get_info(domain) 1/3');
is($d->{currency},'USD','domain_check multi get_info(currency) 1/3');
is($d->{action},'create','domain_check multi get_info(action) 1/3');
is($d->{phase},'sunrise','domain_check multi get_info(phase) 1/3');
is($d->{duration}->years(),'1','domain_check multi get_info(duration) 1/3');
is($d->{fee},'10.00','domain_check multi get_info(fee) 1/3');
$d = shift @{$dri->get_info('fee','domain','example2.bar')};
is($d->{domain},'example2.bar','domain_check multi get_info(domain) 2/3');
is($d->{currency},'EUR','domain_check multi get_info(currency) 2/3');
is($d->{action},'create','domain_check multi get_info(action) 2/3');
is($d->{phase},'claims','domain_check multi get_info(phase) 2/3');
is($d->{sub_phase},'landrush','domain_check multi get_info(sub_phase) 2/3');
is($d->{duration}->years(),'2','domain_check multi get_info(duration) 2/3');
is($d->{fee},'5.00','domain_check multi get_info(fee) 2/3');
$d = shift @{$dri->get_info('fee','domain','example3.website')};
is($d->{domain},'example3.website','domain_check multi get_info(domain) 3/3');
is($d->{currency},'EUR','domain_check multi get_info(currency) 3/3');
is($d->{action},'transfer','domain_check multi get_info(action) 3/3');
is($d->{duration}->years(),'2','domain_check multi get_info(duration) 3/3');
is($d->{fee},'2.50','domain_check multi get_info(fee) 3/3');
# using the standardised methods
is($dri->get_info('is_premium','domain','example3.website'),undef,'domain_check_multi get_info (is_premium) undef');
is($dri->get_info('price_duration','domain','example1.space')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('create_price','domain','example2.bar'),'5.00','domain_check_multi get_info (create_price)');
is($dri->get_info('transfer_price','domain','example3.website'),'2.50','domain_check_multi get_info (transfer_price)');

## domain_check with multiple actions on one domain
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">example4.website</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>create</fee:action><fee:period unit="y">1</fee:period><fee:fee>11.50</fee:fee></fee:chkData><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>renew</fee:action><fee:period unit="y">1</fee:period><fee:fee>11.50</fee:fee></fee:chkData><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">1</fee:period><fee:fee>11.50</fee:fee></fee:chkData><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>restore</fee:action><fee:period unit="y">1</fee:period><fee:fee>27.00</fee:fee></fee:chkData></extension>'.$TRID.'</response>'.$E2;
@fees = (
  {currency=>'USD',action=>'create',duration=>$dri->local_object('duration','years',1)},
  {currency=>'USD',action=>'renew',duration=>$dri->local_object('duration','years',1)},
  {currency=>'USD',action=>'transfer',duration=>$dri->local_object('duration','years',1)},
  {currency=>'USD',action=>'restore',duration=>$dri->local_object('duration','years',1)}
);
$rc=$dri->domain_check('example4.website',{fee=>\@fees});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.website</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>create</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>renew</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>restore</fee:action><fee:period unit="y">1</fee:period></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build with multiple prices');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'example4.website','domain_check multi get_info(domain) 1/3');
is($d->{currency},'USD','domain_check multi get_info(currency) 1/3');
is($d->{action},'create','domain_check multi get_info(action) 1/3');
is($d->{duration}->years(),'1','domain_check multi get_info(duration) 1/3');
is($d->{fee},'11.50','domain_check multi get_info(fee) 1/3');

# domain_check_price (defaults)
$rc=$dri->domain_check_price('example4.website');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.website</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>create</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>renew</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>transfer</fee:action><fee:period unit="y">1</fee:period></fee:check><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:domain>example4.website</fee:domain><fee:currency>USD</fee:currency><fee:action>restore</fee:action><fee:period unit="y">1</fee:period></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_price build');
is($dri->get_info('action'),'check','domain_check_price get_info(action)');
is($dri->get_info('exist'),0,'domain_check_price get_info(exist)');
# using the standardised methods
is($dri->get_info('is_premium'),undef,'domain_check_price get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check_price get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check_price get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check_price get_info (price_currency)');
is($dri->get_info('create_price'),'11.50','domain_check_price get_info (create_price)');
is($dri->get_info('renew_price'),'11.50','domain_check_price get_info (renew_price)');
is($dri->get_info('transfer_price'),'11.50','domain_check_price get_info (transfer_price)');
is($dri->get_info('restore_price'),'27.00','domain_check_price get_info (restore_price)');


## Info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok" /><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.space</domain:hostObj><domain:hostObj>ns1.example.bar</domain:hostObj></domain:ns><domain:host>ns1.example.space</domain:host><domain:host>ns2.example.space</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><fee:infData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:action phase="sunrise">create</fee:action><fee:period unit="y">1</fee:period><fee:fee>10.00</fee:fee></fee:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.space',{fee=>{currency=>'USD',phase=>'sunrise',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.space</domain:name></domain:info></info><extension><fee:info xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:action phase="sunrise">create</fee:action><fee:period unit="y">1</fee:period></fee:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_info build');
$rc=$dri->domain_info('example.space');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'example.space','domain_info get_info (name)');
is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info (roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info ge_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'sh8013','domain_info ge_info(contact) tech srid');
is($dri->get_info('clID'),'ClientX','domain_info get_info (clID)');
is($dri->get_info('crID'),'ClientY','domain_info get_info (crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is($d,'1999-04-03T22:00:00','domain_info get_info(crDate)');
is($dri->get_info('upID'),'ClientX','domain_info get_info (upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is($d,'1999-12-03T09:00:00','domain_info get_info(upDate)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is($d,'2005-04-03T22:00:00','domain_info get_info(exDate)');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','domain_info get_info(trDate)');
is($d,'2000-04-08T09:00:00','domain_info get_info(trDate)');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info (auth)');
$d = shift @{$rc->get_data('fee')};
is($d->{currency},'USD','Fee extension: domain_info parse currency');
is($d->{action},'create','Fee extension: domain_info parse action');
is($d->{phase},'sunrise','Fee extension: domain_info parse phase');
is($d->{duration}->years(),1,'Fee extension: domain_info parse duration');
is($d->{fee},'10.00','Fee extension: domain_check parse fee');

## Transfer query
# No examples to test using the RFC as reference (only the command response).
# Used transform_parse() to add the extension for the command response
# Check registrar_commands on: EPP/Extensions/CentralNic/Fee.pm
##
### END: EPP Query Commands ###

##################################################################

### EPP Transform Commands ###
## Create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('example.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.bar'],['ns2.example.bar']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.bar</domain:hostObj><domain:hostObj>ns2.example.bar</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},5.00,'Fee extension: domain_create parse fee');

## Renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData><extension><fee:renData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example.space',{duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><fee:renew xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_renew build');
is($rc->is_success(),1,'domain_renew is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_renew parse currency');
is($d->{fee},5.00,'Fee extension: domain_renew parse fee');

## Transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><fee:trnData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('example.space',{auth => {pw=>'2fooBAR',roid=>"JD1234-REP"},duration=>DateTime::Duration->new(years=>1),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><fee:transfer xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_transfer build');
is($rc->is_success(),1,'domain_transfer is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');

## Update
$R2=$E1.'<response>'.r().'<extension><fee:updData xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:updData></extension>'.$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('fee',{currency=>'USD',fee=>'5.00'});
$rc=$dri->domain_update('example.space',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.space</domain:name><domain:chg><domain:registrant>sh8013</domain:registrant></domain:chg></domain:update></update><extension><fee:update xmlns:fee="urn:ietf:params:xml:ns:fee-0.4" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.4 fee-0.4.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_update build');
is($rc->is_success(),1,'domain_update is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');
### END: EPP Transform Commands ###
####################################################################################################

exit 0;
