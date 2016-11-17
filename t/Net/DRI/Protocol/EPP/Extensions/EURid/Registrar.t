#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 145;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s);

########################################################################################################

## Process greetings to select namespace versions
# We need secDNS and domain-ext to select correct versions in the test file
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2016-11-17T14:30:12.230Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarFinance-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarHitPoints-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrationLimit-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.0</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.1</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dnsQuality-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/homoglyph-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'registrar_finance'}->[0],'http://www.eurid.eu/xml/epp/registrarFinance-1.0','registrarFinance-1.0 for server announcing 1.0');
is($dri->protocol()->ns()->{'registrar_hit_points'}->[0],'http://www.eurid.eu/xml/epp/registrarHitPoints-1.0','registrarHitPoints-1.0 for server announcing 1.0');
is($dri->protocol()->ns()->{'registration_limit'}->[0],'http://www.eurid.eu/xml/epp/registrationLimit-1.0','registrationLimit-1.0 for server announcing 1.0');

########################################################################################################
### Registrar Finance Info
### Finance is default "type", so you can specify or not...

# Response for prepayment registrar
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><registrarFinance:infData xmlns:registrarFinance="http://www.eurid.eu/xml/epp/registrarFinance-1.0"><registrarFinance:paymentMode>PRE_PAYMENT</registrarFinance:paymentMode><registrarFinance:availableAmount>10000.00</registrarFinance:availableAmount><registrarFinance:accountBalance>0.00</registrarFinance:accountBalance></registrarFinance:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info();
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><registrar:finance xmlns:registrar="http://www.eurid.eu/xml/epp/registrarFinance-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrarFinance-1.0 registrarFinance-1.0"/></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info finance (default) build');
is($dri->get_info('action'),'info','registrar_info get_info(action)');
is($dri->get_info('payment_mode'),'PRE_PAYMENT','registrar_info get_info(payment_mode)');
is($dri->get_info('amount_available'),10000.00,'registrar_info get_info(amount_available)');
is($dri->get_info('account_balance'),0.00,'registrar_info get_info(account_balance)');

# Response for post-payment registrar
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><registrarFinance:infData xmlns:registrarFinance="http://www.eurid.eu/xml/epp/registrarFinance-1.0"><registrarFinance:paymentMode>PRE_PAYMENT</registrarFinance:paymentMode><registrarFinance:availableAmount>10000.00</registrarFinance:availableAmount><registrarFinance:accountBalance>0.00</registrarFinance:accountBalance></registrarFinance:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info({type => 'finance'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><registrar:finance xmlns:registrar="http://www.eurid.eu/xml/epp/registrarFinance-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrarFinance-1.0 registrarFinance-1.0"/></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info finance build');
is($dri->get_info('action'),'info','registrar_info get_info(action)');
is($dri->get_info('payment_mode'),'POST_PAYMENT','registrar_info get_info(payment_mode)');
is($dri->get_info('amount_available'),undef,'registrar_info get_info(amount_available - undef)');
is($dri->get_info('account_balance'),0.00,'registrar_info get_info(account_balance)');
is($dri->get_info('due_amount'),0.00,'registrar_info get_info(due_amount)');
is($dri->get_info('overdue_amount'),0.00,'registrar_info get_info(overdue_amount)');


### Registrar Hit Points Info
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><registrar:hitPoints xmlns:registrar="http://www.eurid.eu/xml/epp/registrarHitPoints-1.0"><registrar:nbrHitPoints>8</registrar:nbrHitPoints><registrar:maxNbrHitPoints>5000</registrar:maxNbrHitPoints><registrar:blockedUntil>2016-10-31T22:59:59.999Z</registrar:blockedUntil></registrar:hitPoints></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info({type => 'hit_points'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><registrar:hitPoints xmlns:registrar="http://www.eurid.eu/xml/epp/registrarHitPoints-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrarHitPoints-1.0 registrarHitPoints-1.0"/></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info hit_points build');
is($dri->get_info('action'),'info','registrar_info hit_points get_info(action)');
$s=$rc->get_data('hitpoints');
isa_ok($s,'HASH','registrar_info get_data(hitpoints)');
is($s->{current_number},2,'registrar_info get_data(hitpoints) current_number');
is($s->{maximum_number},5000,'registrar_info get_data(hitpoints) maximum_number');
isa_ok($s->{blocked_until},'DateTime','registrar_info get_data(hitpoints) blocked_until isa DateTime');
is(''.$s->{blocked_until},'2015-09-20T00:00:00','registrar_info get_data(hitpoints) blocked_until value');

### Registrar Registration Limit Info
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><registrar:registrationLimit xmlns:registrar="http://www.eurid.eu/xml/epp/registrationLimit-1.0"><registrar:monthlyRegistrations>58</registrar:monthlyRegistrations><registrar:maxMonthlyRegistrations>69</registrar:maxMonthlyRegistrations><registrar:limitedUntil>2017-11-30T21:59:59.999Z</registrar:limitedUntil></registrar:registrationLimit></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info({type => 'registration_limit'});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><registrar:registrationLimit xmlns:registrar="http://www.eurid.eu/xml/epp/registrationLimit-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrationLimit-1.0 registrationLimit-1.0"/></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info registration_limit build');
$s=$rc->get_data('registration_limit');
isa_ok($s,'HASH','registrar_info get_data(registration_limit)');
is($s->{monthly_registrations},58,'registrar_info get_data(registration_limit) monthly_registrations');
is($s->{max_monthly_registrations},69,'registrar_info get_data(registration_limit) max_monthly_registrations');
isa_ok($s->{limited_until},'DateTime','registrar_info get_data(registration_limit) limited_until isa DateTime');
is(''.$s->{blocked_until},'2015-09-20T00:00:00','registrar_info get_data(registration_limit) limited_until value');

exit 0;
