#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::Changes;

use Test::More tests => 40;

my $c=Net::DRI::Data::Changes->new();
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],[],'empty types');
is_deeply([$c->all_defined()],[],'empty all_defined');

$c->add('type1','A');
$c->del('type2','B');
$c->set('type3','C');

is_deeply([$c->types()],['type1','type2','type3'],'3 types');
is_deeply([$c->types('type1')],['add'],'add for one type');
is_deeply([$c->types('type2')],['del'],'del for one type');
is_deeply([$c->types('type3')],['set'],'set for one type');

is_deeply([$c->all_defined('type1')],['A'],'retrieve items 1');
is_deeply([$c->all_defined('type2')],['B'],'retrieve items 2');
is_deeply([$c->all_defined('type3')],['C'],'retrieve items 3');

$c->del('type1','D');
is_deeply([$c->types()],['type1','type2','type3'],'3 types with 4 items');
is_deeply([$c->types('type1')],['add','del'],'2 ops in one type');
is_deeply([$c->all_defined('type1')],['A','D'],'2 items in one type');

is($c->add('type1'),'A','get item/op');

$c=Net::DRI::Data::Changes->new('typeX','add','X');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeX'],'new add types()');
is_deeply([$c->types('typeX')],['add'],'new add types(typeX)');
is_deeply([$c->add('typeX')],['X'],'new add add(typeX)');
is($c->del('typeX'),undef,'new add del(typeX)');
is($c->set('typeX'),undef,'new add set(typeX)');

$c=Net::DRI::Data::Changes->new('typeY','del','Y');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeY'],'new del types()');
is_deeply([$c->types('typeY')],['del'],'new del types(typeY)');
is_deeply([$c->del('typeY')],['Y'],'new del del(typeY)');

$c=Net::DRI::Data::Changes->new('typeX','add','X');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeX'],'new add types()');
is_deeply([$c->types('typeX')],['add'],'new add types(typeX)');
is_deeply([$c->add('typeX')],['X'],'new add add(typeX)');


$c=Net::DRI::Data::Changes->new_add('typeM','M');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeM'],'new_add types()');
is_deeply([$c->types('typeM')],['add'],'new_add type(typeM)');
is_deeply([$c->add('typeM')],['M'],'new_add add(typeM)');

$c=Net::DRI::Data::Changes->new_del('typeN','N');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeN'],'new_del types()');
is_deeply([$c->types('typeN')],['del'],'new_del type(typeN)');
is_deeply([$c->del('typeN')],['N'],'new_del del(typeN)');

$c=Net::DRI::Data::Changes->new_set('typeO','O');
isa_ok($c,'Net::DRI::Data::Changes');
is_deeply([$c->types()],['typeO'],'new_set types()');
is_deeply([$c->types('typeO')],['set'],'new_set type(typeO)');
is_deeply([$c->set('typeO')],['O'],'new_set set(typeO)');


1;
