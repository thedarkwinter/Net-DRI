#!/usr/bin/perl -w

use Net::DRI::Data::Hosts;

use Test::More tests => 25;

my $d=Net::DRI::Data::Hosts->new();
isa_ok($d,'Net::DRI::Data::Hosts');

$d=Net::DRI::Data::Hosts->new('ns.example.foo',['1.2.3.4','1.2.3.5']);
$d->name('test1');
$d->loid(12345);
isa_ok($d,'Net::DRI::Data::Hosts');
is($d->count(),1,'count()');
my @c;
@c=$d->get_details(1);
is_deeply($c[1],['1.2.3.4','1.2.3.5'],'get_details(integer) ip address');
is($d->name(),'test1','name()');
is($d->loid(),12345,'loid()');

@c=$d->get_details('ns.example.foo');
is_deeply($c[1],['1.2.3.4','1.2.3.5'],'get_details(name) ip address');
$d->add('ns.example.foo',['1.2.3.5']);
@c=$d->get_details('ns.example.foo');
is_deeply($c[1],['1.2.3.4','1.2.3.5'],'get_details(name) ip address add 1');
$d->add('ns.example.foo',['1.2.3.6']);
@c=$d->get_details('ns.example.foo');
is_deeply($c[1],['1.2.3.4','1.2.3.5','1.2.3.6'],'get_details(name) ip address add 2');
$d->add('ns.example.foo',[],['2001:0:0:0:8:800:200C:417A']);
@c=$d->get_details('ns.example.foo');
is_deeply($c[1],['1.2.3.4','1.2.3.5','1.2.3.6'],'get_details(name) ip address add 3 ip4');
is_deeply($c[2],['2001:0:0:0:8:800:200C:417A'],'get_details(name) ip address add 3 ip6');

$d=Net::DRI::Data::Hosts->new('ns.example.foo',['1.2.3.4','1.2.3.4']);
isa_ok($d,'Net::DRI::Data::Hosts');
@c=$d->get_details(1);
is_deeply($c[1],['1.2.3.4'],'remove dups IP');
is(($d->get_names(1))[0],'ns.example.foo','get_names()');

my $dd=$d->add('ns2.example.foo',['1.2.10.4']);
isa_ok($dd,'Net::DRI::Data::Hosts');
is_deeply($d,$dd,'add() returns the object itself');
@c=$d->get_names();
is_deeply(\@c,['ns.example.foo','ns2.example.foo'],'get_names() after add');
@c=$d->get_names(2);
is_deeply(\@c,['ns.example.foo','ns2.example.foo'],'get_names(2) after add');
@c=$d->get_names(1);
is_deeply(\@c,['ns.example.foo'],'get_names(1) after add');

$d->set(['ns.example.foo',['1.2.3.4','1.2.3.5']]);
is($d->count(),1,'count() after set()');
@c=$d->get_details(1);
is_deeply($c[1],['1.2.3.4','1.2.3.5'],'get_details(integer) ip address after set()');

$d->add('test.extra.parameters',[],[],{key1=>'v1',key2=>2});
@c=$d->get_details(2);
isa_ok($c[-1],'HASH');
is_deeply($c[-1],{key1=>'v1',key2=>2},'correct retrieval of extra parameters');
$d->add('test.extra.parameters',[],[],{key2=>22,key3=>'whatever'});
@c=$d->get_details(2);
is_deeply($c[-1],{key1=>'v1',key2=>22,key3=>'whatever'},'correct retrieval of extra parameters after merge');

TODO: {
        local $TODO='tests on add() with other params, new_set(), is_empty()';
        ok(0);
}

exit 0;
