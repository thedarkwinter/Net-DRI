#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 20;
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
$dri->add_registry('NGTLD',{provider => 'NEUSTAR',name=>'best'}); # for testing Fee
$dri->target('best')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->add_registry('NGTLD',{provider => 'NEUSTAR',name=>'nyc'}); # for testing EXTContact
$dri->target('nyc')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my ($fee,$c,$c2,$toc);

################################################################################
## Fee extension
$dri->target('.best');

# domain check
my $price = { duration=>DateTime::Duration->new(years=>5) };
$R2=$E1.'<response>'.r().'<extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>TierName=Tier2 AnnualTierPrice=50</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example9.best',{fee => 1} );
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.best</domain:name></domain:check></check><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>FeeCheck=Y</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');
$fee = $dri->get_info('fee');
is($fee->{tier},'Tier2','domain_check get_info fee tier');
is($fee->{price},'50','domain_check get_info fee price');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'Tier2','domain_check get_info (price_category)');
is($dri->get_info('create_price'),'50','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),'50','domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

# domain check_price
$R2=$E1.'<response>'.r().'<extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>TierName=Tier3 AnnualTierPrice=100</neulevel:unspec></neulevel:extension></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('example10.best');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example10.best</domain:name></domain:check></check><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>FeeCheck=Y</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check price build_xml');
$fee = $dri->get_info('fee');
is($fee->{tier},'Tier3','domain_check get_info fee tier');
is($fee->{price},'100','domain_check get_info fee price');
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'Tier3','domain_check get_info (price_category)');


$fee = { tier => 'Tier3', 'price' => 100 };
# domain create - # domain renew and domain transfer work exactly the same
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example9.best</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example9.best',{pure_create=>1,auth=>{pw=>'2fooBAR'},fee => $fee });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example9.best</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>TierName=Tier3 AnnualTierPrice=100</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($dri->get_info('action'),'create','domain_create get_info(action)');

exit 0;
