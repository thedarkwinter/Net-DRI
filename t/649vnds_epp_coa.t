#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 4;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::ClientAttributes']});

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.tv</domain:name><domain:roid>EXAMPLE1-VRSN</domain:roid><domain:status s="ok"/><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>2011-02-04T15:44:37.0526Z</domain:crDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><coa:infData xmlns:coa="urn:ietf:params:xml:ns:coa-1.0"><coa:attr><coa:key>KEY1</coa:key><coa:value>value1</coa:value></coa:attr></coa:infData></extension>'.$TRID.'</response>'.$E2;
my $rc=$dri->domain_info('example.tv');
is_deeply($rc->get_data('client_attributes'),{'KEY1'=>'value1'},'domain_info + client object attributes parse');

$R2='';
$rc=$dri->domain_create('create.tv',{pure_create=>1,auth=>{pw=>'2fooBAR'},client_attributes=>{'KEY1'=>'value1'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>create.tv</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><coa:create xmlns:coa="urn:ietf:params:xml:ns:coa-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:coa-1.0 coa-1.0.xsd"><coa:attr><coa:key>KEY1</coa:key><coa:value>value1</coa:value></coa:attr></coa:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create + client object attributes build');

$rc=$dri->domain_update('update1.tv',$dri->local_object('changes')->add('client_attributes',{'KEY1'=>'value1'}));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>update1.tv</domain:name></domain:update></update><extension><coa:update xmlns:coa="urn:ietf:params:xml:ns:coa-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:coa-1.0 coa-1.0.xsd"><coa:put><coa:attr><coa:key>KEY1</coa:key><coa:value>value1</coa:value></coa:attr></coa:put></coa:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update + client object attributes build 1');


$rc=$dri->domain_update('update2.tv',$dri->local_object('changes')->del('client_attributes',['KEY1']));
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>update2.tv</domain:name></domain:update></update><extension><coa:update xmlns:coa="urn:ietf:params:xml:ns:coa-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:coa-1.0 coa-1.0.xsd"><coa:rem><coa:key>KEY1</coa:key></coa:rem></coa:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update + client object attributes build 2');

exit 0;
