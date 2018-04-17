#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 15;
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
$dri->add_registry('Neustar::TWNIC');
$dri->target('Neustar::TWNIC')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$csadd,$csdel,$c1,$c2);

####################################################################################################
# README: test based on their OT&E greeting. Strange urn:ietf:params:xml:ns:neulevel should not be urn:ietf:params:xml:ns:neulevel-1.0 ???
$R2=$E1.'<greeting><svID>Neustar EPP Server:tw10</svID><svDate>2018-04-17T10:03:55.0Z</svDate><svcMenu><version>1.0</version><lang>en-US</lang><objURI>urn:ietf:params:xml:ns:contact</objURI><objURI>urn:ietf:params:xml:ns:host</objURI><objURI>urn:ietf:params:xml:ns:domain</objURI><objURI>urn:ietf:params:xml:ns:svcsub</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:neulevel</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Neustar EPP Server:tw10','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2018-04-17T10:03:55','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en-US'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:contact','urn:ietf:params:xml:ns:host','urn:ietf:params:xml:ns:domain','urn:ietf:params:xml:ns:svcsub'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:neulevel','urn:ietf:params:xml:ns:secDNS-1.1'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:neulevel','urn:ietf:params:xml:ns:secDNS-1.1'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');
####################################################################################################

# domain check multi to test new profile :)
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.tw</domain:name></domain:cd><domain:cd><domain:name avail="0">example22.com.tw</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example22.tw','example22.com.tw');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.tw</domain:name><domain:name>example22.com.tw</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','example22.tw'),0,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example22.com.tw'),1,'domain_check multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','example22.com.tw'),'In use','domain_check multi get_info(exist_reason)');


####################################################################################################
exit 0;
