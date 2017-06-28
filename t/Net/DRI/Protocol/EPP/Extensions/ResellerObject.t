#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 41;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_current_registry('VeriSign::COM_NET');
$dri->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['ResellerObject','-VeriSign::NameStore']});

my $rc;
my $ro=$dri->remote_object('reseller');


$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response> <result code="1000"><msg>Command completed successfully</msg></result><resData><reseller:chkData xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0"><reseller:cd><reseller:id avail="1">res1523</reseller:id></reseller:cd><reseller:cd><reseller:id avail="0">re1523</reseller:id><reseller:reason>In use</reseller:reason></reseller:cd><reseller:cd><reseller:id avail="1">1523res</reseller:id></reseller:cd></reseller:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$ro->check([qw/res1523 re1523 1523res/]);
is_string($R1,$E1.'<command><check><reseller:check xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:reseller-1.0 reseller-1.0.xsd"><reseller:id>res1523</reseller:id><reseller:id>re1523</reseller:id><reseller:id>1523res</reseller:id></reseller:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'reseller check build');
is($rc->get_data('reseller','res1523','action'),'check','get_data reseller check 1');
is($rc->get_data('reseller','res1523','exist'),0,'get_data reseller check 2');
is($rc->get_data('reseller','re1523','action'),'check','get_data reseller check 3');
is($rc->get_data('reseller','re1523','exist'),1,'get_data reseller check 4');
is($rc->get_data('reseller','re1523','exist_reason'),'In use','get_data reseller check 5');
is($rc->get_data('reseller','1523res','action'),'check','get_data reseller check 6');
is($rc->get_data('reseller','1523res','exist'),0,'get_data reseller check 7');



$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><reseller:infData xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0"><reseller:id>res1523</reseller:id><reseller:roid>res1523-REP</reseller:roid><reseller:state>ok</reseller:state><reseller:parentId>1523res</reseller:parentId><reseller:postalInfo type="int"><reseller:name>Example Reseller Inc.</reseller:name><reseller:addr><reseller:street>123 Example Dr.</reseller:street><reseller:street>Suite 100</reseller:street><reseller:city>Dulles</reseller:city><reseller:sp>VA</reseller:sp><reseller:pc>20166-6503</reseller:pc><reseller:cc>US</reseller:cc></reseller:addr></reseller:postalInfo><reseller:voice x="1234">+1.7035555555</reseller:voice><reseller:fax>+1.7035555556</reseller:fax><reseller:email>contact@reseller.example</reseller:email><reseller:url>http://reseller.example</reseller:url><reseller:contact type="admin">sh8013</reseller:contact><reseller:contact type="billing">sh8013</reseller:contact><reseller:clID>ClientY</reseller:clID><reseller:crID>ClientX</reseller:crID><reseller:crDate>1999-04-03T22:00:00.0Z</reseller:crDate><reseller:upID>ClientX</reseller:upID><reseller:upDate>1999-12-03T09:00:00.0Z</reseller:upDate><reseller:disclose flag="0"><reseller:voice/><reseller:email/></reseller:disclose></reseller:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$ro->info('res1523');
is_string($R1,$E1.'<command><info><reseller:info xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:reseller-1.0 reseller-1.0.xsd"><reseller:id>res1523</reseller:id></reseller:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'reseller info build');
is($rc->get_data('reseller','res1523','action'),'info','get_data reseller info 1');
is($rc->get_data('reseller','res1523','exist'),1,'get_data reseller info 2');
my $cs=$rc->get_data('reseller','res1523','contact');
is(ref $cs,'Net::DRI::Data::ContactSet','get_data reseller info 3');
is_deeply([$cs->types()],['admin','billing','main'],'get_data reseller info 4');
my $co=$cs->get('main');
is($rc->get_data('reseller','res1523','id'),'res1523','get_data reseller info 5');
is($rc->get_data('reseller','res1523','roid'),'res1523-REP','get_data reseller info 6');
is($rc->get_data('reseller','res1523','status'),'ok','get_data reseller info 7');
is($rc->get_data('reseller','res1523','parent_id'),'1523res','get_data reseller info 8');
is($co->has_int(),1,'get_data reseller info 9');
is(($co->name())[1],'Example Reseller Inc.','get_data reseller info 10');
is_deeply(($co->street())[1],['123 Example Dr.','Suite 100'],'get_data reseller info 11');
is(($co->city())[1],'Dulles','get_data reseller info 12');
is(($co->sp())[1],'VA','get_data reseller info 13');
is(($co->pc())[1],'20166-6503','get_data reseller info 14');
is(($co->cc())[1],'US','get_data reseller info 15');
is($co->voice(),'+1.7035555555x1234','get_data reseller info 16');
is($co->fax(),'+1.7035555556','get_data reseller info 17');
is($co->email(),'contact@reseller.example','get_data reseller info 18');
is($rc->get_data('reseller','res1523','url'),'http://reseller.example','get_data reseller info 19');
is($cs->get('admin')->srid(),'sh8013','get_data reseller info 20');
is($cs->get('billing')->srid(),'sh8013','get_data reseller info 21');
is($rc->get_data('reseller','res1523','clID'),'ClientY','get_data reseller info 22');
is($rc->get_data('reseller','res1523','crID'),'ClientX','get_data reseller info 23');
is(''.$rc->get_data('reseller','res1523','crDate'),'1999-04-03T22:00:00','get_data reseller info 24');
is($rc->get_data('reseller','res1523','upID'),'ClientX','get_data reseller info 25');
is(''.$rc->get_data('reseller','res1523','upDate'),'1999-12-03T09:00:00','get_data reseller info 26');
is_deeply($co->disclose(),{ voice => 0, email => 0 },'get_data reseller info 27');



$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><reseller:creData xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0"><reseller:id>res1523</reseller:id><reseller:crDate>1999-04-03T22:00:00.0Z</reseller:crDate></reseller:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->name('Example Reseller Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('contact@reseller.example');
$co->disclose({ voice => 0, email => 0 });
$cs->set($co,'main');
$co=$dri->local_object('contact')->srid('sh8013');
$cs->set($co,'admin');
$cs->set($co,'billing');
$rc=$ro->create('res1523',{ status => 'ok', parent_id => '1523res', contact => $cs, url => 'http://reseller.example' } );
is_string($R1,$E1.'<command><create><reseller:create xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:reseller-1.0 reseller-1.0.xsd"><reseller:id>res1523</reseller:id><reseller:state>ok</reseller:state><reseller:parentId>1523res</reseller:parentId><reseller:postalInfo type="loc"><reseller:name>Example Reseller Inc.</reseller:name><reseller:addr><reseller:street>123 Example Dr.</reseller:street><reseller:street>Suite 100</reseller:street><reseller:city>Dulles</reseller:city><reseller:sp>VA</reseller:sp><reseller:pc>20166-6503</reseller:pc><reseller:cc>US</reseller:cc></reseller:addr></reseller:postalInfo><reseller:voice x="1234">+1.7035555555</reseller:voice><reseller:fax>+1.7035555556</reseller:fax><reseller:email>contact@reseller.example</reseller:email><reseller:url>http://reseller.example</reseller:url><reseller:contact type="admin">sh8013</reseller:contact><reseller:contact type="billing">sh8013</reseller:contact><reseller:disclose flag="0"><reseller:voice/><reseller:email/></reseller:disclose></reseller:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'reseller create build');
is($rc->get_data('reseller','res1523','id'),'res1523','get_data reseller create 1');
is(''.$rc->get_data('reseller','res1523','crDate'),'1999-04-03T22:00:00','get_data reseller create 2');



$R2='';
$rc=$ro->delete('res1523');
is_string($R1,$E1.'<command><delete><reseller:delete xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:reseller-1.0 reseller-1.0.xsd"><reseller:id>res1523</reseller:id></reseller:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'reseller delete build');



$R2='';
my $toc=$dri->local_object('changes');
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('sh8013'),'tech');
$toc->add('contact',$cs);
$cs=$dri->local_object('contactset');
$co=$dri->local_object('contact');
$co->org('');
$co->street(['124 Example Dr.','Suite 200']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7034444444');
$co->fax('');
$co->disclose({ voice => 1, email => 1 });
$cs->set($co,'main');
$toc->set('contact',$cs);
$toc->set('status','readonly');
$rc=$ro->update('res1523',$toc);
is_string($R1,$E1.'<command><update><reseller:update xmlns:reseller="urn:ietf:params:xml:ns:reseller-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:reseller-1.0 reseller-1.0.xsd"><reseller:id>res1523</reseller:id><reseller:add><reseller:contact type="tech">sh8013</reseller:contact></reseller:add><reseller:chg><reseller:state>readonly</reseller:state><reseller:postalInfo type="loc"><reseller:org/><reseller:addr><reseller:street>124 Example Dr.</reseller:street><reseller:street>Suite 200</reseller:street><reseller:city>Dulles</reseller:city><reseller:sp>VA</reseller:sp><reseller:pc>20166-6503</reseller:pc><reseller:cc>US</reseller:cc></reseller:addr></reseller:postalInfo><reseller:voice>+1.7034444444</reseller:voice><reseller:fax/><reseller:disclose flag="1"><reseller:voice/><reseller:email/></reseller:disclose></reseller:chg></reseller:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'reseller update build');

exit 0;
