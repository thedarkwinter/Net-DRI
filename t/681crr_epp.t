#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;


use Test::More tests => 20;
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

#$dri->add_registry('NGTLD',{provider=>'crr'});
#$dri->target('crr')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
$dri->add_registry('CRR'); # For fun we are going to go old school DRD on this
$dri->target('CRR')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2);

####################################################################################################
## CRR (Charleston Road Registry) Uses the 0.6 version of Gavin Browns (CentralNic) extension. We use a greeting here to switch the namespace version here to 0.6
$R2=$E1.'<greeting><svID>CRR EPP Server epp.charlestonroadregistry.com</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.6</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.6','Fee 0.6 loaded correctly');

####################################################################################################

# EPP <info> Command
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foo.android</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok" /><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.foo.android</domain:host><domain:host>ns2.foo.android</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><fee:infData xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period><fee:fee refundable="1" grace-period="P5D" applied="immediate">10.00</fee:fee><fee:class>premium-tier1</fee:class></fee:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('foo.android',{fee=>{currency=>'USD',phase=>'sunrise',action=>'create',duration=>$dri->local_object('duration','years',1)}});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">foo.android</domain:name></domain:info></info><extension><fee:info xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:currency>USD</fee:currency><fee:command phase="sunrise">create</fee:command><fee:period unit="y">1</fee:period></fee:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_info build');
$rc=$dri->domain_info('foo.android');
is($rc->is_success(),1,'domain_info is is_success');
is($dri->get_info('action'),'info','domain_info get_info (action)');
is($dri->get_info('name'),'foo.android','domain_info get_info (name)');
my @fees = @{$dri->get_info('fee')};
$d = $fees[0];
is($d->{currency},'USD','Fee extension: domain_info parse currency');
is($d->{action},'create','Fee extension: domain_info parse action');
is($d->{phase},'sunrise','Fee extension: domain_info parse phase');
is($d->{duration}->years(),1,'Fee extension: domain_info parse duration');
is($d->{fee},10.00,'Fee extension: domain_info parse fee');
is($d->{description},'Refundable(Grace=>P5D)(Applied=>immediate)','Fee extension: domain_info parse human-readable description');
is($d->{class},'premium-tier1','Fee extension: domain_info parse classe');

# using the standardised methods
is($dri->get_info('is_premium'),undef,'domain_check get_info (is_premium) undef'); # NOT SUPPORTED
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'10','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),undef,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),undef,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

exit 0;
