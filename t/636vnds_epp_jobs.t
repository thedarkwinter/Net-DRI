#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 29;

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
$dri->add_registry('VNDS');
$ok=eval {
	$dri->target('VNDS')->add_current_profile('p1',
		'epp',
		{
			f_send=> \&mysend,
			f_recv=> \&myrecv
		},
		{default_product=>'dotJOBS',extensions=>['VeriSign::NameStore']});
	1;
};
print $@->as_string() if ! $ok;


my $rc;
my $s;
my $d;
my ($dh,@c);

############################################################################
## Create a contact
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

my $c = $dri->local_object('contact');
$c->srid('8013');
$c->name('John Doe');
$c->org('Example Inc.');
$c->street(['123 Example Dr.', 'Suite 100']);
$c->city('Dulles');
$c->sp('VA');
$c->pc('20166-6503');
$c->cc('US');
$c->email('john@doe.com');
$c->voice('+1.703555555x1234');
$c->fax('+1.703555555x1235');
$c->auth({pw => '2fooBAR'});
$c->disclose({voice => 0, email => 0});
$c->jobinfo({
	title =>	'SE',
	website =>	'http://localhost:8989/index.txt',
	industry =>	'IT',
	admin =>	1,
	member =>	1
});

$ok=eval {
	$rc = $dri->contact_create($c);
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'contact create');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>8013</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.703555555</contact:voice><contact:fax x="1235">+1.703555555</contact:fax><contact:email>john@doe.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><jobsContact:create xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd"><jobsContact:title>SE</jobsContact:title><jobsContact:website>http://localhost:8989/index.txt</jobsContact:website><jobsContact:industryType>IT</jobsContact:industryType><jobsContact:isAdminContact>Yes</jobsContact:isAdminContact><jobsContact:isAssociationMember>Yes</jobsContact:isAssociationMember></jobsContact:create><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotJOBS</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact create xml');

$c->srid('8014');
$ok=eval {
	$rc = $dri->contact_create($c, {subproductid => 'dotAA'});
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'contact create w/subproductid');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>8014</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.703555555</contact:voice><contact:fax x="1235">+1.703555555</contact:fax><contact:email>john@doe.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><jobsContact:create xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd"><jobsContact:title>SE</jobsContact:title><jobsContact:website>http://localhost:8989/index.txt</jobsContact:website><jobsContact:industryType>IT</jobsContact:industryType><jobsContact:isAdminContact>Yes</jobsContact:isAdminContact><jobsContact:isAssociationMember>Yes</jobsContact:isAssociationMember></jobsContact:create><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotAA</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact create xml w/subproductid');

## Update a contact
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

$c = $dri->local_object('contact');
$c->srid('sh8013');
$c->jobinfo({
	title =>	'SE',
	website =>	'http://localhost:8989/index.txt',
	industry =>	'IT',
	admin =>	1,
	member =>	1
});

my $todo = $dri->local_object('changes');
$todo->set('info', $c);

$ok=eval {
	$rc = $dri->contact_update($c, $todo);
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'contact update');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id></contact:update></update><extension><jobsContact:update xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd"><jobsContact:title>SE</jobsContact:title><jobsContact:website>http://localhost:8989/index.txt</jobsContact:website><jobsContact:industryType>IT</jobsContact:industryType><jobsContact:isAdminContact>Yes</jobsContact:isAdminContact><jobsContact:isAssociationMember>Yes</jobsContact:isAssociationMember></jobsContact:update><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotJOBS</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact update xml');

## Query a contact
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully') .
        '<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8023</contact:id><contact:roid>SH8023-VRSN</contact:roid><contact:status s="linked"/><contact:status s="clientUpdateProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>i15d John Doe</contact:name><contact:org>i15d Example Inc.</contact:org><contact:addr><contact:street>i15d 123 Example Dr.</contact:street><contact:street>i15d Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>2007-06-19T00:38:11.0304Z</contact:crDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:name type="int"/><contact:org type="loc"/><contact:org type="int"/><contact:addr type="loc"/><contact:addr type="int"/><contact:voice/><contact:fax/><contact:email/></contact:disclose></contact:infData></resData><extension><jobsContact:infData xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd"><jobsContact:title>Info-title</jobsContact:title><jobsContact:website>whois.example.com</jobsContact:website><jobsContact:industryType>IT</jobsContact:industryType><jobsContact:isAdminContact>Yes</jobsContact:isAdminContact><jobsContact:isAssociationMember>Yes</jobsContact:isAssociationMember></jobsContact:infData></extension>' . $TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->contact_info($dri->local_object('contact')->srid('sh8023'));
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'contact query');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8023</contact:id></contact:info></info><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotJOBS</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact query xml');

$c = $dri->get_info('self', 'contact', 'sh8023');
isa_ok($c, 'Net::DRI::Data::Contact::JOBS');

my $jobinfo = $c->jobinfo();

isa_ok($jobinfo, 'HASH');
is($jobinfo->{title}, 'Info-title', 'contact query job title');
is($jobinfo->{website}, 'whois.example.com', 'contact query job website');
is($jobinfo->{industry}, 'IT', 'contact query job industry');
is($jobinfo->{admin}, 1, 'contact query job admin');
is($jobinfo->{member}, 1, 'contact query job member');

## Query a contact with corrected data
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully') .
        '<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh4053</contact:id><contact:roid>4053_CONTACT-JOBS</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Fourty Fifty-Three</contact:name><contact:org>SyGroup GmbH</contact:org><contact:addr><contact:street>Gueterstrasse 86</contact:street><contact:city>Basel</contact:city><contact:sp>Basel-Stadt</contact:sp><contact:pc>4053</contact:pc><contact:cc>CH</contact:cc></contact:addr></contact:postalInfo><contact:voice>+41.613338033</contact:voice><contact:fax>+41.613831467</contact:fax><contact:email>fourty.fifty-three@sygroup.ch</contact:email><contact:clID>SYREG</contact:clID><contact:crID>SYREG</contact:crID><contact:crDate>2008-01-01T01:01:01.0000Z</contact:crDate><contact:upID>SYREG</contact:upID><contact:upDate>2008-01-01T01:01:01.0000Z</contact:upDate><contact:authInfo><contact:pw>omnomnom</contact:pw></contact:authInfo></contact:infData></resData><extension><jobsContact:infData xmlns:jobsContact="http://www.verisign.com/epp/jobsContact-1.0" xsi:schemaLocation="http://www.verisign.com/epp/jobsContact-1.0 jobsContact-1.0.xsd"><jobsContact:website>http://www.sygroup.ch/</jobsContact:website><jobsContact:industryType>5</jobsContact:industryType><jobsContact:isAdminContact>No</jobsContact:isAdminContact></jobsContact:infData></extension>' . $TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->contact_info($dri->local_object('contact')->srid('sh4053'));
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'contact query');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh4053</contact:id></contact:info></info><extension><namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:subProduct>dotJOBS</namestoreExt:subProduct></namestoreExt:namestoreExt></extension><clTRID>ABC-12345</clTRID></command></epp>', 'contact query xml');

$c = $dri->get_info('self', 'contact', 'sh4053');
isa_ok($c, 'Net::DRI::Data::Contact::JOBS');

$jobinfo = $c->jobinfo();

isa_ok($jobinfo, 'HASH');
is($jobinfo->{title}, undef, 'contact query job title');
is($jobinfo->{website}, 'http://www.sygroup.ch/', 'contact query job website');
is($jobinfo->{industry}, '5', 'contact query job industry');
is($jobinfo->{admin}, 0, 'contact query job admin');
is($jobinfo->{member}, undef, 'contact query job member');

############################################################################
exit(0);

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
