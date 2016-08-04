#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 84;
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
## Fee extension version 0.9 http://tools.ietf.org/html/draft-brown-epp-fees-06
## fee-0.9 will be used by RegBox (and more?)
## We use a greeting here to switch the namespace version here to -0.9 testing
$R2=$E1.'<greeting><svID>Fee-0.9-server</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.9</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.9','Fee 0.9 loaded correctly');
####################################################################################################

####################################################################################################
### check command and response copied draft-brown-epp-fees-06 5.1.1 but names changes
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">tourism.space</domain:name></domain:cd><domain:cd><domain:name avail="0">holidays.space</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="0">hotels.space</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.9"><fee:cd><fee:objID>tourism.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Application Fee" refundable="0">5.00</fee:fee><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">5.00</fee:fee></fee:cd><fee:cd><fee:objID>holidays.space</fee:objID><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period><fee:fee>5.00</fee:fee></fee:cd><fee:cd><fee:objID>hotels.space</fee:objID><fee:currency>EUR</fee:currency><fee:command>transfer</fee:command><fee:period unit="y">2</fee:period><fee:fee description="Transfer Fee" refundable="0">2.50</fee:fee><fee:fee description="Renewal Fee" refundable="1" grace-period="P5D">10.00</fee:fee></fee:cd><fee:cd><fee:objID>restaurants.space</fee:objID><fee:currency>GBP</fee:currency><fee:command>restore</fee:command><fee:fee description="Restore Fee" refundable="0">25</fee:fee><fee:class>premium-tier1</fee:class></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
@fees = ( 
  { domain=>'tourism.space','element'=>'name',currency=>'USD',action=>'create',phase=>'sunrise',duration=>$dri->local_object('duration','years',1) },
  { domain=>'holidays.space',currency=>'EUR',action=>'create',phase=>'claims',sub_phase=>'landrush',duration=>$dri->local_object('duration','years',2) },
  { domain=>'hotels.space',currency=>'EUR',action=>'transfer' },
  { domain=>'restaurants.space',action=>'restore' }
);
$rc=$dri->domain_check('tourism.space','holidays.space','hotels.space', {fee=>\@fees});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>tourism.space</domain:name><domain:name>holidays.space</domain:name><domain:name>hotels.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.9" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.9 fee-0.9.xsd"><fee:object objURI="urn:ietf:params:xml:ns:domain-1.0"><fee:objID element="name">tourism.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:object><fee:object><fee:objID>holidays.space</fee:objID><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period></fee:object><fee:object><fee:objID>hotels.space</fee:objID><fee:currency>EUR</fee:currency><fee:command>transfer</fee:command></fee:object><fee:object><fee:objID>restaurants.space</fee:objID><fee:command>restore</fee:command></fee:object></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('action'),'check','domain_check multi get_info (action)');
is($dri->get_info('exist','domain','tourism.space'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','holidays.space'),1,'domain_check multi get_info(exist) 2/4');
is($dri->get_info('exist','domain','hotels.space'),1,'domain_check multi get_info(exist) 3/4');
$d = shift @{$dri->get_info('fee','domain','tourism.space')};
is($d->{domain},'tourism.space','domain_check multi get_info(domain) 1/4');
is($d->{premium},0,'domain_check multi parse premium 1/4');
is($d->{currency},'USD','domain_check multi get_info(currency) 1/4');
is($d->{action},'create','domain_check multi get_info(action) 1/4');
is($d->{phase},'sunrise','domain_check multi get_info(phase) 1/4');
is($d->{sub_phase},undef,'domain_check multi get_info(sub_phase) 1/4');
is($d->{duration}->years(),'1','domain_check multi get_info(duration) 1/4');
is($d->{fee},10.00,'domain_check multi get_info(fee) 1/4');
is($d->{fee_application_fee},5.00,'domain_check multi parse fee (fee_application_fee) 1/4');
is($d->{fee_registration_fee},5.00,'domain_check multi parse fee (fee_registration_fee) 1/4');
$d = shift @{$dri->get_info('fee','domain','holidays.space')};
is($d->{domain},'holidays.space','domain_check multi get_info(domain) 2/4');
is($d->{premium},0,'domain_check multi parse premium 2/4');
is($d->{currency},'EUR','domain_check multi get_info(currency) 2/4');
is($d->{action},'create','domain_check multi get_info(action) 2/4');
is($d->{phase},'claims','domain_check multi get_info(phase) 2/4');
is($d->{sub_phase},'landrush','domain_check multi get_info(sub_phase) 2/4');
is($d->{duration}->years(),'2','domain_check multi get_info(duration) 2/4');
is($d->{fee},5.00,'domain_check multi get_info(fee) 2/4');
$d = shift @{$dri->get_info('fee','domain','hotels.space')};
is($d->{domain},'hotels.space','domain_check multi get_info(domain) 3/4');
is($d->{premium},0,'domain_check multi parse premium 3/4');
is($d->{currency},'EUR','domain_check multi get_info(currency) 3/4');
is($d->{action},'transfer','domain_check multi get_info(action) 3/4');
is($d->{duration}->years(),'2','domain_check multi get_info(duration) 3/4');
is($d->{fee},12.50,'domain_check multi get_info(fee) 3/4');
is($d->{fee_transfer_fee},2.50,'domain_check multi parse fee (fee_transfer_fee) 1/4');
is($d->{fee_renewal_fee},10.00,'domain_check multi parse fee (fee_renewal_fee) 1/4');
$d = shift @{$dri->get_info('fee','domain','restaurants.space')};
is($d->{domain},'restaurants.space','domain_check multi get_info(domain) 4/4');
is($d->{premium},1,'domain_check multi parse premium 4/4');
is($d->{currency},'GBP','domain_check multi get_info(currency) 4/4');
is($d->{action},'restore','domain_check multi get_info(action) 4/4');
is($d->{fee},25,'domain_check multi get_info(fee) 3/4');
is($d->{fee_restore_fee},25.00,'domain_check multi parse fee (fee_redstore_fee) 4/4');

# using the standardised methods
is($dri->get_info('is_premium','domain','hotels.space'),0,'domain_check_multi get_info (is_premium) undef');
is($dri->get_info('price_duration','domain','tourism.space')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('create_price','domain','holidays.space'),5.00,'domain_check_multi get_info (create_price)');
is($dri->get_info('transfer_price','domain','hotels.space'),12.50,'domain_check_multi get_info (transfer_price)');
is($dri->get_info('restore_price','domain','restaurants.space'),25,'domain_check_multi get_info (restore_price)');

####################################################################################################
### Copied From fee-0.7 tests with only namespace changed

## Check: single domain - minimum data
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">check-claims-landrush.space</domain:name></domain:cd><domain:cd><domain:name avail="1">check-claims-landrush.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.9"><fee:cd><fee:objID>check-claims-landrush.space</fee:objID><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period><fee:fee description="Application Fee" refundable="0">150.00</fee:fee><fee:fee description="Registration Fee" refundable="1">500.00</fee:fee><fee:class>premium-tier1</fee:class></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('check-claims-landrush.space',{fee=>{action=>'create', duration=>DateTime::Duration->new(years=>2), 'currency' => 'EUR', 'phase'=>'claims', 'sub_phase'=>'landrush'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>check-claims-landrush.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.9" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.9 fee-0.9.xsd"><fee:object><fee:objID>check-claims-landrush.space</fee:objID><fee:currency>EUR</fee:currency><fee:command phase="claims" subphase="landrush">create</fee:command><fee:period unit="y">2</fee:period></fee:object></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'check-claims-landrush.space','Fee extension: domain_check single parse domain');
is($d->{premium},1,'Fee extension: domain_check single parse premium');
is($d->{currency},'EUR','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),2,'Fee extension: domain_check singe parse duration');
is($d->{fee_application_fee},150.00,'Fee extension: domain_check singe parse fee (fee_application_fee)');
is($d->{fee_registration_fee},500.00,'Fee extension: domain_check singe parse fee (fee_registration_fee)');
is($d->{fee},650.00,'Fee extension: domain_check singe parse fee');
is($d->{phase},'claims','Fee extension: domain_check singe parse phase');
is($d->{sub_phase},'landrush','Fee extension: domain_check singe parse sub_phase');

# domain_check_price
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">check-sunrise.space</domain:name></domain:cd><domain:cd><domain:name avail="1">check-sunrise.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.9"><fee:cd><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Registration fee" refundable="1" grace-period="P5D">5000.00</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">renew</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Renewal fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">transfer</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Transfer fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd><fee:cd><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">restore</fee:command><fee:period unit="y">1</fee:period><fee:fee description="Transfer fee" refundable="1" grace-period="P5D">9.95</fee:fee><fee:class>premium</fee:class></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('check-sunrise.space',{action=>'create', duration=>DateTime::Duration->new(years=>1), 'currency' => 'USD', 'phase'=>'sunrise'});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>check-sunrise.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.9" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.9 fee-0.9.xsd"><fee:object><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:object><fee:object><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">renew</fee:command><fee:period unit="y">1</fee:period></fee:object><fee:object><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">transfer</fee:command><fee:period unit="y">1</fee:period></fee:object><fee:object><fee:objID>check-sunrise.space</fee:objID><fee:currency>USD</fee:currency><fee:command phase="sunrise">restore</fee:command><fee:period unit="y">1</fee:period></fee:object></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_price build');
is($dri->get_info('action'),'check','domain_check_price get_info(action)');
is($dri->get_info('exist'),0,'domain_check_price get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'check-sunrise.space','Fee extension: domain_check_price single parse domain');
is($d->{premium},1,'Fee extension: domain_check_price single parse premium');
is($d->{currency},'USD','Fee extension: domain_check_price single parse currency');
is($d->{action},'create','Fee extension: domain_check_price single parse action');
is($d->{duration}->years(),1,'Fee extension: domain_check_price single parse duration');
is($d->{fee_registration_fee},5000.00,'Fee extension: domain_check_price single parse fee (fee_registration_fee)');
is($d->{fee},5000.00,'Fee extension: domain_check_price single parse fee');
is($d->{phase},'sunrise','Fee extension: domain_check_price single parse phase');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'premium','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),5000,'domain_check get_info (create_price)');
is($dri->get_info('renew_price'),9.95,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),9.95,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),9.95,'domain_check get_info (restore_price) undef');

## domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.space</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.9" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.9 fee-0.9.xsd"><fee:currency>USD</fee:currency><fee:period unit="y">1</fee:period><fee:fee>5.00</fee:fee><fee:balance>-5.00</fee:balance><fee:creditLimit>1000.00</fee:creditLimit></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('exdomain.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.bar'],['ns2.example.bar']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>exdomain.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.bar</domain:hostObj><domain:hostObj>ns2.example.bar</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.9" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.9 fee-0.9.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},5.00,'Fee extension: domain_create parse fee');
is($d->{balance},-5.00,'Fee extension: domain_create parse balance');
is($d->{credit_limit},1000.00,'Fee extension: domain_create parse credit limit');

####################################################################################################
exit 0;
