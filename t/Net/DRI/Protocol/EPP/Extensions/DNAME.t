#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
require "$FindBin::Bin/../util.pl";

my $test = Net::DRI::Test->new_epp(['DNAME']);
my $dri = $test->dri();

####################################################################################################

my $rc;

$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>com.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="pendingCreate"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><dnameDeleg:dnameTarget xmlns:dnameDeleg="urn:ietf:params:xml:ns:dnameDeleg-1.0">foo.bar.example</dnameDeleg:dnameTarget></extension>');
$rc=$dri->domain_info('com.example');
is($rc->get_data('dname'),'foo.bar.example','domain_info get_data(dname)');



$test->set_response();
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('com.example',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},dname => 'foo.bar.example'});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>com.example</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><dnameDeleg:dnameTarget xmlns:dnameDeleg="urn:ietf:params:xml:ns:dnameDeleg-1.0">foo.bar.example</dnameDeleg:dnameTarget></extension><clTRID>ABC-12345</clTRID></command>','domain_create dname build');



my $toc=$dri->local_object('changes');
$toc->set('dname', 'foo.bar.example');
$rc=$dri->domain_update('com.example',$toc);
is_string($test->get_command(),'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>com.example</domain:name></domain:update></update><extension><dnameDeleg:dnameTarget xmlns:dnameDeleg="urn:ietf:params:xml:ns:dnameDeleg-1.0">foo.bar.example</dnameDeleg:dnameTarget></extension><clTRID>ABC-12345</clTRID></command>','domain_update dname build');



exit 0;
