#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 5;
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
$dri->add_registry('ICMRegistry');
$dri->target('XXX')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

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
$cs->add($dri->local_object('contact')->srid('C1-XXX'), 'registrant');
$cs->add($dri->local_object('contact')->srid('C2-XXX'), 'admin');
$cs->add($dri->local_object('contact')->srid('C3-XXX'), 'tech');
$cs->add($dri->local_object('contact')->srid('C4-XXX'), 'billing');
my $ns = $dri->local_object('hosts');
$ns->add('ns1.eppvalid.xxx');
$ns->add('ns2.eppvalid.xxx');
$rc = $dri->domain_create('epptest.xxx', {
                pure_create =>  1,
				contact =>	$cs,
				ns =>		$ns,
				auth =>		{ pw => 'bleblubleu' },
				association => { id => 'CX1-XXX', pw => 'acdcda' },
				ipr => { class => 'nonResolver' },
	});

$ext = '<extension><ipr:create xmlns:ipr="urn:afilias:params:xml:ns:ipr-1.1" xsi:schemaLocation="urn:afilias:params:xml:ns:ipr-1.1 ipr-1.1.xsd"><ipr:class>nonResolver</ipr:class></ipr:create><association:create xmlns:association="urn:afilias:params:xml:ns:association-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:association-1.0 association-1.0.xsd"><association:contact type="membership"><association:id>CX1-XXX</association:id><association:authInfo><association:pw>acdcda</association:pw></association:authInfo></association:contact></association:create></extension>';	
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.xxx</domain:name><domain:ns><domain:hostObj>ns1.eppvalid.xxx</domain:hostObj><domain:hostObj>ns2.eppvalid.xxx</domain:hostObj></domain:ns><domain:registrant>C1-XXX</domain:registrant><domain:contact type="admin">C2-XXX</domain:contact><domain:contact type="billing">C4-XXX</domain:contact><domain:contact type="tech">C3-XXX</domain:contact><domain:authInfo><domain:pw>bleblubleu</domain:pw></domain:authInfo></domain:create></create>'.$ext.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create +association build');
is($rc->is_success(),1,'domain_create +association is_success');

## Domain update
my $todo = $dri->local_object('changes');
$todo->add('association', { id => 'CX2-XXX', pw => '54321a' } );
$todo->del('association', { id => 'CX9-XXX' } );

$rc = $dri->domain_update('epptest.xxx', $todo);

$ext = '<extension><association:update xmlns:association="urn:afilias:params:xml:ns:association-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:association-1.0 association-1.0.xsd"><association:add><association:contact type="membership"><association:id>CX2-XXX</association:id><association:authInfo><association:pw>54321a</association:pw></association:authInfo></association:contact></association:add><association:rem><association:contact type="membership"><association:id>CX9-XXX</association:id></association:contact></association:rem></association:update></extension>';	
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.xxx</domain:name></domain:update></update>'.$ext.'<clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

## Domain info
$ext = '<extension><association:infData xmlns:association="urn:afilias:params:xml:ns:association-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:association-1.0 association-1.0.xsd"><association:contact type="membership"><association:id>CX1-XXX</association:id></association:contact></association:infData></extension>';	
$R2 = $E1 . '<response><result code="1000"><msg lang="en-US">Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>epptest.xxx</domain:name><domain:roid>U13423-XXX</domain:roid><domain:status s="ok"/><domain:registrant>C1-XXX</domain:registrant><domain:contact type="billing">C2-XXX</domain:contact><domain:contact type="tech">C3-XXX</domain:contact><domain:contact type="admin">C4-XXX</domain:contact><domain:ns><domain:hostObj>ns1.eppvalid.xxx</domain:hostObj><domain:hostObj>ns2.eppvalid.xxx</domain:hostObj></domain:ns><domain:clID>client1</domain:clID><domain:crID>client1</domain:crID><domain:crDate>2007-11-09T08:48:08.0Z</domain:crDate><domain:upID>client1</domain:upID><domain:upDate>2008-04-28T09:45:15.0Z</domain:upDate><domain:exDate>2012-11-09T08:48:08.0Z</domain:exDate><domain:authInfo><domain:pw>blablabla</domain:pw></domain:authInfo></domain:infData></resData>' .$ext  . $TRID . '</response>' . $E2;
$rc = $dri->domain_info('epptest.xxx');
my $as = $dri->get_info('association');
is ($as->{'id'},'CX1-XXX','domain_info association ID');

exit 0;
