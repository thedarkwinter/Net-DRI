#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 16;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => undef});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('CentralNic::CentralNic');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv}, {extensions=>['-CentralNic::Fee','Fee'],brown_fee_version=>'0.23'});

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$c1,$c2,@fees);

####################################################################################################
## Fee extension version 0.23 https://tools.ietf.org/html/draft-ietf-regext-epp-fees-06
## We use a greeting here to switch the namespace version here to -0.23 testing
$R2=$E1.'<greeting><svID>fee-0.23-server</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.23</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.23','Fee 0.23 loaded correctly');
####################################################################################################

## The implementation has not changed since 0.21, so see 0.21 test file for all tests.

###################
###### domain_check (single)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">explore-0.space</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.23" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><fee:currency>USD</fee:currency><fee:cd avail="1"><fee:objID>explore-0.space</fee:objID><fee:command name="create"><fee:period unit="y">2</fee:period><fee:fee description="Registration Fee" refundable="1" grace-period="P5D">10.00</fee:fee></fee:command></fee:cd></fee:chkData></extension>'.$TRID.'</response>'.$E2;

# specify command(s) as an arrayref
$rc=$dri->domain_check('explore-0.space',{fee=>{currency => 'USD',command=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>explore-0.space</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.23" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.23 fee-0.23.xsd"><fee:currency>USD</fee:currency><fee:command name="create"/></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'Fee extension: domain_...');

is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info (action)');
is($dri->get_info('exist','domain','explore-0.space'),0,'domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee','domain','explore-0.space')};
is($d->{domain},'explore-0.space','domain_check get_info(domain)');
is($d->{price_avail},1,'domain_check parse fee (price_avail)');
is($d->{premium},0,'domain_check parse premium');
is($d->{currency},'USD','domain_check get_info(currency)');
is($d->{command}->{create}->{fee},10.00,'domain_check get_info(fee)');
is($d->{command}->{create}->{phase},undef,'domain_check get_info(phase)');
is($d->{command}->{create}->{sub_phase},undef,'domain_check get_info(sub_phase)');
is($d->{command}->{create}->{duration}->years(),'2','domain_check get_info(duration)');

# using the standardised methods
is($dri->get_info('is_premium'),0,'domain_checkget_info (is_premium) 0');
is($dri->get_info('price_currency'),'USD','domain_check get_info (price_currency)');
is($dri->get_info('create_price'),10.00,'domain_check get_info (create_price)');

exit 0;
