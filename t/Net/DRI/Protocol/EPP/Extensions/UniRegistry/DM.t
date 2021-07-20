#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 46;
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

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_current_registry('UniRegistry::DM');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

### Greeting
$R2=$E1.'<greeting>
    <svID>ICM Production LAX1</svID>
    <svDate>2019-11-11T10:41:43.848Z</svDate>
    <svcMenu>
      <version>1.0</version>
      <lang>en</lang>
      <lang>es</lang>
      <lang>fr</lang>
      <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
      <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>
      <objURI>http://ns.uniregistry.net/eps-1.0</objURI>
      <svcExtension>
        <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>
        <extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:idn-1.0</extURI>
        <extURI>http://ns.uniregistry.net/centric-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:launch-1.0</extURI>
        <extURI>http://www.verisign.com/epp/sync-1.0</extURI>
        <extURI>urn:ietf:params:xml:ns:fee-0.7</extURI>
        <extURI>urn:afilias:params:xml:ns:association-1.0</extURI>
        <extURI>urn:afilias:params:xml:ns:ipr-1.1</extURI>
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
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'ICM Production LAX1','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2019-11-11T10:41:43','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','es','fr'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0','urn:ietf:params:xml:ns:contact-1.0','http://ns.uniregistry.net/eps-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7','urn:afilias:params:xml:ns:association-1.0','urn:afilias:params:xml:ns:ipr-1.1'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:idn-1.0','http://ns.uniregistry.net/centric-1.0','urn:ietf:params:xml:ns:launch-1.0','http://www.verisign.com/epp/sync-1.0','urn:ietf:params:xml:ns:fee-0.7','urn:afilias:params:xml:ns:association-1.0','urn:afilias:params:xml:ns:ipr-1.1'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');

### Login

$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 0}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>http://ns.uniregistry.net/centric-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>http://www.verisign.com/epp/sync-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI><extURI>urn:afilias:params:xml:ns:association-1.0</extURI><extURI>urn:afilias:params:xml:ns:ipr-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'Session login build only_local_extensions = 0');
is($rc->is_success(),1,'Session login is_success');


# enforce local extensions
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 1 }]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://ns.uniregistry.net/eps-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:fee-0.7</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'Session login build only_local_extensions = 1');
is($rc->is_success(),1,'Session login, only local, is_success');


## Logout
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');


#####################
## Notifications

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="10" id="123"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Launch Application LA_xyzabc-UR is now in status "pendingValidation"/"": default status for new launch domain objects</msg></msgQ>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'123','message_retrieve get_info(last_id)');
my  $lp = $dri->get_info('lp','message',123);
is($lp->{'application_id'},'LA_xyzabc-UR','message_retrieve get_info lp->{application_id}');
is($lp->{'status'},'pendingValidation','message_retrieve get_info lp->{status}');

# added after warning output from poll with <resData>
$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="9" id="124"><qDate>2014-02-01T16:00:00.000Z</qDate><msg>Transfer request abcde-007410 / CO_xxxx111122223333-ISC.</msg></msgQ><resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>abcde-007410</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>registrar_a</contact:reID><contact:reDate>2014-12-02T16:00:00.000Z</contact:reDate><contact:acID>registrar_b</contact:acID><contact:acDate>2014-12-07T16:00:00.000Z</contact:acDate></contact:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),'124','message_retrieve get_info(last_id)');
is($dri->get_info('reID','message',124),'registrar_a','message_retrieve get_info(reID)');

# message delete
$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->message_delete('b4d5ae3f-0014-4087-9a1e-a3a400bb202f');
is($rc->is_success(),1,'message_delete is_success');
is_string($R1,$E1.'<command><poll msgID="b4d5ae3f-0014-4087-9a1e-a3a400bb202f" op="ack"/><clTRID>ABC-12345</clTRID></command>'.$E2,'message_delete build xml');


#####################
## Domains

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.dm</domain:name></domain:cd><domain:cd><domain:name avail="0">examexample2.dm</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.dm','examexample2.dm');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.dm</domain:name><domain:name>examexample2.dm</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check .dm multi build');
is($rc->is_success(),1,'domain_check .dm multi is_success');
is($dri->get_info('exist','domain','example22.dm'),0,'domain_check .dm multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','examexample2.dm'),1,'domain_check .dm multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','examexample2.dm'),'In use','domain_check .dm multi get_info(exist_reason)');

# domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.dm</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example3.dm');
is($dri->get_info('action'),'info','domain_info get_info(action)');

# domain create (With Fee)
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>example3.dm</domain:name><domain:crDate>2010-08-10T15:38:26.623854Z</domain:crDate><domain:exDate>2012-08-10T15:38:26.623854Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:period unit="y">1</fee:period><fee:fee>5.00</fee:fee><fee:balance>-5.00</fee:balance><fee:creditLimit>1000.00</fee:creditLimit></fee:creData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_create('example3.dm',{pure_create=>1,auth=>{pw=>'2fooBAR'},duration=>DateTime::Duration->new(years=>2),fee=>{currency=>'USD',fee=>'5.00'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.dm</domain:name><domain:period unit="y">2</domain:period><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.7" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.7 fee-0.7.xsd"><fee:currency>USD</fee:currency><fee:fee>5.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is is_success');
is($dri->get_info('action'),'create','domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'USD','Fee extension: domain_create parse currency');
is($d->{fee},5.00,'Fee extension: domain_create parse fee');
is($d->{balance},-5.00,'Fee extension: domain_create parse balance');
is($d->{credit_limit},1000.00,'Fee extension: domain_create parse credit limit');

# domain update
$R2=$E1.'<response>' . r() . $TRID . '</response>' . $E2;
my $toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set('ns2.example.com'));
$rc=$dri->domain_update('example3.dm',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.dm</domain:name><domain:add><domain:ns><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns></domain:add></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build_xml');


##### Host
$R2=$E1.'<response>'.r().'<resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_create($dri->local_object('hosts')->add('ns101.example1.com',['193.0.2.2','193.0.2.29'],['2000:0:0:0:8:800:200C:417A']));
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
is($dri->get_info('action'),'create','host_create get_info(action)');
is($dri->get_info('exist'),1,'host_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_create get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_create get_info(crDate) value');

$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$toc->add('ip',$dri->local_object('hosts')->add('ns1.example1.com',['193.0.2.22'],[]));
$toc->add('status',$dri->local_object('status')->no('update'));
$toc->del('ip',$dri->local_object('hosts')->add('ns1.example1.com',[],['2000:0:0:0:8:800:200C:417A']));
$toc->set('name','ns104.example2.com');
$rc=$dri->host_update('ns103.example1.com',$toc);
is($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns103.example1.com</host:name><host:add><host:addr ip="v4">193.0.2.22</host:addr><host:status s="clientUpdateProhibited"/></host:add><host:rem><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:rem><host:chg><host:name>ns104.example2.com</host:name></host:chg></host:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->host_delete('ns102.example1.com');
is($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns102.example1.com</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'host_delete build');
is($rc->is_success(),1,'host_delete is_success');


exit 0;
