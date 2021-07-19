#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
require "$FindBin::Bin/../../util.pl";

my $test = Net::DRI::Test->new_epp(['Nomulus::Metadata']);
my $dri = $test->dri();

####################################################################################################

my $rc;

$test->set_response();
$rc = $dri->domain_delete('delete.example', {metadata => {reason => 'domain-delete-test', requested_by_registrar => 0}});
is_string($test->get_command(),'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>delete.example</domain:name></domain:delete></delete><extension><metadata:metadata xmlns:metadata="urn:google:params:xml:ns:metadata-1.0" xsi:schemaLocation="urn:google:params:xml:ns:metadata-1.0 metadata-1.0.xsd"><metadata:reason>domain-delete-test</metadata:reason><metadata:requestedByRegistrar>false</metadata:requestedByRegistrar></metadata:metadata></extension><clTRID>ABC-12345</clTRID></command>', 'domain_delete build');



$test->set_response();
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('create.example',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},metadata=>{reason=>'domain-create-test', requested_by_registrar=>0}});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>create.example</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><metadata:metadata xmlns:metadata="urn:google:params:xml:ns:metadata-1.0" xsi:schemaLocation="urn:google:params:xml:ns:metadata-1.0 metadata-1.0.xsd"><metadata:reason>domain-create-test</metadata:reason><metadata:requestedByRegistrar>false</metadata:requestedByRegistrar></metadata:metadata></extension><clTRID>ABC-12345</clTRID></command>','domain_create build');



my $toc=$dri->local_object('changes');
$toc->set('metadata', {reason=>'domain-update-test', requested_by_registrar=>1});
$rc=$dri->domain_update('update.example', $toc);
is_string($test->get_command(),'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>update.example</domain:name></domain:update></update><extension><metadata:metadata xmlns:metadata="urn:google:params:xml:ns:metadata-1.0" xsi:schemaLocation="urn:google:params:xml:ns:metadata-1.0 metadata-1.0.xsd"><metadata:reason>domain-update-test</metadata:reason><metadata:requestedByRegistrar>true</metadata:requestedByRegistrar></metadata:metadata></extension><clTRID>ABC-12345</clTRID></command>', 'domain_update build');



exit 0;
