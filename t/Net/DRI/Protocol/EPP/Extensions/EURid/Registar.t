#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 15;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

########################################################################################################

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2014-09-13T09:31:14.123Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrar-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-1.1</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dynUpdate-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
use Data::Dumper;
is($dri->protocol()->ns()->{'registrar'}->[0],'http://www.eurid.eu/xml/epp/registrar-1.0','registrar 1.0 for server announcing 1.0');


## EU/2.1.09/info%20registrar/registrar-info01-cmd.xml
# Example of info registrar
$R2=$E1.'<response>'.r().'<resData><registrar:infData xmlns:registrar="http://www.eurid.eu/xml/epp/registrar-1.0"><registrar:amountAvailable>14995.17</registrar:amountAvailable><registrar:hitPoints><registrar:nbrHitPoints>2</registrar:nbrHitPoints><registrar:maxNbrHitPoints>5000</registrar:maxNbrHitPoints><registrar:blockedUntil>2015-09-20T00:00:00.0Z</registrar:blockedUntil></registrar:hitPoints><registrar:credits type="renewal">1133</registrar:credits></registrar:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->registrar_info();
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><registrar:info xmlns:registrar="http://www.eurid.eu/xml/epp/registrar-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/registrar-1.0 registrar-1.0.xsd"/></info><clTRID>ABC-12345</clTRID></command></epp>','registrar_info build');
is($rc->is_success(),1,'registrar_info is_success');

SKIP: {
  skip "TODO: regisrar object & dri->get_info", 4;

is($dri->get_info('action'),'info','registrar_info get_info(action)');
is($dri->get_info('amount_available'),14995.17,'registrar_info get_info(amount_available)');
is_deeply($dri->get_info('hitpoints'),{'current_number' => 2, 'maximum_number' => '5000', 'blocked_until' => '2015-09-20T00:00:00' },'registrar_info get_info(hitpoints)');
is_deeply($dri->get_info('credits'),{'renewal' => 1133 },'registrar_info get_info(credits)');
};

$s=$rc->get_data('hitpoints');
isa_ok($s,'HASH','registrar_info get_data(hitpoints)');
is($s->{current_number},2,'registrar_info get_data(hitpoints) current_number');
is($s->{maximum_number},5000,'registrar_info get_data(hitpoints) maximum_number');
isa_ok($s->{blocked_until},'DateTime','registrar_info get_data(hitpoints) blocked_until isa DateTime');
is(''.$s->{blocked_until},'2015-09-20T00:00:00','registrar_info get_data(hitpoints) blocked_until value');
is($rc->get_data('amount_available'),14995.17,'registrar_info get_data(amount_available)');
$s=$rc->get_data('credits');
isa_ok($s,'HASH','registrar_info get_data(credits)');
is($s->{renewal},1133,'registrar_info get_data(credits) renewal');

exit 0;
