#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Data::Dumper; # TODO: delete me when all done :p

use Test::More tests => 84;
use Test::Exception;
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

my ($rc, $co, $d, $s, $cs, $c1, $c2, $c3, $c4);

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

# lets see if validations are working
## sp field missing - mandatory for alloc registrant
delete $co->{'sp'};
throws_ok { $dri->contact_create($co) } qr/sp field is mandatory for registrant/, 'contact_create (Registrant) mandatory sp field missing';
## sp is not a 2 digit
$co->sp('123');
throws_ok { $dri->contact_create($co) } qr/sp is not a 2 digits number/, 'contact_create (Registrant) sp is not a 2 digits number 1/2';
$co->sp('foobar');
throws_ok { $dri->contact_create($co) } qr/sp is not a 2 digits number/, 'contact_create (Registrant) sp is not a 2 digits number 2/2';
# use invalid sp prefecture
$co->sp('50');
throws_ok { $dri->contact_create($co) } qr/sp is not a valid prefecture/, 'contact_create (Registrant) sp is not a valid Japonese prefecture';
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

####################################################################################################
### Contact transfers not available!
####################################################################################################
throws_ok { $dri->contact_transfer_start( $dri->local_object('contact')->srid('sh8017')->auth({pw=>'2fooBAR'}) ) } qr/No operation contact transfer_start available for registry GMORegistry::JPRS/, 'contact transfer operations not available';
####################################################################################################


####################################################################################################
### Domain create
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.jp</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('TEST1');
$c2=$dri->local_object('contact')->srid('TEST2');
$c3=$dri->local_object('contact')->srid('TEST3');
$c4=$dri->local_object('contact')->srid('TEST4');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c3,'tech');
$cs->set($c4,'billing');
note("invalid duration check: != 1 year");
throws_ok { $dri->domain_create('test.jp',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),contact=>$cs,auth=>{pw=>'2fooBAR'}}) } qr/Invalid duration/, 'domain create for 2 years invalid - only 1 year accepted';
# note("missing required suffix");
throws_ok { $dri->domain_create('test.jp',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,auth=>{pw=>'2fooBAR'}}) } qr/suffix is required/, 'domain create mandatory suffix is missing';
# note("invalid suffix");
throws_ok { $dri->domain_create('test.jp',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,auth=>{pw=>'2fooBAR'}, suffix=>'jpp'}) } qr/invalid suffi/, 'domain create invalid suffix usage';
$rc=$dri->domain_create('test.jp',{ pure_create=>1, contact=>$cs, auth=>{pw=>'2fooBAR'}, suffix=>'jp', alloc=>'public', handle=>'TEST5' });
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.jp</domain:name><domain:registrant>TEST1</domain:registrant><domain:contact type="admin">TEST2</domain:contact><domain:contact type="billing">TEST4</domain:contact><domain:contact type="tech">TEST3</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><jpex:create xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="public"><jpex:handle>TEST5</jpex:handle></jpex:contact></jpex:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create get_info(exDate) value');
####################################################################################################


####################################################################################################
### Domain update
####################################################################################################
$R2='';
my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set(['dns1.test.shop'],['dns2.test.shop']));
$toc->del('ns',$dri->local_object('hosts')->set(['dns1.test.com'],['dns2.test.com']));
$toc->add('secdns',{keyTag=>34567,alg=>8,digestType=>2,digest=>'1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF'});
$toc->set('suffix','jp');
$toc->set('alloc','public');
$toc->set('handle','TEST3');
$rc=$dri->domain_update('test.jp',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.jp</domain:name><domain:add><domain:ns><domain:hostObj>dns1.test.shop</domain:hostObj><domain:hostObj>dns2.test.shop</domain:hostObj></domain:ns></domain:add><domain:rem><domain:ns><domain:hostObj>dns1.test.com</domain:hostObj><domain:hostObj>dns2.test.com</domain:hostObj></domain:ns></domain:rem></domain:update></update><extension><jpex:update xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="public"><jpex:handle>TEST3</jpex:handle></jpex:contact></jpex:update><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:add><secDNS:dsData><secDNS:keyTag>34567</secDNS:keyTag><secDNS:alg>8</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');
####################################################################################################


####################################################################################################
### Domain info
####################################################################################################
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.jp</domain:name><domain:roid>DO123456-GMO</domain:roid><domain:status s="inactive"/><domain:registrant>TEST1-xxx</domain:registrant><domain:contact type="tech">TEST5-xxx</domain:contact><domain:contact type="admin">TEST5-xxx</domain:contact><domain:contact type="billing">TEST5-xxx</domain:contact><domain:clID>H12345</domain:clID><domain:crID>H12345</domain:crID><domain:crDate>2020-09-01T08:03:41.0Z</domain:crDate><domain:upDate>2020-09-01T08:12:02.0Z</domain:upDate><domain:exDate>2021-09-29T23:59:59.0Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><jpex:info xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp"/><jpex:contact alloc="public"><jpex:handle>TEST5-xxx</jpex:handle></jpex:contact></jpex:info></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('test.jp',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">test.jp</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'DO123456-GMO','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['inactive'],'domain_info get_info(status) list');
is($s->is_active(),0,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'TEST1-xxx','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'TEST5-xxx','domain_info get_info(contact) admin srid');
is($s->get('billing')->srid(),'TEST5-xxx','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'TEST5-xxx','domain_info get_info(contact) tech srid');
is($dri->get_info('clID'),'H12345','domain_info get_info(clID)');
is($dri->get_info('crID'),'H12345','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2020-09-01T08:03:41','domain_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2020-09-01T08:12:02','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2021-09-29T23:59:59','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
# jpex
is($dri->get_info('suffix'),'jp','domain_info get_info(suffix)');
is($dri->get_info('alloc'),'public','domain_info get_info(public)');
is($dri->get_info('handle'),'TEST5-xxx','domain_info get_info(handle)');
####################################################################################################


####################################################################################################
### TODO Domain delete (suspend date JPEX)
####################################################################################################


####################################################################################################
### TODO Domain update (restore JPEX)
####################################################################################################


####################################################################################################
### Domain transfer
####################################################################################################
$R2='';
$rc=$dri->domain_transfer_start('test.jp',{duration=>DateTime::Duration->new(years=>1),suffix=>'jp',ryid=>'TEST10',handle=>'TEST11'});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>test.jp</domain:name><domain:period unit="y">1</domain:period></domain:transfer></transfer><extension><jpex:transfer xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp" transfer="domain"/><jpex:contact alloc="registrant"><jpex:handle>TEST10</jpex:handle></jpex:contact><jpex:contact alloc="public"><jpex:handle>TEST11</jpex:handle></jpex:contact></jpex:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');


####################################################################################################
### Domain trade
####################################################################################################
$R2='';
$rc=$dri->domain_trade_start('trade.jp',{ryid=>'REG-90-0000-0001',handle=>'TEST12'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>trade.jp</domain:name><domain:period unit="y">0</domain:period></domain:transfer></transfer><extension><jpex:transfer xmlns:jpex="urn:ietf:params:xml:ns:jpex-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:jpex-1.0 jpex-1.0.xsd"><jpex:domain suffix="jp" transfer="registrant"/><jpex:contact alloc="registrant"><jpex:ryid>REG-90-0000-0001</jpex:ryid></jpex:contact><jpex:contact alloc="public"><jpex:handle>TEST12</jpex:handle></jpex:contact></jpex:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_trade_request build');

exit 0;
