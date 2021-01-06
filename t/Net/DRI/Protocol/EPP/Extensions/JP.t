#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 7;
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
$dri->add_current_registry('GMORegistry::JPRS');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc, $co);

####################################################################################################
$R2=$E1.'<greeting><svID>GMO Registry EPP server EPP.GMOREGISTRY.NET</svID><svDate>2017-05-30T07:50:59.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.4</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:Gateway-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);

is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.5','Fee 0.5 loaded correctly');
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','SecDNS 1.1 loaded correctly');
####################################################################################################



####################################################################################################
### Contact create
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8015</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('TEST1');
$co->name('Nihongo Taro');
$co->org('Nihongo Inc.');
$co->street(['123 Abcde.','Suite 100']);
$co->city('Shibuya');
$co->sp('13');
$co->pc('111-2222');
$co->cc('JP');
$co->voice('+81.7035555555');
$co->fax('+81.7035555556');
$co->email('jdoe@example.com');
$co->auth({pw=>'password'});
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST1</contact:id><contact:postalInfo type="loc"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:voice>+81.7035555555</contact:voice><contact:fax>+81.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><jpex:create xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xmlns:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="registrant"/></jpex:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('action'),'create','contact_create get_info(action)');
is($dri->get_info('exist'),1,'contact_create get_info(exist)');
####################################################################################################

exit 0;
