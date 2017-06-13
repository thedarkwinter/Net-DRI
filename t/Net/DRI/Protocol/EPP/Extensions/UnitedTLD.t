#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 80;
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
$dri->add_registry('NGTLD',{provider=>'rightside'});
$dri->target('rightside')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$toc,$ch1,$ch2);

### DUE TO SOME COPY+PASTING FROM DIFFERENT DOCS, SOME OF RESPONSES ARE NOT CORRECT DATAWISE (BUT SYNTAX FINE)... SO EG create

## Charge extension
#Check domain
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">premium.actor</domain:name></domain:cd></domain:chkData></resData><extension><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:cd><charge:name>premium.actor</charge:name><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount><charge:amount command="renew">999.9900</charge:amount><charge:amount command="transfer">750.0000</charge:amount><charge:amount command="update" name="restore">1249.9900</charge:amount></charge:set></charge:cd></charge:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check('premium.actor');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info (exist)');
$ch1 = $dri->get_info('charge')->[0];
is($ch1->{type},'price','domain_check get_info (charge type)');
is($ch1->{category},'premium','domain_check get_info (charge category)');
is($ch1->{category_name},'Price Category A','domain_check get_info (charge category name)');
is($ch1->{create},'999.9900','domain_check get_info (charge create)');
is($ch1->{transfer},'750.0000','domain_check get_info (charge transfer)');
is($ch1->{renew},'999.9900','domain_check get_info (charge renew)');
is($ch1->{restore},'1249.9900','domain_check get_info (charge restore)');
# using the standardised methods
is($dri->get_info('is_premium'),1,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('price_category'),'Price Category A','domain_check get_info (price_category)');
is($dri->get_info('create_price'),'999.9900','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),'999.9900','domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),'750.0000','domain_check get_info (transfer_price)');
is($dri->get_info('restore_price'),'1249.9900','domain_check get_info (restore_price)');

#Check not premium
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">standard.actor</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check('standard.actor');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info (exist)');
is($dri->get_info('charge'),undef,'domain get_info (charge) undef');
is($dri->get_info('is_premium'),undef,'domain_check get_info (is_premium) undef');

# Check multi
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">85014aaaa.actor</domain:name></domain:cd><domain:cd><domain:name avail="1">85014bbbb.actor</domain:name></domain:cd><domain:cd><domain:name avail="1">85014cccc.actor</domain:name></domain:cd></domain:chkData></resData><extension><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:cd><charge:name>85014aaaa.actor</charge:name><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:cd><charge:cd><charge:name>85014bbbb.actor</charge:name><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:cd><charge:cd><charge:name>85014cccc.actor</charge:name><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:cd></charge:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check('85014aaaa.actor','85014bbbb.actor','85014cccc.actor');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('action'),'check','domain_check multi get_info (action)');
is($dri->get_info('exist','domain','85014aaaa.actor'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','85014bbbb.actor'),0,'domain_check multi get_info(exist) 2/3');
is($dri->get_info('exist','domain','85014cccc.actor'),0,'domain_check multi get_info(exist) 3/3');
$ch2 = $dri->get_info('charge','domain','85014bbbb.actor')->[0];
is($ch2->{create},'20.0000','domain_check multi get_info (charge create)');
# using the standardised methods
is($dri->get_info('is_premium','domain','85014bbbb.actor'),1,'domain_check get_info (is_premium)');
is($dri->get_info('create_price','domain','85014bbbb.actor'),'20.0000','domain_check get_info (create_price)');

# Info domain
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>85014aaaa.actor</domain:name><domain:roid>23e82a3f0a614691b9e53d3d0156fe05-D</domain:roid><domain:status s="ok" /><domain:registrant>sh1890</domain:registrant><domain:contact type="admin">sh1890</domain:contact><domain:contact type="tech">sh1890</domain:contact><domain:clID>Registrar100</domain:clID><domain:crID>Registrar100</domain:crID><domain:crDate>2013-10-11T20:26:55.893Z</domain:crDate><domain:upID>Registrar100</domain:upID><domain:upDate>2013-10-11T20:26:56.35Z</domain:upDate><domain:exDate>2014-10-11T20:26:55.893Z</domain:exDate><domain:authInfo><domain:pw>2foo%BAR</domain:pw></domain:authInfo></domain:infData></resData><extension><charge:infData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:infData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_info('85014aaaa.actor');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{renew},'20.0000','domain_info get_info (charge renew)');

# Create domain - using $ch from domain_check
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:crDate>2013-10-16T16:52:24.013Z</domain:crDate><domain:exDate>2014-10-16T16:52:24.013Z</domain:exDate></domain:creData></resData><extension><charge:creData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount><charge:amount command="renew">999.9900</charge:amount><charge:amount command="transfer">750.0000</charge:amount><charge:amount command="update" name="restore">1249.9900</charge:amount></charge:set></charge:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('premium.actor',{pure_create=>1,auth=>{pw=>'2fooBAR'},'charge' => $ch1});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{create},'999.9900','domain_create get_info (charge create)');

# Update (RGP Restore)
$R2=$E1.'<response>'.r().'<extension><rgp:upData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:rgpStatus s="pendingRestore" /></rgp:upData><charge:upData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:upData></extension>'.$TRID.'</response>'.$E2;
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$toc->set('charge',$ch1);
$rc=$dri->domain_update('premium.actor',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="update" name="restore">1249.9900</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_request +charge');
is($rc->is_success(),1,'domain_update is_success');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{restore},'20.0000','domain_update get_info (charge restore)');

# Transfer
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID></domain:trnData></resData><extension><charge:trnData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:trnData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('premium.actor',{auth=>{pw=>'2fooBAR'},charge=>$ch1});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="transfer">750.0000</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer build');
is($rc->is_success(),1,'domain_transfer is_success');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{transfer},'20.0000','domain_transfer get_info (charge transfer)');

# Renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:exDate>2015-10-11T20:26:55.893Z</domain:exDate></domain:renData></resData><extension><charge:renData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="AAAA">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">20.0000</charge:amount><charge:amount command="renew">20.0000</charge:amount><charge:amount command="transfer">20.0000</charge:amount><charge:amount command="update" name="restore">20.0000</charge:amount></charge:set></charge:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('premium.actor',{charge=>$ch1,duration => DateTime::Duration->new(years=>5), current_expiration => DateTime->new(year=>2000,month=>4,day=>3)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><extension><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="renew">999.9900</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($rc->is_success(),1,'domain_transfer is_success');
$ch2 = $dri->get_info('charge')->[0];
is($ch2->{renew},'20.0000','domain_renew get_info (charge renew)');


# Check with multiple charge:sets
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">premium.actor</domain:name></domain:cd></domain:chkData></resData><extension><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:cd><charge:name>premium.actor</charge:name><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount><charge:amount command="renew">999.9900</charge:amount><charge:amount command="transfer">750.0000</charge:amount><charge:amount command="update" name="restore">1249.9900</charge:amount></charge:set><charge:set><charge:category>earlyAccess</charge:category><charge:type>fee</charge:type><charge:amount command="create">10000</charge:amount></charge:set></charge:cd></charge:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check('premium.actor');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info (exist)');
($ch1,$ch2) = @{$dri->get_info('charge')};
is($ch1->{type},'price','domain_check get_info (ch1 charge type)');
is($ch2->{type},'fee','domain_check get_info (ch2 charge type)');
is($ch2->{category},'earlyAccess','domain_check get_info (ch2 charge category)');
is($dri->get_info('eap_price'),10000.00,'domain_check get_info (eap_price)');

# Create with multiple charge:sets
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:crDate>2013-10-16T16:52:24.013Z</domain:crDate><domain:exDate>2014-10-16T16:52:24.013Z</domain:exDate></domain:creData></resData><extension><charge:creData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount><charge:amount command="renew">999.9900</charge:amount><charge:amount command="transfer">750.0000</charge:amount><charge:amount command="update" name="restore">1249.9900</charge:amount></charge:set><charge:set><charge:category>earlyAccess</charge:category><charge:type>fee</charge:type><charge:amount command="create">10000</charge:amount></charge:set></charge:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('premium.actor',{pure_create=>1,auth=>{pw=>'2fooBAR'},'charge' => [$ch1,$ch2]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.actor</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><charge:agreement xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/charge-1.0 charge-1.0.xsd"><charge:set><charge:category name="Price Category A">premium</charge:category><charge:type>price</charge:type><charge:amount command="create">999.9900</charge:amount></charge:set><charge:set><charge:category>earlyAccess</charge:category><charge:type>fee</charge:type><charge:amount command="create">10000</charge:amount></charge:set></charge:agreement></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
($ch1,$ch2) = @{$dri->get_info('charge')};
is($ch1->{create},'999.9900','domain_create get_info (charge premium create)');
is($ch2->{create},'10000','domain_create get_info (charge earlyAccess create)');


## Finance Extension
$R2=$E1.'<response>'.r().'<resData><finance:infData xmlns:finance="http://www.unitedtld.com/epp/finance-1.0"><finance:balance>200000.00</finance:balance><finance:threshold type="final">0.00</finance:threshold><finance:threshold type="restricted">500.00</finance:threshold><finance:threshold type="notification">1000.00</finance:threshold></finance:infData></resData>'.$TRID.'</response>'.$E2;
$rc = $dri->registrar_balance();
is($R1,$E1.'<command><info><finance:info xmlns:finance="http://www.unitedtld.com/epp/finance-1.0" xsi:schemaLocation="http://www.unitedtld.com/epp/finance-1.0 finance-1.0.xsd"/></info><clTRID>ABC-12345</clTRID></command>'.$E2,'registrar_balance build_xml');
is($dri->get_info('balance'),'200000.00','registrar_balance get_info (balance)');
is($dri->get_info('final'),'0.00','registrar_balance get_info (final)');
is($dri->get_info('restricted'),'500.00','registrar_balance get_info (restricted)');
is($dri->get_info('notification'),'1000.00','registrar_balance get_info (notification)');

##########################
#Check 'standard' category (zacr)
$dri->add_registry('NGTLD',{provider=>'zacr',name=>'africa'});
$dri->target('africa')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><domain:cd><domain:name avail="1">test123.africa</domain:name></domain:cd></domain:chkData></resData><extension><launch:chkData xmlns:launch="urn:ietf:params:xml:ns:launch-1.0" xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><launch:phase>claims</launch:phase><launch:cd><launch:name exists="0">test123.africa</launch:name></launch:cd></launch:chkData><charge:chkData xmlns:charge="http://www.unitedtld.com/epp/charge-1.0" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xmlns:launch="urn:ietf:params:xml:ns:launch-1.0"><charge:cd><charge:name>test123.africa</charge:name><charge:set><charge:category>standard</charge:category><charge:type>price</charge:type><charge:amount command="transfer">12.5000</charge:amount><charge:amount command="create">150.0000</charge:amount><charge:amount command="renew">12.5000</charge:amount><charge:amount command="update" name="restore">12.5000</charge:amount></charge:set></charge:cd></charge:chkData></extension>'.$TRID.'</response>'.$E2;
$rc = $dri->domain_check('test123.africa');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist'),0,'domain_check get_info (exist)');
$ch1 = $dri->get_info('charge')->[0];
is($ch1->{type},'price','domain_check get_info (charge type)');
is($ch1->{category},'standard','domain_check get_info (charge category)');
is($ch1->{create},'150.0000','domain_check get_info (charge create)');
is($ch1->{transfer},'12.5000','domain_check get_info (charge transfer)');
is($ch1->{renew},'12.5000','domain_check get_info (charge renew)');
is($ch1->{restore},'12.5000','domain_check get_info (charge restore)');
# using the standardised methods
is($dri->get_info('is_premium'),undef,'domain_check get_info (is_premium)');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'150.0000','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),'12.5000','domain_check get_info (renew_price)');
is($dri->get_info('transfer_price'),'12.5000','domain_check get_info (transfer_price)');
is($dri->get_info('restore_price'),'12.5000','domain_check get_info (restore_price)');

exit 0;
