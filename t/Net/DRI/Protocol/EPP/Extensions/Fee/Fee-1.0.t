#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 146;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => undef});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('CentralNic::CentralNic');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv}, {extensions=>['-CentralNic::Fee','Fee']});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2,@fees);

####################################################################################################
## Fee extension version 0.23 https://tools.ietf.org/html/draft-ietf-regext-epp-fees-06
## We use a greeting here to switch the namespace version here to -0.23 testing
$R2=$E1.'<greeting><svID>fee-1.0-server</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-1.0','Fee-1.0 loaded correctly');

####################################################################################################

## The implementation has not changed since 0.21, so see 0.21 test file for all tests.

###################
###### domain_check (single)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">explore-0.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>explore-0.space</fee:objID><fee:command name="create"><fee:period unit="y">2</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">10.00</fee:fee></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

# specify command(s) as an arrayref
$rc=$dri->domain_check('explore-0.space',{fee=>{currency => 'USD',command=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-0.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_...');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist','domain','explore-0.space'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee','domain','explore-0.space')};
is($d->{domain},'explore-0.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},0,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee},10.00,'domain_check get_info(fee)');
is($d->{command}->{create}->{phase},undef,'domain_check get_info(phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check get_info(sub_phase)');
is($d->{command}->{create}->{duration}->years(),'2','domain_check get_info(duration)');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_checkget_info (is_premium) 0');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),10.00,'domain_check get_info (create_price)');



###################
###### These more comprehensive tests were copied from Fee-0.21.t


# for backwards compatibility, action is still accepted
$rc=$dri->domain_check('explore-1.space',{fee=>{currency => 'USD',action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-1.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using action)');

# specify command(s) as an array
$rc=$dri->domain_check('explore-2.space',{fee=>{currency => 'USD',command=>('create')}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-2.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array)');

# specify command(s) as an arrayref
$rc=$dri->domain_check('explore-3.space',{fee=>{currency => 'USD',command=>['create']}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-3.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using ref array)');

# or the complex array of hashes method
$rc=$dri->domain_check('explore-4.space',{fee=>{currency => 'USD',command=>[ {name => 'create', 'phase' => 'sunrise'}, 'renew']}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-4.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create" phase="sunrise"/><fee:command name="renew"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array of hashes with two commands)');

# or the complex array of hashes method, with period...
$rc=$dri->domain_check('explore-5.space',{fee=>{currency => 'USD', command=>[ {name => 'create', duration=>$dri->local_object('duration','years',2)}]}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-5.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"><fee:period unit="y">2</fee:period></fee:command></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array of hashes inclding duration)');

###################
###### domain_check (single)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">explore-c0.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>explore-c0.space</fee:objID><fee:command name="create"><fee:period unit="y">2</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">10.00</fee:fee></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

# specify command(s) as an arrayref
$rc=$dri->domain_check('explore-c0.space',{fee=>{currency => 'USD',command=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-c0.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_...');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist','domain','explore-c0.space'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee','domain','explore-c0.space')};
is($d->{domain},'explore-c0.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},0,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee},10.00,'domain_check get_info(fee)');
is($d->{command}->{create}->{phase},undef,'domain_check get_info(phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check get_info(sub_phase)');
is($d->{command}->{create}->{duration}->years(),'2','domain_check get_info(duration)');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_checkget_info (is_premium) 0');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),10.00,'domain_check get_info (create_price)');

###################
###### domain_check_multi
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">explore.space</domain:name></domain:cd><domain:cd><domain:name avail="1">discover.space</domain:name></domain:cd><domain:cd><domain:name avail="1">colonize.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>explore.space</fee:objID><fee:command name="create"><fee:period unit="y">2</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">10.00</fee:fee></fee:command><fee:command name="renew"><fee:period unit="y">1</fee:period><fee:fee description="Renewal Fee" refundable="1" grace-period="P5D">5.00</fee:fee></fee:command><fee:command name="transfer"><fee:period unit="y">1</fee:period><fee:fee description="Transfer Fee" refundable="1" grace-period="P5D">5.00</fee:fee></fee:command><fee:command name="restore"><fee:fee description="Redemption Fee">5.00</fee:fee></fee:command></fee:cd><fee:cd avail="1"><fee:objID>discover.space</fee:objID><fee:command name="create"><fee:period unit="y">5</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">25.00</fee:fee></fee:command><fee:command name="renew"><fee:period unit="y">1</fee:period><fee:fee description="Renewal Fee" refundable="1" grace-period="P5D">5.00</fee:fee></fee:command><fee:command name="transfer"><fee:period unit="y">1</fee:period><fee:fee description="Transfer Fee" refundable="1" grace-period="P5D">5.00</fee:fee></fee:command><fee:command name="restore"><fee:fee description="Redemption Fee">5.00</fee:fee></fee:command></fee:cd><fee:cd avail="0"><fee:objID>colonize.space</fee:objID><fee:command name="create"><fee:period unit="y">2</fee:period><fee:reason>Only 1 year registration periods are vaild.</fee:reason></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

$dri->cache_clear();
$rc=$dri->domain_check('explore.space','discover.space','colonize.space', {
    fee => {
        currency => 'USD',
        command => [
          {
            name => 'create',
            duration=>$dri->local_object('duration','years',2)
          },
          {
            name => 'renew'
          },
          {
            name => 'transfer'
          },
          {
            name => 'restore'
          }
          ]
        }
      });

is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore.space</domain:name><domain:name>discover.space</domain:name><domain:name>colonize.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"><fee:period unit="y">2</fee:period></fee:command><fee:command name="renew"/><fee:command name="transfer"/><fee:command name="restore"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_...');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist','domain','explore.space'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee','domain','explore.space')};
is($d->{domain},'explore.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},0,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee},10.00,'domain_check multi get_info(create fee)');
is($d->{command}->{create}->{phase},undef,'domain_check multi get_info(create phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check multi get_info(create sub_phase)');
is($d->{command}->{create}->{duration}->years(),'2','domain_check multi get_info(create duration)');
is($d->{command}->{renew}->{fee},5,'domain_check multi get_info(renew fee)');
is($d->{command}->{transfer}->{fee},5,'domain_check multi get_info(renew fee)');
is($d->{command}->{restore}->{fee},5,'domain_check multi get_info(restore fee)');

# using the standardised methods
is($dri->get_info('is_premium','domain','explore.space'),0,'domain_check get_info (is_premium) undef');
is($dri->get_info('price_currency','domain','explore.space'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_duration','domain','explore.space')->years(),2,'domain_check get_info (price_currency)');
is($dri->get_info('create_price','domain','explore.space'),10.00,'domain_check get_info (create_price)');
is($dri->get_info('renew_price','domain','explore.space'),5.00,'domain_check get_info (renew_price)');
is($dri->get_info('transfer_price','domain','explore.space'),5.00,'domain_check get_info (transfer_price)');
is($dri->get_info('restore_price','domain','explore.space'),5.00,'domain_check get_info (restpre_price)');

is($dri->get_info('is_premium','domain','discover.space'),0,'domain_check get_info (is_premium) undef');
is($dri->get_info('price_currency','domain','discover.space'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_duration','domain','discover.space')->years(),5,'domain_check get_info (price_currency)');
is($dri->get_info('create_price','domain','discover.space'),25.00,'domain_check get_info (create_price)');
is($dri->get_info('renew_price','domain','discover.space'),5.00,'domain_check get_info (renew_price)');
is($dri->get_info('transfer_price','domain','discover.space'),5.00,'domain_check get_info (transfer_price)');
is($dri->get_info('restore_price','domain','discover.space'),5.00,'domain_check get_info (restpre_price)');


$d = shift @{$dri->get_info('fee','domain','colonize.space')};
is($d->{domain},'colonize.space','domain_check get_info(domain)');
is($d->{price_avail},0,'domain_check parse fee (price_avail)');
is($d->{reason},'Only 1 year registration periods are vaild.','domain_check parse fee (reason)');

####################################################################################################

###################
###### domain_create

$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>explore.space</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0"><fee:currency>USD</fee:currency><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">5.00</fee:fee><fee:balance>-5.00</fee:balance><fee:creditLimit>1000.00</fee:creditLimit></fee:creData></extension>'.$TRID.'</response>'.$E2;

$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
my  $fee = {currency=>'USD',fee=>'5.00'};
$rc=$dri->domain_create('explore.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.discover.space'],['ns2.discover.space']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>$fee});

is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.discover.space</domain:hostObj><domain:hostObj>ns2.discover.space</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build_xml');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},5.00,'Fee extension: domain_create parse fee');
is($d->{balance},-5.00,'Fee extension: domain_create parse balance');
is($d->{credit_limit},1000.00,'Fee extension: domain_create parse credit limit');

# using the standardised methods
is($dri->get_info('price_currency'),'USD','domain_create get_info (price_currency)');
is($dri->get_info('create_price'),5,'domain_create get_info (create_price)');

###################
###### domain_create with multiple fee elements
$fee = {currency=>'USD',fee=>['5.00', {fee=>'100.00', 'description'=>'Early Access Period'}]};
$rc=$dri->domain_create('explore-more.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.discover.space'],['ns2.discover.space']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>$fee});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-more.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.discover.space</domain:hostObj><domain:hostObj>ns2.discover.space</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee><fee:fee description="Early Access Period">100.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build_xml');

$fee = {currency=>'USD',fee=>[{fee=>'5.00', description=>'create'}, {fee=>'100.00', 'description'=>'Early Access Period'}]};
$rc=$dri->domain_create('explore-more.space',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.discover.space'],['ns2.discover.space']),contact=>$cs,auth=>{pw=>'2fooBAR'},fee=>$fee});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-more.space</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.discover.space</domain:hostObj><domain:hostObj>ns2.discover.space</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee description="create">5.00</fee:fee><fee:fee description="Early Access Period">100.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build_xml');

###################
###### domain_delete

$R2=$E1.'<response>'.r().'<extension><fee:delData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0"><fee:currency>USD</fee:currency><fee:credit description="AGP Credit">-5.00</fee:credit><fee:balance>1005.00</fee:balance></fee:delData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('explore.space');
is($rc->is_success(),1,'domain_delete is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_delete parse currency');
is($d->{credit},-5.00,'Fee extension: domain_delete parse credit');
is($d->{description},'AGP Credit','Fee extension: domain_delete parse credit description');
is($d->{balance},1005.00,'Fee extension: domain_delete parse balance');


###################
###### domain_renew

$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>explore.space</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData><extension><fee:renData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0"><fee:currency>USD</fee:currency><fee:fee refundable="1" grace-period="P5D">5.00</fee:fee><fee:balance>1000.00</fee:balance></fee:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('explore.space',{ current_expiration => DateTime->new(year=>2000,month=>4,day=>3), duration=>DateTime::Duration->new(years=>5), fee=>{currency=>'USD',fee=>'5.00'} });
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore.space</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><fee:renew xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_renew build_xml');
is($rc->is_success(),1,'domain_renew is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_renew parse currency');
is($d->{fee},5.00,'Fee extension: domain_renew parse fee');

# using the standardised methods
is($dri->get_info('price_currency'),'USD','domain_renew get_info (price_currency)');
is($dri->get_info('renew_price'),5,'domain_renew get_info (renew_price)');



###################
###### domain_transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>explore.space</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData><extension><fee:trnData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0"><fee:currency>USD</fee:currency><fee:fee refundable="1" grace-period="P5D">5.00</fee:fee></fee:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('explore.space',{auth => {pw=>'2fooBAR',roid=>"JD1234-REP"},duration=>DateTime::Duration->new(years=>1),fee=>{currency=>'USD',fee=>'5.00'}});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore.space</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><fee:transfer xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_transfer_start build_xml');
is($rc->is_success(),1,'domain_transfer is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');

# using the standardised methods
is($dri->get_info('price_currency'),'USD','domain_transfer get_info (price_currency)');
is($dri->get_info('transfer_price'),5,'domain_transfer get_info (transfer_price)');


###################
###### domain_update

$R2=$E1.'<response>'.r().'<extension><fee:updData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:updData></extension>'.$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('fee',{currency=>'USD',fee=>'5.00'});
$rc=$dri->domain_update('explore.space',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore.space</domain:name><domain:chg><domain:registrant>sh8013</domain:registrant></domain:chg></domain:update></update><extension><fee:update xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_update (restore) build_xml');
is($rc->is_success(),1,'domain_update is is_success');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_transfer parse currency');
is($d->{fee},5.00,'Fee extension: domain_transfer parse fee');

# using the standardised methods
is($dri->get_info('price_currency'),'USD','domain_update (restore) get_info (price_currency)');
is($dri->get_info('restore_price'),5,'domain_update (restore) get_info (restore_price)');



####################################################################################################
###### domain_check (premium domain)
###### This test is syntesized as no example exists in the draft

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">premium-0.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>premium-0.space</fee:objID><fee:command name="create"><fee:period unit="y">1</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">100.00</fee:fee><fee:class>premium</fee:class></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

# specify command(s) as an arrayref
$rc=$dri->domain_check('premium-0.space',{fee=>{currency => 'USD',command=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium-0.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check (premium) build_xml');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'premium-0.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},1,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee},100.00,'domain_check get_info(fee)');
is($d->{command}->{create}->{phase},undef,'domain_check get_info(phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check get_info(sub_phase)');
is($d->{command}->{create}->{duration}->years(),'1','domain_check get_info(duration)');

# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_checkget_info (is_premium) 0');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),100.00,'domain_check get_info (create_price)');

####################################################################################################
###### domain_check with more than 1 fee element (e.g. sunrise)
###### This test is syntesized as no example exists in the draft

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">sunrise.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>sunrise.space</fee:objID><fee:command name="create" phase="sunrise"><fee:period unit="y">1</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">10.00</fee:fee><fee:fee description="Application Fee" refundable="0" applied="immediate">500.00</fee:fee></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

# specify command(s) as an arrayref
$rc=$dri->domain_check('sunrise.space',{fee=>{currency => 'USD',command=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>sunrise.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check (premium) build_xml');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'sunrise.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},0,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee_registration_fee},10.00,'domain_check get_info(fee_registration_fee)');
is($d->{command}->{create}->{fee_application_fee},500.00,'domain_check get_info(fee_application_fee)');
is($d->{command}->{create}->{fee},510.00,'domain_check get_info(fee)'); # fees are added together for the total. this is debateable!
is($d->{command}->{create}->{description},'Registration Fee (Refundable) (Grace=>P5D),Application Fee (Applied=>immediate)','domain_check get_info(description)'); # descriptions melded into a string
is($d->{command}->{create}->{phase},'sunrise','domain_check get_info(phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check get_info(sub_phase)');
is($d->{command}->{create}->{duration}->years(),'1','domain_check get_info(duration)');

# since 0.21, there is a better way of accessing different fee types with more detail
is_deeply(\@{$d->{command}->{create}->{fee_types}},['registration_fee','application_fee'],'domain_check get_info(fee_types)');
is($d->{command}->{create}->{registration_fee}->{description},'Registration Fee','domain_check get_info(registration_fee->description)');
is($d->{command}->{create}->{registration_fee}->{fee},10.00,'domain_check get_info(registration_fee->fee)');
is($d->{command}->{create}->{registration_fee}->{refundable},1,'domain_check get_info(registration_fee->refundable)');
is($d->{command}->{create}->{registration_fee}->{grace_period},'P5D','domain_check get_info(registration_fee->grace_period)');
is($d->{command}->{create}->{application_fee}->{description},'Application Fee','domain_check get_info(application_fee->description)');
is($d->{command}->{create}->{application_fee}->{fee},500.00,'domain_check get_info(application_fee->fee)');
is($d->{command}->{create}->{application_fee}->{applied},'immediate','domain_check get_info(application_fee->applied)');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_checkget_info (is_premium) 0');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),510.00,'domain_check get_info (create_price)');

####################################################################################################
###### domain_check_price
###### This should be more compatible with other registies too

$rc=$dri->domain_check_price('explore-11.space',{'currency' => 'USD', 'phase'=>'sunrise'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-11.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create" phase="sunrise"/><fee:command name="renew"/><fee:command name="transfer"/><fee:command name="restore"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array of hashes with two commands)');

$rc=$dri->domain_check_price('explore-12.space',{'currency' => 'USD', 'phase'=>'custom', 'sub_phase' => 'prebook', 'duration' => 5});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-12.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:currency>USD</fee:currency><fee:command name="create" phase="custom" subphase="prebook"><fee:period unit="y">5</fee:period></fee:command><fee:command name="renew"><fee:period unit="y">5</fee:period></fee:command><fee:command name="transfer"><fee:period unit="y">5</fee:period></fee:command><fee:command name="restore"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array of hashes with two commands)');

$rc=$dri->domain_check_price('explore-13.space');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-13.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-1.0 fee-1.0.xsd"><fee:command name="create"/><fee:command name="renew"/><fee:command name="transfer"/><fee:command name="restore"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build_xml (using array of hashes with two commands)');

exit 0;
