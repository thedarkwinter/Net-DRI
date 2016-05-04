#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 16;
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
$dri->add_registry('NGTLD',{provider=>'knet'});
$dri->target('knet')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2,@fees);

####################################################################################################
## We use a greeting here to switch the namespace version here to -0.8 testing
$R2=$E1.'<greeting><svID>Minds + Machines EPP Server epp-dub.mm-registry.com</svID><svDate>2014-06-25T10:08:59.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.8</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.8','Fee 0.8 loaded correctly');
####################################################################################################

## fee-check-class
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">crrc.top</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.8" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.8 fee-0.8.xsd"><fee:cd><fee:name>crrc.top</fee:name><fee:currency>CNY</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee applied="delayed" description="Registration Fee" grace-period="P5D" refundable="1">100.00</fee:fee><fee:class>premium</fee:class></fee:cd></fee:chkData>    </extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('crrc.top',{fee=>{action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>crrc.top</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.8" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.8 fee-0.8.xsd"><fee:domain><fee:name>crrc.top</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check build');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'crrc.top','Fee extension: domain_check single parse domain');
is($d->{premium},1,'Fee extension: domain_check single parse premium');
is($d->{currency},'CNY','Fee extension: domain_check single parse currency');
is($d->{action},'create','Fee extension: domain_check single parse action');
is($d->{duration}->years(),1,'Fee extension: domain_check singe parse duration');
is($d->{fee},100.00,'Fee extension: domain_check singe parse fee');

## fee-create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>crrc.top</domain:name><domain:crDate>2016-04-11T07:31:58.0Z</domain:crDate><domain:exDate>2017-04-11T07:31:58.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.8"><fee:currency>CNY</fee:currency><fee:fee applied="delayed" grace-period="P8D" refundable="1">100.00</fee:fee><fee:balance>9664204.00</fee:balance></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('abc001');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'tech');
$cs->set($c1,'billing');
$rc=$dri->domain_create('crrc.top',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,auth=>{pw=>'abc123'},fee=>{currency=>'CNY',fee=>'100.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>crrc.top</domain:name><domain:period unit="y">1</domain:period><domain:registrant>abc001</domain:registrant><domain:contact type="admin">abc001</domain:contact><domain:contact type="billing">abc001</domain:contact><domain:contact type="tech">abc001</domain:contact><domain:authInfo><domain:pw>abc123</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.8" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.8 fee-0.8.xsd"><fee:currency>CNY</fee:currency><fee:fee>100.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_create build');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'CNY','Fee extension: domain_create parse currency');
is($d->{fee},100.00,'Fee extension: domain_create parse fee');
is($d->{balance},9664204.00,'Fee extension: domain_create parse balance');

####################################################################################################
exit 0;
