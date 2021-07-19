#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
require "$FindBin::Bin/../../util.pl";

my $test = Net::DRI::Test->new_epp(['Nomulus::Allocate']);
my $dri = $test->dri();

####################################################################################################

my $rc;


$test->set_response();
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('create.example',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'}, allocate=>{roid=>'SOMEID-42', application_time => $dri->local_object('datetime', year => 2010, month => 8, day => 16, hour => 10, time_zone => 'Z')}});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>create.example</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><allocate:create xmlns:allocate="urn:google:params:xml:ns:allocate-1.0" xsi:schemaLocation="urn:google:params:xml:ns:allocate-1.0 allocate-1.0.xsd"><allocate:applicationRoid>SOMEID-42</allocate:applicationRoid><allocate:applicationTime>2010-08-16T10:00:00Z</allocate:applicationTime></allocate:create></extension><clTRID>ABC-12345</clTRID></command>','domain_create build');


exit 0;
