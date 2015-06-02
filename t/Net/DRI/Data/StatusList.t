#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::StatusList;

use Test::More tests => 17;

my $s=Net::DRI::Data::StatusList->new();
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),1,'is_empty() 1');

$s=Net::DRI::Data::StatusList->new('p','1.0');
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),1,'is_empty() 2');

$s=Net::DRI::Data::StatusList->new('p','1.0','ACTIVE');
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),0,'is_empty() 0');
is_deeply([$s->list_status()],['ACTIVE'],'list_status()');

$s=Net::DRI::Data::StatusList->new('p','1.0',{name => 'ACTIVE', lang=>'en', msg => 'Test' });
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),0,'is_empty() 0');
is_deeply([$s->list_status()],['ACTIVE'],'list_status()');

$s->add('WHATEVER');
is($s->has_any('WHATEVER'),1,'has_any()');
is($s->has_not('ACTIVE'),0,'has_not()');

$s=Net::DRI::Data::StatusList->new();
$s->_register_pno({w=>'WHATEVER',a=>'ACTIVE'});
is_deeply([$s->possible_no()],['a','w'],'possible_no()');
$s->no('w');
is_deeply([$s->list_status()],['WHATEVER'],'no() 1/3');
$s->no('a','Whatever','fr');
is_deeply([$s->list_status()],['ACTIVE','WHATEVER'],'no() 2/3');
is_deeply($s->status_details(),{'WHATEVER'=>{},'ACTIVE'=>{'msg'=>'Whatever','lang'=>'fr'}},'no() 3/3');

can_ok('Net::DRI::Data::StatusList','is_active','is_published','is_pending','is_linked','can_update','can_transfer','can_delete','can_renew');

exit 0;
