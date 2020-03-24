#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;
require "$FindBin::Bin/../../util.pl";

my $test = Net::DRI::Test->new_epp(['GracePeriod', 'AusRegistry::Price']);
my $dri = $test->dri();

use Test::More tests => 26;

my ($rc,$data);
my $dt5y=DateTime::Duration->new(years => 5);



$test->set_response('<extension><chkData xmlns="urn:ar:params:xml:ns:price-1.2"><cd><name>standard.example</name><category>STANDARD</category><period unit="y">5</period><createPrice>50</createPrice><renewPrice>50</renewPrice><transferPrice>5</transferPrice><restorePrice>40</restorePrice></cd><cd><name>lower.example</name><category>DISCOUNT CAT 1</category><period unit="y">5</period><createPrice>5</createPrice><renewPrice>5</renewPrice><transferPrice>1</transferPrice><restorePrice>40</restorePrice></cd><cd><name>higher.example</name><category>PREMIUM CAT 2</category><period unit="y">5</period><createPrice>500</createPrice><renewPrice>500</renewPrice><transferPrice>50</transferPrice><restorePrice>40</restorePrice></cd><cd><name>invalid.example</name><reason>Invalid domain name</reason></cd></chkData></extension>');
$rc=$dri->domain_check(qw/standard.example lower.example higher.example invalid.example/,{price => $dt5y});
is_string($test->get_command(), '<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>standard.example</domain:name><domain:name>lower.example</domain:name><domain:name>higher.example</domain:name><domain:name>invalid.example</domain:name></domain:check></check><extension><price:check xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:period unit="y">5</price:period></price:check></extension><clTRID>ABC-12345</clTRID></command>','domain_check build');
$data=$rc->get_data('domain','standard.example','price');
is($data->{category},'STANDARD','domain_check parse 1 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 1 period');
is($data->{create},50,'domain_check parse 1 createPrice');
is($data->{renew},50,'domain_check parse 1 renewPrice');
is($data->{transfer},5,'domain_check parse 1 transferPrice');
is($data->{restore},40,'domain_check parse 1 restorePrice');
$data=$rc->get_data('domain','lower.example','price');
is($data->{category},'DISCOUNT CAT 1','domain_check parse 2 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 2 period');
is($data->{create},5,'domain_check parse 2 createPrice');
is($data->{renew},5,'domain_check parse 2 renewPrice');
is($data->{transfer},1,'domain_check parse 2 transferPrice');
is($data->{restore},40,'domain_check parse 2 restorePrice');
$data=$rc->get_data('domain','higher.example','price');
is($data->{category},'PREMIUM CAT 2','domain_check parse 3 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 3 period');
is($data->{create},500,'domain_check parse 3 createPrice');
is($data->{renew},500,'domain_check parse 3 renewPrice');
is($data->{transfer},50,'domain_check parse 3 transferPrice');
is($data->{restore},40,'domain_check parse 3 restorePrice');
$data=$rc->get_data('domain','invalid.example','price');
is_deeply($data,{reason=>'Invalid domain name'},'domain_check 4 reason');



my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('premium.example',{pure_create=>1,ns=>$dri->local_object('hosts')->set(['ns1.example.net'],['ns2.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},price=>'ack'});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack/></price:create></extension><clTRID>ABC-12345</clTRID></command>','domain_create build 1');



$rc=$dri->domain_create('premium.example',{pure_create=>1,ns=>$dri->local_object('hosts')->set(['ns1.example.net'],['ns2.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},price=>100});
is_string($test->get_command(),'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack><price:price>100</price:price></price:ack></price:create></extension><clTRID>ABC-12345</clTRID></command>','domain_create build 2');



$rc=$dri->domain_transfer_start('premium.example',{auth=>{pw=>'2fooBAR'},price=>'ack'});
is_string($test->get_command(),'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack/></price:transfer></extension><clTRID>ABC-12345</clTRID></command>','domain_transfer_start build 1');



$rc=$dri->domain_transfer_start('premium.example',{auth=>{pw=>'2fooBAR'},price=>20});
is_string($test->get_command(),'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack><price:price>20</price:price></price:ack></price:transfer></extension><clTRID>ABC-12345</clTRID></command>','domain_transfer_start build 2');



my $toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$rc=$dri->domain_update('premium.example',$toc,{ price => 'ack' });
is_string($test->get_command(),'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name></domain:update></update><extension><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack/></price:update><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:restore op="request"/></rgp:update></extension><clTRID>ABC-12345</clTRID></command>','domain_update rgp build 1');



$rc=$dri->domain_update('premium.example',$toc,{ price => 40 });
is_string($test->get_command(),'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>premium.example</domain:name></domain:update></update><extension><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2"><price:ack><price:price>40</price:price></price:ack></price:update><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0"><rgp:restore op="request"/></rgp:update></extension><clTRID>ABC-12345</clTRID></command>','domain_update rgp build 2');


exit 0;