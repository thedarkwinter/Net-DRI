#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;
use Test::More tests => 14;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('Nominet::Amazon');
$dri->target('Nominet::Amazon')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$dh,@c,$co,$cs,$ns);

## Session commands

$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');


$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

###
# greeting - copy/paste from .moi OT&E
###
$R2=$E1.'<greeting><svID>Nominet gTLD server</svID><svDate>2019-04-15T13:43:25Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.23</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:allocationToken-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/></recipient><retention><business/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Nominet gTLD server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2019-04-15T13:43:25','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:launch-1.0','urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:fee-0.23','urn:ietf:params:xml:ns:idn-1.0','urn:ietf:params:xml:ns:allocationToken-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:launch-1.0','urn:ietf:params:xml:ns:secDNS-1.1','urn:ietf:params:xml:ns:rgp-1.0','urn:ietf:params:xml:ns:fee-0.23','urn:ietf:params:xml:ns:idn-1.0','urn:ietf:params:xml:ns:allocationToken-1.0'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/></recipient><retention><business/></retention></statement>','session noop get_data(session,server,dcp_string)');


# TODO:
# $R2='';
# $rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2'}]);
# is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
# is($rc->is_success(),1,'session login is_success');