#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 23;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1 = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }
my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('ASIA');
$dri->target('ASIA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $ok;
my $rc;
my $s;
my $d;
my ($dh, @c);

####################################################################################################
## CED contact operations

## Contact create
$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result>" . $TRID . '</response>' . $E2;

my $c = $dri->local_object('contact');
$c->srid('TL1-ASIA');
$c->name('Tonnerre Lombard');
$c->org('SyGroup GmbH');
$c->street(['Gueterstrasse 86']);
$c->city('Basel');
$c->sp('BS');
$c->pc('4053');
$c->cc('CH');
$c->voice('+41.61338033');
$c->fax('+41.613831467');
$c->email('tonnerre.lombard@sygroup.ch');
$c->auth({pw => 'blablabla'});
$c->cedcc('IN');
$c->cedsp('Bengal');
$c->cedcity('Bangladesh');
$c->cedetype('naturalPerson');
$c->cediform('passport');
$c->cedinum('24953w-4545');
$ok=eval {
	$rc = $dri->contact_create($c);
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'contact create success');

unless ($rc->is_success())
{
	die('Error ' . $rc->code() . ': ' . $rc->message());
}

is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TL1-ASIA</contact:id><contact:postalInfo type="int"><contact:name>Tonnerre Lombard</contact:name><contact:org>SyGroup GmbH</contact:org><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>BS</contact:sp><contact:pc>4053</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice>+41.61338033</contact:voice><contact:fax>+41.613831467</contact:fax><contact:email>tonnerre.lombard@sygroup.ch</contact:email><contact:authInfo><contact:pw>blablabla</contact:pw></contact:authInfo></contact:create></create><extension><asia:create xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"><asia:cedData><asia:ccLocality>IN</asia:ccLocality><asia:localitySp>Bengal</asia:localitySp><asia:localityCity>Bangladesh</asia:localityCity><asia:legalEntityType>naturalPerson</asia:legalEntityType><asia:identForm>passport</asia:identForm><asia:identNumber>24953w-4545</asia:identNumber></asia:cedData></asia:create></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact create xml');

## Contact query
$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result><resData><contact:infData xmlns:contact='urn:ietf:params:xml:ns:contact-1.0' xsi:schemaLocation='urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd'><contact:id>JD1-ASIA</contact:id><contact:roid>C28909-ASIA</contact:roid><contact:status s='ok'/><contact:status s='linked'/><contact:postalInfo type='loc'><contact:name>John Doe</contact:name><contact:org>Example Corp. Inc</contact:org><contact:addr><contact:street>123 Example St.</contact:street><contact:city>Anytown</contact:city><contact:sp>Any Prov</contact:sp><contact:pc>A1A1A1</contact:pc><contact:cc>FI</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.41565656566</contact:voice><contact:email>jdoe\@valid.asia</contact:email><contact:clID>documentdata1</contact:clID><contact:crID>documentdata1</contact:crID><contact:crDate>2007-10-18T09:31:04.0Z</contact:crDate><contact:upID>documentdata1</contact:upID><contact:upDate>2007-10-18T09:32:58.0Z</contact:upDate><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:infData></resData><extension><asia:infData xmlns:asia='urn:afilias:params:xml:ns:asia-1.0' xsi:schemaLocation='urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd'><asia:cedData><asia:ccLocality>IN</asia:ccLocality><asia:localitySp>Bengal</asia:localitySp><asia:localityCity>Bangladesh</asia:localityCity><asia:legalEntityType>cooperative</asia:legalEntityType><asia:identForm>passport</asia:identForm><asia:identNumber>12-47-AB</asia:identNumber></asia:cedData></asia:infData></extension>" . $TRID . '</response>' . $E2;
$c = $dri->local_object('contact');
$c->srid('JD1-ASIA');
$ok=eval {
	$rc = $dri->contact_info($c);
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'contact query success');

unless ($rc->is_success())
{
	die('Error ' . $rc->code() . ': ' . $rc->message());
}

$c = $dri->get_info('self', 'contact', 'JD1-ASIA');
is($c->srid(), 'JD1-ASIA', 'contact info srid');
is($c->cedcc(), 'IN', 'contact info cedcc');
is($c->cedsp(), 'Bengal', 'contact info cedsp');
is($c->cedcity(), 'Bangladesh', 'contact info cedcity');
is($c->cedetype(), 'cooperative', 'contact info cedetype');
is($c->cediform(), 'passport', 'contact info cediform');
is($c->cedinum(), '12-47-AB', 'contact info cedinum');

####################################################################################################
## CED domain operations

## Domain create

$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result>" . $TRID . '</response>' . $E2;
my $cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C1-ASIA'), 'registrant');
$cs->add($dri->local_object('contact')->srid('C2-ASIA'), 'admin');
$cs->add($dri->local_object('contact')->srid('C3-ASIA'), 'tech');
$cs->add($dri->local_object('contact')->srid('C4-ASIA'), 'billing');
$cs->add($dri->local_object('contact')->srid('C5-ASIA'), 'opn');
$cs->add($dri->local_object('contact')->srid('C6-ASIA'), 'ced');
$cs->add($dri->local_object('contact')->srid('C7-ASIA'), 'regAgent');
my $ns = $dri->local_object('hosts');
$ns->add('ns1.eppvalid.asia');
$ns->add('ns2.eppvalid.asia');
$ok=eval {
	$rc = $dri->domain_create('epptest.asia', {
                pure_create =>  1,
		contact =>	$cs,
		ns =>		$ns,
		maintainer_url =>		'http://www.justgoogleit.com/',
		auth =>		{ pw => 'bleblubleu' }
	});
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'domain create success');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.asia</domain:name><domain:ns><domain:hostObj>ns1.eppvalid.asia</domain:hostObj><domain:hostObj>ns2.eppvalid.asia</domain:hostObj></domain:ns><domain:registrant>C1-ASIA</domain:registrant><domain:contact type="admin">C2-ASIA</domain:contact><domain:contact type="billing">C4-ASIA</domain:contact><domain:contact type="tech">C3-ASIA</domain:contact><domain:authInfo><domain:pw>bleblubleu</domain:pw></domain:authInfo></domain:create></create><extension><asia:create xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"><asia:maintainerUrl>http://www.justgoogleit.com/</asia:maintainerUrl><asia:contact type="ced">C6-ASIA</asia:contact><asia:contact type="opn">C5-ASIA</asia:contact></asia:create></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain create xml');

$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result>" . $TRID . '</response>' . $E2;
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C7-ASIA'), 'opn');

my $todo = $dri->local_object('changes');
$todo->set('contact', $cs);
$todo->set('maintainer_url', 'http://www.chezmoicamarche.com/');

$ok=eval {
	$rc = $dri->domain_update('epptest.asia', $todo);
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'domain update success');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.asia</domain:name></domain:update></update><extension><asia:update xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"><asia:chg><asia:maintainerUrl>http://www.chezmoicamarche.com/</asia:maintainerUrl><asia:contact type="opn">C7-ASIA</asia:contact></asia:chg></asia:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain update xml');

$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result>" . $TRID . '</response>' . $E2;

$todo = $dri->local_object('changes');

$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C5-ASIA'), 'opn');
$todo->set('contact', $cs);

$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C8-ASIA'), 'tech');
$todo->add('contact', $cs);

$ok=eval {
	$rc = $dri->domain_update('epptest.asia', $todo);
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'domain update success');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.asia</domain:name><domain:add><domain:contact type="tech">C8-ASIA</domain:contact></domain:add></domain:update></update><extension><asia:update xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"><asia:chg><asia:contact type="opn">C5-ASIA</asia:contact></asia:chg></asia:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain update xml');

$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result><resData><domain:infData xmlns:domain='urn:ietf:params:xml:ns:domain-1.0' xsi:schemaLocation='urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd'><domain:name>epptest23.asia</domain:name><domain:roid>U13423-ASIA</domain:roid><domain:status s='ok'/><domain:registrant>TL1-ASIA</domain:registrant><domain:contact type='billing'>TL1-ASIA</domain:contact><domain:contact type='tech'>TL1-ASIA</domain:contact><domain:contact type='admin'>JD1-ASIA</domain:contact><domain:ns><domain:hostObj>ns1.eppvalid.asia</domain:hostObj><domain:hostObj>ns2.eppvalid.asia</domain:hostObj><domain:hostObj>ns3.eppvalid.asia</domain:hostObj></domain:ns><domain:clID>client1</domain:clID><domain:crID>client1</domain:crID><domain:crDate>2007-11-09T08:48:08.0Z</domain:crDate><domain:upID>client1</domain:upID><domain:upDate>2008-04-28T09:45:15.0Z</domain:upDate><domain:exDate>2012-11-09T08:48:08.0Z</domain:exDate><domain:authInfo><domain:pw>blablabla</domain:pw></domain:authInfo></domain:infData></resData><extension><asia:infData xmlns:asia='urn:afilias:params:xml:ns:asia-1.0' xsi:schemaLocation='urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd'><asia:maintainerUrl>http://www.justgoogleit.com/</asia:maintainerUrl><asia:contact type='opn'>TL1-ASIA</asia:contact><asia:contact type='regAgent'>YY1-ASIA</asia:contact><asia:contact type='ced'>JD1-ASIA</asia:contact></asia:infData><ipr:infData xmlns:ipr='urn:afilias:params:xml:ns:ipr-1.1' xsi:schemaLocation='urn:afilias:params:xml:ns:ipr-1.1 ipr-1.1.xsd'><ipr:appDate>2007-11-09</ipr:appDate><ipr:regDate>2007-11-09</ipr:regDate></ipr:infData></extension>" . $TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->domain_info('epptest23.asia');
1;
};
if (! $ok)
{
my $err=$@;
	if (ref $err eq 'Net::DRI::Exception')
	{
		die $err->as_string();
	}
	else
	{
		die $err;
	}
}
is($rc->is_success(), 1, 'domain query success');

$cs = $dri->get_info('contact', 'domain', 'epptest23.asia');
is($cs->get('opn')->srid(), 'TL1-ASIA', 'domain contact opn');
is($cs->get('regAgent')->srid(), 'YY1-ASIA', 'domain contact regAgent');
is($cs->get('ced')->srid(), 'JD1-ASIA', 'domain contact ced');
is($dri->get_info('maintainer_url', 'domain', 'epptest23.asia'),
	'http://www.justgoogleit.com/', 'domain contact url');


my $ipr=$rc->get_data('ipr');
is($ipr->{regDate},'2007-11-09T00:00:00','domain_info get_data(ipr) regDate');
is($ipr->{appDate},'2007-11-09T00:00:00','domain_info get_data(ipr) appDate');

exit 0;
