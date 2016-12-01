#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Data::Dumper;

use Test::More tests => 78;
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
$dri->add_registry('NAME');
$dri->target('NAME')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{});

my ($rc,$s,$cs);

########################################################################################################

## Process greetings to select namespace versions
$R2=$E1.'<greeting><svID>VeriSign NameStore EPP Registration Server</svID><svDate>2016-11-24T12:00:08.0207Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>http://www.nic.name/epp/nameWatch-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.nic.name/epp/emailFwd-1.0</objURI><objURI>http://www.nic.name/epp/defReg-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://www.verisign.com/epp/lowbalance-poll-1.0</objURI><svcExtension><extURI>http://www.verisign-grs.com/epp/namestoreExt-1.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.verisign.com/epp/idnLang-1.0</extURI><extURI>http://www.nic.name/epp/persReg-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><other /><prov /></purpose><recipient><ours /><public /><unrelated /></recipient><retention><indefinite /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'emailFwd'}->[0],'http://www.nic.name/epp/emailFwd-1.0','emailFwd-1.0 for server announcing 1.0');

##############
# emailfwd Check - single
$R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:chkData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:cd><emailFwd:name avail="0">johnny@doe.name</emailFwd:name><emailFwd:reason>In use</emailFwd:reason></emailFwd:cd></emailFwd:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->emailfwd_check('johnny@doe.name');
is_string($R1,$E1.'<command><check><emailFwd:check xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>johnny@doe.name</emailFwd:name></emailFwd:check></check><clTRID>ABC-12345</clTRID></command>'.$E2, 'emailfwd_check specific premium build_xml');
is($rc->is_success(),1,'emailfwd_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','emailFwd','johnny@doe.name'),0,'emailfwd_check get_info(exist) from cache');


# # emailfwd Check - muliti (TODO: not working - need to fix the extension)
# $R2=$E1.'<response><result code="1000"><msg>Command completed successfully</msg></result><resData><emailFwd:chkData xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:cd><emailFwd:name avail="1">john@doe.name</emailFwd:name></emailFwd:cd><emailFwd:cd><emailFwd:name avail="0">johnny@doe.name</emailFwd:name><emailFwd:reason>In use</emailFwd:reason></emailFwd:cd><emailFwd:cd><emailFwd:name avail="1">jane@doe.name</emailFwd:name></emailFwd:cd></emailFwd:chkData></resData>'.$TRID.'</response>'.$E2;
# $rc=$dri->emailfwd_check('john@doe.name', 'johnny@doe.name', 'jane@doe.name');
# is_string($R1,$E1.'<command><check><emailFwd:check xmlns:emailFwd="http://www.nic.name/epp/emailFwd-1.0" xsi:schemaLocation="http://www.nic.name/epp/emailFwd-1.0 emailFwd-1.0.xsd"><emailFwd:name>john@doe.name</emailFwd:name><emailFwd:name>johnny@doe.name</emailFwd:name><emailFwd:name>jane@doe.name</emailFwd:name></emailFwd:check></check><clTRID>ABC-12345</clTRID></command>'.$E2, 'emailfwd_check specific premium build_xml');
# is($rc->is_success(),1,'emailfwd_check is_success');
# is($dri->get_info('action','emailfwd','doe'), 'check', 'emailfwd_check get_info(action)');
# is($dri->get_info('exist','emailfwd','doe'),0,'emailfwd_check get_info(exist)');
# is($dri->get_info('exist','emailfwd','john.doe'),1,'emailfwd_check get_info(exist)');
# is($dri->get_info('exist_reason','emailfwd','john.doe'),'Conflicting object exists','emailfwd_check get_info(exist)');
exit 0;
