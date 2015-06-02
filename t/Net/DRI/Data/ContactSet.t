#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::Data::ContactSet;

use Test::More tests => 19;

can_ok('Net::DRI::Data::ContactSet',qw/new types has_type is_empty add del clear set get get_all match has_contact/);

my $s1=Net::DRI::Data::ContactSet->new();
isa_ok($s1,'Net::DRI::Data::ContactSet');

my $s2=Net::DRI::Data::ContactSet->new(admin => 'ABC123', tech => 'DEF456', foobar => 'GHI789');
isa_ok($s2,'Net::DRI::Data::ContactSet');

is_deeply([],[$s1->types()],'types empty');
is_deeply([qw/admin foobar tech/],[$s2->types()],'types not empty');
is($s1->has_type(),0,'has_type empty');
is($s2->has_type('admin'),1,'has_type non empty admin');
is($s2->has_type('whatever'),0,'has_type non empty whatever');

is($s2->contact_admin()->id(),'ABC123','contact_admin 1');
is($s2->contact_tech()->id(),'DEF456','contact_admin 2');
is($s2->contact_foobar()->id(),'GHI789','contact_admin 3');


my $s3=Net::DRI::Data::ContactSet->new({admin => 'ABC123', tech => 'DEF456', foobar => 'GHI789'});
is_deeply($s2,$s3,'same new with ref hash or list');

my $s4=Net::DRI::Data::ContactSet->new(admin => ['ABC123', 'DEF456', 'GHI789']);
my @a=$s4->get('admin');
is(@a,3,'get with ref array, count ok');
is($a[0]->id(),'ABC123','get with ref array, 1st element ok');
is($a[1]->id(),'DEF456','get with ref array, 2nd element ok');
is($a[2]->id(),'GHI789','get with ref array, 3rd element ok');
my @b=$s4->contact_admin();
is_deeply(\@a,\@b,'get(TYPE) & contact_TYPE give same results');
is_deeply(scalar $s4->contact_admin(),$a[0],'get(TYPE) & contact_TYPE give same results in scalar context');

TODO: {
        local $TODO="tests";
        ok(0);
}

exit 0;
