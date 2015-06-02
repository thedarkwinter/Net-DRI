#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 10;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context = 50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1 = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
	my ($transport, $count, $msg) = @_;
	$R1 = $msg->as_string();
	return 1;
}

our $R2;
sub myrecv
{
	return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 :
		$E1 . '<response>' . r() . $TRID . '</response>' . $E2);
}

my $dri = Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('SWITCH');
$dri->target('SWITCH')->add_current_profile('p1', 'epp', {f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c);

$R2 = $E1 . '<greeting><svID>SWITCH_EPP_Server</svID><svDate>2008-07-04T16:06:23+02:00</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI></svcMenu><dcp><access><personalAndOther /></access><statement><purpose><admin /><other /><prov /></purpose><recipient><ours /><public /></recipient><retention><legal /></retention></statement></dcp></greeting>' . $E2;
$rc = $dri->process('session', 'noop', []);
is($R1, $E1 . '<hello/>' . $E2, 'session noop build (hello command)');
is($rc->is_success(), 1, 'session noop is_success');
is($rc->get_data('session','server','server_id'),'SWITCH_EPP_Server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date')->strftime('%FT%T%z'),'2008-07-04T16:06:23+0200','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:host-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),[],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),[],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><personalAndOther/></access><statement><purpose><admin/><other/><prov/></purpose><recipient><ours/><public/></recipient><retention><legal/></retention></statement>','session noop get_data(session,server,dcp_string)');

exit 0;

sub r
{
	my ($c, $m) = @_;
	return '<result code="' . ($c || 1000) . '"><msg>' .
		($m || 'Command completed successfully') .
		'</msg></result>';
}


