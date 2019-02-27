#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 34;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('Neustar::IN');
$dri->target('Neustar::IN')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$dh,@c);
my ($c,$cs,$ns,$c1,$c2,$changes);

####################################################################################################
######## Initial Commands ########

my $drd = $dri->driver();
is_deeply( [$drd->transport_protocol_default('epp')],['Net::DRI::Transport::Socket',{'ssl_version'=>'TLSv12', 'ssl_cipher_list' => undef},'Net::DRI::Protocol::EPP::Extensions::Neustar',{ 'brown_fee_version' => '0.6' }],'IN - epp transport_protocol_default');
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');

# Use SecDNS-1.1
$R2=$E1.'<greeting><svID>epp.ote.neustar.in</svID><svDate>2019-02-15T11:58:58.034Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>en-AU</lang><lang>en-US</lang><lang>en-GB</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ar:params:xml:ns:idn-1.0</extURI><extURI>urn:X-ar:params:xml:ns:kv-1.0</extURI><extURI>urn:X-ar:params:xml:ns:kv-1.1</extURI><extURI>urn:ar:params:xml:ns:block-1.0</extURI><extURI>urn:ar:params:xml:ns:variant-1.1</extURI><extURI>urn:ar:params:xml:ns:application-1.0</extURI><extURI>urn:ar:params:xml:ns:tmch-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:signedMark-1.0</extURI><extURI>urn:ar:params:xml:ns:price-1.0</extURI><extURI>urn:ar:params:xml:ns:price-1.1</extURI><extURI>urn:ar:params:xml:ns:price-1.2</extURI><extURI>urn:ar:params:xml:ns:fund-1.0</extURI><extURI>urn:ietf:params:xml:ns:neulevel-1.0</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:allocationToken-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.6</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');

####################################################################################################
######## Domain Commands ########

# Domain Create
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'tech');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'billing');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.in');
$dh->add('ns2.example.in',['1.2.3.4'],[],1);
$rc=$dri->domain_create('example.in',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,ns=>$dh,auth=>{pw=>'opqrstuv'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostObj>ns1.example.in</domain:hostObj><domain:hostObj>ns2.example.in</domain:hostObj></domain:ns><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="billing">pass1236-FA</domain:contact><domain:contact type="tech">pass1236-FA</domain:contact><domain:authInfo><domain:pw>opqrstuv</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build_xml');
is($rc->is_success(),1,'domain_create is_success');

# Domain Create /w 1 DS Record
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'tech');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'billing');
$rc = $dri->domain_create('dsdomain1.in',
  {
    pure_create=>1,
    duration=>DateTime::Duration->new(years=>'1'),
    contact=>$cs,
    auth=>{pw=>'fooBar'},
    description=>'testing domain description extension',
    secdns=>
    [{
      keyTag=>12345,
      alg=>3,
      digestType=>1,
      digest=>'49FD46E6C4B45C55D4AC49FD46E6C4B45C55D4AC',
    }]
  });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dsdomain1.in</domain:name><domain:period unit="y">1</domain:period><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="billing">pass1236-FA</domain:contact><domain:contact type="tech">pass1236-FA</domain:contact><domain:authInfo><domain:pw>fooBar</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC49FD46E6C4B45C55D4AC</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create secDNS build xml');
is($rc->is_success(),1,'domain_create secDNS is_success');

# Domain Create /w 2 DS Record
$cs=$dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('test1106-27'),'registrant');
$cs->add($dri->local_object('contact')->srid('huma1106-28'),'admin');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'tech');
$cs->add($dri->local_object('contact')->srid('pass1236-FA'),'billing');
$rc = $dri->domain_create('dsdomain1.in',
  {
    pure_create=>1,
    duration=>DateTime::Duration->new(years=>'1'),
    contact=>$cs,
    auth=>{pw=>'fooBar'},
    description=>'testing domain description extension',
    secdns=>
    [{
      keyTag=>12345,
      alg=>3,
      digestType=>1,
      digest=>'49FD46E6C4B45C55D4AC49FD46E6C4B45C55D4AD',
    },{
      keyTag=>12345,
      alg=>3,
      digestType=>1,
      digest=>'49FC66E6C4B45C56D4AC49FD46E6C4B45C55D4AE',
    }]
  });
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dsdomain1.in</domain:name><domain:period unit="y">1</domain:period><domain:registrant>test1106-27</domain:registrant><domain:contact type="admin">huma1106-28</domain:contact><domain:contact type="billing">pass1236-FA</domain:contact><domain:contact type="tech">pass1236-FA</domain:contact><domain:authInfo><domain:pw>fooBar</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FD46E6C4B45C55D4AC49FD46E6C4B45C55D4AD</secDNS:digest></secDNS:dsData><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>49FC66E6C4B45C56D4AC49FD46E6C4B45C55D4AE</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create secDNS multiple_records build xml');
is($rc->is_success(),1,'domain_create secDNS multiple_records is_success');

# Domain Update ADD 'secDNS'
$changes = $dri->local_object('changes');
$changes->add('secdns',[{
	keyTag=>12348,
	alg=>3,
	digestType=>1,
	digest=>'38EC35D5B3A34B44C39B38EC35D5B3A34B44C39B',
}]);
$rc = $dri->domain_update('example.in', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:add><secDNS:dsData><secDNS:keyTag>12348</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update add_DS_record build_xml');
is($rc->is_success(),1,'domain_update add_DS_record is_success');

# Domain Update Delete ALL 'secDNS'
$changes = $dri->local_object('changes');
$changes->del('secdns','all');
$rc = $dri->domain_update('example.in', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.in</domain:name></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:rem><secDNS:all>true</secDNS:all></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update remove_all_DS_record build_xml');
is($rc->is_success(),1,'domain_update remove_all_DS_record is_success');

# Domain Update ADD/REM 2 NS
$changes = $dri->local_object('changes');
$changes->del('ns',$dri->local_object('hosts')->set(['ns1.example.in'],['ns2.example.in']));
$changes->add('ns',$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']));
$rc = $dri->domain_update('domain.in', $changes);
is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domain.in</domain:name><domain:add><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns></domain:add><domain:rem><domain:ns><domain:hostObj>ns1.example.in</domain:hostObj><domain:hostObj>ns2.example.in</domain:hostObj></domain:ns></domain:rem></domain:update></update><clTRID>ABC-12345</clTRID></command></epp>', 'domain_update add_rem_two_ns build_xml');
is($rc->is_success(),1,'domain_update add_rem_two_ns is_success');

#####################################################################################################
######### Fee Commands ####### duplicated & modified from KNET.t

## fee-check-class
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="1">crrc.in</domain:name></domain:cd></domain:chkData></resData><extension><fee:chkData xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:cd><fee:name>crrc.in</fee:name><fee:currency>INR</fee:currency><fee:command>create</fee:command><fee:period unit="y">1</fee:period><fee:fee applied="delayed" description="Registration fee 0.6" grace-period="P5D" refundable="1">100.00</fee:fee><fee:class>premium</fee:class></fee:cd></fee:chkData>    </extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('crrc.in',{fee=>{action=>'create'}});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>crrc.in</domain:name></domain:check></check><extension><fee:check xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:domain><fee:name>crrc.in</fee:name><fee:command>create</fee:command></fee:domain></fee:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'fee 0.6 extension: domain_check build');
is($dri->get_info('action'),'check','fee 0.6 extension: domain_check get_info(action)');
is($dri->get_info('exist'),0,'fee 0.6 extension: domain_check get_info(exist)');
$d = shift @{$dri->get_info('fee')};
is($d->{domain},'crrc.in','fee 0.6 extension: domain_check single parse domain');
is($d->{premium},1,'fee 0.6 extension: domain_check single parse premium');
is($d->{currency},'INR','fee 0.6 extension: domain_check single parse currency');
is($d->{action},'create','fee 0.6 extension: domain_check single parse action');
is($d->{duration}->years(),1,'fee 0.6 extension: domain_check singe parse duration');
is($d->{fee},100.00,'fee 0.6 extension: domain_check singe parse fee');

## fee-create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>crrc.in</domain:name><domain:crDate>2016-04-11T07:31:58.0Z</domain:crDate><domain:exDate>2017-04-11T07:31:58.0Z</domain:exDate></domain:creData></resData><extension><fee:creData xmlns:fee="urn:ietf:params:xml:ns:fee-0.6"><fee:currency>INR</fee:currency><fee:fee applied="delayed" grace-period="P8D" refundable="1">100.00</fee:fee><fee:balance>9664204.00</fee:balance></fee:creData></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('abc001');
$cs->set($c1,'registrant');
$cs->set($c1,'admin');
$cs->set($c1,'tech');
$cs->set($c1,'billing');
$rc=$dri->domain_create('crrc.in',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),contact=>$cs,auth=>{pw=>'abc123'},fee=>{currency=>'INR',fee=>'100.00'}});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>crrc.in</domain:name><domain:period unit="y">1</domain:period><domain:registrant>abc001</domain:registrant><domain:contact type="admin">abc001</domain:contact><domain:contact type="billing">abc001</domain:contact><domain:contact type="tech">abc001</domain:contact><domain:authInfo><domain:pw>abc123</domain:pw></domain:authInfo></domain:create></create><extension><fee:create xmlns:fee="urn:ietf:params:xml:ns:fee-0.6" xsi:schemaLocation="urn:ietf:params:xml:ns:fee-0.6 fee-0.6.xsd"><fee:currency>INR</fee:currency><fee:fee>100.00</fee:fee></fee:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'fee 0.6 extension: domain_create build');
is($rc->is_success(),1,'fee 0.6 extension: domain_create is is_success');
is($dri->get_info('action'),'create','fee 0.6 extension: domain_create get_info (action)');
$d=$rc->get_data('fee');
is($d->{currency},'INR','fee 0.6 extension: domain_create parse currency');
is($d->{fee},100.00,'fee 0.6 extension: domain_create parse fee');
is($d->{balance},9664204.00,'fee 0.6 extension: domain_create parse balance');

#####################################################################################################
######### Closing Commands ########

$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');

#####################################################################################################
######### 4.1 Example from "NSR - Migration Guide - 2.0.pdf" ########
$R2='';
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('jd1234');
$c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net');
$dh->add('ns2.example.net');
$rc=$dri->domain_create('xn--h2brj9c.xn--h2brj9c',{pure_create=>1,duration=>DateTime::Duration->new(years=>2),ns=>$dh,contact=>$cs,auth=>{pw=>'2fooBAR'}, idn_table => 'hin-Deva'});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>xn--h2brj9c.xn--h2brj9c</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.net</domain:hostObj><domain:hostObj>ns2.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><idn:data xmlns:idn="urn:ietf:params:xml:ns:idn-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:idn-1.0 idn-1.0.xsd"><idn:table>hin-Deva</idn:table></idn:data></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build with IDN in Hindi');


exit 0;
