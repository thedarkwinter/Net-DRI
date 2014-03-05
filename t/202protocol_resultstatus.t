#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;

use Test::More tests => 21;

my $n;
$n=Net::DRI::Protocol::ResultStatus->new('epp',1000,undef,1,'Command completed successfully');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->is_success(),1,'epp is_success');
is($n->native_code(),1000,'epp native_code');
is($n->code(),1000,'epp code');
is($n->message(),'Command completed successfully','epp message');
is($n->as_string(0),'SUCCESS 1000 Command completed successfully','epp as_string(0)');
is($n->as_string(1),'SUCCESS 1000 Command completed successfully','epp as_string(1)');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',200,1000,1,'Command completed successfully');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->is_success(),1,'rrp is_success');
is($n->native_code(),200,'rrp native_code');
is($n->code(),1000,'rrp code');
is($n->message(),'Command completed successfully','rrp message');

$n=Net::DRI::Protocol::ResultStatus->new('foobar');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),2400,'foobar code');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',0,undef,0);
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),2400,'rrp undef not success code');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',1,undef,1);
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),1000,'rrp undef success code');


my $a={A=>1,B=>2};
my $b={A=>1,B=>3,C=>2};
my $c={C=>4};
my $r2=Net::DRI::Protocol::ResultStatus::_merge(2,$a,$b,$c);
is_deeply($r2,{C=>4},'_merge with deep=2');

my $aa={DOM1 => $a, DOM2 => $b};
my $bb={DOM2 => $c, DOM3 => $a};
my $r1=Net::DRI::Protocol::ResultStatus::_merge(1,$aa,$bb);
is_deeply($r1,{ DOM1 => $a, DOM2 => $c, DOM3 => $a},'_merge with deep=1');

my $aaa={domain => { %$bb, FIRSTDOM => $c }};
my $bbb={domain => $bb, contact => $aa};
my $ccc={domain => { %$aa, NEWDOM => $c  }};
my $r0=Net::DRI::Protocol::ResultStatus::_merge(0,$aaa,$bbb,$ccc);
is_deeply($r0,{domain => { DOM2 => $b, DOM3 => $a, DOM1 => $a, FIRSTDOM => $c, NEWDOM => $c}, contact => $aa},'_merge with deep=0');

exit 0;
