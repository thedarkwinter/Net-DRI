#!/usr/bin/perl
#
#
# A Net::DRI example

use strict;
use warnings;

use Net::DRI;

my ($rc,$dri);

my $ok=eval {

$dri=Net::DRI->new({cache_ttl => 10});
$dri->add_registry('EURid',{});
$rc=$dri->target('EURid')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('europa.eu');
das('netdri-test-doestnotexist.eu');
$dri->add_registry('BE',{});
$rc=$dri->target('BE')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('brussels.be');
das('netdri-test-doestnotexist.be');
$dri->add_registry('AU',{});
$rc=$dri->target('AU')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('domain.com.au');
das('netdri-test-doestnotexist.com.au');
$dri->add_registry('AdamsNames',{});
$rc=$dri->target('AdamsNames')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('adamsnames.tc');
das('netdri-test-doestnotexist.tc');
$dri->add_registry('SIDN',{});
$rc=$dri->target('SIDN')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('amsterdam.nl');
sleep(2);
das('netdri-test-doestnotexist.nl');
$dri->add_registry('BookMyName',{});
$rc=$dri->target('BookMyName')->add_current_profile('profile1','das');
die($rc) unless $rc->is_success();
das('free.org');
sleep(2);
das('netdri-test-doestnotexist.com');

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

sub das
{
 my $dom=shift;
 print 'DOMAIN: '.$dom."\n";
 $rc=$dri->domain_check($dom);
 print 'IS_SUCCESS: '.$dri->result_is_success()."\n";
 print 'CODE: '.$dri->result_code().' / '.$dri->result_native_code()."\n";
 print 'MESSAGE: ('.$dri->result_lang().') '.$dri->result_message()."\n";
 print 'EXIST: '.$dri->get_info('exist')."\n";
 print 'EXIST_REASON: '.$dri->get_info('exist_reason')."\n";
 print "\n";
}
