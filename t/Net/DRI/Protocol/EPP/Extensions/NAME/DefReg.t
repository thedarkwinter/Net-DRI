#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Data::Dumper;

use Test::More tests => 63;
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
$dri->add_registry('NAME');
$dri->target('NAME')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{});

my ($rc,$s,$cs);

########################################################################################################

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>VeriSign NameStore EPP Registration Server</svID><svDate>2016-11-24T12:00:08.0207Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>http://www.nic.name/epp/nameWatch-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.nic.name/epp/emailFwd-1.0</objURI><objURI>http://www.nic.name/epp/defReg-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://www.verisign.com/epp/lowbalance-poll-1.0</objURI><svcExtension><extURI>http://www.verisign-grs.com/epp/namestoreExt-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.verisign.com/epp/idnLang-1.0</extURI><extURI>http://www.nic.name/epp/persReg-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><other /><prov /></purpose><recipient><ours /><public /><unrelated /></recipient><retention><indefinite /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'defReg'}->[0],'http://www.nic.name/epp/defReg-1.0','defReg-1.0 for server announcing 1.0');

##############
# defreg Check
# set all levels to premium
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:chkData xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:cd><defReg:name level="premium" avail="1">fred</defReg:name></defReg:cd><defReg:cd><defReg:name level="standard" avail="0">def.fred</defReg:name><defReg:reason>Conflicting object exists</defReg:reason></defReg:cd></defReg:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_check('fred', 'jed.fred', { level => 'premium' });
is_string($R1,$E1.'<command><check><defReg:check xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:name level="premium">fred</defReg:name><defReg:name level="premium">jed.fred</defReg:name></defReg:check></check><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_check all premium build_xml');

# defreg Check
# # set only specific name to premium
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:chkData xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:cd><defReg:name level="premium" avail="1">doe</defReg:name></defReg:cd><defReg:cd><defReg:name level="standard" avail="0">john.doe</defReg:name><defReg:reason>Conflicting object exists</defReg:reason></defReg:cd></defReg:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_check('doe', 'john.doe', { level_doe => 'premium' });
is_string($R1,$E1.'<command><check><defReg:check xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:name level="premium">doe</defReg:name><defReg:name level="standard">john.doe</defReg:name></defReg:check></check><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_check specific premium build_xml');
is($rc->is_success(),1,'defreg_check is_success');
is($dri->get_info('action','defreg','doe'), 'check', 'defreg_check get_info(action)');
is($dri->get_info('exist','defreg','doe'),0,'defreg_check get_info(exist)');
is($dri->get_info('exist','defreg','john.doe'),1,'defreg_check get_info(exist)');
is($dri->get_info('exist_reason','defreg','john.doe'),'Conflicting object exists','defreg_check get_info(exist)');

# defReg info
# # set only specific name to premium
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:infData xmlns:defReg="http://www.nic.name/epp/defReg-1.0"><defReg:roid>EXAMPLE1-REP</defReg:roid><defReg:name level="premium">doe</defReg:name><defReg:registrant>jd1234</defReg:registrant><defReg:tm>XYZ-123</defReg:tm><defReg:tmCountry>US</defReg:tmCountry><defReg:tmDate>1990-04-03</defReg:tmDate><defReg:adminContact>sh8013</defReg:adminContact><defReg:status s="ok" /><defReg:clID>ClientX</defReg:clID><defReg:crID>ClientY</defReg:crID><defReg:crDate>1999-04-03T22:00:00.0Z</defReg:crDate><defReg:upID>ClientX</defReg:upID><defReg:upDate>1999-12-03T09:00:00.0Z</defReg:upDate><defReg:exDate>2000-04-03T22:00:00.0Z</defReg:exDate><defReg:trDate>2000-01-08T09:00:00.0Z</defReg:trDate><defReg:authInfo><defReg:pw>2fooBAR</defReg:pw></defReg:authInfo></defReg:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_info('EXAMPLE1-REP', { auth => { pw => 'ABC555' } } );
is_string($R1,$E1.'<command><info><defReg:info xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE1-REP</defReg:roid><defReg:authInfo><defReg:pw>ABC555</defReg:pw></defReg:authInfo></defReg:info></info><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_info build_xml');
is($rc->is_success(),1,'defreg_check is_success');
is($dri->get_info('action','defreg','EXAMPLE1-REP'), 'info', 'defreg_info get_info(action)');
is($dri->get_info('action'), 'info', 'defreg_info get_info(action)');
is($dri->get_info('roid'), 'EXAMPLE1-REP', 'defreg_info get_info(roid)');
is($dri->get_info('name'), 'doe', 'defreg_info get_info(name)');
is($dri->get_info('level'), 'premium', 'defreg_info get_info(level)');
$cs = $dri->get_info('contact');
isa_ok($cs, 'Net::DRI::Data::ContactSet', 'defreg_info get_info(cs)');
is($cs->get('registrant')->srid(),'jd1234', 'defreg_info get_info(cs registrant)');
is($cs->get('admin')->srid(),'sh8013', 'defreg_info get_info(cs admin)');
is($dri->get_info('tm'), 'XYZ-123', 'defreg_info get_info(tm)');
is($dri->get_info('tmCountry'), 'US', 'defreg_info get_info(tm_country)');
is($dri->get_info('tmDate'), '1990-04-03T00:00:00', 'defreg_info get_info(tmDate)');
$s = $dri->get_info('status');
isa_ok($s, 'Net::DRI::Protocol::EPP::Core::Status', 'defreg_info get_info(status)');
is($s->is_active(), 1,'defreg_info get_info(status active)');
is($dri->get_info('clID'), 'ClientX', 'defreg_info get_info(clID)');
is($dri->get_info('crID'), 'ClientY', 'defreg_info get_info(crID)');
is($dri->get_info('upID'), 'ClientX', 'defreg_info get_info(upID)');
is($dri->get_info('crDate'), '1999-04-03T22:00:00', 'defreg_info get_info(crDate)');
is($dri->get_info('upDate'), '1999-12-03T09:00:00', 'defreg_info get_info(upDate)');
is($dri->get_info('exDate'), '2000-04-03T22:00:00', 'defreg_info get_info(exDate)');
is($dri->get_info('trDate'), '2000-01-08T09:00:00', 'defreg_info get_info(trDate)');
is_deeply($dri->get_info('auth'), {pw => '2fooBAR'}, 'defreg_info get_info(authInfo)');

# defreg transfer_query
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:trnData xmlns:defReg="http://www.nic.name/epp/defReg-1.0"><defReg:roid>EXAMPLE2-REP</defReg:roid><defReg:trStatus>pending</defReg:trStatus><defReg:reID>ClientX</defReg:reID><defReg:reDate>2000-06-06T22:00:00.0Z</defReg:reDate><defReg:acID>ClientY</defReg:acID><defReg:acDate>2000-06-11T22:00:00.0Z</defReg:acDate><defReg:exDate>2002-09-08T22:00:00.0Z</defReg:exDate></defReg:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_transfer_query('EXAMPLE2-REP', { auth => { roid => 'JD1234-REP', pw => '2fooBAR' } } );
is_string($R1,$E1.'<command><transfer op="query"><defReg:transfer xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE2-REP</defReg:roid><defReg:authInfo><defReg:pw roid="JD1234-REP">2fooBAR</defReg:pw></defReg:authInfo></defReg:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_transfer_query build_xml');
is($rc->is_success(),1,'defreg_transfer_query is_success');
is($dri->get_info('action','defreg','EXAMPLE2-REP'), 'transfer_query', 'defreg_transfer_query get_info(action)');
is($dri->get_info('action'), 'transfer_query', 'defreg_transfer_query get_info(action)');
is($dri->get_info('roid'), 'EXAMPLE2-REP', 'defreg_transfer_query get_info(roid)');
is($dri->get_info('trStatus'), 'pending', 'defreg_transfer_query get_info(trStatus)');
is($dri->get_info('reID'), 'ClientX', 'defreg_transfer_query get_info(reID)');
is($dri->get_info('acID'), 'ClientY', 'defreg_transfer_query get_info(acID)');
is($dri->get_info('reDate'), '2000-06-06T22:00:00', 'defreg_transfer_query get_info(reDate)');
is($dri->get_info('acDate'), '2000-06-11T22:00:00', 'defreg_transfer_query get_info(acDate)');
is($dri->get_info('exDate'), '2002-09-08T22:00:00', 'defreg_transfer_query get_info(exDate)');

# defreg transfer_start
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:trnData xmlns:defReg="http://www.nic.name/epp/defReg-1.0"><defReg:roid>EXAMPLE3-REP</defReg:roid><defReg:trStatus>pending</defReg:trStatus><defReg:reID>ClientX</defReg:reID><defReg:reDate>2000-06-06T22:00:00.0Z</defReg:reDate><defReg:acID>ClientY</defReg:acID><defReg:acDate>2000-06-11T22:00:00.0Z</defReg:acDate><defReg:exDate>2002-09-08T22:00:00.0Z</defReg:exDate></defReg:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_transfer_start('EXAMPLE3-REP', { duration=>DateTime::Duration->new(years=>1), auth => { roid => 'JD1234-REP', pw => '2fooBAR' } } );
is_string($R1,$E1.'<command><transfer op="request"><defReg:transfer xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE3-REP</defReg:roid><defReg:period unit="y">1</defReg:period><defReg:authInfo><defReg:pw roid="JD1234-REP">2fooBAR</defReg:pw></defReg:authInfo></defReg:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_transfer_start build_xml');
is($rc->is_success(),1,'defreg_transfer_start is_success');
is($dri->get_info('action','defreg','EXAMPLE3-REP'), 'transfer_request', 'defreg_transfer_start get_info(action)');
is($dri->get_info('action'), 'transfer_request', 'defreg_transfer_start get_info(action)');
is($dri->get_info('roid'), 'EXAMPLE3-REP', 'defreg_transfer_start get_info(roid)');
is($dri->get_info('trStatus'), 'pending', 'defreg_transfer_start get_info(trStatus)');
is($dri->get_info('reID'), 'ClientX', 'defreg_transfer_start get_info(reID)');
is($dri->get_info('acID'), 'ClientY', 'defreg_transfer_start get_info(acID)');
is($dri->get_info('reDate'), '2000-06-06T22:00:00', 'defreg_transfer_start get_info(reDate)');
is($dri->get_info('acDate'), '2000-06-11T22:00:00', 'defreg_transfer_start get_info(acDate)');
is($dri->get_info('exDate'), '2002-09-08T22:00:00', 'defreg_transfer_start get_info(exDate)');

# defreg transfer_stop / accept / refuse
$rc=$dri->defreg_transfer_stop('EXAMPLE4-REP');
is_string($R1,$E1.'<command><transfer op="cancel"><defReg:transfer xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE4-REP</defReg:roid></defReg:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_transfer_stop build_xml');
$rc=$dri->defreg_transfer_accept('EXAMPLE5-REP');
is_string($R1,$E1.'<command><transfer op="approve"><defReg:transfer xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE5-REP</defReg:roid></defReg:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_transfer_accept build_xml');
$rc=$dri->defreg_transfer_refuse('EXAMPLE6-REP');
is_string($R1,$E1.'<command><transfer op="reject"><defReg:transfer xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE6-REP</defReg:roid></defReg:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_transfer_refuse build_xml');

# defreg create (with IDN - required language tag)
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><defReg:creData xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:roid>EXAMPLE7-REP</defReg:roid><defReg:name level="premium">xn--gya</defReg:name><defReg:crDate>1999-04-03T22:00:00.0Z</defReg:crDate><defReg:exDate>2000-04-03T22:00:00.0Z</defReg:exDate></defReg:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->defreg_create('xn--gya', {level => 'premium', contact => $cs, 'tm' => 'XYZ-123', 'tmCountry' => 'US', 'tmDate' => '1990-04-03', auth => { pw => '2fooBAR' }, language => 'GRE'} );
is_string($R1,$E1.'<command><create><defReg:create xmlns:defReg="http://www.nic.name/epp/defReg-1.0" xsi:schemaLocation="http://www.nic.name/epp/defReg-1.0 defReg-1.0.xsd"><defReg:name level="premium">xn--gya</defReg:name><defReg:registrant>jd1234</defReg:registrant><defReg:tm>XYZ-123</defReg:tm><defReg:tmCountry>US</defReg:tmCountry><defReg:tmDate>1990-04-03</defReg:tmDate><defReg:adminContact>sh8013</defReg:adminContact><defReg:authInfo><defReg:pw>2fooBAR</defReg:pw></defReg:authInfo></defReg:create></create><extension><idnLang:tag xmlns:idnLang="http://www.verisign.com/epp/idnLang-1.0" xsi:schemaLocation="http://www.verisign.com/epp/idnLang-1.0 idnLang-1.0.xsd">GRE</idnLang:tag></extension><clTRID>ABC-12345</clTRID></command>'.$E2, 'defreg_create build_xml');
is($dri->get_info('action'), 'create', 'defreg_create get_info(action)');
is($dri->get_info('name'), 'xn--gya', 'defreg_create get_info(name)');
is($dri->get_info('roid'), 'EXAMPLE7-REP', 'defreg_create get_info(roid)');
is($dri->get_info('level'), 'premium', 'defreg_create get_info(level)');
is($dri->get_info('crDate'), '1999-04-03T22:00:00', 'defreg_create get_info(crDate)');
is($dri->get_info('exDate'), '2000-04-03T22:00:00', 'defreg_create get_info(exDate)');


exit 0;
