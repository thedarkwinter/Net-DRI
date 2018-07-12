#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use XML::Tidy;

use Net::DRI;
use Net::DRI::Data::Raw;
use Data::Dumper;

use Test::More tests => 107;

eval { no warnings; require Test::LongString; Test::LongString->import( max => 100 ); $Test::LongString::Context = 50; };
if ($@) { no strict 'refs'; *{'main::is_string'} = \&main::is; }

our $E1
    = ''.
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'.
    '<registry-response xmlns="http://registry.denic.de/global/2.1" xmlns:tr="http://registry.denic.de/transaction/2.1" xmlns:domain="http://registry.denic.de/domain/2.1" xmlns:contact="http://registry.denic.de/contact/2.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/2.1">';
our $E2   = ''.
    '</registry-response>';
our $TRID = ''.
    '<tr:ctid>ABC-12345'.
    '</tr:ctid>'.
    '<tr:stid>54322-XYZ'.
    '</tr:stid>';

our ( $R1, $R2 );
sub mysend { my ( $transport, $count, $msg ) = @_; $R1 = $msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string( $R2 ? $R2 : $E1 . ''.
    '<registry-response>' . r() . $TRID . ''.
    '</registry-response>' . $E2 ); }
sub r { my ( $c, $m ) = @_; return ''.
    '<result code="' . ( $c || 1000 ) . '">'.
    '<msg>' . ( $m || 'Command completed successfully' ) . ''.
    '</msg>'.
    '</result>'; }

my $dri = Net::DRI::TrapExceptions->new( { cache_ttl => 10 } );
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('DENIC');
$dri->target('DENIC')->add_current_profile( 'p1', 'rri', { f_send => \&mysend, f_recv => \&myrecv } );

my $rc;
my $s;
my $d;
my ( $dh, @c );
my $test_name;
our $xml_path = './RRI/xml';
our $xml_tidy;

# used while writing tests
sub write_xml_file {
    my ($filename, $xml) = @_;
    $xml_tidy = XML::Tidy->new('xml' => $xml);
    $xml_tidy->tidy('  ');
    $xml_tidy->write('filename' => "$xml_path/$filename");
}

# read xml and reformat it
sub read_xml_file {
    my ($filename) = @_;
    $xml_tidy = XML::Tidy->new('filename' => "$xml_path/$filename");
    $xml_tidy->strip();
    my $xml = $xml_tidy->toString();
    $xml =~ s/^.*\x{0a}/<?xml version="1.0" encoding="UTF-8" standalone="yes"?>/; # set the header
    $xml =~ s/ \/>/\/>/; # remove space in empty elements
    return $xml;
}

sub save_command {
    my $cmd_file_n = shift;
    write_xml_file($cmd_file_n.'command.xml', $R1);
    write_xml_file($cmd_file_n.'response.xml', $R2);
}

####################################################################################################
## Session Management
$test_name = 'login';
$R2 = read_xml_file($test_name . '_response.xml');
$rc = $dri->process( 'session', 'login', [ 'user', 'password' ] );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Login successful' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Login XML correct');

####################################################################################################
## Contact Operations
$test_name = 'contact_check_01';
$R2 = read_xml_file($test_name . '_response.xml');
$rc = $dri->contact_check( $dri->local_object('contact')->srid('DENIC-12345-BSP') );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( defined($rc) && $rc->is_success(), 1, 'Contact successfully checked' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Check Contact XML correct');
is( $dri->get_info( 'exist', 'contact', 'DENIC-12345-BSP' ), 0, 'Contact does not exist' );

# Contact create
$test_name = 'contact_create_01';
$R2 = read_xml_file($test_name . '_response.xml');

my $c = $dri->local_object('contact');
$c->srid('DENIC-99990-10240-BSP');
$c->type('PERSON');
$c->name('Theobald Tester');
$c->org('Test-Org');
$c->street( ['Kleiner Dienstweg 17'] );
$c->pc('09538');
$c->city('Gipsnich');
$c->cc('DE');
$c->voice('+49.123456');
$c->fax('+49.123457');
$c->email('email@denic.de');
$c->sip('sip:benutzer@denic.de');
$c->remarks('Interesting remark');
$c->disclose( { voice => 1 } );

$rc = $dri->contact_create($c);
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Contact successfully created' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Create Contact XML correct');

# Contact update
$test_name = 'contact_update_01';
$R2 = read_xml_file($test_name . '_response.xml');

my $todo = $dri->local_object('changes');
$todo->set( 'info', $c );
$rc = $dri->contact_update( $c, $todo );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Contact successfully updated' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Update Contact XML correct');

# Contact check
$test_name = 'contact_check_02';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->contact_check($c);
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( defined($rc) && $rc->is_success(), 1, 'Contact successfully checked' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Check Contact XML correct');
is( $dri->get_info( 'exist', 'contact', 'DENIC-99990-10240-BSP' ), 1, 'Contact exists' );

# Contact info
$test_name = 'contact_info_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->contact_info( $dri->local_object('contact')->srid('DENIC-99989-BSP') );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Contact successfully queried' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Query Contact XML correct');

$c = $dri->get_info( 'self', 'contact', 'DENIC-99989-BSP' );
isa_ok( $c, 'Net::DRI::Data::Contact::DENIC' );
is( $c->name() . '|' . $c->org() . '|' . $c->sip() . '|' . $c->type(),
    'SyGroup GmbH|SyGroup GmbH|sip:secretary@sygroup.ch|ROLE',
    'Selected info from contact' );

my $mod = $dri->get_info( 'upDate', 'contact', 'DENIC-99989-BSP' );
isa_ok( $mod, 'DateTime' );
is( $mod->ymd . 'T' . $mod->hms, '2007-05-23T22:55:33', 'Update Date' );

####################################################################################################
## Domain Operations

# Domain check
$test_name = 'domain_check_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_check('rritestdomain.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Check Domain XML correct');
is( $dri->get_info( 'exist', 'domain', 'rritestdomain.de' ), 0, 'Domain does not exist' );

# Domain check using IDN (ace)
$test_name = 'domain_check_02';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_check('xn--rriberdomain-flb.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
utf8::encode($R1);    # this encoding is normally done at transport so we have to encode it manually for this test to pass
my $command
    = ''.
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'.
    '<registry-request xmlns="http://registry.denic.de/global/2.1" xmlns:domain="http://registry.denic.de/domain/2.1">'.
    '<domain:check>'.
    '<domain:handle>rriüberdomain.de'.
    '</domain:handle>'.
    '<domain:ace>xn--rriberdomain-flb.de'.
    '</domain:ace>'.
    '</domain:check>'.
    '</registry-request>';
utf8::encode($command);
is( $R1,                     $command, 'Check Domain XML correct' );
is( $dri->get_info('exist'), 0,        'domain get_info(exist)' );
is( $dri->get_info( 'exist', 'domain', 'xn--rriberdomain-flb.de' ), 0, 'domain get_info(exist) from cache ace' );
is( $dri->get_info( 'exist', 'domain', 'rriüberdomain.de' ),       0, 'domain get_info(exist) from cache idn' );
is( $dri->get_info('name'),     'rriüberdomain.de',       'domain get_info(name)' );
is( $dri->get_info('name_ace'), 'xn--rriberdomain-flb.de', 'domain get_info(name_ace)' );
is( $dri->get_info('name_idn'), 'rriüberdomain.de',       'domain get_info(name_idn)' );
$dri->cache_clear();

# Domain check using IDN (native)
$test_name = 'domain_check_02';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_check('rriüberdomain.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
utf8::encode($R1);    # this encoding is normally done at transport so we have to encode it manually for this test to pass
$command
    = ''.
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'.
    '<registry-request xmlns="http://registry.denic.de/global/2.1" xmlns:domain="http://registry.denic.de/domain/2.1">'.
    '<domain:check>'.
    '<domain:handle>rriüberdomain.de'.
    '</domain:handle>'.
    '<domain:ace>xn--rriberdomain-flb.de'.
    '</domain:ace>'.
    '</domain:check>'.
    '</registry-request>';
utf8::encode($command);
is( $R1,                     $command, 'Check Domain XML correct' );

is( $dri->get_info('exist'), 0,        'domain get_info(exist)' );
is( $dri->get_info( 'exist', 'domain', 'xn--rriberdomain-flb.de' ), 0, 'domain get_info(exist) from cache ace' );
is( $dri->get_info( 'exist', 'domain', 'rriüberdomain.de' ),       0, 'domain get_info(exist) from cache idn' );
is( $dri->get_info('name'),     'rriüberdomain.de',       'domain get_info(name)' );
is( $dri->get_info('name_ace'), 'xn--rriberdomain-flb.de', 'domain get_info(name_ace)' );
is( $dri->get_info('name_idn'), 'rriüberdomain.de',       'domain get_info(name_idn)' );
$dri->cache_clear();

# Domain create
$test_name = 'domain_create_01';
$R2 = read_xml_file($test_name . '_response.xml');

my $cs = $dri->local_object('contactset');
$cs->add( $dri->local_object('contact')->srid('DENIC-99990-10240-BSP'),  'registrant' );
$cs->add( $dri->local_object('contact')->srid('DENIC-99990-10240-BSP1'), 'admin' );
$cs->add( $dri->local_object('contact')->srid('DENIC-99990-10240-BSP2'), 'tech' );

my @secdns = (
  { key_flags    => 257,
    key_protocol => 3,
    key_alg      => 5,
    key_pubKey =>
        'AwEAAdDECajHaTjfSoNTY58WcBah1BxPKVIHBz4IfLjfqMvium4lgKtKZLe97DgJ5/NQrNEGGQmr6fKvUj67cfrZUojZ2cGRizVhgkOqZ9scaTVXNuXLM5Tw7VWOVIceeXAuuH2mPIiEV6MhJYUsW6dvmNsJ4XwCgNgroAmXhoMEiWEjBB+wjYZQ5GtZHBFKVXACSWTiCtddHcueOeSVPi5WH94VlubhHfiytNPZLrObhUCHT6k0tNE6phLoHnXWU+6vpsYpz6GhMw/R9BFxW5PdPFIWBgoWk2/XFVRSKG9Lr61b2z1R126xeUwvw46RVy3h anV3vNO7LM5H niqaYclBbhk='
  } );
$rc = $dri->domain_create( 'rritestdomain.de',
                           { pure_create => 1,
                             contact     => $cs,
                             ns          => $dri->local_object('hosts')->add( 'dns1.syhosting.ch', ['193.219.115.46'] ),
                             secdns      => [@secdns],
                           } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully created' );

is_string($R1, read_xml_file($test_name . '_command.xml'), 'Create Domain XML correct');


# Domain create idn (ace)
$test_name = 'domain_create_02';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_create( 'xn--rriberdomain-flb.de',
                           { pure_create => 1,
                             contact     => $cs,
                             ns          => $dri->local_object('hosts')->add( 'dns1.syhosting.ch', ['193.219.115.46'] ),
                             secdns      => [@secdns],
                           } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully created' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Create Domain IDN (ace)	XML correct');

# Domain create idn (native)
$test_name = 'domain_create_03';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_create( 'rriüberdomain.de',
                           { pure_create => 1,
                             contact     => $cs,
                             ns          => $dri->local_object('hosts')->add( 'dns1.syhosting.ch', ['193.219.115.46'] ),
                             secdns      => [@secdns],
                           } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully created' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Create Domain IDN (native) XML correct');

# Domain info
$test_name = 'domain_info_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_info( 'xn--rriberdomain-flb.de', { withProvider => 1 } );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Query Domain XML correct');

isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully queried with withProvider' );

$mod = $dri->get_info('upDate');
isa_ok( $mod, 'DateTime' );
is( $mod->ymd . 'T' . $mod->hms,                          '2001-09-11T11:45:23', 'Update Date' );
is( $dri->get_info('contact')->get('registrant')->srid(), 'DENIC-1000006-1',     'Random contact is correct' );
my $ns = $dri->get_info( 'ns', 'domain', 'rriüberdomain.de' );
is( join( ',', $ns->get_names() ), 'dns1.rritestdomain.de', 'Name server records' );
is( join( ',', map { my ( $name, $v4, $v6 ) = $ns->get_details($_); $v4->[0] } $ns->get_names() ), '194.25.2.129', 'Name server v4 IPs' );
is( join( ',', map { my ( $name, $v4, $v6 ) = $ns->get_details($_); $v6->[0] } $ns->get_names() ),
    '2001:4d88:ffff:ffff:2:b345:af62:2',
    'Name server v6 IPs' );

# Domain transfer query
$test_name = 'domain_transfer_query_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_transfer_query('rritestdomain2.de');
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Accept Transfer XML correct');

isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully transferred' );
is( $dri->get_info( 'trStatus', 'domain', 'rritestdomain2.de' ), 'pending', 'Transfer status set correctly' );
$mod = $dri->get_info( 'reDate', 'domain', 'rritestdomain2.de' );
is( $mod->ymd . 'T' . $mod->hms, '2005-11-20T00:00:00', 'Update Date' );

# Domain transfer start
$test_name = 'domain_transfer_start_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_transfer_start( 'sygroup.de',
                                   { contact => $cs,
                                     ns      => $dri->local_object('hosts')->add( 'dns1.syhosting.ch', ['193.219.115.46'] ),
                                     auth    => { pw => 'test-auth' },
                                   } );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Transfer Domain XML correct');

isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully transferred' );

# Domain transfer refuse
$test_name = 'domain_transfer_refuse_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_transfer_refuse('rritestdomain.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain transfer successfully refused' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Refuse Transfer XML correct');

# Domain transfer accaept
$test_name = 'domain_transfer_accept_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_transfer_accept('rritestdomain2.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain transfer successfully approved' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Accept Transfer XML correct');

# Domain delete
$test_name = 'domain_delete_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_delete( 'rritestdomain3.de', { contact => $cs } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully deleted' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Delete Domain XML correct');

# Domain trade
$test_name = 'domain_trade_01';
$R2 = read_xml_file($test_name . '_response.xml');

$cs = $dri->local_object('contactset');
$cs->add( $dri->local_object('contact')->srid('DENIC-99990-10240-BSP5'), 'registrant' );
$rc = $dri->domain_trade( 'rritestdomain2.de', { contact => $cs } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully traded' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Trade Domain XML correct');

# Domain update
$test_name = 'domain_update_01';
$R2 = read_xml_file('domain_update_01_seed_info' . '_response.xml');
$rc = $dri->domain_info('rritestdomain.de');
$R2 = read_xml_file($test_name . '_response.xml');

my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add( $dri->local_object('contact')->srid('ALFRED-RIPE'), 'tech' );
$changes->add( 'contact', $cs );
$cs = $dri->local_object('contactset');
$cs->add( $dri->local_object('contact')->srid('DENIC-1000006-OPS'), 'tech' );
$changes->del( 'contact', $cs );
$changes->add( 'ns', $dri->local_object('hosts')->add( 'dns1.syhosting.ch', ['193.219.115.46'] ) );
$changes->del( 'ns', $dri->local_object('hosts')->add('dns1.rritestdomain.de') );

$rc = $dri->domain_update( 'rritestdomain.de', $changes );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully updated' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Update Domain XML correct');

# Domain transit
$test_name = 'domain_transit_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_transit( 'rritestdomain.de', { disconnect => 'true' } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully transitted' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Transit Domain XML correct');

# Domain migrate descr
$test_name = 'domain_migrate_descr_01';
$R2 = read_xml_file($test_name . '_response.xml');

$cs = $dri->local_object('contactset');
$cs->add( $dri->local_object('contact')->srid('DENIC-99990-10240-BSP5'), 'registrant' );
$rc = $dri->domain_migrate_descr( 'rritestdomain.de', { contact => $cs } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully migrated' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Migrate Domain XML correct');

# Domain create authinfo
$test_name = 'domain_create_authinfo_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_create_authinfo( 'rritestdomain.de', { authinfohash => '444', authinfoexpire => '20121010' } );
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully created authinfo' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Domain Create Authinfo XML correct');

# Domain delete authinfo
$test_name = 'domain_delete_authinfo_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->domain_delete_authinfo('rritestdomain.de');
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Domain successfully deleted authinfo' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Domain Delete Authinfo XML correct');

####################################################################################################
## Poll Message Operations

# Message retrieve
$test_name = 'domain_message_retrieve_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->message_retrieve();
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Message successfully deleted' );
my $msgid = $dri->get_info( 'last_id', 'message', 'session' );
is( $msgid, 423, 'Message ID parsed successfully' );
is( $dri->get_info( 'id',        'message', $msgid ), $msgid,           'Message ID correct' );
is( $dri->get_info( 'action',    'message', $msgid ), 'chprovAuthInfo', 'Message type correct' );
is( $dri->get_info( 'object_id', 'message', $msgid ), 'blafasel.de',    'Message domain correct' );
$mod = $dri->get_info( 'qdate', 'message', $msgid );
is( $mod->ymd . 'T' . $mod->hms, '2007-12-27T14:52:13', 'Update Date' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Retrieve Message XML correct');

# Message delete
$test_name = 'domain_message_delete_01';
$R2 = read_xml_file($test_name . '_response.xml');

$rc = $dri->message_delete($msgid);
isa_ok( $rc, 'Net::DRI::Protocol::ResultStatus' );
is( $rc->is_success(), 1, 'Message successfully deleted' );
is_string($R1, read_xml_file($test_name . '_command.xml'), 'Delete Message XML correct');

####################################################################################################

exit(0);
