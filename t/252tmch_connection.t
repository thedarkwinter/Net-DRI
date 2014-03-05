#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::Protocol::TMCH::Connection;
use Encode ();

use Test::More tests => 1;

can_ok('Net::DRI::Protocol::TMCH::Connection',qw(read_data write_message));

exit 0;

sub _n
{
 my $in=shift;
 $in=~s/^\s+//gm;
 $in=~s/\n/ /g;
 $in=~s/>\s+</></g;
 $in=~s/\s+$//gm;
 return $in;
}
