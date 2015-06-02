#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 59;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
	my ($transport, $count, $msg) = @_;
	$R1 = $msg->as_string();
	return 1;
}

our $R2;
sub myrecv
{
	return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1 .
		'<response>' . r() . $TRID . '</response>' . $E2);
}

my $dri;
my $ok=eval {
	$dri = Net::DRI->new({cache_ttl => 10});
	1;
};
print $@->as_string() if ! $ok;
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('PRO');
$ok=eval {
	$dri->target('PRO')->add_current_profile('p1',
		'epp',
		{
			f_send=> \&mysend,
			f_recv=> \&myrecv
		});
	1;
};
print $@->as_string() if ! $ok;


my $rc;
my $s;
my $d;
my ($dh,@c);

############################################################################
## Create a domain
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

my $cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('testcontact1'), 'tech');
$cs->add($dri->local_object('contact')->srid('testcontact2'), 'admin');
$cs->add($dri->local_object('contact')->srid('testcontact3'), 'registrant');

$ok=eval {
	$rc = $dri->domain_create('wirzenius.law.pro', {
                pure_create => 1,
		ns => $dri->local_object('hosts')->add('ns1.test.pro')->
			add('ns2.test.pro'),
		duration =>	new DateTime::Duration(years => 4),
		contact =>	$cs,
		pro =>		{
			type =>	'Resolving',
			auth => {
				pw =>	'FAKETEXT',
				roid =>	'RPRODEF-SAMPLE-1'
			}
		},
		auth =>		{ pw => 'testTest' }
	});
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'domain create');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>wirzenius.law.pro</domain:name><domain:period unit="y">4</domain:period><domain:ns><domain:hostObj>ns1.test.pro</domain:hostObj><domain:hostObj>ns2.test.pro</domain:hostObj></domain:ns><domain:registrant>testcontact3</domain:registrant><domain:contact type="admin">testcontact2</domain:contact><domain:contact type="tech">testcontact1</domain:contact><domain:authInfo><domain:pw>testTest</domain:pw></domain:authInfo></domain:create></create><extension><rpro:proDomain xmlns:rpro="http://registrypro.pro/2003/epp/1/rpro-epp-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/rpro-epp-2.0 rpro-epp-2.0.xsd"><rpro:registrationType>Resolving</rpro:registrationType><rpro:authorization roid="RPRODEF-SAMPLE-1">FAKETEXT</rpro:authorization></rpro:proDomain></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain create xml');

$ok=eval {
	$rc = $dri->domain_create('bucerius.law.pro', {
                pure_create => 1,
		ns => $dri->local_object('hosts')->add('ns1.test.pro')->
			add('ns2.test.pro'),
		duration =>	new DateTime::Duration(years => 4),
		contact =>	$cs,
		pro =>		{
			type =>	'Resolving',
			auth => {
				pw =>	'FAKETEXT',
				roid =>	'RPRODEF-SAMPLE-1'
			},
			activate => 1
	},
		auth =>		{ pw => 'testTest' }
	});
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'domain activate');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>bucerius.law.pro</domain:name><domain:period unit="y">4</domain:period><domain:ns><domain:hostObj>ns1.test.pro</domain:hostObj><domain:hostObj>ns2.test.pro</domain:hostObj></domain:ns><domain:registrant>testcontact3</domain:registrant><domain:contact type="admin">testcontact2</domain:contact><domain:contact type="tech">testcontact1</domain:contact><domain:authInfo><domain:pw>testTest</domain:pw></domain:authInfo></domain:create></create><extension><rpro:proDomain xmlns:rpro="http://registrypro.pro/2003/epp/1/rpro-epp-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/rpro-epp-2.0 rpro-epp-2.0.xsd"><rpro:registrationType activate="y">Resolving</rpro:registrationType><rpro:authorization roid="RPRODEF-SAMPLE-1">FAKETEXT</rpro:authorization></rpro:proDomain></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain activate xml');

## Update a domain
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

my $todo = $dri->local_object('changes');
$todo->set('pro', +{ redirect => 'localhost.localnet' });

$ok=eval {
	$rc = $dri->domain_update('localhost.eng.pro', $todo);
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'domain update');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>localhost.eng.pro</domain:name></domain:update></update><extension><rpro:proDomain xmlns:rpro="http://registrypro.pro/2003/epp/1/rpro-epp-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/rpro-epp-2.0 rpro-epp-2.0.xsd"><rpro:redirectTarget>localhost.localnet</rpro:redirectTarget></rpro:proDomain></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain update xml');

## Query a domain
$R2 = $E1 . '<response>' . r(1000,'Command completed successfully') .
	'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>cocaine.cpa.pro</domain:name><domain:roid>DM1234-PRO</domain:roid><domain:status s="ok"/><domain:registrant>jordynbuchanan</domain:registrant><domain:contact type="admin">jordynbuchanan</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:host>ns1.cocaine.cpa.pro</domain:host><domain:ns><domain:hostObj>ns1.test.pro</domain:hostObj><domain:hostObj>ns2.test.pro</domain:hostObj></domain:ns><domain:host>ns2.cocaine.cpa.pro</domain:host><domain:clID>RegistrarX</domain:clID><domain:crID>RegistrarY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>RegistrarX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>testTest</domain:pw></domain:authInfo></domain:infData></resData><extension><rpro:proDomain xmlns:rpro="http://registrypro.pro/2003/epp/1/rpro-epp-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/rpro-epp-2.0 rpro-epp-2.0.xsd"><rpro:registrationType>PremiumIPDefensive</rpro:registrationType><rpro:tradeMark><rpro:tradeMarkName>Coke</rpro:tradeMarkName><rpro:tradeMarkJurisdiction>US</rpro:tradeMarkJurisdiction><rpro:tradeMarkDate>1991-12-11</rpro:tradeMarkDate><rpro:tradeMarkNumber>349876</rpro:tradeMarkNumber></rpro:tradeMark></rpro:proDomain></extension>' .
	$TRID . '</response>' . $E2;
$ok=eval {
	$rc = $dri->domain_info('cocaine.cpa.pro');
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'domain query is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">cocaine.cpa.pro</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'domain query xml');

my $pro = $dri->get_info('pro', 'domain', 'cocaine.cpa.pro');
isa_ok($pro, 'HASH');
is($dri->get_info('name', 'domain', 'cocaine.cpa.pro'), 'cocaine.cpa.pro',
	'domain query name');
is($pro->{type}, 'PremiumIPDefensive', 'domain query type');
is($pro->{tmname}, 'Coke', 'domain query trademark name');
is($pro->{tmjurisdiction}, 'US', 'domain query trademark jurisdiction');
is($pro->{tmdate}->ymd, '1991-12-11', 'domain query trademark date');
is($pro->{tmnumber}, '349876', 'domain query trademark number');
is($pro->{redirect}, undef, 'domain query redirect');

############################################################################
## Check for existence of A/V contacts
$R2 = $E1 . '<response>' . r(1000,'Command completed successfully') .
	'<resData><av:chkData xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:cd><av:id avail="1">sh8013</av:id></av:cd><av:cd><av:id avail="0">sah8013</av:id><av:reason>In use</av:reason></av:cd><av:cd><av:id avail="1">8013sah</av:id></av:cd></av:chkData></resData>' .
	$TRID . '</response>' . $E2;

$ok=eval {
        $rc=$dri->av_check(['sh8013', 'sah8013', '8013sah']);
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'a/v check is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><av:check xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:id>sh8013</av:id><av:id>sah8013</av:id><av:id>8013sah</av:id></av:check></check><clTRID>ABC-12345</clTRID></command></epp>', 'a/v check xml');

is($dri->get_info('exist', 'av', 'sh8013'), 0, 'av exist sh8013');
is($dri->get_info('exist', 'av', 'sah8013'), 1, 'av exist sah8013');
is($dri->get_info('exist_reason', 'av', 'sah8013'), 'In use',
	'av exist_reason sah8013');
is($dri->get_info('exist', 'av', '8013sah'), 0, 'av exist 8013sah');

## Create an A/V contact
$R2 = $E1 . '<response>' . r(1000,'Command completed successfully') .
	'<resData><av:creData xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:id>sh8013</av:id><av:roid>SH8013-REP</av:roid><av:CrDate>1999-04-03T22:00:00.0Z</av:CrDate><av:avURL>https://avhost.registrypro.pro/index.jsp?id=sh8013</av:avURL></av:creData></resData>' .
	$TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->av_create('sh8013', +{
		type =>	'Individual-Pro-OOB',
		host =>	'registryTK-registrarUI',
		contact => $dri->local_object('contact')->srid('con9486')
	});
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'a/v create is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><av:create xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:id>sh8013</av:id><av:checkType>Individual-Pro-OOB</av:checkType><av:host>registryTK-registrarUI</av:host><av:contact><av:contactId>con9486</av:contactId></av:contact></av:create></create><clTRID>ABC-12345</clTRID></command></epp>', 'a/v create xml');

is($dri->get_info('id', 'av', 'sh8013'), 'sh8013', 'av info id');
is($dri->get_info('roid', 'av', 'sh8013'), 'SH8013-REP', 'av info roid');
is($dri->get_info('crDate', 'av', 'sh8013'), '1999-04-03T22:00:00',
	'av info crDate');
is($dri->get_info('avurl', 'av', 'sh8013'),
	'https://avhost.registrypro.pro/index.jsp?id=sh8013', 'av info avurl');

## Create an A/V contact
$R2 = $E1 . '<response>' . r(1000,'Command completed successfully') .
	'<resData><av:infData xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:id>sh8014</av:id><av:roid>SH8014-REP</av:roid><av:CrId>ClientX</av:CrId><av:CrDate>1999-04-03T22:00:00.0Z</av:CrDate><av:contactId>con9486</av:contactId><av:checkType>Individual-Pro-OOB</av:checkType><av:host>registryTK-registryUI</av:host><av:UpId>ClientX</av:UpId><av:UpDate>1999-12-03T09:00:00.0Z</av:UpDate><av:avResult><av:avCheckId>avchk9483</av:avCheckId><av:personalAvDataFingerprint>9043905jujf8w9</av:personalAvDataFingerprint><av:professionalAvDataFingerprint>9er3k5</av:professionalAvDataFingerprint><av:oobMethodId>oob001</av:oobMethodId><av:profession>med</av:profession><av:jurisdiction>NY-US</av:jurisdiction><av:resultData><av:result>success</av:result><av:date>1999-12-03T08:32:17.0Z</av:date></av:resultData><av:status>complete</av:status></av:avResult></av:infData></resData>' .
	$TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->av_info('sh8014');
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'a/v info is_success');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><av:info xmlns:av="http://registrypro.pro/2003/epp/1/av-2.0" xsi:schemaLocation="http://registrypro.pro/2003/epp/1/av-2.0 av-2.0.xsd"><av:id>sh8014</av:id></av:info></info><clTRID>ABC-12345</clTRID></command></epp>', 'a/v info xml');

is($dri->get_info('id', 'av', 'sh8014'), 'sh8014', 'av info id');
is($dri->get_info('roid', 'av', 'sh8014'), 'SH8014-REP', 'av info roid');
is($dri->get_info('clID', 'av', 'sh8014'), undef, 'av info clID');
is($dri->get_info('crID', 'av', 'sh8014'), 'ClientX', 'av info crID');
is($dri->get_info('upID', 'av', 'sh8014'), 'ClientX', 'av info upID');
is($dri->get_info('crDate', 'av', 'sh8014'), '1999-04-03T22:00:00',
	'av info crDate');
is($dri->get_info('upDate', 'av', 'sh8014'), '1999-12-03T09:00:00',
	'av info upDate');
is($dri->get_info('avurl', 'av', 'sh8014'), undef, 'av info avurl');
is($dri->get_info('type', 'av', 'sh8014'), 'Individual-Pro-OOB',
	'av info type');
is($dri->get_info('host', 'av', 'sh8014'), 'registryTK-registryUI',
	'av info host');
isa_ok($dri->get_info('contact', 'av', 'sh8014'), 'Net::DRI::Data::Contact');
is($dri->get_info('contact', 'av', 'sh8014')->srid(), 'con9486',
	'av info contact');

my $res = $dri->get_info('avresult', 'av', 'sh8014');
isa_ok($res, 'HASH');
is($res->{checkid}, 'avchk9483', 'av info result checkid');
is($res->{persfingerprint}, '9043905jujf8w9', 'av info result persfp');
is($res->{proffingerprint}, '9er3k5', 'av info result proffp');
is($res->{oobmethodid}, 'oob001', 'av info result oobmethodid');
is($res->{profession}, 'med', 'av info result profession');
is($res->{jurisdiction}, 'NY-US', 'av info result jurisdiction');
is($res->{status}, 'complete', 'av info result status');
is($res->{avresult}, 'success', 'av info result avresult');
is($res->{avDate}, '1999-12-03T08:32:17', 'av info result avDate');

############################################################################

exit(0);

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
