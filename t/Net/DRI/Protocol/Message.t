#!/usr/bin/perl -w

use Net::DRI::Protocol::Message;

use Test::More tests=>1;

can_ok('Net::DRI::Protocol::Message','new','is_success','result_status','parse','version');

exit 0;
