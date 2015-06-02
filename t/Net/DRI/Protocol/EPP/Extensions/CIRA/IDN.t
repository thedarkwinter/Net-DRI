#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 13;
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
$dri->add_registry('CIRA');
$dri->target('CIRA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $ro=$dri->remote_object('bundle');


$R2='';
$rc=$dri->domain_check(qw/abc123.ca xyz987.ca xn--r-wfan6a.ca/,{idn_table => 'fr'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>abc123.ca</domain:name><domain:name>xyz987.ca</domain:name><domain:name>xn--r-wfan6a.ca</domain:name></domain:check></check><extension><cira-idn:ciraIdnCheck xmlns:cira-idn="urn:ietf:params:xml:ns:cira-idn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-idn-1.0 cira-idn-1.0.xsd"><cira-idn:repertoire>fr</cira-idn:repertoire></cira-idn:ciraIdnCheck></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build with idn_table');



$R2='<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>xn--r-wfan6a.ca</domain:name><domain:roid>CIRA-lifecycle-00122</domain:roid><domain:status s="serverUpdateProhibited">change registrant</domain:status><domain:status s="serverDeleteProhibited" /><domain:status s="serverRenewProhibited" /><domain:status s="serverTransferProhibited" /><domain:status s="serverHold" /><domain:registrant>rant003</domain:registrant><domain:contact type="admin">admin003</domain:contact><domain:contact type="tech">tech003</domain:contact><domain:ns><domain:hostObj>ns1.example.ca</domain:hostObj><domain:hostObj>ns2.example.ca</domain:hostObj></domain:ns><domain:host>ns1.pc-case3.ca</domain:host><domain:host>ns2.pc-case3.ca</domain:host><domain:clID>rar600</domain:clID><domain:crID>rar600</domain:crID><domain:crDate>2012-12-08T16:25:01.0Z</domain:crDate><domain:exDate>2012-12-08T16:25:01.0Z</domain:exDate><domain:authInfo><domain:pw>password2</domain:pw></domain:authInfo></domain:infData></resData><extension><cira-idn:ciraIdnInfo xmlns:cira-idn="urn:ietf:params:xml:ns:cira-idn-1.0"><cira-idn:domainVariants><cira-idn:name>xn--r-wfan6a.ca</cira-idn:name><cira-idn:name>xn--cir-cla.ca</cira-idn:name><cira-idn:name>cira.ca</cira-idn:name></cira-idn:domainVariants></cira-idn:ciraIdnInfo></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('xn--r-wfan6a.ca');
is_deeply($rc->get_data('variants'),[qw/xn--r-wfan6a.ca xn--cir-cla.ca cira.ca/],'domain_info with domainVariants');



$R2='<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData></resData><extension><cira-idn-bundle:infData xmlns:cira-idn="urn:ietf:params:xml:ns:cira-idn-1.0" xmlns:cira-idn-bundle="urn:ietf:params:xml:ns:cira-idn-bundle-1.0"><cira-idn-bundle:canonicalDomainName>evaluation.ca</cira-idn-bundle:canonicalDomainName><cira-idn-bundle:roid>CIRA-123</cira-idn-bundle:roid><cira-idn-bundle:clID>rar600</cira-idn-bundle:clID><cira-idn-bundle:registrant>rant600</cira-idn-bundle:registrant><cira-idn-bundle:crID>rar600</cira-idn-bundle:crID><cira-idn-bundle:crDate>2012-12-08T16:25:01.0Z</cira-idn-bundle:crDate><cira-idn-bundle:upID>rar600</cira-idn-bundle:upID><cira-idn-bundle:upDate>2012-12-08T17:25:01.0Z</cira-idn-bundle:upDate><cira-idn-bundle:bundleDomains><cira-idn:name>evaluation.ca</cira-idn:name><cira-idn:name>xn--valuation-93a.ca</cira-idn:name><cira-idn:name>xn--valution-2ya9f.ca</cira-idn:name></cira-idn-bundle:bundleDomains></cira-idn-bundle:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$ro->info('xn--valuation-93a.ca',{ idn_table => 'fr' });
is_string($R1,$E1.'<command><info><cira-idn-bundle:info xmlns:cira-idn-bundle="urn:ietf:params:xml:ns:cira-idn-bundle-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-idn-bundle-1.0 cira-idn-bundle-1.0.xsd"><cira-idn-bundle:name>xn--valuation-93a.ca</cira-idn-bundle:name><cira-idn-bundle:repertoire>fr</cira-idn-bundle:repertoire></cira-idn-bundle:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'bundle_info build');
is($rc->get_data('bundle','xn--valuation-93a.ca','canonical_domain_name'),'evaluation.ca','bundle_info get_data canonical_domain_name');
is($rc->get_data('bundle','xn--valuation-93a.ca','roid'),'CIRA-123','bundle_info get_data roid');
is($rc->get_data('bundle','xn--valuation-93a.ca','clID'),'rar600','bundle_info get_data clID');
is($rc->get_data('bundle','xn--valuation-93a.ca','contact')->get('registrant')->srid(),'rant600','bundle_info get_data registrant');
is($rc->get_data('bundle','xn--valuation-93a.ca','crID'),'rar600','bundle_info get_data crID');
is(''.$rc->get_data('bundle','xn--valuation-93a.ca','crDate'),'2012-12-08T16:25:01','bundle_info get_data crDate');
is($rc->get_data('bundle','xn--valuation-93a.ca','upID'),'rar600','bundle_info get_data upID');
is(''.$rc->get_data('bundle','xn--valuation-93a.ca','upDate'),'2012-12-08T17:25:01','bundle_info get_data upDate');
is_deeply($rc->get_data('bundle','xn--valuation-93a.ca','variants'),[qw/evaluation.ca xn--valuation-93a.ca xn--valution-2ya9f.ca/],'bundle_info get_data variants');



my $ns=$dri->local_object('hosts');
$ns->add('hostname.example.net');
$ns->add('hostname.example.com');
my $cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact')->srid('contactid-1');
$cs->set($co,'registrant');
$cs->set($co,'admin');
$cs->add($dri->local_object('contact')->srid('nbguy'),'tech');
$cs->add($dri->local_object('contact')->srid('nbtech'),'tech');
$cs->add($dri->local_object('contact')->srid('nbadmin'),'tech');
$rc=$dri->domain_create('xn--r-wfan6a.ca',{ pure_create => 1, duration => $dri->local_object('duration',years => 2), ns => $ns, contact => $cs, auth => { pw => 'password' }, idn_table => 'fr', ulabel => 'cira.ca' });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--r-wfan6a.ca</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>hostname.example.net</domain:hostObj><domain:hostObj>hostname.example.com</domain:hostObj></domain:ns><domain:registrant>contactid-1</domain:registrant><domain:contact type="admin">contactid-1</domain:contact><domain:contact type="tech">nbguy</domain:contact><domain:contact type="tech">nbtech</domain:contact><domain:contact type="tech">nbadmin</domain:contact><domain:authInfo><domain:pw>password</domain:pw></domain:authInfo></domain:create></create><extension><cira-idn:ciraIdnCreate xmlns:cira-idn="urn:ietf:params:xml:ns:cira-idn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:cira-idn-1.0 cira-idn-1.0.xsd"><cira-idn:repertoire>fr</cira-idn:repertoire><cira-idn:u-label>cira.ca</cira-idn:u-label></cira-idn:ciraIdnCreate></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build with idn_table');



exit 0;
