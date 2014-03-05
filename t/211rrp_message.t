#!/usr/bin/perl -w

use Net::DRI::Protocol::RRP::Message;
use Encode;

use Test::More tests=>28;

my $n;

## Creation

$n=Net::DRI::Protocol::RRP::Message->new()->command('add')->entities('EntityName','Domain')->entities('DomainName','example.com')->options('Period',10);
is($n->as_string(),"add\r\nEntityName:Domain\r\nDomainName:example.com\r\n-Period:10\r\n.\r\n",'RRP Message create domain add 1 string');
is($n->command(),'add','RRP Message create domain add 1 command');

$n=Net::DRI::Protocol::RRP::Message->new()->command('add')->entities('EntityName','Domain')->entities('DomainName','example.com')->entities('NameServer',['ns1.example.com','ns2.example.com'])->options('Period',10);
is($n->as_string(),"add\r\nEntityName:Domain\r\nDomainName:example.com\r\n-Period:10\r\nNameServer:ns1.example.com\r\nNameServer:ns2.example.com\r\n.\r\n",'RRP Message create domain add 2');

$n=Net::DRI::Protocol::RRP::Message->new()->command('add')->entities('EntityName','NameServer')->entities('NameServer','ns1.example.com')->entities('IPAddress','198.41.1.11');
is($n->as_string(),"add\r\nEntityName:NameServer\r\nNameServer:ns1.example.com\r\nIPAddress:198.41.1.11\r\n.\r\n",'RRP Message create nameserver add string');

$n=Net::DRI::Protocol::RRP::Message->new()->command('check')->entities('EntityName','Domain')->entities('DomainName','example.com');
is($n->as_string(),"check\r\nEntityName:Domain\r\nDomainName:example.com\r\n.\r\n",'RRP Message create domain check');

$n=Net::DRI::Protocol::RRP::Message->new()->command('check')->entities('EntityName','NameServer')->entities('NameServer','ns1.example.com');
is($n->as_string(),"check\r\nEntityName:NameServer\r\nNameServer:ns1.example.com\r\n.\r\n",'RRP Message create nameserver check');

$n=Net::DRI::Protocol::RRP::Message->new()->command('del')->entities('EntityName','Domain')->entities('DomainName','example.com');
is($n->as_string(),"del\r\nEntityName:Domain\r\nDomainName:example.com\r\n.\r\n",'RRP Message create domain del');

$n=Net::DRI::Protocol::RRP::Message->new()->command('del')->entities('EntityName','NameServer')->entities('NameServer','ns1.registrarA.com');
is($n->as_string(),"del\r\nEntityName:NameServer\r\nNameServer:ns1.registrarA.com\r\n.\r\n",'RRP Message create nameserver del');

$n=Net::DRI::Protocol::RRP::Message->new()->command('describe')->options('Target','Protocol');
is($n->as_string(),"describe\r\n-Target:Protocol\r\n.\r\n",'RRP Message create describe');

$n=Net::DRI::Protocol::RRP::Message->new()->command('mod')->entities('EntityName','Domain')->entities('DomainName','example.com')->entities('NameServer',['ns3.registrarA.com','ns1.registrarA.com=']);
is($n->as_string(),"mod\r\nEntityName:Domain\r\nDomainName:example.com\r\nNameServer:ns3.registrarA.com\r\nNameServer:ns1.registrarA.com=\r\n.\r\n",'RRP Message create domain mod');

$n=Net::DRI::Protocol::RRP::Message->new()->command('mod')->entities('EntityName','NameServer')->entities('NameServer','ns1.registrarA.com')->entities('NewNameServer','ns2.registrarA.com')->entities('IPAddress',['198.42.1.11','198.41.1.11=']);
is($n->as_string(),"mod\r\nEntityName:NameServer\r\nNameServer:ns1.registrarA.com\r\nNewNameServer:ns2.registrarA.com\r\nIPAddress:198.42.1.11\r\nIPAddress:198.41.1.11=\r\n.\r\n",'RRP Message create nameserver mod');

$n=Net::DRI::Protocol::RRP::Message->new()->command('quit');
is($n->as_string(),"quit\r\n.\r\n",'RRP Message create quit');

$n=Net::DRI::Protocol::RRP::Message->new()->command('renew')->entities('EntityName','Domain')->entities('DomainName','example.com')->options('Period',9)->options('CurrentExpirationYear',2001);
is($n->as_string(),"renew\r\nEntityName:Domain\r\nDomainName:example.com\r\n-Period:9\r\n-CurrentExpirationYear:2001\r\n.\r\n",'RRP Message create domain renew');

$n=Net::DRI::Protocol::RRP::Message->new()->command('session')->options('Id','registrarA')->options('Password','i-am-registrarA');
is($n->as_string(),"session\r\n-Id:registrarA\r\n-Password:i-am-registrarA\r\n.\r\n",'RRP Message create session');

$n=Net::DRI::Protocol::RRP::Message->new()->command('status')->entities('EntityName','Domain')->entities('DomainName','example.com');
is($n->as_string(),"status\r\nEntityName:Domain\r\nDomainName:example.com\r\n.\r\n",'RRP Message create domain status');

$n=Net::DRI::Protocol::RRP::Message->new()->command('status')->entities('EntityName','NameServer')->entities('NameServer','ns1.registrarA.com');
is($n->as_string(),"status\r\nEntityName:NameServer\r\nNameServer:ns1.registrarA.com\r\n.\r\n",'RRP Message create nameserver status');

$n=Net::DRI::Protocol::RRP::Message->new()->command('transfer')->entities('EntityName','Domain')->entities('DomainName','example.com');
is($n->as_string(),"transfer\r\nEntityName:Domain\r\nDomainName:example.com\r\n.\r\n",'RRP Message create domain transfer');

$n=Net::DRI::Protocol::RRP::Message->new()->command('transfer')->entities('EntityName','Domain')->entities('DomainName','example.com')->options('Approve','Yes');
is($n->as_string(),"transfer\r\n-Approve:Yes\r\nEntityName:Domain\r\nDomainName:example.com\r\n.\r\n",'RRP Message create domain transfer');
ok(!Encode::is_utf8($n->as_string()),'Unicode : string sent on network is bytes not characters');

### Parse

use Net::DRI::Data::Raw;

my $R="\r";

my $r;
$r=Net::DRI::Data::Raw->new_from_string(<<EOF);
200 Command completed successfully$R
registration expiration date:2009-09-22 10:27:00.0$R
status:ACTIVE$R
.$R
EOF

$n=Net::DRI::Protocol::RRP::Message->new();
$n->parse($r);
## check result_code
is($n->errcode(),200,'RRP Message parse domain add, errcode');
is($n->errmsg(),'Command completed successfully','RRP Message parse domain add, errmsg');
eq_set([$n->entities()],['registration expiration date','status'],'RRP Message parse domain add, entities');
is($n->entities('registration expiration date'),'2009-09-22 10:27:00.0','RRP Message parse domain add, entity 1');
is($n->entities('status'),'ACTIVE','RRP Message parse domain add, entity 2');
is($n->entities('StAtus'),'ACTIVE','RRP Message parse domain add, entity 2 case insensitive');

$r=Net::DRI::Data::Raw->new_from_string(<<EOF);
200 Command completed successfully
.
EOF

$n=Net::DRI::Protocol::RRP::Message->new();
$n->parse($r);
is($n->errcode(),200,'RRP Message parse empty, errcode');
is($n->errmsg(),'Command completed successfully','RRP Message empty, errmsg');
eq_set([$n->entities()],[],'RRP Message parse empty, entities');
is_deeply($n->options(),{},'RRP Message parse empty, options');
is($n->is_success(),1,'RRP Message parse empty, is_success');


exit 0;
