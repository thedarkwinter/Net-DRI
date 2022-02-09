#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 10;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CentralNic::RRPProxy');
$dri->target('CentralNic::RRPProxy')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2,$ns);

####################################################################################################

# domain info
$R2=$E1.'<response>'.r().'
    <resData>
     <domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
       <domain:name>example.am</domain:name>
       <domain:roid>2464151135031_DOMAIN-KEYSYS</domain:roid>
       <domain:status s="clientHold"/>
       <domain:status s="clientUpdateProhibited"/>
       <domain:registrant>P-JCD21</domain:registrant>
       <domain:contact type="admin">P-JID21</domain:contact>
       <domain:contact type="tech">P-JID21</domain:contact>
       <domain:contact type="billing">P-JID21</domain:contact>
       <domain:contact type="tech">P-JCD21</domain:contact>
       <domain:ns>
         <domain:hostObj>NS1.EXAMPLE.COM</domain:hostObj>
         <domain:hostObj>NS2.EXAMPLE.COM</domain:hostObj>
         <domain:hostObj>NS3.EXAMPLE.COM</domain:hostObj>
         <domain:hostObj>NS4.EXAMPLE.COM</domain:hostObj>
       </domain:ns>
       <domain:clID>reseller</domain:clID>
       <domain:crID>reseller</domain:crID>
       <domain:crDate>2016-12-27T13:46:20.0Z</domain:crDate>
       <domain:upID>reseller</domain:upID>
       <domain:upDate>2018-04-18T08:26:52.0Z</domain:upDate>
       <domain:exDate>2025-12-27T13:46:20.0Z</domain:exDate>
       <domain:authInfo>
         <domain:pw>2BARfoo2</domain:pw>
       </domain:authInfo>
     </domain:infData>
   </resData>
   <extension>
     <keysys:resData xmlns:keysys="http://www.key-systems.net/epp/keysys-1.0">
       <keysys:infData>
         <keysys:renDate>2026-01-31T13:46:20.0Z</keysys:renDate>
          <keysys:punDate>2025-12-27T13:46:20.0Z</keysys:punDate>
          <keysys:domain-roid>1850955283_DOMAIN_COM-VRSN</keysys:domain-roid>
          <keysys:renewalmode>DEFAULT</keysys:renewalmode>
          <keysys:transferlock>1</keysys:transferlock>
          <keysys:transfermode>DEFAULT</keysys:transfermode>
       </keysys:infData>
     </keysys:resData>
     <secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
        <secDNS:dsData>
          <secDNS:keyTag>51941</secDNS:keyTag>
          <secDNS:alg>8</secDNS:alg>
          <secDNS:digestType>2</secDNS:digestType>
          <secDNS:digest>96A73136C2362059487B60104F1A6F3C2877B7A9ED3873D9CE3DA76F297D45F9</secDNS:digest>
        </secDNS:dsData>
      </secDNS:infData>
   </extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example1.am');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('name'),'example1.am','domain_info get_info (name)');
is($dri->get_info('ks_renDate')->ymd,'2026-01-31','domain_info get_info (ks_renDate)');
is($dri->get_info('ks_punDate')->ymd,'2025-12-27','domain_info get_info (ks_punDate)');
is($dri->get_info('ks_domain-roid'),'1850955283_DOMAIN_COM-VRSN','domain_info get_info (ks_domain-roid)');
is($dri->get_info('ks_renewalmode'),'DEFAULT','domain_info get_info (ks_renewalmode)');
is($dri->get_info('ks_transferlock'),1,'domain_info get_info (ks_transferlock)');
is($dri->get_info('ks_transfermode'),'DEFAULT','domain_info get_info (ks_transfermode)');


## domain create
$R2='';
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('P-JCD21');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'tech');
$cs->set($c1,'billing');
$ns = $dri->local_object('hosts');
$ns->add('ns1.domaindiscount24.net',['193.219.115.46']),
$ns->add('ns2.domaindiscount24.net',['193.219.115.47']),
$ns->add('ns3.domaindiscount24.net',['193.219.115.48']),
$rc=$dri->domain_create('example2.am',{ pure_create  => 1,
	                                      duration     => DateTime::Duration->new(years=>2),
	                                      contact      => $cs,
	                                      ns           => $ns,
	                                      auth         => {pw=>'2fooBAR'},
                                      });

is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.am</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.domaindiscount24.net</domain:hostObj><domain:hostObj>ns2.domaindiscount24.net</domain:hostObj><domain:hostObj>ns3.domaindiscount24.net</domain:hostObj></domain:ns><domain:registrant>P-JCD21</domain:registrant><domain:contact type="admin">P-JCD21</domain:contact><domain:contact type="billing">P-JCD21</domain:contact><domain:contact type="tech">P-JCD21</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');

## domain update
$R2='';
$toc=Net::DRI::Data::Changes->new();
$toc->set('reg_type','foobar');
$rc=$dri->domain_update('example3.am',$toc);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.am</domain:name></domain:update></update><extension><regType:update xmlns:regType="urn:ietf:params:xml:ns:regtype-0.1" xsi:schemaLocation="urn:ietf:params:xml:ns:regtype-0.1 regtype-0.1.xsd"><regType:chg><regType:type>foobar</regType:type></regType:chg></regType:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

####################################################################################################
exit 0;
