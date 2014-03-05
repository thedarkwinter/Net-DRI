#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 3;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; } 
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('MOBI');
$dri->target('MOBI')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co);

####################################################################################################
## Domains

$R2='';
my $cs=$dri->local_object('contactset');
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$cs->set($c2,'billing');
$rc=$dri->domain_create('whatever.mobi',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'},maintainer_url=>'http://www.afilias.info'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>whatever.mobi</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><mobi:create xmlns:mobi="urn:afilias:params:xml:ns:ext:mobi-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:mobi-1.0 mobi-1.0.xsd"><mobi:maintainerUrl>http://www.afilias.info</mobi:maintainerUrl></mobi:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');


$R2='';
my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns2.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mak21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('publish','Payment overdue.'));
$toc->del('ns',$dri->local_object('hosts')->set('ns1.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('sh8013'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('update'));
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('auth',{pw=>'2BARfoo'});
$toc->set('maintainer_url','http://www.afilias.info');
$rc=$dri->domain_update('whatever.mobi',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>whatever.mobi</domain:name><domain:add><domain:ns><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:contact type="tech">mak21</domain:contact><domain:status lang="en" s="clientHold">Payment overdue.</domain:status></domain:add><domain:rem><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:contact type="tech">sh8013</domain:contact><domain:status s="clientUpdateProhibited"/></domain:rem><domain:chg><domain:registrant>sh8013</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><mobi:update xmlns:mobi="urn:afilias:params:xml:ns:ext:mobi-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:mobi-1.0 mobi-1.0.xsd"><mobi:maintainerUrl>http://www.afilias.info</mobi:maintainerUrl></mobi:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>whatever.mobi</domain:name><domain:roid>BARCA-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:contact type="billing">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.barca.cat</domain:host><domain:host>ns2.barca.cat</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2006-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>2006-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2007-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2006-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><mobi:infData xmlns:mobi="urn:afilias:params:xml:ns:ext:mobi-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ext:mobi-1.0 mobi-1.0.xsd"><mobi:maintainerUrl>http://www.afilias.info</mobi:maintainerUrl></mobi:infData></extension><trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID></response>'.$E2;
$rc=$dri->domain_info('whatever.mobi',{auth=>{pw=>'2fooBAR'}});
is($dri->get_info('maintainer_url'),'http://www.afilias.info','domain_info parse');

####################################################################################################

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
