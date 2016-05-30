#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 26;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}});
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['AusRegistry::Price','-VeriSign::NameStore','-VeriSign::IDNLanguage']});

my ($rc,$data);
my $dt5y=DateTime::Duration->new(years => 5);



$R2=$E1.'<response>'.r().'<extension><chkData xmlns="urn:ar:params:xml:ns:price-1.2"><cd><name>standard.com</name><category>STANDARD</category><period unit="y">5</period><createPrice>50</createPrice><renewPrice>50</renewPrice><transferPrice>5</transferPrice><restorePrice>40</restorePrice></cd><cd><name>lower.com</name><category>DISCOUNT CAT 1</category><period unit="y">5</period><createPrice>5</createPrice><renewPrice>5</renewPrice><transferPrice>1</transferPrice><restorePrice>40</restorePrice></cd><cd><name>higher.com</name><category>PREMIUM CAT 2</category><period unit="y">5</period><createPrice>500</createPrice><renewPrice>500</renewPrice><transferPrice>50</transferPrice><restorePrice>40</restorePrice></cd><cd><name>invalid.com</name><reason>Invalid domain name</reason></cd></chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check(qw/standard.com lower.com higher.com invalid.com/,{price => $dt5y});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>standard.com</domain:name><domain:name>lower.com</domain:name><domain:name>higher.com</domain:name><domain:name>invalid.com</domain:name></domain:check></check><extension><price:check xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:period unit="y">5</price:period></price:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
$data=$rc->get_data('domain','standard.com','price');
is($data->{category},'STANDARD','domain_check parse 1 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 1 period');
is($data->{create},50,'domain_check parse 1 createPrice');
is($data->{renew},50,'domain_check parse 1 renewPrice');
is($data->{transfer},5,'domain_check parse 1 transferPrice');
is($data->{restore},40,'domain_check parse 1 restorePrice');
$data=$rc->get_data('domain','lower.com','price');
is($data->{category},'DISCOUNT CAT 1','domain_check parse 2 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 2 period');
is($data->{create},5,'domain_check parse 2 createPrice');
is($data->{renew},5,'domain_check parse 2 renewPrice');
is($data->{transfer},1,'domain_check parse 2 transferPrice');
is($data->{restore},40,'domain_check parse 2 restorePrice');
$data=$rc->get_data('domain','higher.com','price');
is($data->{category},'PREMIUM CAT 2','domain_check parse 3 category');
is(DateTime::Duration->compare($data->{duration},$dt5y),0,'domain_check 3 period');
is($data->{create},500,'domain_check parse 3 createPrice');
is($data->{renew},500,'domain_check parse 3 renewPrice');
is($data->{transfer},50,'domain_check parse 3 transferPrice');
is($data->{restore},40,'domain_check parse 3 restorePrice');
$data=$rc->get_data('domain','invalid.com','price');
is_deeply($data,{reason=>'Invalid domain name'},'domain_check 4 reason');



$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('premium.com',{pure_create=>1,ns=>$dri->local_object('hosts')->set(['ns1.example.net'],['ns2.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},price=>'ack'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build 1');



$rc=$dri->domain_create('premium.com',{pure_create=>1,ns=>$dri->local_object('hosts')->set(['ns1.example.net'],['ns2.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},price=>100});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><price:create xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>100</price:price></price:ack></price:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build 2');



$rc=$dri->domain_transfer_start('premium.com',{auth=>{pw=>'2fooBAR'},price=>'ack'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build 1');



$rc=$dri->domain_transfer_start('premium.com',{auth=>{pw=>'2fooBAR'},price=>20});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><extension><price:transfer xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>20</price:price></price:ack></price:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_start build 2');



my $toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$rc=$dri->domain_update('premium.com',$toc,{ price => 'ack' });
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack/></price:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update rgp build 1');



$rc=$dri->domain_update('premium.com',$toc,{ price => 40 });
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>premium.com</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update><price:update xmlns:price="urn:ar:params:xml:ns:price-1.2" xsi:schemaLocation="urn:ar:params:xml:ns:price-1.2 price-1.2.xsd"><price:ack><price:price>40</price:price></price:ack></price:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update rgp build 2');


exit 0;
