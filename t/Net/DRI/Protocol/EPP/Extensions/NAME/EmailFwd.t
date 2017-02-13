#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Data::Dumper;

use Test::More tests => 54;
eval { no warnings; require Test::LongString; Test::LongString->import( max => 100 ); $Test::LongString::Context = 50; };
if ($@) { no strict 'refs'; *{'main::is_string'} = \&main::is; }

our $E1
    = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2   = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ( $R1, $R2 );
sub mysend { my ( $transport, $count, $msg ) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string( $R2 ? $R2 : $E1 . '<response>' . r() . $TRID . '</response>' . $E2 ); }
sub r { my ( $c, $m ) = @_; return '<result code="' . ( $c || 1000 ) . '"><msg>' . ( $m || 'Command completed successfully' ) . '</msg></result>'; }

my $dri = Net::DRI::TrapExceptions->new( { cache_ttl => 10, trid_factory => sub { return 'ABC-12345' }, logging => 'null' } );
$dri->add_registry('NAME');
$dri->target('NAME')->add_current_profile( 'p1', 'epp', { f_send => \&mysend, f_recv => \&myrecv }, {} );

my ( $rc, $s, $cs );

########################################################################################################

## Process greetings to select namespace versions
$R2
    = $E1
    . '<greeting><svID>VeriSign NameStore EPP Registration Server</svID><svDate>2016-11-24T12:00:08.0207Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>http://www.nic.name/epp/nameWatch-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.nic.name/epp/emailFwd-1.0</objURI><objURI>http://www.nic.name/epp/defReg-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://www.verisign.com/epp/lowbalance-poll-1.0</objURI><svcExtension><extURI>http://www.verisign-grs.com/epp/namestoreExt-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.verisign.com/epp/idnLang-1.0</extURI><extURI>http://www.nic.name/epp/persReg-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><other /><prov /></purpose><recipient><ours /><public /><unrelated /></recipient><retention><indefinite /></retention></statement></dcp></greeting>'
    . $E2;
$rc = $dri->process( 'session', 'noop', [] );
is( $dri->protocol()->ns()->{'emailFwd'}->[0], 'http://www.nic.name/epp/emailFwd-1.0', 'emailFwd-1.0 for server announcing 1.0' );

##############
# emailfwd Check - single
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:chkData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:cd><emailFwd:name avail="0">johnny@doe.name</emailFwd:name><emailFwd:reason>In use</emailFwd:reason></emailFwd:cd></emailFwd:chkData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_check('johnny@doe.name');
is_string(
  $R1,
  $E1
      . '<command><check><emailFwd:check xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>johnny@doe.name</emailFwd:name></emailFwd:check></check><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_check specific premium build_xml'
);
is( $rc->is_success(),        1,       'emailfwd_check is_success' );
is( $dri->get_info('action'), 'check', 'domain_check get_info(action)' );
is( $dri->get_info('exist'),  1,       'domain_check get_info(exist)' );
is( $dri->get_info( 'exist', 'emailFwd', 'johnny@doe.name' ), 1, 'emailfwd_check get_info(exist) from cache' );

# emailfwd Check - multi
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:chkData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:cd><emailFwd:name avail="1">john@doe.name</emailFwd:name></emailFwd:cd><emailFwd:cd><emailFwd:name avail="0">johnny@doe.name</emailFwd:name><emailFwd:reason>In use</emailFwd:reason></emailFwd:cd><emailFwd:cd><emailFwd:name avail="1">jane@doe.name</emailFwd:name></emailFwd:cd></emailFwd:chkData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_check( 'john@doe.name', 'johnny@doe.name', 'jane@doe.name' );
is_string(
  $R1,
  $E1
      . '<command><check><emailFwd:check xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:name>johnny@doe.name</emailFwd:name><emailFwd:name>jane@doe.name</emailFwd:name></emailFwd:check></check><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_check multi build_xml'
);
is( $rc->is_success(), 1, 'emailfwd_check multi is_success' );
is( $dri->get_info( 'action',       'emailfwd', 'john@doe.name' ),   'check',  'emailfwd_check multi get_info(action) - 1/3' );
is( $dri->get_info( 'exist',        'emailfwd', 'john@doe.name' ),   0,        'emailfwd_check multi get_info(exist) - 1/3' );
is( $dri->get_info( 'exist',        'emailfwd', 'johnny@doe.name' ), 1,        'emailfwd_check multi get_info(exist) - 2/3' );
is( $dri->get_info( 'exist_reason', 'emailfwd', 'johnny@doe.name' ), 'In use', 'emailfwd_check multi get_info(exist) - 2/3' );
is( $dri->get_info( 'exist',        'emailfwd', 'jane@doe.name' ),   0,        'emailfwd_check multi get_info(exist) - 3/3' );

# emailfwd info
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:infData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:roid>EXAMPLE1-VRSN</emailFwd:roid><emailFwd:status s="ok"/><emailFwd:registrant>jd1234</emailFwd:registrant><emailFwd:contact type="admin">sh8013</emailFwd:contact><emailFwd:contact type="tech">sh8013</emailFwd:contact><emailFwd:fwdTo>jdoe@example.com</emailFwd:fwdTo><emailFwd:clID>ClientX</emailFwd:clID><emailFwd:crID>ClientY</emailFwd:crID><emailFwd:crDate>1999-04-03T22:00:00.0Z</emailFwd:crDate><emailFwd:upID>ClientX</emailFwd:upID><emailFwd:upDate>1999-12-03T09:00:00.0Z</emailFwd:upDate><emailFwd:exDate>2005-04-03T22:00:00.0Z</emailFwd:exDate><emailFwd:trDate>2000-04-08T09:00:00.0Z</emailFwd:trDate><emailFwd:authInfo><emailFwd:pw>2fooBAR</emailFwd:pw></emailFwd:authInfo></emailFwd:infData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_info('john@doe.name');
is_string(
  $R1,
  $E1
      . '<command><info><emailFwd:info xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name></emailFwd:info></info><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_info build_xml'
);
is( $rc->is_success(),        1,               'emailfwd_info is_success' );
is( $dri->get_info('action'), 'info',          'emailfwd_info get_info(action)' );
is( $dri->get_info('exist'),  1,               'emailfwd_info get_info(exist)' );
is( $dri->get_info('name'),   'john@doe.name', 'emailfwd_info get_info(name)' );
is( $dri->get_info('roid'),   'EXAMPLE1-VRSN', 'emailfwd_info get_info(roid)' );
$s = $dri->get_info('status');
isa_ok( $s, 'Net::DRI::Data::StatusList', 'emailfwd_info get_info(status)' );
is_deeply( [ $s->list_status() ], ['ok'], 'emailfwd_info get_info(status) list' );
is( $s->is_active(), 1, 'emailfwd_info get_info(status) is_active' );
$s = $dri->get_info('contact');
isa_ok( $s, 'Net::DRI::Data::ContactSet', 'emailfwd_info get_info(contact)' );
is_deeply( [ $s->types() ], [ 'admin', 'registrant', 'tech' ], 'emailfwd_info get_info(contact) types' );
is( $s->get('registrant')->srid(), 'jd1234',              'emailfwd_info get_info(contact) registrant srid' );
is( $s->get('admin')->srid(),      'sh8013',              'emailfwd_info get_info(contact) admin srid' );
is( $s->get('tech')->srid(),       'sh8013',              'emailfwd_info get_info(contact) tech srid' );
is( $dri->get_info('fwdTo'),       'jdoe@example.com',    'emailfwd_info get_info(fwdTo)' );
is( $dri->get_info('clID'),        'ClientX',             'emailfwd_info get_info(clID)' );
is( $dri->get_info('crID'),        'ClientY',             'emailfwd_info get_info(crID)' );
is( $dri->get_info('crDate'),      '1999-04-03T22:00:00', 'emailfwd_info get_info(crDate)' );
is( $dri->get_info('upID'),        'ClientX',             'emailfwd_info get_info(upID)' );
is( $dri->get_info('upDate'),      '1999-12-03T09:00:00', 'emailfwd_info get_info(upDate)' );
is( $dri->get_info('exDate'),      '2005-04-03T22:00:00', 'emailfwd_info get_info(exDate)' );
is( $dri->get_info('trDate'),      '2000-04-08T09:00:00', 'emailfwd_info get_info(trDate)' );
is_deeply( $dri->get_info('auth'), { pw => '2fooBAR' }, 'emailfwd_info get_info(authInfo)' );

# emailfwd info - response for an unauthorized client
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:infData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:roid>EXAMPLE1-VRSN</emailFwd:roid><emailFwd:clID>ClientX</emailFwd:clID></emailFwd:infData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_info('john@doe.name');
is_string(
  $R1,
  $E1
      . '<command><info><emailFwd:info xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name></emailFwd:info></info><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_info unauthorized client build_xml'
);
is( $rc->is_success(),        1,               'emailfwd_info unauthorized client is_success' );
is( $dri->get_info('action'), 'info',          'emailfwd_info unauthorized client get_info(action)' );
is( $dri->get_info('exist'),  1,               'emailfwd_info unauthorized client get_info(exist)' );
is( $dri->get_info('name'),   'john@doe.name', 'emailfwd_info unauthorized client get_info(name)' );
is( $dri->get_info('roid'),   'EXAMPLE1-VRSN', 'emailfwd_info unauthorized client get_info(roid)' );
is( $dri->get_info('clID'),   'ClientX',       'emailfwd_info unauthorized client get_info(clID)' );

# emailfwd transfer_query
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:trnData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:trStatus>pending</emailFwd:trStatus><emailFwd:reID>ClientX</emailFwd:reID><emailFwd:reDate>2000-06-06T22:00:00.0Z</emailFwd:reDate><emailFwd:acID>ClientY</emailFwd:acID><emailFwd:acDate>2000-06-11T22:00:00.0Z</emailFwd:acDate><emailFwd:exDate>2002-09-08T22:00:00.0Z</emailFwd:exDate></emailFwd:trnData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_transfer_query( 'john@doe.name', { auth => { roid => 'JD1234-REP', pw => '2fooBAR' } } );
is_string(
  $R1,
  $E1
      . '<command><transfer op="query"><emailFwd:transfer xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:authInfo><emailFwd:pw roid="JD1234-REP">2fooBAR</emailFwd:pw></emailFwd:authInfo></emailFwd:transfer></transfer><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_transfer_query build_xml'
);
is( $rc->is_success(), 1, 'emailfwd_transfer_query is_success' );
is( $dri->get_info( 'action', 'emailfwd', 'john@doe.name' ), 'transfer_query', 'emailfwd_transfer_query get_info(action)' );
is( $dri->get_info('action'),   'transfer_query',      'emailfwd_transfer_query get_info(action)' );
is( $dri->get_info('name'),     'john@doe.name',       'emailfwd_transfer_query get_info(name)' );
is( $dri->get_info('trStatus'), 'pending',             'emailfwd_transfer_query get_info(trStatus)' );
is( $dri->get_info('reID'),     'ClientX',             'emailfwd_transfer_query get_info(reID)' );
is( $dri->get_info('acID'),     'ClientY',             'emailfwd_transfer_query get_info(acID)' );
is( $dri->get_info('reDate'),   '2000-06-06T22:00:00', 'emailfwd_transfer_query get_info(reDate)' );
is( $dri->get_info('acDate'),   '2000-06-11T22:00:00', 'emailfwd_transfer_query get_info(acDate)' );
is( $dri->get_info('exDate'),   '2002-09-08T22:00:00', 'emailfwd_transfer_query get_info(exDate)' );

exit 0;
