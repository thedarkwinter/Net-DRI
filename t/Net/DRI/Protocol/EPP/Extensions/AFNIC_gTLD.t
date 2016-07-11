#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 23;
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
$dri->add_registry('NGTLD',{provider => 'afnic',name=>'paris'} );
$dri->target('paris')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
#$dri->add_registry('AFNIC_GTLD');
#$dri->target('AFNIC_GTLD')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);


##################### 
## Notifications

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Application switches to "allocated" state</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'123','message_retrieve get_info(last_id)');
my  $lp = $dri->get_info('lp','message',123);
is($lp->{'status'},'allocated','message_retrieve get_info lp->{status}');

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="3" id="124"><qDate>2015-10-05T10:03:13.0Z</qDate><msg>Application switches to "invalid" state</msg></msgQ><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>foobar.paris</domain:name><domain:roid>DOM000000271999-PARIS</domain:roid><domain:status s="pendingCreate"/><domain:status s="serverRenewProhibited"/><domain:status s="serverTransferProhibited"/><domain:status s="serverUpdateProhibited"/><domain:registrant>TEST</domain:registrant><domain:contact type="admin">A101</domain:contact><domain:contact type="tech">T101</domain:contact><domain:contact type="billing">B101</domain:contact><domain:clID>IANAXXX</domain:clID><domain:crID>IANAXXX</domain:crID><domain:crDate>2015-10-02T17:44:25Z</domain:crDate><domain:exDate>2017-10-02T17:44:25Z</domain:exDate><domain:upID>IANAXXXX</domain:upID><domain:upDate>2015-10-02T17:44:25Z</domain:upDate><domain:authInfo>fooBAR2</domain:authInfo></domain:infData></resData><extension><launch:infData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><launch:phase>sunrise</launch:phase><launch:applicationID>PARISS20151002194424SITYPYCY92499435</launch:applicationID><launch:status s="invalid"/></launch:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'124','message_retrieve get_info(last_id)');
$lp = $dri->get_info('lp','message',124);
is($lp->{'status'},'invalid','message_retrieve get_info lp->{status}');
is($dri->get_info('name','message',124),'foobar.paris','message_retrieve get info name');
is($dri->get_info('object_type','message',124),'domain','message_retrieve get info object_type');
is($dri->get_info('object_id','message',124),'foobar.paris','message_retrieve get info object_id');

##################### 
## PremiumDomain

## Old format (?)
my $price = { duration=>DateTime::Duration->new(years=>5) };
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">hotel.paris</domain:name><domain:reason>PremiumParis1 - Reserve Auction Price: 2500 Create: 29 Tranfer:2500 Renew:2500</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
# domain_check has the same result since you don't need to trigger price_check
$rc=$dri->domain_check_price('hotel.paris');
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'EUR','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'PremiumParis1','domain_check get_info (price_category)');
is($dri->get_info('create_price'),'2500','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),2500,'domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),2500,'domain_check get_info (transfer_price)');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

## New format (?)
$price = { duration=>DateTime::Duration->new(years=>5) };
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">shop.paris</domain:name><domain:reason>PremiumParis1 - Annual Fee - Create:2500 Tranfer:2500 Renew:2500</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
# domain_check has the same result since you don't need to trigger price_check
$rc=$dri->domain_check_price('shop.paris');
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'EUR','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'PremiumParis1','domain_check get_info (price_category)');
is($dri->get_info('create_price'),'2500','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),2500,'domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),2500,'domain_check get_info (transfer_price)');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

exit 0;