#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 164;
use Test::Exception;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-response xmlns="http://registry.denic.de/global/3.0" xmlns:tr="http://registry.denic.de/transaction/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:contact="http://registry.denic.de/contact/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0">';
our $E2='</registry-response>';
our $TRID='<tr:ctid>ABC-12345</tr:ctid><tr:stid>54322-XYZ</tr:stid>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<registry-response>'.r().$TRID.'</registry-response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('DENIC');
$dri->target('DENIC')->add_current_profile('p1','rri',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$ns,$secdns);

####################################################################################################
## Session Management
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc=$dri->process('session','noop',[]);
is($rc->is_success(),1,'session noop is_success');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:msg="http://registry.denic.de/msg/3.0"><msg:queue-read/></registry-request>', 'Noop XML correct (sending message_retrieve)');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc = $dri->process('session', 'login', ['user','password']);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Login successful');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0"><login><user>user</user><password>password</password></login></registry-request>', 'Login XML correct');

####################################################################################################
## Contact Operations
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><contact:checkData><contact:handle>DENIC-12345-BSP</contact:handle><contact:status>free</contact:status></contact:checkData></tr:data></tr:transaction>' . $E2;

$rc = $dri->contact_check($dri->local_object('contact')->srid('DENIC-12345-BSP'));
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is(defined($rc) && $rc->is_success(), 1, 'Contact successfully checked');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:check><contact:handle>DENIC-12345-BSP</contact:handle></contact:check></registry-request>', 'Check Contact XML correct');
is($dri->get_info('exist', 'contact', 'DENIC-12345-BSP'), 0, 'Contact does not exist');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

my $c = $dri->local_object('contact');
$c->srid('DENIC-1000002-MAX');
$c->type('PERSON');
$c->name('Max Mustermann');
$c->org('DENIC eG');
$c->street(['Abteilung Business Services - dies ist ein Text um die maximale Anzahl von Zeichen darzustellen, die in einem Adressfeld vorkommen können, die Anzahl der Zeichen ist auf zweihundertfünfundfünfzig begrenzt- Kaiserstrasse fünfundsiebzig bis siebenundsiebzig']);
$c->pc('60329');
$c->city('Frankfurt am Main');
$c->cc('DE');
$c->email('email@denic.de');

# Contact create (based on RRI v3.0 sample)
$rc = $dri->contact_create($c);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully created (version 3.0)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:create><contact:handle>DENIC-1000002-MAX</contact:handle><contact:type>PERSON</contact:type><contact:name>Max Mustermann</contact:name><contact:organisation>DENIC eG</contact:organisation><contact:postal><contact:address>Abteilung Business Services - dies ist ein Text um die maximale Anzahl von Zeichen darzustellen, die in einem Adressfeld vorkommen können, die Anzahl der Zeichen ist auf zweihundertfünfundfünfzig begrenzt- Kaiserstrasse fünfundsiebzig bis siebenundsiebzig</contact:address><contact:postalCode>60329</contact:postalCode><contact:city>Frankfurt am Main</contact:city><contact:countryCode>DE</contact:countryCode></contact:postal><contact:email>email@denic.de</contact:email></contact:create><ctid>ABC-12345</ctid></registry-request>', 'Create Contact XML correct (version 3.0)');

# Contact request (based on RRI v3.0 sample)
my $c2 = $dri->local_object('contact');
$c2->srid('DENIC-99995-GENREQ');
$c2->type('REQUEST');
$c2->uri_template('https://denic.de/contact/form{?Alabel,Ulabel}');
$rc = $dri->contact_create($c2);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully requested (version 3.0)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:create><contact:handle>DENIC-99995-GENREQ</contact:handle><contact:type>REQUEST</contact:type><contact:uri-template>https://denic.de/contact/form{?Alabel,Ulabel}</contact:uri-template></contact:create><ctid>ABC-12345</ctid></registry-request>', 'Request Contact XML correct (version 3.0)');

# Contact check (based on RRI v3.0 sample)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><contact:checkData><contact:handle>DENIC-1000002-MAX</contact:handle><contact:status>exist</contact:status></contact:checkData></tr:data></tr:transaction>' . $E2;
$rc = $dri->contact_check($c);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is(defined($rc) && $rc->is_success(), 1, 'Contact successfully checked (version 3.0)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:check><contact:handle>DENIC-1000002-MAX</contact:handle></contact:check></registry-request>', 'Check Contact XML correct (version 3.0)');
is($dri->get_info('exist', 'contact', 'DENIC-1000002-MAX'), 1, 'Contact exists');

# Contact update (based on RRI v3.0 sample)
my $todo = $dri->local_object('changes');
$todo->set('info', $c2);
$rc = $dri->contact_update($c2, $todo);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully updated (version 3.0)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:update><contact:handle>DENIC-99995-GENREQ</contact:handle><contact:type>REQUEST</contact:type><contact:uri-template>https://denic.de/contact/form{?Alabel,Ulabel}</contact:uri-template></contact:update><ctid>ABC-12345</ctid></registry-request>', 'Update Contact XML correct (version 3.0)');

# Contact update (original test tweaked)
$todo = $dri->local_object('changes');
$todo->set('info', $c);
$rc = $dri->contact_update($c, $todo);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully updated');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:update><contact:handle>DENIC-1000002-MAX</contact:handle><contact:type>PERSON</contact:type><contact:name>Max Mustermann</contact:name><contact:organisation>DENIC eG</contact:organisation><contact:postal><contact:address>Abteilung Business Services - dies ist ein Text um die maximale Anzahl von Zeichen darzustellen, die in einem Adressfeld vorkommen können, die Anzahl der Zeichen ist auf zweihundertfünfundfünfzig begrenzt- Kaiserstrasse fünfundsiebzig bis siebenundsiebzig</contact:address><contact:postalCode>60329</contact:postalCode><contact:city>Frankfurt am Main</contact:city><contact:countryCode>DE</contact:countryCode></contact:postal><contact:email>email@denic.de</contact:email></contact:update><ctid>ABC-12345</ctid></registry-request>', 'Update Contact XML correct');

# Contact info (based on RRI v3.0 sample)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><contact:infoData><contact:handle>DENIC-99995-GENREQ</contact:handle><contact:type>REQUEST</contact:type><contact:uri-template>http://denic.de/contact/{Ulabel}</contact:uri-template><contact:changed>2010-03-31T15:51:08+02:00</contact:changed></contact:infoData></tr:data></tr:transaction>' . $E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('DENIC-99995-GENREQ'));
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully queried (version 3.0)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:info><contact:handle>DENIC-99995-GENREQ</contact:handle></contact:info></registry-request>', 'Query Contact XML correct (version 3.0)');
$c = $dri->get_info('self', 'contact', 'DENIC-99995-GENREQ');
isa_ok($c, 'Net::DRI::Data::Contact::DENIC');
is($c->type() . '|' . $c->uri_template(),
	'REQUEST|http://denic.de/contact/{Ulabel}',
	'Selected info from contact (version 3.0)');
my $mod = $dri->get_info('upDate', 'contact', 'DENIC-99995-GENREQ');
isa_ok($mod, 'DateTime');
is($mod->ymd . 'T' . $mod->hms, '2010-03-31T15:51:08', 'Update Date (version 3.0)');

# Contact info (original test tweaked)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><contact:infoData><contact:handle>DENIC-99989-BSP</contact:handle><contact:type>ROLE</contact:type><contact:name>SyGroup GmbH</contact:name><contact:organisation>SyGroup GmbH</contact:organisation><contact:postal><contact:address>Gueterstrasse 86</contact:address><contact:city>Basel</contact:city><contact:postalCode>4053</contact:postalCode><contact:countryCode>CH</contact:countryCode></contact:postal><contact:email>info@sygroup.ch</contact:email><contact:changed>2007-05-23T22:55:33+02:00</contact:changed></contact:infoData></tr:data></tr:transaction>' . $E2;
$rc = $dri->contact_info($dri->local_object('contact')->srid('DENIC-99989-BSP'));
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully queried');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:contact="http://registry.denic.de/contact/3.0"><contact:info><contact:handle>DENIC-99989-BSP</contact:handle></contact:info></registry-request>', 'Query Contact XML correct');
$c = $dri->get_info('self', 'contact', 'DENIC-99989-BSP');
isa_ok($c, 'Net::DRI::Data::Contact::DENIC');
is($c->name() . '|' . $c->org() . '|' . $c->type(),
	'SyGroup GmbH|SyGroup GmbH|ROLE',
	'Selected info from contact');
$mod = $dri->get_info('upDate', 'contact', 'DENIC-99989-BSP');
isa_ok($mod, 'DateTime');
is($mod->ymd . 'T' . $mod->hms, '2007-05-23T22:55:33', 'Update Date');

# Contact delete - operation doesn't exist
throws_ok { $dri->contact_delete($c) } qr/No operation contact delete available for registry DENIC/, 'contact_delete not possible';

####################################################################################################
## Domain Operations

# Domain check
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><domain:checkData><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace><domain:status>free</domain:status></domain:checkData></tr:data></tr:transaction>' . $E2;
$rc = $dri->domain_check('rritestdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:check><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:check></registry-request>', 'Check Domain XML correct');
is($dri->get_info('exist', 'domain', 'rritestdomain.de'), 0, 'Domain does not exist');

# Domain check using IDN (ace)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><domain:checkData><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace><domain:status>free</domain:status></domain:checkData></tr:data></tr:transaction>' . $E2;
$rc = $dri->domain_check('xn--rriberdomain-flb.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
utf8::encode($R1); # this encoding is normally done at transport so we have to encode it manually for this test to pass
my $command = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:check><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace></domain:check></registry-request>';
utf8::encode($command);
is($R1, $command, 'Check Domain XML correct');
is($dri->get_info('exist'), 0, 'domain get_info(exist)');
is($dri->get_info('exist', 'domain', 'xn--rriberdomain-flb.de'), 0, 'domain get_info(exist) from cache ace');
is($dri->get_info('exist', 'domain', 'rriüberdomain.de'), 0, 'domain get_info(exist) from cache idn');
is($dri->get_info('name'), 'rriüberdomain.de', 'domain get_info(name)');
is($dri->get_info('name_ace'), 'xn--rriberdomain-flb.de', 'domain get_info(name_ace)');
is($dri->get_info('name_idn'), 'rriüberdomain.de', 'domain get_info(name_idn)');
$dri->cache_clear();

# Domain check using IDN (native)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><domain:checkData><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace><domain:status>free</domain:status></domain:checkData></tr:data></tr:transaction>' . $E2;
$rc = $dri->domain_check('rriüberdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
utf8::encode($R1); # this encoding is normally done at transport so we have to encode it manually for this test to pass
$command = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:check><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace></domain:check></registry-request>';
utf8::encode($command);
is($R1, $command, 'Check Domain XML correct');
is($dri->get_info('exist'), 0, 'domain get_info(exist)');
is($dri->get_info('exist', 'domain', 'xn--rriberdomain-flb.de'), 0, 'domain get_info(exist) from cache ace');
is($dri->get_info('exist', 'domain', 'rriüberdomain.de'), 0, 'domain get_info(exist) from cache idn');
is($dri->get_info('name'), 'rriüberdomain.de', 'domain get_info(name)');
is($dri->get_info('name_ace'), 'xn--rriberdomain-flb.de', 'domain get_info(name_ace)');
is($dri->get_info('name_idn'), 'rriüberdomain.de', 'domain get_info(name_idn)');
$dri->cache_clear();

# Domain create
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
my $cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP'), 'registrant');

my @secdns = ({key_flags=>257,key_protocol=>3,key_alg=>5,key_pubKey=>'AwEAAdDECajHaTjfSoNTY58WcBah1BxPKVIHBz4IfLjfqMvium4lgKtKZLe97DgJ5/NQrNEGGQmr6fKvUj67cfrZUojZ2cGRizVhgkOqZ9scaTVXNuXLM5Tw7VWOVIceeXAuuH2mPIiEV6MhJYUsW6dvmNsJ4XwCgNgroAmXhoMEiWEjBB+wjYZQ5GtZHBFKVXACSWTiCtddHcueOeSVPi5WH94VlubhHfiytNPZLrObhUCHT6k0tNE6phLoHnXWU+6vpsYpz6GhMw/R9BFxW5PdPFIWBgoWk2/XFVRSKG9Lr61b2z1R126xeUwvw46RVy3h anV3vNO7LM5H niqaYclBbhk='});
$rc = $dri->domain_create('rritestdomain.de', {
	pure_create =>  1,
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->
	add('dns1.syhosting.ch',['193.219.115.46']),
	secdns => [ @secdns ],
	});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created');

is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:create><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>rritestdomain.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:DNSKEY"><dnsentry:owner>rritestdomain.de.</dnsentry:owner><dnsentry:rdata><dnsentry:flags>257</dnsentry:flags><dnsentry:protocol>3</dnsentry:protocol><dnsentry:algorithm>5</dnsentry:algorithm><dnsentry:publicKey>AwEAAdDECajHaTjfSoNTY58WcBah1BxPKVIHBz4IfLjfqMvium4lgKtKZLe97DgJ5/NQrNEGGQmr6fKvUj67cfrZUojZ2cGRizVhgkOqZ9scaTVXNuXLM5Tw7VWOVIceeXAuuH2mPIiEV6MhJYUsW6dvmNsJ4XwCgNgroAmXhoMEiWEjBB+wjYZQ5GtZHBFKVXACSWTiCtddHcueOeSVPi5WH94VlubhHfiytNPZLrObhUCHT6k0tNE6phLoHnXWU+6vpsYpz6GhMw/R9BFxW5PdPFIWBgoWk2/XFVRSKG9Lr61b2z1R126xeUwvw46RVy3h anV3vNO7LM5H niqaYclBbhk=</dnsentry:publicKey></dnsentry:rdata></dnsentry:dnsentry></domain:create><ctid>ABC-12345</ctid></registry-request>', 'Create Domain XML correct');

# Domain create idn (ace)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc = $dri->domain_create('xn--rriberdomain-flb.de', {
	pure_create =>  1,
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->
	add('dns1.syhosting.ch',['193.219.115.46']),
	secdns => [ @secdns ],
	});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:create><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>xn--rriberdomain-flb.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:DNSKEY"><dnsentry:owner>xn--rriberdomain-flb.de.</dnsentry:owner><dnsentry:rdata><dnsentry:flags>257</dnsentry:flags><dnsentry:protocol>3</dnsentry:protocol><dnsentry:algorithm>5</dnsentry:algorithm><dnsentry:publicKey>AwEAAdDECajHaTjfSoNTY58WcBah1BxPKVIHBz4IfLjfqMvium4lgKtKZLe97DgJ5/NQrNEGGQmr6fKvUj67cfrZUojZ2cGRizVhgkOqZ9scaTVXNuXLM5Tw7VWOVIceeXAuuH2mPIiEV6MhJYUsW6dvmNsJ4XwCgNgroAmXhoMEiWEjBB+wjYZQ5GtZHBFKVXACSWTiCtddHcueOeSVPi5WH94VlubhHfiytNPZLrObhUCHT6k0tNE6phLoHnXWU+6vpsYpz6GhMw/R9BFxW5PdPFIWBgoWk2/XFVRSKG9Lr61b2z1R126xeUwvw46RVy3h anV3vNO7LM5H niqaYclBbhk=</dnsentry:publicKey></dnsentry:rdata></dnsentry:dnsentry></domain:create><ctid>ABC-12345</ctid></registry-request>', 'Create Domain IDN (ace)	XML correct');

# Domain create idn (native)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc = $dri->domain_create('rriüberdomain.de', {
	pure_create =>  1,
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->
	add('dns1.syhosting.ch',['193.219.115.46']),
	secdns => [ @secdns ],
	});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:create><domain:handle>rriüberdomain.de</domain:handle><domain:ace>xn--rriberdomain-flb.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>xn--rriberdomain-flb.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:DNSKEY"><dnsentry:owner>xn--rriberdomain-flb.de.</dnsentry:owner><dnsentry:rdata><dnsentry:flags>257</dnsentry:flags><dnsentry:protocol>3</dnsentry:protocol><dnsentry:algorithm>5</dnsentry:algorithm><dnsentry:publicKey>AwEAAdDECajHaTjfSoNTY58WcBah1BxPKVIHBz4IfLjfqMvium4lgKtKZLe97DgJ5/NQrNEGGQmr6fKvUj67cfrZUojZ2cGRizVhgkOqZ9scaTVXNuXLM5Tw7VWOVIceeXAuuH2mPIiEV6MhJYUsW6dvmNsJ4XwCgNgroAmXhoMEiWEjBB+wjYZQ5GtZHBFKVXACSWTiCtddHcueOeSVPi5WH94VlubhHfiytNPZLrObhUCHT6k0tNE6phLoHnXWU+6vpsYpz6GhMw/R9BFxW5PdPFIWBgoWk2/XFVRSKG9Lr61b2z1R126xeUwvw46RVy3h anV3vNO7LM5H niqaYclBbhk=</dnsentry:publicKey></dnsentry:rdata></dnsentry:dnsentry></domain:create><ctid>ABC-12345</ctid></registry-request>', 'Create Domain IDN (native) XML correct');

# Domain create (based on RRI v3.0 sample)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-ABUSE'), 'abuse');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-GENERAL'), 'general');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-MAX'), 'registrant');
$rc = $dri->domain_create('de-example.de', {
	pure_create =>  1,
	contact =>	$cs,
	ns => $dri->local_object('hosts')->set(
		['ns1.xn--de-xample-x2a.de'],
		['ns2.de-example.de',['81.91.170.12']])
	});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created');

is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:create><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:contact role="abusecontact">DENIC-1000002-ABUSE</domain:contact><domain:contact role="generalrequest">DENIC-1000002-GENERAL</domain:contact><domain:contact role="holder">DENIC-1000002-MAX</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns1.xn--de-xample-x2a.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns2.de-example.de.</dnsentry:nameserver><dnsentry:address>81.91.170.12</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:create><ctid>ABC-12345</ctid></registry-request>', 'Create Domain XML correct (version 3.0)');

# Domain info own domain (based on RRI v3.0 sample)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data>
      <domain:infoData xmlns:domain="http://registry.denic.de/domain/3.0">
        <domain:handle>denic.de</domain:handle>
        <domain:ace>denic.de</domain:ace>
        <domain:status>connect</domain:status>
        <domain:regAccId>DENIC-1000006</domain:regAccId>
        <domain:regAccName>DENIC eG</domain:regAccName>
        <domain:contact role="generalrequest">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-GENERAL-REQUEST</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:dbs@denic.de</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="abusecontact">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-ABUSE-CONTACT</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:abuse@denic.de?subject=domain:{Ulabel}</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="holder">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-DENIC</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">ORG</contact:type>
          <contact:name xmlns:contact="http://registry.denic.de/contact/3.0">DENIC eG</contact:name>
          <contact:postal xmlns:contact="http://registry.denic.de/contact/3.0">
            <contact:address>Kaiserstraße 75 - 77</contact:address>
            <contact:postalCode>60329</contact:postalCode>
            <contact:city>Frankfurt am Main</contact:city>
            <contact:countryCode>DE</contact:countryCode>
          </contact:postal>
          <contact:email xmlns:contact="http://registry.denic.de/contact/3.0">info@denic.de</contact:email>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2017-01-06T15:51:08+02:00</contact:changed>
        </domain:contact>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns1.denic.de.</dnsentry:nameserver>
            <dnsentry:address>2a02:568:121:6:2:0:0:2</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns1.denic.de.</dnsentry:nameserver>
            <dnsentry:address>181.91.170.1</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns2.denic.de.</dnsentry:nameserver>
            <dnsentry:address>193.171.255.36</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns3.denic.de.</dnsentry:nameserver>
            <dnsentry:address>87.233.175.19</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:DNSKEY">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:flags>257</dnsentry:flags>
            <dnsentry:protocol>3</dnsentry:protocol>
            <dnsentry:algorithm>7</dnsentry:algorithm>
            <dnsentry:publicKey>BwFBBceSXa/P93GbzsO8/aqk4w3NA0C3Ll4bPCptnAu2drcmyhQcw4HzKHCBI5qAIcOZPgVi47jbi8lR7w+EB8jvCqIHKxGUxcw16qu5qKCGxpEY+qPyLiwTIStcJSIYllx5Jsh0cw77o9eFnyTGAR4m+X9nES1tpVs4axqulSCrO9N5RrBEuWyeNOAmVIpClT3nsPfBy30B+vkv6OQPY8eDRDLQ1LOe3ac+KpA7R0mXD9twCYOnruPe4mIiccrkopiT7cLFRrjGEDNYQnEEPVbVujQDmTldCLIQ9xpYHaLlxJZ1DYJA7lew2iExLyE5IVFH8lRDg+aCkTUGSA3GV8tQhDc=</dnsentry:publicKey>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:DNSKEY">
          <dnsentry:owner>denic.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:flags>257</dnsentry:flags>
            <dnsentry:protocol>3</dnsentry:protocol>
            <dnsentry:algorithm>7</dnsentry:algorithm>
            <dnsentry:publicKey>AwFBBceSXa/P93GbzsO8/aqk4w3NA0C3Ll4bPCptnAu2drcmyhQcw4HzKHCBI5qAIcOZPgVi47jbi8lR7w+EB8jvCqIHKxGUxcw16qu5qKCGxpEY+qPyLiwTIStcJSIYllx5Jsh0cw77o9eFnyTGAR4m+X9nES1tpVs4axqulSCrO9N5RrBEuWyeNOAmVIpClT3nsPfBy30B+vkv6OQPY8eDRDLQ1LOe3ac+KpA7R0mXD9twCYOnruPe4mIiccrkopiT7cLFRrjGEDNYQnEEPVbVujQDmTldCLIQ9xpYHaLlxJZ1DYJA7lew2iExLyE5IVFH8lRDg+aCkTUGSA3GV8tQhDc=</dnsentry:publicKey>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <domain:changed>2018-08-13T14:24:38+02:00</domain:changed>
      </domain:infoData>
    </tr:data>
  </tr:transaction>' . $E2;
$rc = $dri->domain_info('denic.de',{recursive=>1});
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:info recursive="true"><domain:handle>denic.de</domain:handle><domain:ace>denic.de</domain:ace></domain:info></registry-request>', 'Query Domain XML correct (version 3.0)');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully queried (version 3.0)');
$mod = $dri->get_info('upDate');
isa_ok($mod, 'DateTime');
is($mod->ymd . 'T' . $mod->hms, '2018-08-13T14:24:38', 'Update Date');
is($dri->get_info('contact')->get('registrant')->srid(), 'DENIC-1000006-DENIC',	'Holder handle is correct');
is($dri->get_info('contact')->get('abusecontact')->srid(), 'DENIC-1000006-ABUSE-CONTACT',	'Abuse handle is correct');
is($dri->get_info('contact')->get('generalrequest')->srid(), 'DENIC-1000006-GENERAL-REQUEST',	'General handle is correct');
$ns = $dri->get_info('ns', 'domain', 'denic.de');
is_deeply([$ns->get_names()],['ns1.denic.de','ns2.denic.de','ns3.denic.de'],'Name server records');
is(join(',', map { my ($name, $v4, $v6) = $ns->get_details($_); $v4->[0] }
	$ns->get_names()), '181.91.170.1,193.171.255.36,87.233.175.19', 'Name server v4 IPs');
is(join(',', map { my ($name, $v4, $v6) = $ns->get_details($_); $v6->[0] }
	$ns->get_names(1)), '2a02:568:121:6:2:0:0:2', 'Name server v6 IPs');
$secdns = $dri->get_info('secdns', 'domain', 'denic.de');
is_deeply($secdns,[
  {
    key_flags=>257,
    key_protocol=>3,
    key_alg=>7,
    key_pubKey=>'BwFBBceSXa/P93GbzsO8/aqk4w3NA0C3Ll4bPCptnAu2drcmyhQcw4HzKHCBI5qAIcOZPgVi47jbi8lR7w+EB8jvCqIHKxGUxcw16qu5qKCGxpEY+qPyLiwTIStcJSIYllx5Jsh0cw77o9eFnyTGAR4m+X9nES1tpVs4axqulSCrO9N5RrBEuWyeNOAmVIpClT3nsPfBy30B+vkv6OQPY8eDRDLQ1LOe3ac+KpA7R0mXD9twCYOnruPe4mIiccrkopiT7cLFRrjGEDNYQnEEPVbVujQDmTldCLIQ9xpYHaLlxJZ1DYJA7lew2iExLyE5IVFH8lRDg+aCkTUGSA3GV8tQhDc='
  },
  {
    key_flags=>257,
    key_protocol=>3,
    key_alg=>7,
    key_pubKey=>'AwFBBceSXa/P93GbzsO8/aqk4w3NA0C3Ll4bPCptnAu2drcmyhQcw4HzKHCBI5qAIcOZPgVi47jbi8lR7w+EB8jvCqIHKxGUxcw16qu5qKCGxpEY+qPyLiwTIStcJSIYllx5Jsh0cw77o9eFnyTGAR4m+X9nES1tpVs4axqulSCrO9N5RrBEuWyeNOAmVIpClT3nsPfBy30B+vkv6OQPY8eDRDLQ1LOe3ac+KpA7R0mXD9twCYOnruPe4mIiccrkopiT7cLFRrjGEDNYQnEEPVbVujQDmTldCLIQ9xpYHaLlxJZ1DYJA7lew2iExLyE5IVFH8lRDg+aCkTUGSA3GV8tQhDc='
  }
],'domain_info get_info(secdns) - key data');

# domain:CHPROV (based on RRI v3.0 sample)
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc = $dri->domain_transfer_start('de-example.de', {
	contact =>	$cs,
  ns =>		$dri->local_object('hosts')->set(
    ['ns1.provider.de'],
    ['ns2.provider.de']
  ),
  auth => { pw => 'SupermanistSuper'},
});
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:chprov><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:contact role="abusecontact">DENIC-1000002-ABUSE</domain:contact><domain:contact role="generalrequest">DENIC-1000002-GENERAL</domain:contact><domain:contact role="holder">DENIC-1000002-MAX</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns1.provider.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns2.provider.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><domain:authInfo>SupermanistSuper</domain:authInfo></domain:chprov><ctid>ABC-12345</ctid></registry-request>', 'Transfer Domain XML correct');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transferred');

# Domain transfer refuse
$rc = $dri->domain_transfer_refuse('rritestdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain transfer successfully refused');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:chprovNack><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:chprovNack><ctid>ABC-12345</ctid></registry-request>', 'Refuse Transfer XML correct');

# Domain transfer accept
$rc = $dri->domain_transfer_accept('rritestdomain2.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain transfer successfully approved');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:chprovAck><domain:handle>rritestdomain2.de</domain:handle><domain:ace>rritestdomain2.de</domain:ace></domain:chprovAck><ctid>ABC-12345</ctid></registry-request>', 'Accept Transfer XML correct');

# Domain delete
$rc = $dri->domain_delete('rritestdomain3.de', { contact => $cs });
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully deleted');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:delete><domain:handle>rritestdomain3.de</domain:handle><domain:ace>rritestdomain3.de</domain:ace><domain:contact role="holder">DENIC-1000002-MAX</domain:contact></domain:delete><ctid>ABC-12345</ctid></registry-request>', 'Delete Domain XML correct');

# Domain delete (based on RRI v3.0 sample)
$rc = $dri->domain_delete('de-example.de', { contact => $cs });
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully deleted (version 3.0 sample)');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:domain="http://registry.denic.de/domain/3.0"><domain:delete><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:contact role="holder">DENIC-1000002-MAX</domain:contact></domain:delete><ctid>ABC-12345</ctid></registry-request>', 'Delete Domain XML correct (version 3.0 sample)');

# Domain delete authinfo (based on RRI v3.0 sample)
$rc = $dri->domain_delete_authinfo('de-example.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully deleted authinfo');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:deleteAuthInfo1><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:deleteAuthInfo1><ctid>ABC-12345</ctid></registry-request>', 'Domain Delete Authinfo XML correct');

# Domain restore (based on RRI v3.0 sample)
$rc = $dri->domain_restore('de-example.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully restored');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:restore><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:restore><ctid>ABC-12345</ctid></registry-request>', 'Domain restore XML correct');

# Domain create authinfo1 (based on RRI v3.0 sample)
$rc = $dri->domain_create_authinfo('de-example.de', {
  authinfohash => '4213d924230224fd719218b4acbd92f96ebe4344f3d5d1478dede1aa44e4cf4b',
  authinfoexpire => '20100815'
});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created authinfo1');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:createAuthInfo1 expire="20100815" hash="4213d924230224fd719218b4acbd92f96ebe4344f3d5d1478dede1aa44e4cf4b"><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:createAuthInfo1><ctid>ABC-12345</ctid></registry-request>', 'Domain Create Authinfo1 XML correct');

# Domain create authinfo2 (based on RRI v3.0 sample)
$rc = $dri->domain_create_authinfo('de-example.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created authinfo2');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:createAuthInfo2><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:createAuthInfo2><ctid>ABC-12345</ctid></registry-request>', 'Domain Create Authinfo2 XML correct');

# Domain trade | domain:CHHOLDER)
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP5'), 'registrant');
$rc = $dri->domain_trade('rritestdomain2.de', { contact =>	$cs });
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully traded');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:chholder><domain:handle>rritestdomain2.de</domain:handle><domain:ace>rritestdomain2.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP5</domain:contact></domain:chholder><ctid>ABC-12345</ctid></registry-request>', 'Trade Domain XML correct');

# Domain trade | domain:CHHOLDER (based on RRI v3.0 sample)
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-MAX'), 'registrant');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-ABUSE'), 'abuse');
$cs->add($dri->local_object('contact')->srid('DENIC-1000002-GENERAL'), 'general');
$rc = $dri->domain_trade('de-example.de', { contact => $cs, ns => $dri->local_object('hosts')->set(
  ['ns1.xn--de-xample-x2a.de'],
  ['ns2.de-example.de',['81.91.170.12']])
});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully traded');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:chholder><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:contact role="abusecontact">DENIC-1000002-ABUSE</domain:contact><domain:contact role="generalrequest">DENIC-1000002-GENERAL</domain:contact><domain:contact role="holder">DENIC-1000002-MAX</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns1.xn--de-xample-x2a.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns2.de-example.de.</dnsentry:nameserver><dnsentry:address>81.91.170.12</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:chholder><ctid>ABC-12345</ctid></registry-request>', 'Trade Domain XML correct');

# Domain transit
$rc = $dri->domain_transit('rritestdomain.de', {disconnect => 'true'});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transitted');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:transit disconnect="true"><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:transit><ctid>ABC-12345</ctid></registry-request>', 'Transit Domain XML correct');

# Domain transit (based on RRI v3.0 sample)
$rc = $dri->domain_transit('de-example.de', {disconnect => 'true'});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transitted');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:transit disconnect="true"><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:transit><ctid>ABC-12345</ctid></registry-request>', 'Transit Domain (true) XML correct');
$rc = $dri->domain_transit('de-example.de', {disconnect => 'false'});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transitted');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:transit disconnect="false"><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace></domain:transit><ctid>ABC-12345</ctid></registry-request>', 'Transit Domain (false) XML correct');

# Domain update
# $R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><domain:infoData><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:status>connect</domain:status><domain:regAccId>DENIC-1000006</domain:regAccId><domain:contact role="holder"><contact:handle>DENIC-1000006-1</contact:handle></domain:contact><domain:contact role="holder"><contact:handle>DENIC-1000006-2</contact:handle></domain:contact><domain:contact role="admin-c"><contact:handle>DENIC-1000006-SD</contact:handle></domain:contact><domain:contact role="tech-c"><contact:handle>DENIC-1000006-OPS</contact:handle></domain:contact><domain:contact role="zone-c"><contact:handle>DENIC-1000006-OPS</contact:handle></domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>rritestdomain.de</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.rritestdomain.de</dnsentry:nameserver><dnsentry:address>194.25.1.029</dnsentry:address><dnsentry:address>2001:4d88:ffff:ffff:2:b345:af62:2</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><domain:changed>2001-09-11T11:45:23-07:00</domain:changed></domain:infoData></tr:data></tr:transaction>' . $E2;
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data>
      <domain:infoData xmlns:domain="http://registry.denic.de/domain/3.0">
        <domain:handle>de-example.de</domain:handle>
        <domain:ace>de-example.de</domain:ace>
        <domain:status>connect</domain:status>
        <domain:regAccId>DENIC-1000006</domain:regAccId>
        <domain:regAccName>DENIC eG</domain:regAccName>
        <domain:contact role="generalrequest">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-GENERAL-REQUEST</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:dbs@denic.de</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="abusecontact">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-ABUSE-CONTACT</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:abuse@denic.de?subject=domain:{Ulabel}</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="holder">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-DENIC</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">ORG</contact:type>
          <contact:name xmlns:contact="http://registry.denic.de/contact/3.0">DENIC eG</contact:name>
          <contact:postal xmlns:contact="http://registry.denic.de/contact/3.0">
            <contact:address>Kaiserstraße 75 - 77</contact:address>
            <contact:postalCode>60329</contact:postalCode>
            <contact:city>Frankfurt am Main</contact:city>
            <contact:countryCode>DE</contact:countryCode>
          </contact:postal>
          <contact:email xmlns:contact="http://registry.denic.de/contact/3.0">info@denic.de</contact:email>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2017-01-06T15:51:08+02:00</contact:changed>
        </domain:contact>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>de-example.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns1.de-example.de.</dnsentry:nameserver>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>de-example.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns2.de-example.de.</dnsentry:nameserver>
            <dnsentry:address>193.171.255.36</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:NS">
          <dnsentry:owner>de-example.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:nameserver>ns3.de-example.de.</dnsentry:nameserver>
            <dnsentry:address>87.233.175.19</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <domain:changed>2018-08-13T14:24:38+02:00</domain:changed>
      </domain:infoData>
    </tr:data>
  </tr:transaction>' . $E2;
$rc = $dri->domain_info('de-example.de');
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-GENERAL'), 'generalrequest');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-ABUSE'), 'abusecontact');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-MAX'), 'registrant');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-GENERAL-REQUEST'), 'generalrequest');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-ABUSE-CONTACT'), 'abusecontact');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-DENIC'), 'registrant');
$changes->del('contact', $cs);
$changes->add('ns', $dri->local_object('hosts')->add('ns4.de-example.de',
	['87.233.175.19'],[]));
$changes->del('ns', $dri->local_object('hosts')->add('ns3.de-example.de'));
$rc = $dri->domain_update('de-example.de', $changes);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully updated');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:update><domain:handle>de-example.de</domain:handle><domain:ace>de-example.de</domain:ace><domain:contact role="abusecontact">DENIC-1000002-ABUSE</domain:contact><domain:contact role="generalrequest">DENIC-1000002-GENERAL</domain:contact><domain:contact role="holder">DENIC-1000002-MAX</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns1.de-example.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns2.de-example.de.</dnsentry:nameserver><dnsentry:address>193.171.255.36</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns4.de-example.de.</dnsentry:nameserver><dnsentry:address>87.233.175.19</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:update><ctid>ABC-12345</ctid></registry-request>', 'Update Domain XML correct');



# Domain update 2 - Registry only parsing address element under dnsentry
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data>
      <domain:infoData xmlns:domain="http://registry.denic.de/domain/3.0">
        <domain:handle>de-example-entry-only.de</domain:handle>
        <domain:ace>de-example-entry-only.de</domain:ace>
        <domain:status>connect</domain:status>
        <domain:regAccId>DENIC-1000006</domain:regAccId>
        <domain:regAccName>DENIC eG</domain:regAccName>
        <domain:contact role="generalrequest">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-GENERAL-REQUEST</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:dbs@denic.de</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="abusecontact">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-ABUSE-CONTACT</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:abuse@denic.de?subject=domain:{Ulabel}</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2018-08-13T14:14:18+02:00</contact:changed>
        </domain:contact>
        <domain:contact role="holder">
          <contact:handle xmlns:contact="http://registry.denic.de/contact/3.0">DENIC-1000006-DENIC</contact:handle>
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">ORG</contact:type>
          <contact:name xmlns:contact="http://registry.denic.de/contact/3.0">DENIC eG</contact:name>
          <contact:postal xmlns:contact="http://registry.denic.de/contact/3.0">
            <contact:address>Kaiserstraße 75 - 77</contact:address>
            <contact:postalCode>60329</contact:postalCode>
            <contact:city>Frankfurt am Main</contact:city>
            <contact:countryCode>DE</contact:countryCode>
          </contact:postal>
          <contact:email xmlns:contact="http://registry.denic.de/contact/3.0">info@denic.de</contact:email>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2017-01-06T15:51:08+02:00</contact:changed>
        </domain:contact>
        <dnsentry:dnsentry xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dnsentry:A">
          <dnsentry:owner>www.aimmune.de.</dnsentry:owner>
          <dnsentry:rdata>
            <dnsentry:address>81.91.170.22</dnsentry:address>
          </dnsentry:rdata>
        </dnsentry:dnsentry>
        <domain:changed>2022-04-22T13:09:40+02:00</domain:changed>
      </domain:infoData>
    </tr:data>
  </tr:transaction>' . $E2;
$rc = $dri->domain_info('de-example-entry-only.de');
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-GENERAL'), 'generalrequest');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-ABUSE'), 'abusecontact');
$cs->set($dri->local_object('contact')->srid('DENIC-1000002-MAX'), 'registrant');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-GENERAL-REQUEST'), 'generalrequest');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-ABUSE-CONTACT'), 'abusecontact');
$cs->set($dri->local_object('contact')->srid('DENIC-1000006-DENIC'), 'registrant');
$changes->del('contact', $cs);
$changes->add('ns', $dri->local_object('hosts')->add('ns4.de-example-entry-only.de',
	['87.233.175.19'],[]));
$changes->del('ns', $dri->local_object('hosts')->add('ns3.de-example-entry-only.de'));
$rc = $dri->domain_update('de-example-entry-only.de', $changes);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully updated');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:dnsentry="http://registry.denic.de/dnsentry/3.0" xmlns:domain="http://registry.denic.de/domain/3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><domain:update><domain:handle>de-example-entry-only.de</domain:handle><domain:ace>de-example-entry-only.de</domain:ace><domain:contact role="abusecontact">DENIC-1000002-ABUSE</domain:contact><domain:contact role="generalrequest">DENIC-1000002-GENERAL</domain:contact><domain:contact role="holder">DENIC-1000002-MAX</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns1.de-example.de.</dnsentry:nameserver></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example-entry-only.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns2.de-example-entry-only.de.</dnsentry:nameserver><dnsentry:address>193.171.255.36</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>de-example-entry-only.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>ns4.de-example-entry-only.de.</dnsentry:nameserver><dnsentry:address>87.233.175.19</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:update><ctid>ABC-12345</ctid></registry-request>', 'Update Domain Two XML correct');


####################################################################################################
## Poll Message Operations

# Message retrieve
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result><tr:data><msg:message xmlns:msg="http://registry.denic.de/msg/3.0" msgid="423" msgcnt="42" msgtime="2007-12-27T14:52:13+02:00"><msg:chprovAuthInfo><msg:domain><msg:handle>blafasel.de</msg:handle><msg:ace>blafasel.de</msg:ace></msg:domain><msg:new>DENIC eG</msg:new><msg:old>RoedelDoedelCorp</msg:old></msg:chprovAuthInfo></msg:message></tr:data></tr:transaction>' . $E2;
$rc = $dri->message_retrieve();
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Message successfully deleted');
my $msgid = $dri->get_info('last_id', 'message', 'session');
is($msgid, 423, 'Message ID parsed successfully');
is($dri->get_info('id', 'message', $msgid), $msgid, 'Message ID correct');
is($dri->get_info('action', 'message', $msgid), 'chprovAuthInfo', 'Message type correct');
is($dri->get_info('object_id', 'message', $msgid), 'blafasel.de', 'Message domain correct');
$mod = $dri->get_info('qdate', 'message', $msgid);
is($mod->ymd . 'T' . $mod->hms, '2007-12-27T14:52:13', 'Update Date');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:msg="http://registry.denic.de/msg/3.0"><msg:queue-read/></registry-request>', 'Retrieve Message XML correct');

# Message delete
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID . '</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;
$rc = $dri->message_delete($msgid);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Message successfully deleted');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:msg="http://registry.denic.de/msg/3.0"><msg:delete msgid="423"/><ctid>ABC-12345</ctid></registry-request>', 'Delete Message XML correct');

####################################################################################################


####################################################################################################
## RegAcc:Info
$R2 = '<?xml version="1.0" encoding="UTF-8"?>
<registry-response xmlns="http://registry.denic.de/global/3.0" xmlns:tr="http://registry.denic.de/transaction/3.0">
  <tr:transaction>
    <tr:stid>eb7c2a09-a963-11e9-aba1-217bf86bcda0</tr:stid>
    <tr:result>success</tr:result>
    <tr:data>
      <regacc:infoData xmlns:regacc="http://registry.denic.de/regacc/3.0">
        <regacc:handle>DENIC-99995</regacc:handle>
        <regacc:name>DENIC eG - Business Services</regacc:name>
        <regacc:postal>
          <regacc:address>DENIC eG</regacc:address>
          <regacc:address>Kaiserstraße 75-77</regacc:address>
          <regacc:postalCode>60329</regacc:postalCode>
          <regacc:city>Frankfurt</regacc:city>
          <regacc:countryCode>DE</regacc:countryCode>
        </regacc:postal>
        <regacc:phone>+49 69 27235 0</regacc:phone>
        <regacc:fax>+49 69 27235 235</regacc:fax>
        <regacc:email>dbs@denic.de</regacc:email>
        <regacc:url>http://www.denic.de</regacc:url>
        <regacc:memberacc>DENIC-99995</regacc:memberacc>
        <regacc:contact role="generalrequest">
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:general@denic.de?subject=domain:{Ulabel}</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2019-01-01T01:00:00+01:00</contact:changed>
        </regacc:contact>
        <regacc:contact role="abusecontact">
          <contact:type xmlns:contact="http://registry.denic.de/contact/3.0">REQUEST</contact:type>
          <contact:uri-template xmlns:contact="http://registry.denic.de/contact/3.0">mailto:abuse@denic.de?subject=domain:{Ulabel}</contact:uri-template>
          <contact:changed xmlns:contact="http://registry.denic.de/contact/3.0">2019-01-01T01:00:00+01:00</contact:changed>
        </regacc:contact>
        <regacc:changed>2019-05-17T10:48:29+02:00</regacc:changed>
      </regacc:infoData>
    </tr:data>
  </tr:transaction>
</registry-response>';
$rc = $dri->regacc_info('DENIC-99995');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:regacc="http://registry.denic.de/regacc/3.0"><regacc:info><regacc:handle>DENIC-99995</regacc:handle></regacc:info></registry-request>', 'Query RegAcc XML correct (version 3.0)');
is($rc->is_success(), 1, 'RegAcc successfully queried (version 3.0)');
is($dri->get_info('handle'),'DENIC-99995','regacc_info get_info(handle)');
is($dri->get_info('name'),'DENIC eG - Business Services','regacc_info get_info(name)');
is_deeply(scalar $dri->get_info('street'),['DENIC eG','Kaiserstraße 75-77'],'regacc_info get_info(self) street');
is($dri->get_info('pc'),'60329','regacc_info get_info(pc)');
is($dri->get_info('city'),'Frankfurt','regacc_info get_info(city)');
is($dri->get_info('cc'),'DE','regacc_info get_info(cc)');
is($dri->get_info('phone'),'+49 69 27235 0','regacc_info get_info(phone)');
is($dri->get_info('fax'),'+49 69 27235 235','regacc_info get_info(fax)');
is($dri->get_info('email'),'dbs@denic.de','regacc_info get_info(email)');
is($dri->get_info('url'),'http://www.denic.de','regacc_info get_info(url)');
is($dri->get_info('memberacc'),'DENIC-99995','regacc_info get_info(memberacc)');
$c=$dri->get_info('contact');
is_string($c->{'generalrequest'}->{'type'},'REQUEST','regacc_info get_info(contact) generalrequest type');
is_string($c->{'generalrequest'}->{'uri-template'},'mailto:general@denic.de?subject=domain:{Ulabel}','regacc_info get_info(contact) generalrequest uri-template');
is_string($c->{'generalrequest'}->{'changed'},'2019-01-01T01:00:00+01:00','regacc_info get_info(contact) generalrequest changed');
is_string($c->{'abusecontact'}->{'type'},'REQUEST','regacc_info get_info(contact) abusecontact type');
is_string($c->{'abusecontact'}->{'uri-template'},'mailto:abuse@denic.de?subject=domain:{Ulabel}','regacc_info get_info(contact) abusecontact uri-template');
is_string($c->{'abusecontact'}->{'changed'},'2019-01-01T01:00:00+01:00','regacc_info get_info(contact) abusecontact changed');
$d=$dri->get_info('changed');
isa_ok($d,'DateTime','regacc_info get_info(changed)');
is("".$d,'2019-05-17T10:48:29','regacc_info get_info(changed) value');
# similar as previous test but calling registrar_info() instead of regacc_info() - does the same (try to standardize command on Net-DRI)
$rc = $dri->registrar_info('DENIC-99995');
is_string($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/3.0" xmlns:regacc="http://registry.denic.de/regacc/3.0"><regacc:info><regacc:handle>DENIC-99995</regacc:handle></regacc:info></registry-request>', 'Query RegAcc XML correct (version 3.0)');
is($rc->is_success(), 1, 'RegAcc successfully queried (version 3.0)');
is($dri->get_info('handle'),'DENIC-99995','regacc_info get_info(handle)');
is($dri->get_info('name'),'DENIC eG - Business Services','regacc_info get_info(name)');

####################################################################################################

exit(0);
