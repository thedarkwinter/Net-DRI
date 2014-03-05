#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI::Data::Contact;

use Test::More tests => 17;

can_ok('Net::DRI::Data::Contact',qw/new id validate name org street city sp pc cc email voice fax loid roid srid auth disclose/);

my $s=Net::DRI::Data::Contact->new();
isa_ok($s,'Net::DRI::Data::Contact');


$s->name('Test');
is(scalar($s->name()),'Test','Scalar access (simple set)');
my @d=$s->name();
is_deeply(\@d,['Test'],'List access (simple set)');

$s->name('Test1','Test2');
is(scalar($s->name()),'Test1','Scalar access (double set)');
@d=$s->name();
is_deeply(\@d,['Test1','Test2'],'List access (double set)');


my @S1=qw/A1 A2 A3/;
my @S2=qw/B1 B2 B3/;

$s=Net::DRI::Data::Contact->new();
$s->street(\@S1);
is_deeply(scalar($s->street()),\@S1,'street() Scalar access (simple set)');
is_deeply([$s->street()],[\@S1,undef],'street() List access (simple set)');
is($s->has_loc(),1,'street() has_loc (simple set)');
is($s->has_int(),0,'street() has_int (simple set)');

$s=Net::DRI::Data::Contact->new();
$s->street(\@S1,\@S2);
is_deeply(scalar($s->street()),\@S1,'street() Scalar access (double set)');
is_deeply([$s->street()],[\@S1,\@S2],'street() List access (double set)');
is($s->has_loc(),1,'street() has_loc (double set)');
is($s->has_int(),1,'street() has_int (double set)');


$s=Net::DRI::Data::Contact->new();
$s->org('Something é');
$s->loc2int();
is_deeply([$s->org()],['Something é','Something ?'],'loc2int()');
$s->int2loc();
is_deeply([$s->org()],['Something ?','Something ?'],'int2loc()');

TODO: {
        local $TODO="tests on validate()";
        ok(0);
}

exit 0;
