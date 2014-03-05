#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Test::More tests => 4;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };

use Net::DRI::DRD::VNDS;
{
 no strict;
 no warnings;
 sub Net::DRI::DRD::VNDS::tlds { return ('e164.arpa'); };
 sub Net::DRI::DRD::VNDS::verify_name_domain { return ''; };
}

$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['E164']});

my ($rc,$e,$toc);

#########################################################################################################
## Extension: E164

## (see Erratum)
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><e164:infData xmlns:e164="urn:ietf:params:xml:ns:e164epp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:e164epp-1.0 e164epp-1.0.xsd"><e164:naptr><e164:order>10</e164:order><e164:pref>100</e164:pref><e164:flags>u</e164:flags><e164:svc>E2U+sip</e164:svc><e164:regex>"!^.*$!sip:info@example.com!"</e164:regex></e164:naptr><e164:naptr><e164:order>10</e164:order><e164:pref>102</e164:pref><e164:flags>u</e164:flags><e164:svc>E2U+msg</e164:svc><e164:regex>"!^.*$!mailto:info@example.com!"</e164:regex></e164:naptr></e164:infData></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->domain_info('3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa',{auth=>{pw=>'2fooBAR'}});
is($dri->get_info('exist'),1,'domain_info get_info(exist) +E164');
$e=$dri->get_info('e164');
is_deeply($e,[{order=>10,pref=>100,flags=>'u',svc=>'E2U+sip',regex=>'"!^.*$!sip:info@example.com!"'},{order=>10,pref=>102,flags=>'u',svc=>'E2U+msg',regex=>'"!^.*$!mailto:info@example.com!"'}],'domain_info get_info(e164) +E164');

$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create('3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']),contact=>$cs,auth=>{pw=>'2fooBAR'},e164=>[{order=>10,pref=>100,flags=>'u',svc=>'E2U+sip',regex=>'"!^.*$!sip:info@example.com!"'},{order=>10,pref=>102,flags=>'u',svc=>'E2U+msg',regex=>'"!^.*$!mailto:info@example.com!"'}]});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><e164:create xmlns:e164="urn:ietf:params:xml:ns:e164epp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:e164epp-1.0 e164epp-1.0.xsd"><e164:naptr><e164:order>10</e164:order><e164:pref>100</e164:pref><e164:flags>u</e164:flags><e164:svc>E2U+sip</e164:svc><e164:regex>"!^.*$!sip:info@example.com!"</e164:regex></e164:naptr><e164:naptr><e164:order>10</e164:order><e164:pref>102</e164:pref><e164:flags>u</e164:flags><e164:svc>E2U+msg</e164:svc><e164:regex>"!^.*$!mailto:info@example.com!"</e164:regex></e164:naptr></e164:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build +E164');

$R2='';
$toc=$dri->local_object('changes');
$toc->del('e164',[{order=>10,pref=>102,flags=>'u',svc=>'E2U+msg',regex=>'"!^.*$!mailto:info@example.com!"'}]);
$rc=$dri->domain_update('3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>3.8.0.0.6.9.2.3.6.1.4.4.e164.arpa</domain:name></domain:update></update><extension><e164:update xmlns:e164="urn:ietf:params:xml:ns:e164epp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:e164epp-1.0 e164epp-1.0.xsd"><e164:rem><e164:naptr><e164:order>10</e164:order><e164:pref>102</e164:pref><e164:flags>u</e164:flags><e164:svc>E2U+msg</e164:svc><e164:regex>"!^.*$!mailto:info@example.com!"</e164:regex></e164:naptr></e164:rem></e164:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +E164');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
