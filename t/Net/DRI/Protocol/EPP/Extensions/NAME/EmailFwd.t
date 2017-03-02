#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Data::Dumper;

use Test::More tests => 77;
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

my ( $rc, $s, $cs, $d );

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

# emailfwd create
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:creData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:crDate>1999-04-03T22:00:00.0Z</emailFwd:crDate><emailFwd:exDate>2001-04-03T22:00:00.0Z</emailFwd:exDate></emailFwd:creData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$cs = $dri->local_object('contactset');
my $c1 = $dri->local_object('contact')->srid('jd1234');
my $c2 = $dri->local_object('contact')->srid('sh8013');
$cs->set( $c1, 'registrant' );
$cs->set( $c2, 'admin' );
$cs->set( $c2, 'tech' );
$rc = $dri->emailfwd_create( 'john@doe.name',
                             { fwdTo    => 'jdoe@example.com',
                               duration => DateTime::Duration->new( years => 2 ),
                               contact  => $cs,
                               auth     => { pw => '2fooBAR' } } );
is_string(
  $R1,
  $E1
      . '<command><create><emailFwd:create xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:fwdTo>jdoe@example.com</emailFwd:fwdTo><emailFwd:period unit="y">2</emailFwd:period><emailFwd:registrant>jd1234</emailFwd:registrant><emailFwd:contact type="admin">sh8013</emailFwd:contact><emailFwd:contact type="tech">sh8013</emailFwd:contact><emailFwd:authInfo><emailFwd:pw>2fooBAR</emailFwd:pw></emailFwd:authInfo></emailFwd:create></create><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_create build_xml'
);
is( $dri->get_info('action'), 'create',              'emailfwd_create get_info(action)' );
is( $dri->get_info('name'),   'john@doe.name',       'emailfwd_create get_info(name)' );
is( $dri->get_info('crDate'), '1999-04-03T22:00:00', 'emailfwd_create get_info(crDate)' );
is( $dri->get_info('exDate'), '2001-04-03T22:00:00', 'emailfwd_create get_info(exDate)' );

# emailfwd delete
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;
$rc = $dri->emailfwd_delete('john@doe.name');
is_string(
  $R1,
  $E1
      . '<command><delete><emailFwd:delete xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name></emailFwd:delete></delete><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_delete build_xml'
);

# emailfwd renew
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:renData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:exDate>2005-04-03T22:00:00.0Z</emailFwd:exDate></emailFwd:renData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_renew( 'john@doe.name',
                            { duration => DateTime::Duration->new( years => 5 ),
                              current_expiration => DateTime->new( year => 2000, month => 4, day => 3 ) } );
is(
  $R1,
  $E1
      . '<command><renew><emailFwd:renew xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:curExpDate>2000-04-03</emailFwd:curExpDate><emailFwd:period unit="y">5</emailFwd:period></emailFwd:renew></renew><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_renew build_xml'
);
is( $dri->get_info('action'), 'renew', 'emailfwd_renew get_info(action)' );
is( $dri->get_info('exist'),  1,       'emailfwd_renew get_info(exist)' );
$d = $dri->get_info('exDate');
isa_ok( $d, 'DateTime', 'emailfwd_renew get_info(exDate)' );
is( "" . $d, '2005-04-03T22:00:00', 'emailfwd_renew get_info(exDate) value' );

# emailfwd transfer request
$R2
    = $E1
    . '<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:trnData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:trStatus>pending</emailFwd:trStatus><emailFwd:reID>ClientX</emailFwd:reID><emailFwd:reDate>2000-06-08T22:00:00.0Z</emailFwd:reDate><emailFwd:acID>ClientY</emailFwd:acID><emailFwd:acDate>2000-06-13T22:00:00.0Z</emailFwd:acDate><emailFwd:exDate>2002-09-08T22:00:00.0Z</emailFwd:exDate></emailFwd:trnData></resData>'
    . $TRID
    . '</response>'
    . $E2;
$rc = $dri->emailfwd_transfer_start( 'john@doe.name',
                                     { duration => DateTime::Duration->new( years => 1 ), auth => { roid => 'JD1234-REP', pw => '2fooBAR' } } );

is_string(
  $R1,
  $E1
      . '<command><transfer op="request"><emailFwd:transfer xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:period unit="y">1</emailFwd:period><emailFwd:authInfo><emailFwd:pw roid="JD1234-REP">2fooBAR</emailFwd:pw></emailFwd:authInfo></emailFwd:transfer></transfer><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_transfer_start build_xml'
);
is( $rc->is_success(), 1, 'emailfwd_transfer_start is_success' );
is( $dri->get_info( 'action', 'emailfwd', 'john@doe.name' ), 'transfer_request', 'emailfwd_transfer_start get_info(action)' );
is( $dri->get_info('action'),   'transfer_request',    'emailfwd_transfer_start get_info(action)' );
is( $dri->get_info('name'),     'john@doe.name',       'emailfwd_transfer_start get_info(name)' );
is( $dri->get_info('trStatus'), 'pending',             'emailfwd_transfer_start get_info(trStatus)' );
is( $dri->get_info('reID'),     'ClientX',             'emailfwd_transfer_start get_info(reID)' );
is( $dri->get_info('acID'),     'ClientY',             'emailfwd_transfer_start get_info(acID)' );
is( $dri->get_info('reDate'),   '2000-06-08T22:00:00', 'emailfwd_transfer_start get_info(reDate)' );
is( $dri->get_info('acDate'),   '2000-06-13T22:00:00', 'emailfwd_transfer_start get_info(acDate)' );
is( $dri->get_info('exDate'),   '2002-09-08T22:00:00', 'emailfwd_transfer_start get_info(exDate)' );

# emailfwd update
$R2 = $E1 . '<response><result code="1000"><msg>Command completed successfully</msg></result>' . $TRID . '</response>' . $E2;
my $toc = $dri->local_object('changes');

# add/del status
$toc->add( 'status', $dri->local_object('status')->no( 'publish', 'Payment overdue.' ) );
$toc->del( 'status', $dri->local_object('status')->no('update') );

# add contact
$cs = $dri->local_object('contactset');
$cs->set( $dri->local_object('contact')->srid('mak21'), 'tech' );
$toc->add( 'contact', $cs );

# delete contact
$cs = $dri->local_object('contactset');
$cs->set( $dri->local_object('contact')->srid('sh8013'), 'tech' );
$toc->del( 'contact', $cs );

# set fields
$cs = $dri->local_object('contactset');
$cs->set( $dri->local_object('contact')->srid('sh8013'), 'registrant' );
$toc->set( 'contact', $cs );
$toc->set( 'fwdTo',   'johnny@example.com' );
$toc->set( 'auth', { pw => '2BARfoo' } );
$rc = $dri->emailfwd_update( 'john@doe.name', $toc );
is_string(
  $R1,
  $E1
      . '<command><update><emailFwd:update xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:add><emailFwd:contact type="tech">mak21</emailFwd:contact><emailFwd:status lang="en" s="clientHold">Payment overdue.</emailFwd:status></emailFwd:add><emailFwd:rem><emailFwd:contact type="tech">sh8013</emailFwd:contact><emailFwd:status s="clientUpdateProhibited"/></emailFwd:rem><emailFwd:chg><emailFwd:fwdTo>johnny@example.com</emailFwd:fwdTo><emailFwd:registrant>sh8013</emailFwd:registrant><emailFwd:authInfo><emailFwd:pw>2BARfoo</emailFwd:pw></emailFwd:authInfo></emailFwd:chg></emailFwd:update></update><clTRID>ABC-12345</clTRID></command>'
      . $E2,
  'emailfwd_update build_xml'
);

exit 0;
