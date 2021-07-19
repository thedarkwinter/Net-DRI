#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use FindBin;
require "$FindBin::Bin/../util.pl";

my $test = Net::DRI::Test->new_epp(['ArtRecord']);
my $dri = $test->dri();

####################################################################################################

my $rc;

$test->set_response('<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>com.example</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="pendingCreate"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2012-04-03T22:00:00.0Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><artRecord:infData xmlns:artRecord="urn:ietf:params:xml:ns:artRecord-0.1"><artRecord:objectType>[TBA1]</artRecord:objectType><artRecord:materialsAndTechniques>[TBA2]</artRecord:materialsAndTechniques><artRecord:dimensions>[TBA3]</artRecord:dimensions><artRecord:title>[TBA4]</artRecord:title><artRecord:dateOrPeriod>[TBA5]</artRecord:dateOrPeriod><artRecord:maker>[TBA6]</artRecord:maker><artRecord:reference>[TBA7]</artRecord:reference></artRecord:infData></extension>');
$rc=$dri->domain_info('com.example');
my $rart=$rc->get_data('art_record');
is($rart->{object_type}, '[TBA1]', 'art_record object_type');
is($rart->{materials_and_techniques}, '[TBA2]', 'art_record materials_and_techniques');
is($rart->{dimensions}, '[TBA3]', 'art_record dimensions');
is($rart->{title}, '[TBA4]', 'art_record title');
is($rart->{date_or_period}, '[TBA5]', 'art_record date_or_period');
is($rart->{maker}, '[TBA6]', 'art_record maker');
is($rart->{reference}, '[TBA7]', 'art_record reference');



$test->set_response();
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
my %art=(object_type              => '[TBA1]',
         materials_and_techniques => '[TBA2]',
         dimensions               => '[TBA3]',
         title                    => '[TBA4]',
         date_or_period           => '[TBA5]',
         maker                    => '[TBA6]',
         reference                => '[TBA7]',
       );
$rc=$dri->domain_create('com.example',{pure_create=>1,contact=>$cs,auth=>{pw=>'2fooBAR'},art_record => \%art});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>com.example</domain:name><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><artRecord:create xmlns:artRecord="urn:ietf:params:xml:ns:artRecord-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:artRecord-0.1 artRecord-0.1.xsd"><artRecord:objectType>[TBA1]</artRecord:objectType><artRecord:materialsAndTechniques>[TBA2]</artRecord:materialsAndTechniques><artRecord:dimensions>[TBA3]</artRecord:dimensions><artRecord:title>[TBA4]</artRecord:title><artRecord:dateOrPeriod>[TBA5]</artRecord:dateOrPeriod><artRecord:maker>[TBA6]</artRecord:maker><artRecord:reference>[TBA7]</artRecord:reference></artRecord:create></extension><clTRID>ABC-12345</clTRID></command>','domain_create dname build');



my $toc=$dri->local_object('changes');
$toc->set('art_record', \%art);
$rc=$dri->domain_update('com.example',$toc);
is_string($test->get_command(),'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>com.example</domain:name></domain:update></update><extension><artRecord:update xmlns:artRecord="urn:ietf:params:xml:ns:artRecord-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:artRecord-0.1 artRecord-0.1.xsd"><artRecord:objectType>[TBA1]</artRecord:objectType><artRecord:materialsAndTechniques>[TBA2]</artRecord:materialsAndTechniques><artRecord:dimensions>[TBA3]</artRecord:dimensions><artRecord:title>[TBA4]</artRecord:title><artRecord:dateOrPeriod>[TBA5]</artRecord:dateOrPeriod><artRecord:maker>[TBA6]</artRecord:maker><artRecord:reference>[TBA7]</artRecord:reference></artRecord:update></extension><clTRID>ABC-12345</clTRID></command>','domain_update dname build');



exit 0;
