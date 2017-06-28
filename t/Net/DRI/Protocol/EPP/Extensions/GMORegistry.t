#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 2;
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
$dri->add_current_registry('GMORegistry::KYOTO'); # any will do
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc);

####################################################################################################
$R2=$E1.'<greeting><svID>GMO Registry EPP server EPP.GMOREGISTRY.NET</svID><svDate>2017-05-30T07:50:59.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.4</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:Gateway-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);

is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.5','Fee 0.5 loaded correctly');
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','SecDNS 1.1 loaded correctly');
####################################################################################################

exit 0;
