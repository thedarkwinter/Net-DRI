#!/usr/bin/perl
#
#
# A Net::DRI example

use strict;
use warnings;

use Net::DRI;

my $dri=Net::DRI->new({cache_ttl => 10});
my $rc;

my $ok=eval {
############################################################################################################

$dri->add_registry('VeriSign::COM_NET',{});
$rc=$dri->target('VeriSign::COM_NET')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('nsi.com',$dri);
display('laposte.net',$dri);

$dri->add_registry('SITA',{});
$rc=$dri->target('SITA')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('cdg.aero',$dri);

$dri->add_registry('PIR',{});
$rc=$dri->target('PIR')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('laptop.org',$dri);

$dri->add_registry('Afilias',{});
$rc=$dri->target('Afilias')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('mta.info',$dri);

$dri->add_registry('EURid',{});
$rc=$dri->target('EURid')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('europa.eu',$dri);
display('eurid.eu',$dri);

$dri->add_registry('dotMOBI',{});
$rc=$dri->target('dotMOBI')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('buongiorno.mobi',$dri);

$dri->add_registry('VeriSign::NameStore',{});
$rc=$dri->target('VeriSign::NameStore')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('sudoku.name',$dri);

$dri->add_registry('RESTENA',{});
$rc=$dri->target('RESTENA')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('restena.lu',$dri);

$dri->add_registry('GDI',{});
$rc=$dri->target('GDI')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('website.ws',$dri);

$dri->add_registry('IIS',{});
$rc=$dri->target('IIS')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('malmo.se',$dri);

$dri->add_registry('puntCAT',{});
$rc=$dri->target('puntCAT')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('barcelona.cat',$dri);

$dri->add_registry('NicAT',{});
$rc=$dri->target('NicAT')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('stare.at',$dri);

$dri->add_registry('Tralliance',{});
$rc=$dri->target('Tralliance')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('paris.travel',$dri);

$dri->add_registry('DNSPT',{});
$rc=$dri->target('DNSPT')->add_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('lisboa.pt',$dri);

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
 my ($dom,$dri)=@_;
 print 'DOMAIN: '.$dom."\n";
 my $rc=$dri->domain_info($dom);
 print 'IS_SUCCESS: '.$dri->result_is_success().' [CODE: '.$dri->result_code().' / '.$dri->result_native_code()."]\n";
 my $e=$dri->get_info('exist');
 print 'EXIST: '.$e."\n" if defined $e;
 if ($e)
 {
  foreach my $k (qw/clName clID clWebsite clWhois upName upID crName crID crDate upDate exDate wuDate/)
  {
   print $k.': '.($dri->get_info($k) || 'n/a')."\n";
  }
  print 'status: '.join(' ',$dri->get_info('status')->list_status())."\n" if defined($dri->get_info('status'));
  print 'ns: '.$dri->get_info('ns')->as_string()."\n" if defined($dri->get_info('ns'));
 }
 my $cs=$dri->get_info('contact');
 if ($cs)
 {
  foreach my $t ($cs->types())
  {
   foreach my $c ($cs->get($t))
   {
    print 'contact '.$t.' : '.$c->as_string()."\n";
   }
  }
 }
 print "\n\n";
}
