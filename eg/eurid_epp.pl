#!/usr/bin/perl
#
#
# A Net::DRI example
# See also t/606eurid_epp.t

use utf8;
use strict;
use warnings;

use Net::DRI;

my $CLID='YOUR TEST CLIENT ID'; ### Change this information
my $PASS='YOUR PASSWORD'; ### Change this information

my $dri=Net::DRI->new({cache_ttl=>10,logging=>'files'});

my $ok=eval {
############################################################################################################
$dri->add_registry('EURid',{clid=>$CLID});

## This connects to .EU server for tests
my $rc=$dri->target('EURid')->add_current_profile('profile1','epp',{client_login=>$CLID,client_password=>$PASS});

die($rc) unless $rc->is_success(); ## Here we catch all errors during setup of transport, such as authentication errors

my $c1=new_contact($dri,'registrant');
my $c2=new_contact($dri,'billing');
my $c3=new_contact($dri,'tech');

$rc=$dri->contact_create($c1);
die($rc) unless $rc->is_success();
my $id=$dri->get_info('id');
print "Contact1 created, id=$id\n";
$c1->srid($id);
$rc=$dri->contact_create($c2);
die($rc) unless $rc->is_success();
$id=$dri->get_info('id');
print "Contact2 created, id=$id\n";
$c2->srid($id);
$rc=$dri->contact_create($c3);
die($rc) unless $rc->is_success();
$id=$dri->get_info('id');
print "Contact3 created, id=$id\n";
$c3->srid($id);

my $dom='toto-'.time().'.eu';
$rc=$dri->domain_check($dom);
print "$dom does not exist\n" unless $dri->get_info('exist');
my $cs=$dri->local_object('contactset');
$cs->set($c1,'registrant');
$cs->set($c2,'billing');
$cs->set($c3,'tech');
print "Attempting to create domain $dom\n";
$rc=$dri->domain_create($dom,{pure_create=>1,duration=>$dri->local_object('duration',years => 1),ns=>$dri->local_object('hosts')->set('ns.example.com'),contact=>$cs});
print "$dom created\n" if $rc->is_success();

## After the domain:create, the connection is dropped by the server
## Net::DRI will see that and reconnect automatically

$rc=$dri->domain_check($dom);
print "$dom does exist now\n" if $dri->get_info('exist');
$rc=$dri->domain_info($dom);
print "domain_info OK\n" if $rc->is_success();

my $ns='ns.titi-'.time().'.fr';
my $nso=$dri->local_object('hosts')->set($ns);
print "NS=$ns\n";

if ($dri->has_object('ns')) ## Should be false for EURid
{
 my $e=$dri->host_exist($ns);
 print "Host exist\n" if ($e==1);
 if ($e==0)
 {
  print "Creating $ns\n";
  $rc=$dri->host_create($nso);
  print "Host created OK\n";
 }
}

$rc=$dri->domain_update_ns_add($dom,$nso);
print "ns_add OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);
$rc=$dri->domain_update_ns_del($dom,$nso);
print "ns_del OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);

# No domain status handling in EURid
#my $s=$dri->local_object('status')->no('update');
#$rc=$dri->domain_update_status_add($dom,$s);
#print "status_add OK\n" if $rc->is_success();
#$rc=$dri->domain_info($dom);
#$rc=$dri->domain_update_status_del($dom,$s);
#print "status_del OK\n" if $rc->is_success();
#$rc=$dri->domain_info($dom);

$rc=$dri->domain_delete($dom,{pure_delete => 1});
print "domain_delete OK\n" if $rc->is_success();

$rc=$dri->contact_delete($c1);
print "Contact1 deleted successfully" if $rc->is_success();
$rc=$dri->contact_delete($c2);
print "Contact2 deleted successfully" if $rc->is_success();
$rc=$dri->contact_delete($c3);
print "Contact3 deleted successfully" if $rc->is_success();


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
 my ($dri,$type)=@_;
 my $c=$dri->local_object('contact');
 $c->name('My Name');
 $c->org('My Organisation àé æ'.time());
 $c->street(['My Address']);
 $c->city('My city');
 $c->pc(11111);
 $c->cc('FR');
 $c->email('test@example.com');
 $c->lang('fr');
 $c->type($type);
 $c->voice('+44.1111111');
 $c->fax('+55.2222222');
 return $c;
}
