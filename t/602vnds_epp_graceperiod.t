#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use Net::DRI::Data::Changes;
use DateTime;

use Test::More tests => 7;

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
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$toc);

#########################################################################################################
## Extension: GracePeriod

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example50.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:rgpStatus s="addPeriod"/></rgp:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example50.com',{auth=>{pw=>'2fooBAR'}});
is($dri->get_info('exist'),1,'domain_info get_info(exist) +RGP');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status) +RGP');
is_deeply([$s->list_status()],['addPeriod','ok'],'domain_info get_info(status) list +RGP');


$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'request'});
$rc=$dri->domain_update('example51.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example51.com</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="request"/></rgp:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_request');
is($rc->is_success(),1,'domain_update is_success +RGP');


$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('rgp',{ op => 'report', report => {predata=>'Pre-delete registration data goes here. Both XML and free text are allowed.', postdata=>'Post-restore registration data goes here. Both XML and free text are allowed.',deltime=>DateTime->new(year=>2003,month=>7,day=>10,hour=>22),restime=>DateTime->new(year=>2003,month=>7,day=>20,hour=>22),reason=>'Registrant error.',statement1=>'This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.',statement2=>'The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.',other=>'Supporting information goes here.' }});
$rc=$dri->domain_update('example52.com',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example52.com</domain:name></domain:update></update><extension><rgp:update xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd"><rgp:restore op="report"><rgp:report><rgp:preData>Pre-delete registration data goes here. Both XML and free text are allowed.</rgp:preData><rgp:postData>Post-restore registration data goes here. Both XML and free text are allowed.</rgp:postData><rgp:delTime>2003-07-10T22:00:00.0Z</rgp:delTime><rgp:resTime>2003-07-20T22:00:00.0Z</rgp:resTime><rgp:resReason>Registrant error.</rgp:resReason><rgp:statement>This registrar has not restored the Registered Name in order to assume the rights to use or sell the Registered Name for itself or for any third party.</rgp:statement><rgp:statement>The information in this report is true to best of this registrar\'s knowledge, and this registrar acknowledges that intentionally supplying false information in this report shall constitute an incurable material breach of the Registry-Registrar Agreement.</rgp:statement><rgp:other>Supporting information goes here.</rgp:other></rgp:report></rgp:restore></rgp:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build +RGP/restore_report');
is($rc->is_success(),1,'domain_update is_success +RGP');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
