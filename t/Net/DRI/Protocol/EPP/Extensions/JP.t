#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Data::Dumper; # TODO: delete me when all done :p

use Test::More tests => 40;
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

my ($rc, $co, $d, $s);

####################################################################################################
$R2=$E1.'<greeting>
    <svID>GMO Registry EPP server EPP-OTE.GMOREGISTRY.NET</svID>
    <svDate>2021-01-28T14:39:22.0Z</svDate>
    <svcMenu>
      <version>1.0</version>
      <lang>en</lang>
      <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
      <svcExtension>
        <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
        <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:fee-0.4</extURI>
        <extURI>urn:ietf:params:xml:ns:fee-0.5</extURI>
        <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:Gateway-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:jpex-1.0</extURI>
      </svcExtension>
    </svcMenu>
    <dcp>
      <access>
        <all/>
      </access>
      <statement>
        <purpose>
          <admin/>
          <prov/>
        </purpose>
        <recipient>
          <ours/>
          <public/>
        </recipient>
        <retention>
          <stated/>
        </retention>
      </statement>
    </dcp>
  </greeting>'.$E2;
$rc=$dri->process('session','noop',[]);

is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.5','Fee 0.5 loaded correctly');
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','SecDNS 1.1 loaded correctly');
####################################################################################################



####################################################################################################
### Contact create (Registrant)
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST1</contact:id><contact:crDate>2021-01-28T14:39:22.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
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
# jpex extension
$co->suffix('jp');
$co->alloc('registrant');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST1</contact:id><contact:postalInfo type="loc"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:voice>+81.7035555555</contact:voice><contact:fax>+81.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><jpex:create xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="registrant"/></jpex:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create (Registrant) build');
is($rc->is_success(),1,'contact_create  (Registrant) is_success');
is($dri->get_info('action'),'create','contact_create (Registrant) get_info(action)');
is($dri->get_info('exist'),1,'contact_create (Registrant) get_info(exist)');
####################################################################################################

####################################################################################################
### Contact create (Public)
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST5</contact:id><contact:crDate>2021-01-28T14:39:22.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('TEST5');
$co->name('Nihongo Taro');
$co->street(['123 Abcde.','Suite 100']);
$co->city('Shibuya');
$co->sp('13');
$co->pc('111-2222');
$co->cc('JP');
$co->voice('+81.7035555555');
$co->email('jdoe@example.com');
$co->auth({pw=>'password'});
# jpex extension
$co->suffix('jp');
$co->alloc('public');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST5</contact:id><contact:postalInfo type="loc"><contact:name>Nihongo Taro</contact:name><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="int"><contact:name>Nihongo Taro</contact:name><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:voice>+81.7035555555</contact:voice><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:create></create><extension><jpex:create xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="public"/></jpex:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create (Public) build');
is($rc->is_success(),1,'contact_create  (Public) is_success');
is($dri->get_info('action'),'create','contact_create (Public) get_info(action)');
is($dri->get_info('exist'),1,'contact_create (Public) get_info(exist)');
####################################################################################################



####################################################################################################
### Contact info
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST1</contact:id><contact:roid>HA00001-GMO</contact:roid><contact:status s="linked"/><contact:status s="serverDeleteProhibited"/><contact:postalInfo type="int"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:postalInfo type="loc"><contact:name>Nihongo Taro</contact:name><contact:org>Nihongo Inc.</contact:org><contact:addr><contact:street>123 Abcde.</contact:street><contact:street>Suite 100</contact:street><contact:city>Shibuya</contact:city><contact:sp>13</contact:sp><contact:pc>111-2222</contact:pc><contact:cc>JP</contact:cc></contact:addr></contact:postalInfo><contact:voice>+81.7035555555</contact:voice><contact:fax>+81.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>2020-09-01T17:01:13.0Z</contact:crDate><contact:upDate>2020-09-01T17:01:13.0Z</contact:upDate><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:infData></resData><extension><jpex:info xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="registrant"><jpex:ryid>REG-90-1234-5678</jpex:ryid></jpex:contact></jpex:info></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('TEST1')->auth({pw=>'password'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>TEST1</contact:id><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'TEST1','contact_info get_info(self) srid');
is($co->roid(),'HA00001-GMO','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['linked','serverDeleteProhibited'],'contact_info get_info(status) list_status');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'Nihongo Taro','contact_info get_info(self) name');
is($co->org(),'Nihongo Inc.','contact_info get_info(self) org');
is_deeply(scalar $co->street(),['123 Abcde.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Shibuya','contact_info get_info(self) city');
is($co->sp(),'13','contact_info get_info(self) sp');
is($co->pc(),'111-2222','contact_info get_info(self) pc');
is($co->cc(),'JP','contact_info get_info(self) cc');
is($co->voice(),'+81.7035555555','contact_info get_info(self) voice');
is($co->fax(),'+81.7035555556','contact_info get_info(self) fax');
is($co->email(),'jdoe@example.com','contact_info get_info(self) email');
is($dri->get_info('clID'),'ClientY','contact_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'2020-09-01T17:01:13','contact_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'2020-09-01T17:01:13','contact_info get_info(upDate) value');
is_deeply($co->auth(),{pw=>'password'},'contact_info get_info(self) auth');
# jpex extension
is($co->suffix(),'jp','contact_info get_info(self) suffix');
is($co->alloc(),'registrant','contact_info get_info(self) alloc');
is($co->ryid(),'REG-90-1234-5678','contact_info get_info(self) ryid');
####################################################################################################


exit 0;
