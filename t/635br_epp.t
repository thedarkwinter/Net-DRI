#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use Test::More tests => 75;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('BR');
$dri->target('BR')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$dh,@c,$co);

## Domain commands

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="0">e-xample.net.br</domain:name><domain:reason>In use</domain:reason></domain:cd><domain:cd><domain:name avail="0">example.org.br</domain:name></domain:cd><domain:cd><domain:name avail="1">example.com.br</domain:name></domain:cd><domain:cd><domain:name avail="1">example.ind.br</domain:name></domain:cd></domain:chkData></resData><extension><brdomain:chkData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:cd><brdomain:name>e-xample.net.br</brdomain:name><brdomain:equivalentName>example.net.br</brdomain:equivalentName><brdomain:organization>043.828.151/0001-45</brdomain:organization></brdomain:cd><brdomain:cd><brdomain:name>example.org.br</brdomain:name><brdomain:organization>043.828.151/0001-45</brdomain:organization></brdomain:cd><brdomain:cd hasConcurrent="1" inReleaseProcess="0"><brdomain:name>example.com.br</brdomain:name><brdomain:ticketNumber>123456</brdomain:ticketNumber></brdomain:cd><brdomain:cd hasConcurrent="0" inReleaseProcess="1"><brdomain:name>example.ind.br</brdomain:name></brdomain:cd></brdomain:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('e-xample.net.br','example.org.br','example.com.br','example.ind.br',{orgid => '005.506.560/0001-36'});
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>e-xample.net.br</domain:name><domain:name>example.org.br</domain:name><domain:name>example.com.br</domain:name><domain:name>example.ind.br</domain:name></domain:check></check><extension><brdomain:check xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:organization>005.506.560/0001-36</brdomain:organization></brdomain:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','e-xample.net.br'),1,'domain_check multi get_info(exist) 1/4');
is($dri->get_info('exist','domain','example.org.br'),1,'domain_check multi get_info(exist) 2/4');
is($dri->get_info('exist','domain','example.com.br'),0,'domain_check multi get_info(exist) 3/4');
is($dri->get_info('exist','domain','example.ind.br'),0,'domain_check multi get_info(exist) 4/4');


is($dri->get_info('equivalent_name','domain','e-xample.net.br'),'example.net.br','domain_check multi get_info(equivalent_name)');
is($dri->get_info('orgid','domain','e-xample.net.br'),'043.828.151/0001-45','domain_check multi get_info(orgid) 1');
is($dri->get_info('orgid','domain','example.org.br'),'043.828.151/0001-45','domain_check multi get_info(orgid) 2');
is($dri->get_info('has_concurrent','domain','example.com.br'),1,'domain_check multi get_info(has_concurrent) 1');
is($dri->get_info('in_release_process','domain','example.com.br'),0,'domain_check multi get_info(in_release_process) 1');
is_deeply($dri->get_info('ticket','domain','example.com.br'),[123456],'domain_check multi get_info(ticket)');
is($dri->get_info('has_concurrent','domain','example.ind.br'),0,'domain_check multi get_info(has_concurrent) 2');
is($dri->get_info('in_release_process','domain','example.ind.br'),1,'domain_check multi get_info(in_release_process) 2');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="pendingCreate"/><domain:contact type="admin">fan</domain:contact><domain:contact type="tech">fan</domain:contact><domain:contact type="billing">fan</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com.br</domain:hostName><domain:hostAddr ip="v4">192.0.2.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.net.br</domain:hostName></domain:hostAttr></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientX</domain:crID><domain:crDate>2006-01-30T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>2006-01-31T09:00:00.0Z</domain:upDate></domain:infData></resData><extension><brdomain:infData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber><brdomain:organization>005.506.560/0001-36</brdomain:organization><brdomain:releaseProcessFlags flag1="1"/><brdomain:pending><brdomain:dns status="queryTimeOut"><brdomain:hostName>ns1.example.com.br</brdomain:hostName><brdomain:limit>2006-02-13T22:00:00.0Z</brdomain:limit></brdomain:dns><brdomain:doc status="notReceived"><brdomain:docType>CNPJ</brdomain:docType><brdomain:limit>2006-03-01T22:00:00.0Z</brdomain:limit><brdomain:description lang="pt">Cadastro Nacional da Pessoa Juridica</brdomain:description></brdomain:doc><brdomain:releaseProc status="waiting"><brdomain:limit>2006-02-01T22:00:00.0Z</brdomain:limit></brdomain:releaseProc></brdomain:pending><brdomain:ticketNumberConc>123451</brdomain:ticketNumberConc><brdomain:ticketNumberConc>123455</brdomain:ticketNumberConc></brdomain:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.com.br',{ticket => 123456});
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example.com.br</domain:name></domain:info></info><extension><brdomain:info xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber></brdomain:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info 1 is_success');
is($dri->get_info('ticket'),123456,'domain_info 1 get_info(ticket)');
is($dri->get_info('orgid'),'005.506.560/0001-36','domain_info 1 get_info(orgid)');
is_deeply($dri->get_info('release_process'),{flag1=>1},'domain_info 1 get_info(release_process)');
my $p=$dri->get_info('pending');
is_deeply($p->{dns},[{status=>'queryTimeOut',hostname=>'ns1.example.com.br',limit=>'2006-02-13T22:00:00'}],'domain_info 1 get_info(pending) dns');
is_deeply($p->{doc},[{status=>'notReceived',type=>'CNPJ',limit=>'2006-03-01T22:00:00',description=>'Cadastro Nacional da Pessoa Juridica',lang=>'pt'}],'domain_info 1 get_info(pending) doc');
is_deeply($p->{release},{status => 'waiting', limit => '2006-02-01T22:00:00'},'domain_info 1 get_info(pending) release');
is_deeply($dri->get_info('ticket_concurrent'),[123451,123455],'domain_info 1 get_info(ticket_concurrent)');

$dri->cache_clear();

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:contact type="admin">fan</domain:contact><domain:contact type="tech">fan</domain:contact><domain:contact type="billing">fan</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com.br</domain:hostName><domain:hostAddr ip="v4">192.0.2.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.net.br</domain:hostName></domain:hostAttr></domain:ns><domain:clID>ClientX</domain:clID><domain:crID>ClientX</domain:crID><domain:crDate>2006-02-03T12:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>2006-02-03T12:00:00.0Z</domain:upDate></domain:infData></resData><extension><brdomain:infData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:organization>005.506.560/0001-36</brdomain:organization><brdomain:publicationStatus publicationFlag="onHold"><brdomain:onHoldReason>billing</brdomain:onHoldReason></brdomain:publicationStatus><brdomain:autoRenew active="1"/></brdomain:infData></extension>'.$TRID.'</response>'.$E2; 
$rc=$dri->domain_info('example.com.br',{ticket => 123456});
is($rc->is_success(),1,'domain_info 2 is_success');
is($dri->get_info('orgid'),'005.506.560/0001-36','domain_info 2 get_info(orgid)');
is_deeply($dri->get_info('publication'),{flag=>'onHold',onhold_reason=>['billing']},'domain_info 2 get_info(publication)');
is($dri->get_info('auto_renew'),1,'domain_info 2 get_info(auto_renew)');


$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:crDate>2006-01-30T22:00:00.0Z</domain:crDate></domain:creData></resData><extension><brdomain:creData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber><brdomain:pending><brdomain:dns status="queryTimeOut"><brdomain:hostName>ns1.example.com.br</brdomain:hostName><brdomain:limit>2006-02-13T22:00:00.0Z</brdomain:limit></brdomain:dns><brdomain:doc status="notReceived"><brdomain:docType>CNPJ</brdomain:docType><brdomain:limit>2006-03-01T22:00:00.0Z</brdomain:limit><brdomain:description lang="pt">Cadastro Nacional da Pessoa Juridica</brdomain:description></brdomain:doc></brdomain:pending><brdomain:ticketNumberConc>123451</brdomain:ticketNumberConc><brdomain:ticketNumberConc>123455</brdomain:ticketNumberConc></brdomain:creData></extension>'.$TRID.'</response>'.$E2;

my $cs=$dri->local_object('contactset');
$co=$dri->local_object('contact')->srid('fan');
$cs->set($co,'admin');
$cs->set($co,'tech');
$cs->set($co,'billing');
$rc=$dri->domain_create('example.com.br',{pure_create=>1,ns=>$dri->local_object('hosts')->add('ns1.example.com.br',['92.0.2.1'])->add('ns1.example.net.br'),contact=>$cs,auth=>{pw=>'2fooBAR'},orgid=>'005.506.560/0001-36',release=>{flag1=>1},auto_renew=>0});
is_string($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com.br</domain:hostName><domain:hostAddr ip="v4">92.0.2.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.net.br</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="admin">fan</domain:contact><domain:contact type="billing">fan</domain:contact><domain:contact type="tech">fan</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><brdomain:create xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:organization>005.506.560/0001-36</brdomain:organization><brdomain:releaseProcessFlags flag1="1"/><brdomain:autoRenew active="0"/></brdomain:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('ticket'),123456,'domain_create get_info(ticket)');
$p=$dri->get_info('pending');
is_deeply($p->{dns},[{status=>'queryTimeOut',hostname=>'ns1.example.com.br',limit=>'2006-02-13T22:00:00'}],'domain_create get_info(pending) dns');
is_deeply($p->{doc},[{status=>'notReceived',type=>'CNPJ',limit=>'2006-03-01T22:00:00',description=>'Cadastro Nacional da Pessoa Juridica',lang=>'pt'}],'domain_create get_info(pending) doc');
is_deeply($dri->get_info('ticket_concurrent'),[123451,123455],'domain_create get_info(ticket_concurrent)');

$dri->cache_clear();

$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:exDate>2007-04-03T00:00:00.0Z</domain:exDate></domain:renData></resData><extension><brdomain:renData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:publicationStatus publicationFlag="published"/></brdomain:renData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example.com.br',{current_expiration => DateTime->new(year=>2005,month=>4,day=>9)});
is_deeply($dri->get_info('publication'),{flag=>'published'},'domain_renew get_info(publication)');

$R2=$E1.'<response>'.r().'<extension><brdomain:updData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber><brdomain:pending><brdomain:doc status="notReceived"><brdomain:docType>CNPJ</brdomain:docType><brdomain:limit>2006-03-01T22:00:00.0Z</brdomain:limit><brdomain:description lang="pt">Cadastro Nacional da Pessoa Juridica</brdomain:description></brdomain:doc></brdomain:pending></brdomain:updData></extension>'.$TRID.'</response>'.$E2;
my $toc=$dri->local_object('changes');
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->srid('hkk');
$cs->set($co,'tech');
$toc->add('contact',$cs);
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->srid('fan');
$cs->set($co,'tech');
$toc->del('contact',$cs);
$dh=$dri->local_object('hosts');
$dh->add('ns2.example.com');
$toc->add('ns',$dh);
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.com.br');
$toc->del('ns',$dh);
$toc->set('ticket',123456);
$toc->set('release',{flag2=>1});
$toc->set('auto_renew',1);
$rc=$dri->domain_update('example.com.br',$toc);

is_string($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.com.br</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns2.example.com</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">hkk</domain:contact></domain:add><domain:rem><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com.br</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">fan</domain:contact></domain:rem></domain:update></update><extension><brdomain:update xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber><brdomain:chg><brdomain:releaseProcessFlags flag2="1"/><brdomain:autoRenew active="1"/></brdomain:chg></brdomain:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update_build');
is($rc->is_success(),1,'domain_update is_success');
$p=$dri->get_info('pending');
is_deeply($p->{doc},[{status=>'notReceived',type=>'CNPJ',limit=>'2006-03-01T22:00:00',description=>'Cadastro Nacional da Pessoa Juridica',lang=>'pt'}],'domain_update get_info(pending) doc');

$dri->cache_clear();

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>1999-04-04T22:01:00.0Z</qDate><msg>Pending action completed successfully.</msg></msgQ><resData><domain:panData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name paResult="0">example.com.br</domain:name><domain:paTRID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></domain:paTRID><domain:paDate>2006-02-13T22:30:00.0Z</domain:paDate></domain:panData></resData><extension><brdomain:panData xmlns:brdomain="urn:ietf:params:xml:ns:brdomain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brdomain-1.0 brdomain-1.0.xsd"><brdomain:ticketNumber>123456</brdomain:ticketNumber><brdomain:reason lang="pt">Nao obtivemos uma resposta adequada durante o prazo fixado do servidor de DNS (ns1.example.com.br) para o presente dominio.</brdomain:reason></brdomain:panData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id');
is($dri->get_info('object_type','message','12345'),'domain','message get_info object_type');
is($dri->get_info('object_id','message','12345'),'example.com.br','message get_info id');

## Information retrieved is available through the message ID we got back...
is($dri->get_info('ticket','message','12345'),123456,'message_retrieve message get_info(ticket)');
is($dri->get_info('reason','message','12345'),'Nao obtivemos uma resposta adequada durante o prazo fixado do servidor de DNS (ns1.example.com.br) para o presente dominio.','message_retrieve message get_info(reason)');
is($dri->get_info('reason_lang','message','12345'),'pt','message_retrieve message get_info(reason_lang)');
## ... and also through the object queried
is($dri->get_info('ticket','domain','example.com.br'),123456,'message_retrieve domain get_info(ticket)');
is($dri->get_info('reason','domain','example.com.br'),'Nao obtivemos uma resposta adequada durante o prazo fixado do servidor de DNS (ns1.example.com.br) para o presente dominio.','message_retrieve domain get_info(reason)');
is($dri->get_info('reason_lang','domain','example.com.br'),'pt','message_retrieve domain get_info(reason_lang)');

#########################################################################################################
## Contact commands

$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="0">e12345</contact:id></contact:cd></contact:chkData></resData><extension><brorg:chkData xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:ticketInfo><brorg:organization>005.506.560/0001-36</brorg:organization><brorg:ticketNumber>1234</brorg:ticketNumber><brorg:domainName>exemplo.com.br</brorg:domainName></brorg:ticketInfo></brorg:chkData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('e12345')->orgid('005.506.560/0001-36');
$rc=$dri->contact_check($co);
is_string($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e12345</contact:id></contact:check></check><extension><brorg:check xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:cd><brorg:id>e12345</brorg:id><brorg:organization>005.506.560/0001-36</brorg:organization></brorg:cd></brorg:check></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build');
is($dri->get_info('exist'),1,'contact_check get_info(exist)');
is($dri->get_info('ticket','orgid','005.506.560/0001-36'),1234,'contact_check get_info(ticket,orgid,$id)');
is($dri->get_info('domain','orgid','005.506.560/0001-36'),'exemplo.com.br','contact_check get_info(domain,orgid,$id)');
is($dri->get_info('ticket','domain','exemplo.com.br'),1234,'contact_check get_info(ticket,domain,$domain)');
is($dri->get_info('orgid','domain','exemplo.com.br'),'005.506.560/0001-36','contact_check get_info(orgid,domain,$domain)');

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e654321</contact:id><contact:roid>e654321-REP</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Example Inc.</contact:name><contact:addr><contact:street>Av. Nacoes Unidas, 11541</contact:street><contact:street>7o. andar</contact:street><contact:city>Sao Paulo</contact:city><contact:sp>SP</contact:sp><contact:pc>04578-000</contact:pc><contact:cc>BR</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+55.1155093500</contact:voice><contact:fax>+55.1155093501</contact:fax><contact:email>jdoe@example.com.br</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>2005-12-05T12:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>2005-12-05T12:00:00.0Z</contact:upDate><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData><extension><brorg:infData xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:organization>005.506.560/0001-36</brorg:organization><brorg:contact type="admin">fan</brorg:contact><brorg:responsible>John Doe</brorg:responsible><brorg:domainName>antispam.br</brorg:domainName><brorg:domainName>cert.br</brorg:domainName><brorg:domainName>dns.br</brorg:domainName><brorg:domainName>nic.br</brorg:domainName><brorg:domainName>ptt.br</brorg:domainName><brorg:domainName>registro.br</brorg:domainName></brorg:infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('e654321')->orgid('005.506.560/0001-36');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e654321</contact:id></contact:info></info><extension><brorg:info xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:organization>005.506.560/0001-36</brorg:organization></brorg:info></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
$co=$dri->get_info('self');
is($co->orgid(),'005.506.560/0001-36','contact_info get_info(self)->orgid');
$cs=$co->associated_contacts();
isa_ok($cs,'Net::DRI::Data::ContactSet','contact_info get_info(self)->associated_contacts');
is_deeply([$cs->types()],['admin'],'contact_info get_info(self)->associated_contacts->types');
isa_ok($cs->get('admin'),'Net::DRI::Data::Contact::BR','contact_info get_info(self)->associated_contacts->get(admin)');
is($cs->get('admin')->srid(),'fan','contact_info get_info(self)->associated_contacts->get(admin)->srid');
is($cs->get('admin')->orgid(),'005.506.560/0001-36','contact_info get_info(self)->associated_contacts->get(admin)->orgid');
is($co->responsible(),'John Doe','contact_info get_info(self)->responsible');
is_deeply($co->associated_domains(),[qw/antispam.br cert.br dns.br nic.br ptt.br registro.br/],'contact_info get_info(self)->associated_domains');

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e123456</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('e123456');
$co->name('Example Inc.');
$co->street(['Av. Nacoes Unidas, 11541','7o. andar']);
$co->city('Sao Paulo');
$co->sp('SP');
$co->pc('04578-000');
$co->cc('BR');
$co->voice('+55.1155093500x1234');
$co->fax('+55.1155093501');
$co->email('jdoe@example.com');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
$co->orgid('005.506.560/0001-36');
$co->associated_contacts($dri->local_object('contactset')->add($dri->local_object('contact')->srid('fan'),'admin'));
$co->responsible('John Doe');
$rc=$dri->contact_create($co);

is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e123456</contact:id><contact:postalInfo type="loc"><contact:name>Example Inc.</contact:name><contact:addr><contact:street>Av. Nacoes Unidas, 11541</contact:street><contact:street>7o. andar</contact:street><contact:city>Sao Paulo</contact:city><contact:sp>SP</contact:sp><contact:pc>04578-000</contact:pc><contact:cc>BR</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+55.1155093500</contact:voice><contact:fax>+55.1155093501</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><extension><brorg:create xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:organization>005.506.560/0001-36</brorg:organization><brorg:contact type="admin">fan</brorg:contact><brorg:responsible>John Doe</brorg:responsible></brorg:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('action'),'create','contact_create get_info(action)');
is($dri->get_info('exist'),1,'contact_create get_info(exist)');

$R2='';
$co=$dri->local_object('contact')->srid('e654321')->orgid('005.506.560/0001-36');
$toc=$dri->local_object('changes');
$toc->add('associated_contacts',$dri->local_object('contactset')->add($dri->local_object('contact')->srid('hkk'),'admin'));
$toc->del('associated_contacts',$dri->local_object('contactset')->add($dri->local_object('contact')->srid('fan'),'admin'));
$toc->set('responsible','John Joe');
$rc=$dri->contact_update($co,$toc);

is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>e654321</contact:id></contact:update></update><extension><brorg:update xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:organization>005.506.560/0001-36</brorg:organization><brorg:add><brorg:contact type="admin">hkk</brorg:contact></brorg:add><brorg:rem><brorg:contact type="admin">fan</brorg:contact></brorg:rem><brorg:chg><brorg:responsible>John Joe</brorg:responsible></brorg:chg></brorg:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

$dri->cache_clear();

$R2=$E1.'<response>'.r(1301,'Command completed successfully; ack to dequeue').'<msgQ count="5" id="12345"><qDate>1999-04-04T22:01:00.0Z</qDate><msg>Pending action completed successfully.</msg></msgQ><resData><contact:panData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id paResult="0">e123450</contact:id><contact:paTRID><clTRID>ABC-12345</clTRID><svTRID>54321-XYZ</svTRID></contact:paTRID><contact:paDate>2005-12-05T12:00:00.0Z</contact:paDate></contact:panData></resData><extension><brorg:panData xmlns:brorg="urn:ietf:params:xml:ns:brorg-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:brorg-1.0 brorg-1.0.xsd"><brorg:organization>004.857.383/6000-10</brorg:organization><brorg:reason lang="pt">Este documento nao existe na base de dados da SRF.</brorg:reason></brorg:panData></extension>'.$TRID.'</response>'.$E2;

$rc=$dri->message_retrieve();
is($dri->get_info('last_id'),12345,'message get_info last_id');
is($dri->get_info('object_type','message','12345'),'contact','message get_info object_type');
is($dri->get_info('object_id','message','12345'),'e123450','message get_info id');

## Information retrieved is available through the message ID we got back...
is($dri->get_info('orgid','message','12345'),'004.857.383/6000-10','message_retrieve message get_info(orgid)');
is($dri->get_info('reason','message','12345'),'Este documento nao existe na base de dados da SRF.','message_retrieve message get_info(reason)');
is($dri->get_info('reason_lang','message','12345'),'pt','message_retrieve message get_info(reason_lang)');
## ... and also through the object queried
is($dri->get_info('orgid','contact','e123450'),'004.857.383/6000-10','message_retrieve domain get_info(orgid)');
is($dri->get_info('reason','contact','e123450'),'Este documento nao existe na base de dados da SRF.','message_retrieve domain get_info(reason)');
is($dri->get_info('reason_lang','contact','e123450'),'pt','message_retrieve domain get_info(reason_lang)');

exit 0;
