#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 112;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('NGTLD',{provider=>'ARI'});
$dri->target('ARI')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$idn);


#####################
## IDN Extension + Variants Extensions (both use the Net::DRI::Data::IDN Object) : IDNVariant.pm

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><idn:infData xmlns:idn="urn:ar:params:xml:ns:idn-1.0"><idn:languageTag>und-Zyyy</idn:languageTag></idn:infData><variant:infData xmlns:variant="urn:ar:params:xml:ns:variant-1.1"><variant:variant>xn--eqrt2gr10cmna.menu</variant:variant></variant:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.menu');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.menu','domain_info get_info name');
isa_ok($dri->get_info('idn'),'Net::DRI::Data::IDN','domain_get get idn is a idn object');
is($dri->get_info('idn')->iso15924(),'Zyyy','domain_info get_info idn language Tag 15924');
is($dri->get_info('idn')->iso639_2(),'und','domain_info get_info idn language Tag 639_2');
is_deeply($dri->get_info('idn')->variants(),['xn--eqrt2gr10cmna.menu'],'domain_info get_info idn_variants');

# domain create with idn language and variants
$idn = $dri->local_object('idn')->autodetect('example3.art','und-Zyyy');
$idn->variants(['abc.menu','xyz.menu']);
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},idn => $idn });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:create xmlns:idn="urn:ar:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:languageTag>und-Zyyy</idn:languageTag></idn:create><variant:create xmlns:variant="urn:ar:params:xml:ns:variant-1.1" xsi:schemaLocation="urn:ar:params:xml:ns:variant-1.1 variant-1.1.xsd"><variant:variant>abc.menu</variant:variant><variant:variant>xyz.menu</variant:variant></variant:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create idn_variants build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

# domain update with variants
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$idn = $dri->local_object('idn');
$toc->add('idn',$idn->clone()->variants(['ggg.menu']));
$toc->del('idn',$idn->clone()->variants(['abc.menu','xyz.menu']));
$rc=$dri->domain_update('example3.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name></domain:update></update><extension><variant:update xmlns:variant="urn:ar:params:xml:ns:variant-1.1" xsi:schemaLocation="urn:ar:params:xml:ns:variant-1.1 variant-1.1.xsd"><variant:add><variant:variant>ggg.menu</variant:variant></variant:add><variant:rem><variant:variant>abc.menu</variant:variant><variant:variant>xyz.menu</variant:variant></variant:rem></variant:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update variants build_xml');


#####################
## KeyValue Extension

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><kv:infData xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.menu');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example3.menu','domain_info get_info name');
my $kv = $dri->get_info('keyvalue');
is_deeply($kv,{ bn => { 'entityType' => 'Australian Private Company', 'abn' => '18 092 242 209' } },'domain_info get_info keyvalue');

# domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},keyvalue => $kv });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><kv:create xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:kv-1.0 kv-1.0.xsd"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create idn_variants build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

#doman update
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
$toc=$dri->local_object('changes');
$toc->set('keyvalue',$kv);
$rc=$dri->domain_update('example3.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.menu</domain:name></domain:update></update><extension><kv:update xmlns:kv="urn:X-ar:params:xml:ns:kv-1.0" xsi:schemaLocation="urn:X-ar:params:xml:ns:kv-1.0 kv-1.0.xsd"><kv:kvlist name="bn"><kv:item key="abn">18 092 242 209</kv:item><kv:item key="entityType">Australian Private Company</kv:item></kv:kvlist></kv:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update variants build_xml');



#####################
## exAvail Extension

# domain check
$R2=$E1.'<response>'.r().'<extension><exAvail:chkData xmlns:exAvail="urn:ar:params:xml:ns:exAvail-1.0"><exAvail:cd><exAvail:name>example6.menu</exAvail:name><exAvail:state s="application"><exAvail:phase>sunrise</exAvail:phase><exAvail:date>2012-10-20T00:00:00Z</exAvail:date><exAvail:reason>some reason</exAvail:reason><exAvail:primaryDomainName>example.menu</exAvail:primaryDomainName></exAvail:state></exAvail:cd></exAvail:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example6.menu',{ex_avail=>1});
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example6.menu</domain:name></domain:check></check><extension><exAvail:check xmlns:exAvail="urn:ar:params:xml:ns:exAvail-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:exAvail-1.0 exAvail-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check ex_avail build_xml');
is($dri->get_info('action'),'check','domain_check get_info(check)');
is($dri->get_info('name'),'example6.menu','domain_check get_info name');
is($dri->get_info('exist'),'1','domain_check get_info exists');
my $ea = $dri->get_info('ex_avail');
is($ea->{'state'},'application','domain_check get_info ex_avail state');
is($ea->{'phase'},'sunrise','domain_check get_info ex_avail phase');
is($ea->{'reason'},'some reason','domain_check get_info ex_avail reason');
is($ea->{'date'},'2012-10-20T00:00:00','domain_check get_info ex_avail date');
is($ea->{'primary_domain_name'},'example.menu','domain_check get_info ex_avail primary_domain_name');


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
is($price->{premium},'1','domain_check get_info price premium');
is($dri->get_info('create_price','domain','lower.menu'),5.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','lower.menu'),1,'domain_check get_info (is_premium)');
is($dri->get_info('create_price','domain','standard.menu'),50.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','standard.menu'),0,'domain_check get_info (is_premium)');
is($dri->get_info('create_price','domain','higher.menu'),500.00,'domain_check get_info (create_price)');
is($dri->get_info('is_premium','domain','higher.menu'),1,'domain_check get_info (is_premium)');

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

#####################
## TMCHApplication Extension (TMCH + Application = LaunchPhase type system)

my $encoded_mark = <<'EOF';
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNtZDpzaWdu
ZWRNYXJrIHhtbG5zOnNtZD0idXJuOmlldGY6cGFyYW1zOnhtbDpuczpzaWduZWRN
YXJrLTEuMCIgeG1sOmlkPSJzaWduZWRNYXJrIj4KICA8c21kOmlkPjEtMjwvc21k
OmlkPgogIDxzbWQ6aXNzdWVySW5mbyBpc3N1ZXJJRD0iMiI+CiAgICA8c21kOm9y
Zz5FeGFtcGxlIEluYy48L3NtZDpvcmc+CiAgICA8c21kOmVtYWlsPnN1cHBvcnRA
ZXhhbXBsZS50bGQ8L3NtZDplbWFpbD4KICAgIDxzbWQ6dXJsPmh0dHA6Ly93d3cu
ZXhhbXBsZS50bGQ8L3NtZDp1cmw+CiAgICA8c21kOnZvaWNlIHg9IjEyMzQiPisx
LjcwMzU1NTU1NTU8L3NtZDp2b2ljZT4KICA8L3NtZDppc3N1ZXJJbmZvPgogIDxz
bWQ6bm90QmVmb3JlPjIwMDktMDgtMTZUMDk6MDA6MDAuMFo8L3NtZDpub3RCZWZv
cmU+CiAgPHNtZDpub3RBZnRlcj4yMDEwLTA4LTE2VDA5OjAwOjAwLjBaPC9zbWQ6
bm90QWZ0ZXI+CiAgPG1hcms6bWFyayB4bWxuczptYXJrPSJ1cm46aWV0ZjpwYXJh
bXM6eG1sOm5zOm1hcmstMS4wIj4KICAgIDxtYXJrOnRyYWRlbWFyaz4KICAgICAg
PG1hcms6aWQ+MTIzNC0yPC9tYXJrOmlkPgogICAgICA8bWFyazptYXJrTmFtZT5F
eGFtcGxlIE9uZTwvbWFyazptYXJrTmFtZT4KICAgICAgPG1hcms6aG9sZGVyIGVu
dGl0bGVtZW50PSJvd25lciI+CiAgICAgICAgPG1hcms6b3JnPkV4YW1wbGUgSW5j
LjwvbWFyazpvcmc+CiAgICAgICAgPG1hcms6YWRkcj4KICAgICAgICAgIDxtYXJr
OnN0cmVldD4xMjMgRXhhbXBsZSBEci48L21hcms6c3RyZWV0PgogICAgICAgICAg
PG1hcms6c3RyZWV0PlN1aXRlIDEwMDwvbWFyazpzdHJlZXQ+CiAgICAgICAgICA8
bWFyazpjaXR5PlJlc3RvbjwvbWFyazpjaXR5PgogICAgICAgICAgPG1hcms6c3A+
VkE8L21hcms6c3A+CiAgICAgICAgICA8bWFyazpwYz4yMDE5MDwvbWFyazpwYz4K
ICAgICAgICAgIDxtYXJrOmNjPlVTPC9tYXJrOmNjPgogICAgICAgIDwvbWFyazph
ZGRyPgogICAgICA8L21hcms6aG9sZGVyPgogICAgICA8bWFyazpqdXJpc2RpY3Rp
b24+VVM8L21hcms6anVyaXNkaWN0aW9uPgogICAgICA8bWFyazpjbGFzcz4zNTwv
bWFyazpjbGFzcz4KICAgICAgPG1hcms6Y2xhc3M+MzY8L21hcms6Y2xhc3M+CiAg
ICAgIDxtYXJrOmxhYmVsPmV4YW1wbGUtb25lPC9tYXJrOmxhYmVsPgogICAgICA8
bWFyazpsYWJlbD5leGFtcGxlb25lPC9tYXJrOmxhYmVsPgogICAgICA8bWFyazpn
b29kc0FuZFNlcnZpY2VzPkRpcmlnZW5kYXMgZXQgZWl1c21vZGkKICAgICAgICBm
ZWF0dXJpbmcgaW5mcmluZ28gaW4gYWlyZmFyZSBldCBjYXJ0YW0gc2VydmljaWEu
CiAgICAgIDwvbWFyazpnb29kc0FuZFNlcnZpY2VzPiAKICAgICAgPG1hcms6cmVn
TnVtPjIzNDIzNTwvbWFyazpyZWdOdW0+CiAgICAgIDxtYXJrOnJlZ0RhdGU+MjAw
OS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpyZWdEYXRlPgogICAgICA8bWFyazpl
eERhdGU+MjAxNS0wOC0xNlQwOTowMDowMC4wWjwvbWFyazpleERhdGU+CiAgICA8
L21hcms6dHJhZGVtYXJrPgogIDwvbWFyazptYXJrPgogIDxTaWduYXR1cmUgeG1s
bnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPgogICAgPFNp
Z25lZEluZm8+CiAgICAgIDxDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRo
bT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+CiAg
ICAgIDxTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9y
Zy8yMDAxLzA0L3htbGRzaWctbW9yZSNyc2Etc2hhMjU2Ii8+CiAgICAgIDxSZWZl
cmVuY2UgVVJJPSIjc2lnbmVkTWFyayI+CiAgICAgICAgPFRyYW5zZm9ybXM+CiAg
ICAgICAgICA8VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcv
MjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz4KICAgICAgICA8
L1RyYW5zZm9ybXM+CiAgICAgICAgPERpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0
dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIvPgogICAgICAg
IDxEaWdlc3RWYWx1ZT4rSDc3ajNlMVZ4bDM1bk9MdHdLbHdvdFdZSTFaTnIycm1G
ZmlPRnZMM3VjPTwvRGlnZXN0VmFsdWU+CiAgICAgIDwvUmVmZXJlbmNlPgogICAg
PC9TaWduZWRJbmZvPgogICAgPFNpZ25hdHVyZVZhbHVlPlZpYUdaZWxnOU5tL1Bm
SkVONGxGYXRoSnhPL3YxTndJV0hQTjFyZ0Z4a2lsK1lwT08xK1RNa2Y5Ymx1eW1B
ZGcKekpFQWQrTlVuRURZa2swQ2RkTDgxb095cmE1T0F0UHNjeEpGVmt5ZzdBS3U3
SDdwTTArMHZ6bnJWakU5TFE1ZApiMTEwUjFRQnJpcUxIcmpkYzZOSnhHVlhqRXEy
bTE0VXQ0VFdtcWdsTVNWdTluL2lVRVg0SHJDSFBSbE9ra01yCmVwVHk2M21xdWZB
c3JrTk54WllJSnBDL1Y5blZnU1hOVE56Zjg0UVMvTG5GNnhkS25ZTDY3Z0VXa1pU
YnppWWoKNU43RnhnM003OEgrU0NvOEQ4YUJzZFl5VkxZS1ByUC9FUWFQbHh3K2Z4
UFQ2MUl4U0VJVy81UnZ6cjdYalpDNwpybEFoNGdDOU5DazlDMnVyVXlycEVnPT08
L1NpZ25hdHVyZVZhbHVlPgogICAgPEtleUluZm8+CiAgICAgIDxLZXlWYWx1ZT4K
PFJTQUtleVZhbHVlPgo8TW9kdWx1cz4Kby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVU
VlpWVmNNQ292VVZOZy9zd1dpbnVNZ0VXZ1ZRRnJ6MHhBMDRwRWhYQwpGVnY0ZXZi
VXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1cERxYTUxRmxrMFRNYU1r
SVFqczdhVUtDCm1BNFJHNHRUVEdLL0VqUjFpeDgvRDBnSFlWUmxkeTFZUHJNUCtv
dTc1Yk9WbklvcytIaWZyQXRySXY0cUVxd0wKTDRGVFpBVXBhQ2EyQm1nWGZ5MkNT
UlFieEQ1T3IxZ2NTYTN2dXJoNXNQTUNOeHFhWG1JWG1RaXBTK0R1RUJxTQpNOHRs
ZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2TDRHZ0RZcWhKWVdW
NjFEblhneC9KZDZDCld4dnNuREY2c2NzY1F6VVRFbCtoeXc9PQo8L01vZHVsdXM+
CjxFeHBvbmVudD4KQVFBQgo8L0V4cG9uZW50Pgo8L1JTQUtleVZhbHVlPgo8L0tl
eVZhbHVlPgogICAgICA8WDUwOURhdGE+CjxYNTA5Q2VydGlmaWNhdGU+TUlJRVNU
Q0NBekdnQXdJQkFnSUJBakFOQmdrcWhraUc5dzBCQVFzRkFEQmlNUXN3Q1FZRFZR
UUdFd0pWVXpFTApNQWtHQTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJi
bWRsYkdWek1STXdFUVlEVlFRS0V3cEpRMEZPClRpQlVUVU5JTVJzd0dRWURWUVFE
RXhKSlEwRk9UaUJVVFVOSUlGUkZVMVFnUTBFd0hoY05NVE13TWpBNE1EQXcKTURB
d1doY05NVGd3TWpBM01qTTFPVFU1V2pCc01Rc3dDUVlEVlFRR0V3SlZVekVMTUFr
R0ExVUVDQk1DUTBFeApGREFTQmdOVkJBY1RDMHh2Y3lCQmJtZGxiR1Z6TVJjd0ZR
WURWUVFLRXc1V1lXeHBaR0YwYjNJZ1ZFMURTREVoCk1COEdBMVVFQXhNWVZtRnNh
V1JoZEc5eUlGUk5RMGdnVkVWVFZDQkRSVkpVTUlJQklqQU5CZ2txaGtpRzl3MEIK
QVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBby9jd3ZYaGJWWWwwUkRXV3ZveWVacEVU
VlpWVmNNQ292VVZOZy9zdwpXaW51TWdFV2dWUUZyejB4QTA0cEVoWENGVnY0ZXZi
VXBla0o1YnVxVTFnbVF5T3NDS1FsaE9IVGRQanZrQzV1CnBEcWE1MUZsazBUTWFN
a0lRanM3YVVLQ21BNFJHNHRUVEdLL0VqUjFpeDgvRDBnSFlWUmxkeTFZUHJNUCtv
dTcKNWJPVm5Jb3MrSGlmckF0ckl2NHFFcXdMTDRGVFpBVXBhQ2EyQm1nWGZ5MkNT
UlFieEQ1T3IxZ2NTYTN2dXJoNQpzUE1DTnhxYVhtSVhtUWlwUytEdUVCcU1NOHRs
ZGFON1JZb2pVRUtyR1ZzTms1aTl5Mi83c2puMXp5eVVQZjd2Ckw0R2dEWXFoSllX
VjYxRG5YZ3gvSmQ2Q1d4dnNuREY2c2NzY1F6VVRFbCtoeXdJREFRQUJvNEgvTUlI
OE1Bd0cKQTFVZEV3RUIvd1FDTUFBd0hRWURWUjBPQkJZRUZQWkVjSVFjRC9CajJJ
RnovTEVSdW8yQURKdmlNSUdNQmdOVgpIU01FZ1lRd2dZR0FGTzAvN2tFaDNGdUVL
UytRL2tZSGFEL1c2d2lob1dha1pEQmlNUXN3Q1FZRFZRUUdFd0pWClV6RUxNQWtH
QTFVRUNCTUNRMEV4RkRBU0JnTlZCQWNUQzB4dmN5QkJibWRsYkdWek1STXdFUVlE
VlFRS0V3cEoKUTBGT1RpQlVUVU5JTVJzd0dRWURWUVFERXhKSlEwRk9UaUJVVFVO
SUlGUkZVMVFnUTBHQ0FRRXdEZ1lEVlIwUApBUUgvQkFRREFnZUFNQzRHQTFVZEh3
UW5NQ1V3STZBaG9CK0dIV2gwZEhBNkx5OWpjbXd1YVdOaGJtNHViM0puCkwzUnRZ
Mmd1WTNKc01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjJxU3k3dWkrNDNjZWJL
VUt3V1Byeno5eS8KSWtyTWVKR0tqbzQwbis5dWVrYXczREo1RXFpT2YvcVo0cGpC
RCsrb1I2QkpDYjZOUXVRS3dub0F6NWxFNFNzdQp5NStpOTNvVDNIZnlWYzRnTk1J
b0htMVBTMTlsN0RCS3Jid2J6QWVhLzBqS1dWenJ2bVY3VEJmanhEM0FRbzFSCmJV
NWRCcjZJamJkTEZsbk81eDBHMG1yRzd4NU9VUHV1cmloeWlVUnBGRHB3SDhLQUgx
d01jQ3BYR1hGUnRHS2sKd3lkZ3lWWUF0eTdvdGtsL3ozYlprQ1ZUMzRnUHZGNzBz
UjYrUXhVeTh1MEx6RjVBL2JlWWFacHhTWUczMWFtTApBZFhpdFRXRmlwYUlHZWE5
bEVHRk0wTDkrQmc3WHpObjRuVkxYb2t5RUIzYmdTNHNjRzZRem5YMjNGR2s8L1g1
MDlDZXJ0aWZpY2F0ZT4KPC9YNTA5RGF0YT4KICAgIDwvS2V5SW5mbz4KICA8L1Np
Z25hdHVyZT4KPC9zbWQ6c2lnbmVkTWFyaz4K
EOF
chomp $encoded_mark;
$encoded_mark =~ s/^\s+//gs;
$encoded_mark =~ s/\s+$//gs;
#$encoded_mark =~ s/\s+//gs;
#print $encoded_mark;

# domain check (claims check)
my $lp = {type=>'claims'} ;
$R2=$E1.'<response>'.r().'<extension><tmch:chkData xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0"><tmch:cd><tmch:name claim="1">example2.menu</tmch:name><tmch:key>CLAIM_KEY</tmch:key></tmch:cd></tmch:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example2.menu',{lp => $lp});
is ($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.menu</domain:name></domain:check></check><extension><tmch:check xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_check claims build_xml');
my $lpres = $dri->get_info('lp');
is($lpres->{'exist'},1,'domain_check get_info(exist)');
is($lpres->{'type'},'claims','domain_check get_info(type) ');
is($lpres->{'claim_key'},'CLAIM_KEY','domain_check get_info(claim_key) ');

# domain info
$lp = {'application_id'=>'3F2504E0-4F89-11D3-9A0C-0305E82C3301','include_mark'=>'true'};
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><application:infData xmlns:application="urn:ar:params:xml:ns:application-1.0"><application:id>3F2504E0-4F89-11D3-9A0C-0305E82C3301</application:id><application:phase>landrush</application:phase><application:status s="pendingAllocation" /></application:infData><tmch:infData xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0"><tmch:smd>'.$encoded_mark.'</tmch:smd></tmch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example4.menu',{lp => $lp});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example4.menu</domain:name></domain:info></info><extension><application:info xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>3F2504E0-4F89-11D3-9A0C-0305E82C3301</application:id></application:info><tmch:info xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"/></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info lp build_xml');
is($dri->get_info('action'),'info','domain_info lp get_info(action)');
is($dri->get_info('name'),'example4.menu','domain_info lp get_info name');
$lpres = $dri->get_info('lp');
is($lpres->{'phase'},'landrush','domain_info lp get_info(phase) ');
is($lpres->{'application_id'},'3F2504E0-4F89-11D3-9A0C-0305E82C3301','domain_info lp get_info(application_id) ');
is($lpres->{'status'},'pendingAllocation','domain_info lp get_info(launch_status) ');
my @marks = @{$lpres->{'marks'}};
my $m = shift @marks;
is ($m->{mark_name},'Example One','domain_info lp get_info(mark name)');

# domain create

## Application Create
$lp = {phase => 'landrush'};
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>landrush</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>landrush</application:phase></application:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [application phase]');
$lpres = $dri->get_info('lp');
is($lpres->{phase},'landrush','domain_create lp get_info (phase)');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (application_id)');

## Application Allocatate
$lp = {phase => 'landrush','application_id' => 'NEWAPP123'};
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>landrush</application:phase></application:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [application allocate]');

## SUNRISE - unpadded SMD
my $encoded_mark_test = 'ACB123=';
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $encoded_mark_test ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>'.$encoded_mark_test.'</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using unpadded string]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## SUNRISE - padded SMD
$encoded_mark_test = '<smd:encodedSignedMark xmlns:smd="urn:ietf:params:xml:ns:signedMark-1.0">ABC123=</smd:encodedSignedMark>';
$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $encoded_mark_test ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using padded (xml) string]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## SUNRISE - SMD XML::Element
my $po=$dri->{registries}->{ARI}->{profiles}->{p1}->{protocol};
eval { Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark::setup(undef,$po,undef);};
my $parser=XML::LibXML->new();
my ($doc,$root,$rh);
$doc=$parser->parse_string($encoded_mark_test);
$root=$doc->getDocumentElement();

$lp = {phase => 'sunrise','encoded_signed_marks'=>[ $root ] }; # CAREFUL how you build the list, this is *single* encoded signed mark
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>sunrise</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>sunrise</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [encoded_signed_mark validation model - using xml root element]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (sunrise application_id)');

## Claims
$lp = {phase => 'claims', notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>claims</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>claims</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:noticeID>abc123</tmch:noticeID><tmch:notAfter>2008-12-01T00:00:00Z</tmch:notAfter><tmch:accepted>2009-10-01T00:00:00Z</tmch:accepted></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [claims create]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (claims application_id)');

## Mixed (theoretical)
$lp = {phase => 'claims', 'encoded_signed_marks'=>[ $encoded_mark_test ], notices => [ {id=>'abc123','not_after_date'=>DateTime->new({year=>2008,month=>12}),'accepted_date'=>DateTime->new({year=>2009,month=>10}) } ] }; # notices = array of hashes
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example4.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate></domain:creData></resData><extension><application:creData xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>NEWAPP123</application:id><application:phase>claims</application:phase></application:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example4.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},lp=>$lp});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example4.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><application:create xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:phase>claims</application:phase></application:create><tmch:create xmlns:tmch="urn:ar:params:xml:ns:tmch-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:tmch-1.0 tmch-1.0.xsd"><tmch:smd>ABC123=</tmch:smd><tmch:noticeID>abc123</tmch:noticeID><tmch:notAfter>2008-12-01T00:00:00Z</tmch:notAfter><tmch:accepted>2009-10-01T00:00:00Z</tmch:accepted></tmch:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create lp build_xml [mixed create]');
$lpres = $dri->get_info('lp');
is($lpres->{application_id},'NEWAPP123','domain_create lp get_info (mixed application_id)');

# UPDATE
$lp = {phase => 'sunrise','application_id'=>'abc123'};
$R2='';
$toc=$dri->local_object('changes');
$toc->set('lp',$lp);
$rc=$dri->domain_update('example5.menu',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example5.menu</domain:name></domain:update></update><extension><application:update xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>abc123</application:id><application:phase>sunrise</application:phase></application:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update lp build_xml');

# DELETE
$lp = {'application_id'=>'abc123' };
$R2='';
$rc=$dri->domain_delete('example8.menu',{pure_delete=>1,lp=>$lp});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example8.menu</domain:name></domain:delete></delete><extension><application:delete xmlns:application="urn:ar:params:xml:ns:application-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:application-1.0 application-1.0.xsd"><application:id>abc123</application:id></application:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete lp build_xml');


#####################
## Block Extension

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example22.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><infData xmlns="urn:ar:params:xml:ns:block-1.0"><id>BLK-1</id></infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example22.menu',{block_id => 'BLK-1'});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example22.menu</domain:name></domain:info></info><extension><block:info xmlns:block="urn:ar:params:xml:ns:block-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:block-1.0 block-1.0.xsd"><block:id>BLK-1</block:id></block:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info block build_xml');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example22.menu','domain_info get_info name');
is($dri->get_info('block_id'),'BLK-1','domain_info get_info name');

# domain create - # domain renew and domain transfer work exactly the same
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example23.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData><extension><creData xmlns="urn:ar:params:xml:ns:block-1.0"><id>BLK-2</id></creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example23.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},block_id => 'BLK-2'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example23.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><block:create xmlns:block="urn:ar:params:xml:ns:block-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:block-1.0 block-1.0.xsd"><block:id>BLK-2</block:id></block:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('block_id'),'BLK-2','domain_info get_info name');

# domain renew & delete are the same

# migration tests

# domain check
# test .xn--jvr189m TLD
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.xn--jvr189m</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.xn--jvr189m');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.xn--jvr189m</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build (.xn--jvr189m)');
is($rc->is_success(),1,'domain_check is_success (.xn--jvr189m)');
is($dri->get_info('action'),'check','domain_check get_info(action) (.xn--jvr189m)');
is($dri->get_info('exist'),0,'domain_check get_info(exist) (.xn--jvr189m)');
is($dri->get_info('exist','domain','example3.xn--jvr189m'),0,'domain_check get_info(exist) from cache (.xn--jvr189m)');

# domain check
# test .kindle TLD
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.kindle</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.kindle');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.kindle</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build (.kindle)');
is($rc->is_success(),1,'domain_check is_success (.kindle)');
is($dri->get_info('action'),'check','domain_check get_info(action) (.kindle)');
is($dri->get_info('exist'),0,'domain_check get_info(exist) (.kindle)');
is($dri->get_info('exist','domain','example3.kindle'),0,'domain_check get_info(exist) from cache (.kindle)');

exit 0;
