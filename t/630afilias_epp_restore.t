#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 3;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

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
	return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1 .
		'<response>' . r() . $TRID . '</response>' . $E2);
}

my $dri;
my $ok=eval {
	$dri = Net::DRI->new({cache_ttl => 10});
	1;
};
print $@->as_string() if ! $ok;
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('HN');
$ok=eval {
	$dri->target('HN')->add_current_profile('p1',
		'epp',
		{
			f_send=> \&mysend,
			f_recv=> \&myrecv
		});
	1;
};
print $@->as_string() if ! $ok;


my $rc;
my $s;
my $d;
my ($dh,@c);

####################################################################################################
## Restore a deleted domain
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

$ok=eval {
	$rc = $dri->domain_renew('deleted-by-accident.com.hn', {
		current_expiration => new DateTime(year => 2008, month => 12,
			day => 24),
		rgp => 1});
	1;
};
print(STDERR $@->as_string()) if ! $ok;
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully recovered');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>deleted-by-accident.com.hn</domain:name><domain:curExpDate>2008-12-24</domain:curExpDate></domain:renew></renew><extension><rgp:renew xmlns:rgp="urn:EPP:xml:ns:ext:rgp-1.0" xsi:schemaLocation="urn:EPP:xml:ns:ext:rgp-1.0 rgp-1.0.xsd"><rgp:restore/></rgp:renew></extension><clTRID>ABC-12345</clTRID></command></epp>', 'Recover Domain XML correct');

####################################################################################################
exit(0);

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
