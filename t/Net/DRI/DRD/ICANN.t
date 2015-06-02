#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::DRD::ICANN;

use Test::More tests => 12;

is(Net::DRI::DRD::ICANN::is_reserved_name('whatever.foo','create'),'','whatever.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_A','icann.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.bar.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_A','icann.bar.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab--cd.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_C','ab--cd.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('a.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_B1','a.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_B2','ab.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('biz.foo','create'),'','biz.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.biz','create'),'','foo.biz');
is(Net::DRI::DRD::ICANN::is_reserved_name('www.foo','create'),'NAME_RESERVED_PER_ICANN_RULE_D','www.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.www','create'),'','foo.www');
is(Net::DRI::DRD::ICANN::is_reserved_name('q.com','create'),'NAME_RESERVED_PER_ICANN_RULE_B1','q.com (creation)');
is(Net::DRI::DRD::ICANN::is_reserved_name('q.com','update'),'','q.com (update)');

exit 0;
