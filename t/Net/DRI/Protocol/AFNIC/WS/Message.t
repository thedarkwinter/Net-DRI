#!/usr/bin/perl -w

use Net::DRI::Protocol::AFNIC::WS::Message;

use Test::More tests=>13;

my $n;

## Creation

$n=Net::DRI::Protocol::AFNIC::WS::Message->new();
is($n->service(),undef,'new empty service()');
is($n->method(),undef,'new empty method()');
is_deeply($n->params(),[],'new empty params()');
is($n->errcode(),undef,'new empty errcode()');

$n->method('example');
is($n->method(),'example','method() get/set');
$n->method('check_domain');
$n->params(['toto.fr']);

## Parse

$n=Net::DRI::Protocol::AFNIC::WS::Message->new();
$r={free=>1};
$n->parse($r);
is($n->errcode(),undef,'parse free=1');
is_deeply($n->result(),$r,'parse set result()');
is($n->is_success(),1,'parse is_success');
my $rs=$n->result_status();
is($rs->code(),1000,'result_status code');

$r={free=>0,reason=>1,message=>'whatever'};
$n=Net::DRI::Protocol::AFNIC::WS::Message->new();
$n->parse($r);
is($n->errcode(),1,'parse free=0');
is_deeply($n->result(),$r,'parse set result()');
is($n->is_success(),0,'parse is_success');
$rs=$n->result_status();
is($rs->code(),2302,'result_status code');


exit 0;
