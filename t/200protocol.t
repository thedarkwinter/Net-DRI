#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::Protocol;
use Net::DRI::Logging::Null;

use Test::More tests => 7;

my $ndr={};
bless($ndr);

sub logging { return Net::DRI::Logging::Null->new(); }
sub name { return 'test'; }

my $p;
$p=Net::DRI::Protocol->new({registry=>$ndr});
isa_ok($p,'Net::DRI::Protocol');
is($p->message(),undef,'empty message at init');
is_deeply($p->capabilities(),{},'empty capabilities at init');

$p->name('myname');
$p->version('1.5');

is($p->name(),'myname','name()');
is($p->version(),'1.5','version()');
is($p->nameversion(),'myname/1.5','nameversion()');

TODO: {
	local $TODO='other tests (factories, commands)';
	ok(0);
}

exit 0;
