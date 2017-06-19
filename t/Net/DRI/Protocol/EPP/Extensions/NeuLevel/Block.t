#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 8;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri,$rc,$s,$d,$dh,@c,$idn);

sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

$dri=Net::DRI::TrapExceptions->new({cache_ttl => -1, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
# $rc = $dri->add_registry('NGTLD',{provider => 'ari'});
# To use ARI extensions instead
$rc = $dri->add_current_registry('Neustar::Narwal');
$dri->add_current_profile('p2','epp_ari',{f_send=>\&mysend,f_recv=>\&myrecv});

#####################
## Block Extension

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example22.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData><extension><infData xmlns="urn:ar:params:xml:ns:block-1.0"><id>BLK-1</id></infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example22.menu',{block_id => 'BLK-1'});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example22.menu</domain:name></domain:info></info><extension><block:info xmlns:block="urn:ar:params:xml:ns:block-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:block-1.0 block-1.0.xsd"><block:id>BLK-1</block:id></block:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info block build_xml');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('name'),'example22.menu','domain_info get_info name');
is($dri->get_info('block_id'),'BLK-1','domain_info get_info name');

# domain create - # domain renew and domain transfer work exactly the same
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example23.menu</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData><extension><creData xmlns="urn:ar:params:xml:ns:block-1.0"><id>BLK-2</id></creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example23.menu',{pure_create=>1,auth=>{pw=>'2fooBAR'},block_id => 'BLK-2'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example23.menu</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><block:create xmlns:block="urn:ar:params:xml:ns:block-1.0" xsi:schemaLocation="urn:ar:params:xml:ns:block-1.0 block-1.0.xsd"><block:id>BLK-2</block:id></block:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create price build_xml');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('block_id'),'BLK-2','domain_info get_info name');

# domain renew & delete are the same
exit 0;
