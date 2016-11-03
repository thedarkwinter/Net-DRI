#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use DateTime;
use DateTime::Duration;

use Test::More tests => 1;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1 = '<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
my ($dri, $rc, $s, $d, $dh, @c);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $ok=eval {
  $dri = Net::DRI->new({cache_ttl => 10});
  $dri->{trid_factory} = sub { return 'ABC-12345'; };
  $dri->add_registry('MW');
  $dri->target('MW')->add_current_profile('p1', 'epp', {f_send => \&mysend, f_recv => \&myrecv});
  1;
};

if (! $ok) {
  my $err=$@;
  if (ref $err eq 'Net::DRI::Exception') {
    die $err->as_string();
  } else {
    die $err;
  }
}

# See CZ.t for tests

ok(1,'No tests yet as same as CZ FRED system');

exit 0;
