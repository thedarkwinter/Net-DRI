#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 19;
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
$dri->add_registry('CO');
$dri->target('CO')->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});

my $rc;
my $s;
my $d;
my ($dh, @c, $fee);

####################################################################################################
## Fee extension version 0.6 http://tools.ietf.org/html/draft-brown-epp-fees-03
## Fee-0.6 (In use by Charlseston Road Registry, Famous Four Media, and Neustar [at least for .co and .club])
## We use a greeting here to switch the namespace version here to -0.6 testing
$R2=$E1.'<greeting><svID>Neustar EPP Server:co</svID><svDate>2015-06-18T10:03:23.0Z</svDate><svcMenu><version>1.0</version><lang>en-US</lang><objURI>urn:ietf:params:xml:ns:contact</objURI><objURI>urn:ietf:params:xml:ns:host</objURI><objURI>urn:ietf:params:xml:ns:domain</objURI><objURI>urn:ietf:params:xml:ns:svcsub</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:neulevel</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.6</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.6','Fee 0.6 loaded correctly');
####################################################################################################

# domain_check_price
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">shoes.co</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns="urn:ietf:params:xml:ns:fee-0.6" xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:cd><fee:name>shoes.co</fee:name><fee:currency>USD</fee:currency><fee:command phase="open">create</fee:command><fee:period unit="y">1</fee:period><fee:fee>20.00</fee:fee><fee:class>CO Default Tier</fee:class></fee:cd><fee:cd><fee:name>shoes.co</fee:name><fee:currency>USD</fee:currency><fee:command phase="open">renew</fee:command><fee:period unit="y">1</fee:period><fee:fee>20.00</fee:fee><fee:class>CO Default Tier</fee:class></fee:cd><fee:cd><fee:name>shoes.co</fee:name><fee:currency>USD</fee:currency><fee:command phase="open">transfer</fee:command><fee:period unit="y">1</fee:period><fee:fee>20.00</fee:fee><fee:class>CO Default Tier</fee:class></fee:cd><fee:cd><fee:name>shoes.co</fee:name><fee:currency>USD</fee:currency><fee:command phase="open">restore</fee:command><fee:period unit="y">1</fee:period></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_price('shoes.co');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>shoes.co</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:domain><fee:name>shoes.co</fee:name><fee:command>create</fee:command></fee:domain><fee:domain><fee:name>shoes.co</fee:name><fee:command>renew</fee:command></fee:domain><fee:domain><fee:name>shoes.co</fee:name><fee:command>transfer</fee:command></fee:domain><fee:domain><fee:name>shoes.co</fee:name><fee:command>restore</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_check_price build');
is($rc->is_success(),1,'domain_check_price is is_success');
is($dri->get_info('action'),'check','domain_check_price get_info (action)');
is($dri->get_info('name'),'shoes.co','domain_check_price get_info (name)');
my @fees = @{$dri->get_info('fee')};
$d = $fees[0];
is($d->{currency},'USD','Fee extension: domain_check_price parse currency');
is($d->{action},'create','Fee extension: domain_check_price parse action');
is($d->{phase},'open','Fee extension: domain_check_price parse phase');
is($d->{duration}->years(),1,'Fee extension: domain_check_price parse duration');
is($d->{fee},20.00,'Fee extension: domain_check_price parse fee');
is($d->{class},'CO Default Tier','Fee extension: domain_check_price parse classe');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_check get_info (is_premium) undef');
isa_ok($dri->get_info('price_duration'),'DateTime::Duration','domain_check get_info (price_duration) is DateTime::Duration');
is($dri->get_info('price_duration')->years(),1,'domain_check get_info (price_duration)');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),'20','domain_check get_info (create_price)');
is($dri->get_info('renew_price'),20,'domain_check get_info (renew_price) undef');
is($dri->get_info('transfer_price'),20,'domain_check get_info (transfer_price) undef');
is($dri->get_info('restore_price'),undef,'domain_check get_info (restore_price) undef');

exit 0;