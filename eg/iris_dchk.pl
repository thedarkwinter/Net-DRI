#!/usr/bin/perl
#
#
# A Net::DRI example for IRIS DCHK operations, currently only .DE

use strict;
use warnings;

use Net::DRI;

my ($dri,$rc);

my $ok=eval {
$dri=Net::DRI->new({cache_ttl => 10});
$dri->add_registry('DENIC',{});
$rc=$dri->target('DENIC')->add_current_profile('profile1','dchk');
die($rc) unless $rc->is_success();
display($dri,'denic.de');
display($dri,'ecb.de');
display($dri,'netdri-test-doesnotexist.de');
display($dri,'1.5.3.2.7.2.9.6.9.4.e164.arpa'); ## example with ENUM domain names

$dri->end();
};

if (! $ok)
{ 
 my $err=$@;
 print "\n\nAn EXCEPTION happened !\n";
 if (ref $err)
 {
  $err->print();
 } else
 {
  print $err;
 }
} else
{
 print "\n\nNo exception happened";
}

print "\n";
exit 0;

sub display
{
 my ($dri,$dom)=@_;
 print 'DOMAIN: '.$dom."\n";
 my $rc=$dri->domain_info($dom);
 print 'IS_SUCCESS: '.$rc->is_success().' [CODE: '.$rc->code().' / '.$rc->native_code()."]\n";
 unless ($rc->is_success())
 {
  print $rc->message(),"\n";
  return;
 }
 my $e=$dri->get_info('exist');
 print 'EXIST: '.$e."\n";
 if ($e eq '1')
 {
  foreach my $k (qw/crDate exDate duDate idDate/)
  {
   print $k.': '.($dri->get_info($k) || 'n/a')."\n";
  }
  print 'status: '.join(' ',$dri->get_info('status')->list_status())."\n" if defined($dri->get_info('status'));
 }
 my $rs=$dri->get_info('result_status');
 print 'RESULT STATUS: ';
 $rs->print(1) if defined($rs);
 print "\n\n";
}
