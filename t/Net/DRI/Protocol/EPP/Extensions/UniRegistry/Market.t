#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 100;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::UniRegistry');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$contact);

##########################################
## Market - EPP Query Commands

## market check - with suggestions
$R2=$E1.'<response>'.r().'<resData><market:chkData xmlns:market="http://ns.uniregistry.net/market-1.0" type="domain"><market:cd><market:name bin="1" offer="1" avail="1">example.com</market:name><market:price>10000</market:price></market:cd><market:cd><market:name avail="0">testing.com</market:name><market:suggestion><market:name bin="1" offer="0">retesting.com</market:name><market:price>5000.00</market:price></market:suggestion><market:suggestion><market:name bin="1" offer="1">iqtesting.net</market:name><market:price>5000.00</market:price></market:suggestion><market:suggestion><market:name bin="0" offer="1">hivtesting.ca</market:name><market:price>5000.00</market:price></market:suggestion></market:cd></market:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_check((qw/example.com testing.com/), { 'type_attr'=>'domain', 'suggestions_attr'=>'true'} );
is_string($R1,$E1.'<command><check><market:check xmlns:market="http://ns.uniregistry.net/market-1.0" type="domain" suggestions="true"><market:name>example.com</market:name><market:name>testing.com</market:name></market:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'market_check build');
is($rc->is_success(),1,'market_check multi is_success');
is($dri->get_info('exist','market','example.com'),0,'market_check multi get_info(exist,domain1)');
is($dri->get_info('exist','market','testing.com'),1,'market_check multi get_info(exist,domain2)');
is($dri->get_info('bin','market','example.com'),0,'market_check multi get_info(bin,domain1)');
is($dri->get_info('offer','market','example.com'),0,'market_check multi get_info(offer,domain1)');
is($dri->get_info('price','market','example.com'),10000,'market_check multi get_info(price,domain1)');
my $suggestions=$dri->get_info('suggestion','market','testing.com');
is(@{$suggestions}[0]->{name},'retesting.com','market_check multi get_info(exists,domain2) suggestion1 name');
is(@{$suggestions}[0]->{price},'5000.00','market_check multi get_info(exists,domain2) suggestion1 price');
is(@{$suggestions}[0]->{offer},1,'market_check multi get_info(exists,domain2) suggestion1 offer');
is(@{$suggestions}[0]->{bin},0,'market_check multi get_info(exists,domain2) suggestion1 bin');
is(@{$suggestions}[1]->{name},'iqtesting.net','market_check multi get_info(exists,domain2) suggestion2 name');
is(@{$suggestions}[1]->{price},'5000.00','market_check multi get_info(exists,domain2) suggestion2 price');
is(@{$suggestions}[1]->{offer},0,'market_check multi get_info(exists,domain2) suggestion2 offer');
is(@{$suggestions}[1]->{bin},0,'market_check multi get_info(exists,domain2) suggestion2 bin');
is(@{$suggestions}[2]->{name},'hivtesting.ca','market_check multi get_info(exists,domain2) suggestion3 name');
is(@{$suggestions}[2]->{price},'5000.00','market_check multi get_info(exists,domain2) suggestion3 price');
is(@{$suggestions}[2]->{offer},0,'market_check multi get_info(exists,domain2) suggestion3 offer');
is(@{$suggestions}[2]->{bin},1,'market_check multi get_info(exists,domain2) suggestion3 bin');

## market check - without suggestions
$R2=$E1.'<response>'.r().'<resData><market:chkData xmlns:market="http://ns.uniregistry.net/market-1.0" type="domain"><market:cd><market:name bin="1" offer="1" avail="1">example.com</market:name><market:price>10000</market:price></market:cd><market:cd><market:name avail="0">testing.com</market:name></market:cd></market:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_check(qw/example.com testing.com/);
is_string($R1,$E1.'<command><check><market:check xmlns:market="http://ns.uniregistry.net/market-1.0" type="domain" suggestions="true"><market:name>example.com</market:name><market:name>testing.com</market:name></market:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'market_check build');
is($rc->is_success(),1,'market_check multi is_success');
is($dri->get_info('exist','market','example.com'),0,'market_check multi get_info(exist,domain1)');
is($dri->get_info('exist','market','testing.com'),1,'market_check multi get_info(exist,domain2)');
is($dri->get_info('bin','market','example.com'),0,'market_check multi get_info(bin,domain1)');
is($dri->get_info('offer','market','example.com'),0,'market_check multi get_info(offer,domain1)');
is($dri->get_info('price','market','example.com'),10000,'market_check multi get_info(price,domain1)');

# market info
# response when the order is in status "completed"
$R2=$E1.'<response>'.r().'<resData><market:infData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_885-UR</market:orderID><market:name type="domain">example.game</market:name><market:amount>5000.00</market:amount><market:status>completed</market:status><market:crDate>2015-02-16T14:47:40Z</market:crDate><market:upDate>2015-02-16T14:47:45Z</market:upDate><market:transferInfo><market:pw>p@55w0rD!</market:pw></market:transferInfo></market:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_info('MA_885-UR');
is_string($R1,$E1.'<command><info><market:info xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_885-UR</market:orderID></market:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'market_info build');
is($rc->is_success(),1,'market_info multi is_success');
is($dri->get_info('action'),'info','market_info get_info(action)');
is($dri->get_info('type'),'market','market_info get_info(type)');
is($dri->get_info('order_id'),'MA_885-UR','market_info get_info(orderID)');
is($dri->get_info('name'),'example.game','market_info get_info(name)');
is($dri->get_info('type_attr'),'domain','market_info get_info(type_attr)');
is($dri->get_info('amount'),'5000.00','market_info get_info(amount)');
is($dri->get_info('status'),'completed','market_info get_info(status)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','market_info get_info(crDate)');
is("".$d,'2015-02-16T14:47:40','market_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','market_info get_info(upDate)');
is("".$d,'2015-02-16T14:47:45','market_info get_info(upDate) value');
is_deeply($dri->get_info('transfer_info'),{pw=>'p@55w0rD!'},'market_info get_info(transferInfo pw)');
# response when the order is in status "hold"
$R2=$E1.'<response>'.r().'<resData><market:infData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_885-UR</market:orderID><market:name type="domain">example.game</market:name><market:amount>5000.00</market:amount><market:status>completed</market:status><market:crDate>2015-02-16T14:47:40Z</market:crDate><market:upDate>2015-02-16T14:47:45Z</market:upDate><market:holdExpiryDate>2015-02-23T14:47:45Z</market:holdExpiryDate></market:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_info('MA_885-UR');
$d=$dri->get_info('hold_expiry_date');
isa_ok($d,'DateTime','market_info get_info(holdExpiryDate)');
is("".$d,'2015-02-23T14:47:45','market_info get_info(holdExpiryDate) value');

# market poll response
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="1" id="12"><qDate>2015-02-09T17:31:30.0Z</qDate><msg>Market operation updated.</msg></msgQ><resData><market:infData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_885-UR</market:orderID><market:name type="domain">example.com</market:name><market:amount>5000.00</market:amount><market:status>approved</market:status><market:crDate>2015-02-09T17:31:30Z</market:crDate><market:upDate>2015-02-09T17:31:30Z</market:upDate></market:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12,'message get_info last_id 1');
is($dri->get_info('id','message',12),12,'message get_info id');
is($dri->get_info('content','message', 12), 'Market operation updated.', 'message get_info(content)');
is($dri->get_info('object_id', 'message', 12), 'MA_885-UR', 'message get_info(object_id)');
is($dri->get_info('object_type', 'message', 12), 'market', 'message get_info(object_type)');
is($dri->get_info('order_id','message',12),'MA_885-UR','message get_info(orderID)');
is($dri->get_info('name','message',12),'example.com','message get_info(name)');
is($dri->get_info('type_attr','message',12),'domain','message get_info(type_attr)');
is($dri->get_info('amount','message',12),'5000.00','message get_info(amount)');
is($dri->get_info('status','message',12),'approved','message get_info(status)');
$d=$dri->get_info('crDate','message',12);
isa_ok($d,'DateTime','message get_info(crDate)');
is("".$d,'2015-02-09T17:31:30','message get_info(crDate) value');
$d=$dri->get_info('upDate','message',12);
isa_ok($d,'DateTime','message get_info(upDate)');
is("".$d,'2015-02-09T17:31:30','message get_info(upDate) value');

## END: Market - EPP Query Commands
##########################################


##########################################
## Market - EPP Transform Commands

## market create for an order of type "offer"
$R2=$E1.'<response>'.r().'<resData><market:creData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_6fc-UR</market:orderID><market:name type="domain">example.com</market:name><market:amount>15000.00</market:amount><market:status>received</market:status><market:crDate>2015-02-18T11:49:18Z</market:crDate></market:creData></resData>'.$TRID.'</response>'.$E2;
$contact = { 'fname'=>'John', 'lname'=>'Doe', 'email'=>'jdoe@example.com', 'voice'=>'+1.5552223344' };
$rc=$dri->market_create('example.com', { 'order_type'=>'offer', 'amount'=>15000, 'contact'=>$contact });
is_string($R1,$E1.'<command><create><market:create xmlns:market="http://ns.uniregistry.net/market-1.0" type="offer"><market:name type="domain">example.com</market:name><market:amount>15000</market:amount><market:contact><market:firstName>John</market:firstName><market:lastName>Doe</market:lastName><market:email>jdoe@example.com</market:email><market:phone>+1.5552223344</market:phone></market:contact></market:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'market_create of type "offer" build');
is($rc->is_success(),1,'market_create of type "offer" is_success');
is($dri->get_info('action'),'create','market_create get_info(action)');
is($dri->get_info('type'),'market','market_create get_info(type)');
is($dri->get_info('order_id'),'MA_6fc-UR','market_create get_info(orderID)');
is($dri->get_info('name'),'example.com','market_create get_info(name)');
is($dri->get_info('type_attr'),'domain','market_create get_info(type_attr)');
is($dri->get_info('amount'),'15000.00','market_create get_info(amount)');
is($dri->get_info('status'),'received','market_create get_info(status)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','market_create get_info(crDate)');
is("".$d,'2015-02-18T11:49:18','market_create get_info(crDate) value');

## market create for an order of type "bin"
$R2=$E1.'<response>'.r().'<resData><market:creData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_6fc-UR</market:orderID><market:name type="domain">example.com</market:name><market:amount>20000.00</market:amount><market:status>bin</market:status><market:crDate>2015-02-18T13:54:01Z</market:crDate><market:holdExpiryDate>2015-02-25T13:54:01Z</market:holdExpiryDate></market:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_create('example.com', { 'order_type'=>'bin', 'amount'=>20000 });
is_string($R1,$E1.'<command><create><market:create xmlns:market="http://ns.uniregistry.net/market-1.0" type="bin"><market:name type="domain">example.com</market:name><market:amount>20000</market:amount></market:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'market_create of type "bin" build');
is($rc->is_success(),1,'market_create of type "bin" is_success');
$d=$dri->get_info('hold_expiry_date');
isa_ok($d,'DateTime','market_create get_info(holdExpiryDate)');
is("".$d,'2015-02-25T13:54:01','market_create get_info(holdExpiryDate) value');

## market create for an order of type "hold"
$R2=$E1.'<response>'.r().'<resData><market:creData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>123123123</market:orderID><market:name type="domain">example.com</market:name><market:amount>20000.00</market:amount><market:status>hold</market:status><market:crDate>2015-02-18T13:54:01Z</market:crDate><market:holdExpiryDate>2015-02-25T13:54:01Z</market:holdExpiryDate></market:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_create('example.com', { 'order_type'=>'hold', 'amount'=>20000 });
is_string($R1,$E1.'<command><create><market:create xmlns:market="http://ns.uniregistry.net/market-1.0" type="hold"><market:name type="domain">example.com</market:name><market:amount>20000</market:amount></market:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'market_create of type "hold" build');
is($rc->is_success(),1,'market_create of type "hold" is_success');


## market update - cancel order
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->market_update('MA_382-UR', { 'order'=>'cancel' });
is_string($R1,$E1.'<command><update><market:update xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_382-UR</market:orderID><market:cancel/></market:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'market_update cancel order build');
is($rc->is_success(),1,'market_update cancel order is_success');

## market update - complete order
$R2=$E1.'<response>'.r().'<resData><market:creData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_862-UR</market:orderID><market:name type="domain">example.com</market:name><market:amount>20000.00</market:amount><market:status>completed</market:status><market:crDate>2015-02-18T13:54:01Z</market:crDate><market:upDate>2015-02-18T13:54:02Z</market:upDate><market:transferInfo><market:pw>b4a78783c95d78d</market:pw></market:transferInfo></market:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->market_update('MA_382-UR', { 'order'=>'complete' });
is_string($R1,$E1.'<command><update><market:update xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_382-UR</market:orderID><market:complete/></market:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'market_update complete order build');
is($rc->is_success(),1,'market_update complete order is_success');
is($dri->get_info('order_id'),'MA_862-UR','market_update get_info(orderID)');
is($dri->get_info('name'),'example.com','market_update get_info(name)');
is($dri->get_info('type_attr'),'domain','market_update get_info(type_attr)');
is($dri->get_info('amount'),'20000.00','market_update get_info(amount)');
is($dri->get_info('status'),'completed','market_update get_info(status)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','market_update get_info(crDate)');
is("".$d,'2015-02-18T13:54:01','market_update get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','market_update get_info(upDate)');
is("".$d,'2015-02-18T13:54:02','market_update get_info(upDate) value');
is_deeply($dri->get_info('transfer_info'),{pw=>'b4a78783c95d78d'},'market_update get_info(transferInfo pw)');

# market update - complete acknowledge
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->market_update('MA_382-UR', { 'order'=>'acknowledge' });
is_string($R1,$E1.'<command><update><market:update xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_382-UR</market:orderID><market:acknowledge/></market:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'market_update acknowledge order build');
is($rc->is_success(),1,'market_update acknowledge order is_success');

## END: Market - EPP Transform Commands
##########################################



##########################################
## Market - simple market create test for new UniRegistry::INC DRD
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::INC');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
## market create for an order of type "offer"
$R2=$E1.'<response>'.r().'<resData><market:creData xmlns:market="http://ns.uniregistry.net/market-1.0"><market:orderID>MA_6fc-UR</market:orderID><market:name type="domain">example.com</market:name><market:amount>15000.00</market:amount><market:status>received</market:status><market:crDate>2015-02-18T11:49:18Z</market:crDate></market:creData></resData>'.$TRID.'</response>'.$E2;
$contact = { 'fname'=>'John', 'lname'=>'Doe', 'email'=>'jdoe@example.com', 'voice'=>'+1.5552223344' };
$rc=$dri->market_create('example.com', { 'order_type'=>'offer', 'amount'=>15000, 'contact'=>$contact });
is_string($R1,$E1.'<command><create><market:create xmlns:market="http://ns.uniregistry.net/market-1.0" type="offer"><market:name type="domain">example.com</market:name><market:amount>15000</market:amount><market:contact><market:firstName>John</market:firstName><market:lastName>Doe</market:lastName><market:email>jdoe@example.com</market:email><market:phone>+1.5552223344</market:phone></market:contact></market:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'market_create of type "offer" build');
is($rc->is_success(),1,'market_create of type "offer" is_success');
is($dri->get_info('action'),'create','market_create get_info(action)');
is($dri->get_info('type'),'market','market_create get_info(type)');
is($dri->get_info('order_id'),'MA_6fc-UR','market_create get_info(orderID)');
is($dri->get_info('name'),'example.com','market_create get_info(name)');
is($dri->get_info('type_attr'),'domain','market_create get_info(type_attr)');
is($dri->get_info('amount'),'15000.00','market_create get_info(amount)');
is($dri->get_info('status'),'received','market_create get_info(status)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','market_create get_info(crDate)');
is("".$d,'2015-02-18T11:49:18','market_create get_info(crDate) value');
## END: Market - simple market create test for new UniRegistry::INC DRD
##########################################

exit 0;
