#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use DateTime::Duration;

use Test::More tests => 48;

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : "200 Command completed successfully\r\n.\r\n"); }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1}); ## we do not want caching for now

$dri->add_registry('VNDS',{tz=>'America/New_York'});
$dri->target('VNDS')->add_current_profile('p1','rrp',{f_send=>\&mysend,f_recv=>\&myrecv});

$R2="200 Command completed successfully\r\nregistration expiration date:2009-09-22 10:27:00.0\r\nstatus:ACTIVE\r\n.\r\n";
my $rc=$dri->domain_create('example2.com',{pure_create=>1,duration => DateTime::Duration->new(years => 10)});
is($R1,"add\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\n-Period:10\r\n.\r\n",'domain_create build');
is($rc->is_success(),1,'domain_create rc is_success');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
is($rc->code(),1000,'domain_create rc code');
is($rc->native_code(),200,'domain_create rc native_code');
is($rc->message(),'Command completed successfully','domain_create rc message');
my $d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is($d.'','2009-09-22T10:27:00','domain_create get_info(exDate) value');

my $s=$dri->get_info('status');

is($s->is_active(),1,'domain_create get_info(status) is_active');
is($s->is_published(),1,'domain_create get_info(status) is_published');
is($s->can_update(),1,'domain_create get_info(status) can_update');

$R2="211 Domain name not available\r\n.\r\n";
$rc=$dri->domain_check('example2.com');
is($R1,"check\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\n.\r\n",'domain_check send');
is($rc->is_success(),1,'domain_check rc is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),1,'domain_check get_info(exist)');
is($rc->code(),2302,'domain_check rc code');
is($rc->native_code(),211,'domain_check rc native_code');
is($rc->message(),'Domain name not available','domain_check rc message');
is($dri->domain_exist('example2.com'),1,'domain_exist');

$R2="213 Name server not available\r\nipAddress:192.10.10.10\r\n.\r\n";
$rc=$dri->host_check('ns1.example2.com');
is($R1,"check\r\nEntityName:NameServer\r\nNameServer:NS1.EXAMPLE2.COM\r\n.\r\n",'host_check send');
is($dri->host_exist('ns1.example2.com'),1,'host_exist');
is($dri->get_info('action'),'check','host_check get_info(action)');
is($dri->get_info('exist'),1,'host_check get_info(exist)');
my $dh=$dri->get_info('self');
my @c=$dh->get_names(1);
is_deeply(\@c,['ns1.example2.com'],'host_check get_info(self) get_names');

$R2="532 Domain names linked with name server\r\n.\r\n";
$rc=$dri->host_delete('ns1.registrarA.com');
is($R1,"del\r\nEntityName:NameServer\r\nNameServer:NS1.REGISTRARA.COM\r\n.\r\n",'host_delete send');
is($rc->is_success(),0,'host_delete rc is_success');
is($rc->code(),2305,'host_delete rc code');

$R2=undef;
$rc=$dri->domain_update_ns_add('example2.com',$dri->local_object('hosts')->set('ns3.registrarA.com'));
is($R1,"mod\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\nNameServer:ns3.registrara.com\r\n.\r\n",'domain_update_ns_add send');
$rc=$dri->domain_update_ns_del('example2.com',$dri->local_object('hosts')->set('ns1.registrarA.com'));
is($R1,"mod\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\nNameServer:ns1.registrara.com=\r\n.\r\n",'domain_update_ns_del send');
$rc=$dri->domain_update_ns('example2.com',$dri->local_object('hosts')->set('ns3.registrarA.com'),$dri->local_object('hosts')->set('ns1.registrarA.com'));
is($R1,"mod\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\nNameServer:ns3.registrara.com\r\nNameServer:ns1.registrara.com=\r\n.\r\n",'domain_update_ns send');

$R2="200 Command completed successfully\r\nnameserver:ns2.registrarA.com\r\nnameserver:ns3.registrarA.com\r\nregistration expiration date:2010-09-22 10:27:00.0\r\nregistrar:registrarA\r\nregistrar transfer date:1999-09-22 10:27:00.0\r\nstatus:ACTIVE\r\ncreated date:1998-09-22 10:27:00.0\r\ncreated by:registrarA\r\nupdated date:2002-09-22 10:27:00.0\r\nupdated by:registrarA\r\n.\r\n";
$rc=$dri->domain_info('example2.com');
is($R1,"status\r\nEntityName:Domain\r\nDomainName:EXAMPLE2.COM\r\n.\r\n",'domain_info send');
is($rc->is_success(),1,'domain_info rc is_success');
is($dri->result_is_success(),1,'result_is_success');
is($dri->result_code(),1000,'result_code');
is($dri->result_native_code(),200,'result_native_code');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
$dh=$dri->get_info('ns');
@c=$dh->get_names();
is_deeply(\@c,['ns2.registrara.com','ns3.registrara.com'],'domain_info get_info(host) get_names');
is($dri->get_info('exDate').'','2010-09-22T10:27:00','domain_info get_info(exDate)');
is($dri->get_info('clID'),'registrarA','domain_info get_info(clID)');
is($dri->get_info('trDate').'','1999-09-22T10:27:00','domain_info get_info(trDate)');
is($dri->get_info('trDate')->time_zone->name,'America/New_York','domain_info get_info(trDate)->time_zone->name');

is($dri->get_info('crDate').'','1998-09-22T10:27:00','domain_info get_info(crDate)');
is($dri->get_info('crID'),'registrarA','domain_info get_info(crID)');
is($dri->get_info('upDate').'','2002-09-22T10:27:00','domain_info get_info(upDate)');
is($dri->get_info('upID'),'registrarA','domain_info get_info(upID)');

$s=$dri->get_info('status');
is($s->is_active(),1,'domain_info get_info(status) is_active');

exit 0;
