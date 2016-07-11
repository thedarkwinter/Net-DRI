#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 6;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('UA');
$dri->target('UA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$co,$d,$toc,$co2,$cs);

####################################################################################################

$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

## Domain create with license

$R2='';
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('reg1'),'registrant');
$cs->set($dri->local_object('contact')->srid('adm1'),'admin');
$cs->set($dri->local_object('contact')->srid('bil1'),'billing');
$cs->set($dri->local_object('contact')->srid('tec1'),'tech');
$rc=$dri->domain_create('example123.ua', { pure_create=>1, duration=>DateTime::Duration->new(years=>5), contact=>$cs, auth=>{pw=>'2fooBAR'}, license => 'abc123'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="http://hostmaster.ua/epp/domain-1.1" xsi:schemaLocation="http://hostmaster.ua/epp/domain-1.1 domain-1.1.xsd"><domain:name>example123.ua</domain:name><domain:period unit="y">5</domain:period><domain:registrant>reg1</domain:registrant><domain:contact type="admin">adm1</domain:contact><domain:contact type="billing">bil1</domain:contact><domain:contact type="tech">tec1</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><uaepp:create xmlns:uaepp="http://hostmaster.ua/epp/uaepp-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hostmaster.ua/epp/uaepp-1.1 uaepp-1.1.xsd"><uaepp:license>abc123</uaepp:license></uaepp:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($rc->is_success(),1,'domain_create is_success');

## Host delete with no confirm key
$R2='';
$rc=$dri->host_delete('ns1.example123.ua');
is_string($R1,$E1.'<command><delete><host:delete xmlns:host="http://hostmaster.ua/epp/host-1.1" xsi:schemaLocation="http://hostmaster.ua/epp/host-1.1 host-1.1.xsd"><host:name>ns1.example123.ua</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

## Host delete with confirm key
$R2='';
$rc=$dri->host_delete('ns1.example123.ua', { confirm => 'yes'});
is_string($R1,$E1.'<command><delete><host:delete xmlns:host="http://hostmaster.ua/epp/host-1.1" xsi:schemaLocation="http://hostmaster.ua/epp/host-1.1 host-1.1.xsd"><host:name>ns1.example123.ua</host:name></host:delete></delete><extension><uaepp:delete xmlns:uaepp="http://hostmaster.ua/epp/uaepp-1.1"><uaepp:deleteNS confirm="yes"/></uaepp:delete></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');


exit 0;