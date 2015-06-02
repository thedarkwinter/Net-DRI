#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 6;
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
$dri->add_registry('Telnic');
$dri->target('TEL')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my $ext;
my ($dh, @c);


####################################################################################################
## Association domain operations
## Domain create

$R2 = $E1 . "<response><result code='1000'><msg lang='en-US'>Command completed successfully</msg></result>" . $TRID . '</response>' . $E2;
my $cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('C1-tel'), 'registrant');
$cs->add($dri->local_object('contact')->srid('C2-tel'), 'admin');
$cs->add($dri->local_object('contact')->srid('C3-tel'), 'tech');
$cs->add($dri->local_object('contact')->srid('C4-tel'), 'billing');
my $ns = $dri->local_object('hosts');
$ns->add('ns1.eppvalid.tel');
$ns->add('ns2.eppvalid.tel');
$rc = $dri->domain_create('epptest.tel', {
                pure_create =>  1,
				contact =>	$cs,
				ns =>		$ns,
				auth =>		{ pw => 'bleblubleu' },
				whois_type => { type => 'natural', publish => 'n'},
	});

$ext = '<extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>WhoisType=NATURAL Publish=N</neulevel:unspec></neulevel:extension></extension>';	
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.tel</domain:name><domain:ns><domain:hostObj>ns1.eppvalid.tel</domain:hostObj><domain:hostObj>ns2.eppvalid.tel</domain:hostObj></domain:ns><domain:registrant>C1-tel</domain:registrant><domain:contact type="admin">C2-tel</domain:contact><domain:contact type="billing">C4-tel</domain:contact><domain:contact type="tech">C3-tel</domain:contact><domain:authInfo><domain:pw>bleblubleu</domain:pw></domain:authInfo></domain:create></create>'.$ext.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');

## Domain update
my $todo = $dri->local_object('changes');
$todo->set('whois_type', {type=>'LEGAL',publish=>'y'});
$rc = $dri->domain_update('epptest.tel', $todo);

$ext = '<extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>WhoisType=LEGAL</neulevel:unspec></neulevel:extension></extension>';	
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.tel</domain:name></domain:update></update>'.$ext.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

## Domain info
$ext = '<extension><neulevel:extension xmlns="urn:ietf:params:xml:ns:neulevel-1.0" xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>WhoisType=Legal Publish=Y</neulevel:unspec></neulevel:extension></extension>';
$R2 = $E1 . '<response><result code="1000"><msg lang="en-US">Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.tel</domain:name><domain:roid>U13423-tel</domain:roid><domain:status s="ok"/><domain:registrant>C1-tel</domain:registrant><domain:contact type="billing">C2-tel</domain:contact><domain:contact type="tech">C3-tel</domain:contact><domain:contact type="admin">C4-tel</domain:contact><domain:ns><domain:hostObj>ns1.eppvalid.tel</domain:hostObj><domain:hostObj>ns2.eppvalid.tel</domain:hostObj></domain:ns><domain:clID>client1</domain:clID><domain:crID>client1</domain:crID><domain:crDate>2007-11-09T08:48:08.0Z</domain:crDate><domain:upID>client1</domain:upID><domain:upDate>2008-04-28T09:45:15.0Z</domain:upDate><domain:exDate>2012-11-09T08:48:08.0Z</domain:exDate><domain:authInfo><domain:pw>blablabla</domain:pw></domain:authInfo></domain:infData></resData>' .$ext  . $TRID . '</response>' . $E2;
$rc = $dri->domain_info('epptest.tel');
my $wt = $dri->get_info('whois_type');
is($wt->{'type'},'Legal','domain_info whois_type');
is($wt->{'publish'},'Y','domain_info whoisPublish');

exit 0;
