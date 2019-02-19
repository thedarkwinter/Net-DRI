#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 31;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';  }

my $rc;
my $dri;
my $s;
my $d;
my ($dh,@c);

####################################################################################################



###
# IITCNR (.IT)
###
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('IITCNR');
$dri->add_current_profile('p1','epp',{f_send => \&mysend, f_recv => \&myrecv});
# test using only_local_extensions set to true (1)
$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.nic.it/ITNIC-EPP/extcon-2.0</extURI>http://www.nic.it/ITNIC-EPP/extdom-2.0<extURI></extURI><extURI>http://www.nic.it/ITNIC-EPP/extsecDNS-1.0</extURI><extURI>http://www.nic.it/ITNIC-EPP/extepp-2.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{only_local_extensions => 1}]);
is_string($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>http://www.nic.it/ITNIC-EPP/extcon-1.0</extURI><extURI>http://www.nic.it/ITNIC-EPP/extdom-2.0</extURI><extURI>http://www.nic.it/ITNIC-EPP/extepp-2.0</extURI><extURI>http://www.nic.it/ITNIC-EPP/extsecDNS-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'IITCNR - session login build only_local_extensions = 1');
# test based on Core.t and forcing IITCNR profile only_local_extensions set to false (0) - so login will be based/built on <greeting>
$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'Example EPP server epp.example.com','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2000-06-08T22:00:00','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','fr'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:obj1','urn:ietf:params:xml:ns:obj2','urn:ietf:params:xml:ns:obj3'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['http://custom/obj1ext-1.0'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['http://custom/obj1ext-1.0'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 0}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'IITCNR - session login build only_local_extensions = 0');
is($rc->is_success(),1,'IITCNR - session login is_success');
####################################################################################################



###
# Centralnic
###
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('NGTLD',{provider=>'centralnic'});
$dri->target('centralnic')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
# test using CentralNIC Fee - greeting return fee-0.11
$R2=$E1.'<greeting><svID>Fee-0.11-server</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.11</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{fee}->[0],'urn:ietf:params:xml:ns:fee-0.11','centralnic - Fee 0.11 loaded correctly');
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 0}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.11</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'centralnic - Fee 0.11 session login build only_local_extensions = 0');
is($rc->is_success(),1,'centralnic - session login is_success');
# test using CentralNIC Fee - greeting return fee-0.5 but enabling use of only_local_extensions to 1 - we should get following ns: auxcontact-0.1, idn-1.0 and regtype-0.1 (not sent in greeting on purpose)
$R2=$E1.'<greeting><svID>Fee-0.11-server</svID><svDate>2014-11-21T10:10:46.0751Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2', only_local_extensions => 1}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:auxcontact-0.1</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:regtype-0.1</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'centralnic - Fee 0.5 session login build only_local_extensions = 1');
####################################################################################################



###
# FRED
###
$dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('FRED');
$dri->target('FRED')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
# test based on Core.t
$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'FRED - session noop build (hello command)');
is($rc->is_success(),1,'FRED - session noop is_success');
is($rc->get_data('session','server','server_id'),'Example EPP server epp.example.com','FRED - session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2000-06-08T22:00:00','FRED - session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'FRED - session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en','fr'],'FRED - session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:obj1','urn:ietf:params:xml:ns:obj2','urn:ietf:params:xml:ns:obj3'],'FRED - session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['http://custom/obj1ext-1.0'],'FRED - session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['http://custom/obj1ext-1.0'],'FRED - session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','FRED - session noop get_data(session,server,dcp_string)');
$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{client_newpassword => 'bar-FOO2'}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'FRED - session login build default/only_local_extensions = 0');
is($rc->is_success(),1,'FRED - session login is_success');
# force only_local_extensions - loging should get bunch of FRED ns: domain-1.4, contact-1.6, keyset-1.3, fred-1.5 and nsset-1.2
$rc=$dri->process('session','login',['ClientX','foo-BAR2',{only_local_extensions => 1}]);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://www.nic.cz/xml/epp/contact-1.6</extURI><extURI>http://www.nic.cz/xml/epp/domain-1.4</extURI><extURI>http://www.nic.cz/xml/epp/fred-1.5</extURI><extURI>http://www.nic.cz/xml/epp/keyset-1.3</extURI><extURI>http://www.nic.cz/xml/epp/nsset-1.2</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build only_local_extensions = 0');
is($rc->is_success(),1,'session login is_success');
####################################################################################################



exit 0;