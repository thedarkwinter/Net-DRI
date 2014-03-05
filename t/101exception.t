#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 45;

use Net::DRI::Exception;

my $e=Net::DRI::Exception->new(1,'test area',786,'test message'); my $ln=__LINE__;
my $fn=__FILE__;

isa_ok($e,'Net::DRI::Exception','Exception object');

is($e->is_error(),1,'retrieve error');
is($e->area(),'test area','retrieve area');
is($e->code(),786,'retrieve code');
is($e->msg(),'test message','retrieve message');

my $err=$e->as_string();

is($err,'EXCEPTION 786@test area from line '.$ln.' of file '.$fn.":\ntest message\n",'print complete error message');

$e=f1('A','B');
$err=$e->as_string();

like($err,qr/test message f3:A_B/,'backtrace of nested calls (final message)');
## \s* added because of perl 5.8.2 on netbsd : http://www.nntp.perl.org/group/perl.cpan.testers/2008/08/msg1973281.html
like($err,qr/main::f1\('A',\s*'B'\) called at ${fn}/,'                          (first level)');
like($err,qr/main::f2\('A',\s*'B'\) called at ${fn}/,'                          (second level)');
like($err,qr/main::f3\('A',\s*'B'\) called at ${fn}/,'                          (third level)');

eval { Net::DRI::Exception->die(1,'test area die',788,'test message die'); };
isa_ok($@,'Net::DRI::Exception','Exception->die() results');
is($@->is_error(),1,'Exception->die() is error');
is($@->area(),'test area die','Exception->die() area');
is($@->code(),788,'Exception->die() code');
is($@->msg(),'test message die','Exception->die() message');

eval { Net::DRI::Exception::method_not_implemented('foobar','zorglub'); };
isa_ok($@,'Net::DRI::Exception','method_not_implemented() results');
is($@->is_error(),1,'method_not_implemented() is error');
is($@->area(),'internal','method_not_implemented() area');
is($@->code(),1,'method_not_implemented() code');
is($@->msg(),'Method "foobar" not implemented in "zorglub"','method_not_implemented() message');

eval { Net::DRI::Exception::err_insufficient_parameters('stuff missing'); };
isa_ok($@,'Net::DRI::Exception','err_insufficient_parameters() results');
is($@->is_error(),1,'err_insufficient_parameters() is error');
is($@->area(),'internal','err_insufficient_parameters() area');
is($@->code(),2,'err_insufficient_parameters() code');
is($@->msg(),'Insufficient parameters: stuff missing','err_insufficient_parameters() message');

eval { Net::DRI::Exception::err_invalid_parameters('crazy stuff'); };
isa_ok($@,'Net::DRI::Exception','err_invalid_parameters() results');
is($@->is_error(),1,'err_invalid_parameters() is error');
is($@->area(),'internal','err_invalid_parameters() area');
is($@->code(),3,'err_invalid_parameters() code');
is($@->msg(),'Invalid parameters: crazy stuff','err_invalid_parameters() message');

eval { Net::DRI::Exception::usererr_insufficient_parameters('user stuff missing'); };
isa_ok($@,'Net::DRI::Exception','usererr_insufficient_parameters() results');
is($@->is_error(),0,'usererr_insufficient_parameters() is error');
is($@->area(),'internal','usererr_insufficient_parameters() area');
is($@->code(),2,'usererr_insufficient_parameters() code');
is($@->msg(),'Insufficient parameters: user stuff missing','usererr_insufficient_parameters() message');

eval { Net::DRI::Exception::usererr_invalid_parameters('crazy user stuff'); };
isa_ok($@,'Net::DRI::Exception','usererr_invalid_parameters() results');
is($@->is_error(),0,'usererr_invalid_parameters() is error');
is($@->area(),'internal','usererr_invalid_parameters() area');
is($@->code(),3,'usererr_invalid_parameters() code');
is($@->msg(),'Invalid parameters: crazy user stuff','usererr_invalid_parameters() message');

eval { Net::DRI::Exception::err_assert('something has failed'); };
isa_ok($@,'Net::DRI::Exception','err_assert() results');
is($@->is_error(),1,'err_assert is error');
is($@->area(),'internal','err_assert area');
is($@->code(),4,'err_assert code');
is($@->msg(),'Assert failed: something has failed','err_assert message');

exit 0;

sub f1 
{
 return f2(@_);
}

sub f2
{
 return f3(@_);
}

sub f3
{
 return Net::DRI::Exception->new(1,'test area f3',787,'test message f3:'.join('_',@_));
}
