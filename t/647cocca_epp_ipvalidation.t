#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 2;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport, $count, $msg) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }


my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('CoCCA');
$dri->target('CoCCA')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['CoCCA::IPVerification']});


$R2='';
my $rc=$dri->domain_create('mychipdomain.cx',{pure_create => 1, duration => $dri->local_object('duration',years => 1),contact=>$dri->local_object('contactset')->add($dri->local_object('contact')->srid('regis-AmQyW885sq'),'registrant'),auth=>{pw=>'nHOiQttnHO'},chip=>'CHIP Code'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mychipdomain.cx</domain:name><domain:period unit="y">1</domain:period><domain:registrant>regis-AmQyW885sq</domain:registrant><domain:authInfo><domain:pw>nHOiQttnHO</domain:pw></domain:authInfo></domain:create></create><extension><cocca:extension xmlns:cocca="https://production.coccaregistry.net/cocca-ip-verification-1.1" xsi:schemaLocation="https://production.coccaregistry.net/cocca-ip-verification-1.1 cocca-ip-verification-1.1.xsd"><cocca:chip><cocca:code>CHIP Code</cocca:code></cocca:chip></cocca:extension></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create with chip code');

$rc=$dri->domain_create('mychipdomain.cx',{pure_create => 1, duration => $dri->local_object('duration',years => 1),contact=>$dri->local_object('contactset')->add($dri->local_object('contact')->srid('regis-AmQyW885sq'),'registrant'),auth=>{pw=>'nHOiQttnHO'},trademark=>[{trademark_name=>'Trademarked Name',trademark_number=>'1234',trademark_locality=>'NZ',trademark_entitlement=>'OWNER'},{trademark_name=>'Trademarked Name',trademark_number=>'5678',trademark_locality=>'AU',trademark_entitlement=>'ASSIGNEE',legal_id=>'9090'}]});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>mychipdomain.cx</domain:name><domain:period unit="y">1</domain:period><domain:registrant>regis-AmQyW885sq</domain:registrant><domain:authInfo><domain:pw>nHOiQttnHO</domain:pw></domain:authInfo></domain:create></create><extension><cocca:extension xmlns:cocca="https://production.coccaregistry.net/cocca-ip-verification-1.1" xsi:schemaLocation="https://production.coccaregistry.net/cocca-ip-verification-1.1 cocca-ip-verification-1.1.xsd"><cocca:trademarks><cocca:trademark><cocca:registeredMark>Trademarked Name</cocca:registeredMark><cocca:registrationNumber>1234</cocca:registrationNumber><cocca:registrationLocality>NZ</cocca:registrationLocality><cocca:capacity>OWNER</cocca:capacity></cocca:trademark><cocca:trademark><cocca:registeredMark>Trademarked Name</cocca:registeredMark><cocca:registrationNumber>5678</cocca:registrationNumber><cocca:registrationLocality>AU</cocca:registrationLocality><cocca:capacity>ASSIGNEE</cocca:capacity><cocca:companyNumber>9090</cocca:companyNumber></cocca:trademark></cocca:trademarks></cocca:extension></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create with 2 trademarks');

exit 0;

