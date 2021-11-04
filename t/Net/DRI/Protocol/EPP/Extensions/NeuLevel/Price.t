#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 42;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn,$toc);

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('GoDaddy::DNRS');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});

#####################
## Price Extension

# domain check
my $price = { duration=>DateTime::Duration->new(years=>5) };
$R2=$E1.'<response>'.r().'<extension><price:chkData xmlns:price="urn:ar:params:xml:ns:price-1.2"><cd><name>random.menu</name><category>PREMIUM CAT 2</category><period unit="y">5</period><createPrice>500</createPrice><renewPrice>500</renewPrice><transferPrice>50</transferPrice><restorePrice>40</restorePrice></cd></price:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('random.menu',{price => $price});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>random.menu</domain:name></domain:check></check><extension><price:check xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:period unit="y">5</price:period></price:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');
$price = $dri->get_info('price');
is($price->{premium},'1','domain_check get_info price premium');
is($price->{price},500.00,'domain_check get_info price price');
is($price->{create_price},500.00,'domain_check get_info create_price');
is($price->{renew_price},500.00,'domain_check get_info price renewal_price');
is($price->{renewal_price},500.00,'domain_check get_info price renewal_price');
is($price->{transfer_price},50.00,'domain_check get_info price transfer_price');
is($price->{restore_price},40.00,'domain_check get_info price restore_price');
is($price->{category},'PREMIUM CAT 2','domain_check get_info price renewal_price');
isa_ok($price->{duration},'DateTime::Duration','domain_check get_info duration');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),undef,'domain_check get_info (price_currency) undef');
is($dri->get_info('create_price'),500.00,'domain_check get_info (create_price)');
is($dri->get_info('renew_price'),500.00,'domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),50,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),40,'domain_check get_info (restore_price) undef');

# domain_check_price
$R2=$E1.'<response>'.r().'<extension><price:chkData xmlns:price="urn:ar:params:xml:ns:price-1.2"><cd><name>random2.menu</name><category>PREMIUM CAT 3</category><period unit="y">5</period><createPrice>1000</createPrice><renewPrice>1000</renewPrice><transferPrice>50</transferPrice><restorePrice>40</restorePrice></cd></price:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('random2.menu',{duration => 5});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>random2.menu</domain:name></domain:check></check><extension><price:check xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:period unit="y">5</price:period></price:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');

is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
is($dri->get_info('create_price'),1000.00,'domain_check get_info (create_price)');

# domain check multi
$price = { duration=>DateTime::Duration->new(years=>1) };
$R2=$E1.'<response>'.r().'<extension><price:chkData xmlns:price="urn:ar:params:xml:ns:price-1.2"><cd><name>standard.menu</name><category>STANDARD</category><period unit="y">5</period><createPrice>50</createPrice><renewPrice>50</renewPrice><transferPrice>5</transferPrice><restorePrice>40</restorePrice></cd><cd><name>lower.menu</name><category>DISCOUNT CAT 1</category><period unit="y">5</period><createPrice>5</createPrice><renewPrice>5</renewPrice><transferPrice>1</transferPrice><restorePrice>40</restorePrice></cd><cd><name>higher.menu</name><category>PREMIUM CAT 2</category><period unit="y">5</period><createPrice>500</createPrice><renewPrice>500</renewPrice><transferPrice>50</transferPrice><restorePrice>40</restorePrice></cd></price:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('standard.menu','lower.menu','higher.menu',{price => $price});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>standard.menu</domain:name><domain:name>lower.menu</domain:name><domain:name>higher.menu</domain:name></domain:check></check><extension><price:check xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:period unit="y">1</price:period></price:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');

$price = $dri->get_info('price','domain','higher.menu');
SKIP: {
    skip 'TODO FIXME: check multi not working without cache!',6;
is($price->{premium},'1','domain_check get_info price premium');
is($dri->get_info('create_price','domain','lower.menu'),5.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','lower.menu'),1,'domain_check get_info (is_premium)');
is($dri->get_info('create_price','domain','standard.menu'),50.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','standard.menu'),0,'domain_check get_info (is_premium)');
is($dri->get_info('create_price','domain','higher.menu'),500.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','higher.menu'),1,'domain_check get_info (is_premium)');
};
# domain create - # domain renew and domain transfer work exactly the same
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example9.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$price = { 'price' => 100 };
$rc=$dri->domain_create('example9.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},price => $price });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>100</price:price></price:ack></price:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# domain create with plain ack (no price)
$rc=$dri->domain_create('example10.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},price => 1 });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($rc->is_success(),1,'domain_create is_success');

# update (RGP Restore)
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$toc->set('price', 1);
$rc=$dri->domain_update('example11.menu',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example11.menu</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_request +charge');
is($rc->is_success(),1,'domain_update is_success');

# rbp restore with explicit price
$toc->set('price', {price => 100});
$rc=$dri->domain_update('example11.menu',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example11.menu</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>100</price:price></price:ack></price:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_request +charge');
is($rc->is_success(),1,'domain_update is_success');

# transfer request - simple acknowledgement (based on: http://ausregistry.github.io/doc/price-1.2/price-1.2.html#anchor14)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example12.menu</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>RegistrarY</domain:reID><domain:reDate>2013-09-15T10:59:06.0Z</domain:reDate><domain:acID>RegistrarX</domain:acID><domain:acDate>2013-09-20T10:59:06.0Z</domain:acDate><domain:exDate>2017-07-15T10:59:06.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$price = { 'premium' => 1 };
$rc=$dri->domain_transfer_start('example12.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},price => $price });
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example12.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start simple ack build_xml');
is($rc->is_success(),1,'domain_transfer_start simple ack is_success');
is($dri->get_info('action'),'transfer','domain_transfer_start simple ack get_info(action)');

# transfer request - including price information (based on: http://ausregistry.github.io/doc/price-1.2/price-1.2.html#anchor14)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example13.menu</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>RegistrarY</domain:reID><domain:reDate>2013-09-15T10:59:06.0Z</domain:reDate><domain:acID>RegistrarX</domain:acID><domain:acDate>2013-09-20T10:59:06.0Z</domain:acDate><domain:exDate>2017-07-15T10:59:06.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$price = { 'premium' => 1, 'price' => 20 };
$rc=$dri->domain_transfer_start('example13.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},price => $price });
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example13.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>20</price:price></price:ack></price:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start price build_xml');
is($rc->is_success(),1,'domain_transfer_start price is_success');
is($dri->get_info('action'),'transfer','domain_transfer_start price get_info(action)');

exit 0;
