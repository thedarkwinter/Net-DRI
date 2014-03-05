#!/usr/bin/perl
#
#
# A Net::DRI example
# See also t/613cat_epp.t

use utf8;
use strict;
use warnings;

use Net::DRI;

my $CLID='YOUR TEST CLIENT ID'; ### Change this information
my $PASS='YOUR PASSWORD'; ### Change this information

my $dri=Net::DRI->new({cache_ttl=>10,logging=>'files'});

my $ok=eval {
############################################################################################################
$dri->add_registry('CAT',{clid=>$CLID});

## This connects to .CAT server for tests
my $rc=$dri->target('CAT')->add_current_profile('profile1','epp',{remote_host=>'epp.ote.puntcat.corenic.net',client_login=>$CLID,client_password=>$PASS});

die($rc) unless $rc->is_success(); ## Here we catch all errors during setup of transport, such as authentication errors

my $c1=new_contact($dri,'CONTACT1');
my $c2=new_contact($dri,'CONTACT2');
my $c3=new_contact($dri,'CONTACT3');
my $c4=new_contact($dri,'CONTACT4');

$rc=$dri->contact_create($c1);
die($rc) unless $rc->is_success();
$rc=$dri->contact_create($c2);
die($rc) unless $rc->is_success();
$rc=$dri->contact_create($c3);
die($rc) unless $rc->is_success();
$rc=$dri->contact_create($c4);
die($rc) unless $rc->is_success();

my $nso=$dri->local_object('hosts');
foreach my $ns (qw/ns1.example22.com ns2.example22.com/)
{
 print "Attempting to create host $ns ";
 my $e=$dri->host_exist($ns);
 if ($e==0)
 {
  $rc=$dri->host_create($ns);
  print $rc->is_success()? "OK\n" : "KO\n";
 } else
 {
  print "EXIST already\n";
 }
 $nso->add($ns);
}

my $dom='a-netdri'.time().'.cat';
$rc=$dri->domain_check($dom);
print "$dom does ".($dri->get_info('exist')? '' : 'not ')."exist\n";
my $cs=$dri->local_object('contactset');
$cs->set($c1,'registrant');
$cs->set($c2,'billing');
$cs->set($c3,'tech');
$cs->set($c4,'admin');
print "Attempting to create domain $dom\n";
$rc=$dri->domain_create($dom,{pure_create=>1,duration=>$dri->local_object('duration',years => 1),ns=>$nso,contact=>$cs,lang=>'ca',ens=>{auth=>{id=>'FASE3-100000',key=>'0000'},intended_use=>'To test Net::DRI'},auth=>{pw=>'XYZE'}});
print "Created $dom is_success=".$rc->is_success()."\n";


# In OT&E you may need to wait for automated review of your domain,
# in which case please uncomment the following lines
#print "Now sleeping for 10 minutes...\n";
#sleep(10*60);
#print "Back from sleep\n";
#$dri->transport()->current_state(0); ## forcing reconnection

$rc=$dri->domain_check($dom);
print "$dom does exist now\n" if $dri->get_info('exist');
$rc=$dri->domain_info($dom);
print "domain_info OK\n" if $rc->is_success();

my $ns='ns.titi-'.time().'.fr';
$nso=$dri->local_object('hosts')->set('ns.titi-'.time().'.fr');
print "NS=$ns\n";

print "Creating $ns\n";
$rc=$dri->host_create($nso);
print "Host created, is_success()=".$rc->is_success()."\n"; 

$rc=$dri->domain_update_ns_add($dom,$nso);
print "ns_add OK=".$rc->is_success()."\n";
$rc=$dri->domain_info($dom);
$rc=$dri->domain_update_ns_del($dom,$nso);
print "ns_del OK=".$rc->is_success()."\n";
$rc=$dri->domain_info($dom);

my $s=$dri->local_object('status')->no('update');
$rc=$dri->domain_update_status_add($dom,$s);
print "status_add OK=".$rc->is_success()."\n";
$rc=$dri->domain_info($dom);
$rc=$dri->domain_update_status_del($dom,$s);
print "status_del OK=".$rc->is_success()."\n";
$rc=$dri->domain_info($dom);

$rc=$dri->domain_delete($dom,{pure_delete => 1});
print "domain_delete OK=".$rc->is_success()."\n";

$rc=$dri->contact_delete($c1);
print "Contact1 deleted successfully\n" if $rc->is_success();
$rc=$dri->contact_delete($c2);
print "Contact2 deleted successfully\n" if $rc->is_success();
$rc=$dri->contact_delete($c3);
print "Contact3 deleted successfully\n" if $rc->is_success();
$rc=$dri->contact_delete($c4);
print "Contact4 deleted successfully\n" if $rc->is_success();

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

######################################################

sub new_contact
{
 my ($dri,$srid)=@_;
 my $c=$dri->local_object('contact');
 $c->name('My Name');
 $c->org('My Organisation àé æ'.time());
 $c->street(['My Address']);
 $c->city('My city');
 $c->pc(11111);
 $c->cc('FR');
 $c->email('test@example.com');
 $c->voice('+44.1111111');
 $c->fax('+55.2222222');
 $c->auth({pw=>'XYZ'});
 $c->srid($srid);
 return $c;
}
