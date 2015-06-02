#!/usr/bin/perl -w

use Net::DRI::Data::RegistryObject;

use Test::More tests => 1;

can_ok('Net::DRI::Data::RegistryObject',qw/new target/);


exit 0;
