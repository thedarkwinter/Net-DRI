## Domain Registry Interface, virtual superclass for all DRD modules
##
## Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::DRD;

use strict;
use warnings;

use base qw/Net::DRI::BaseClass/;
__PACKAGE__->make_exception_if_not_implemented(qw/name tlds object_types periods profile_types transport_protocol_default/); ## methods that should be in subclasses

use DateTime;
use DateTime::Duration;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::DRD::ICANN;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

=pod

=head1 NAME

Net::DRI::DRD - Superclass of all Net::DRI Registry Drivers

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUBROUTINES/METHODS

=head2 name()

Name of this registry driver (this should not contain any dot at all)

=head2 tlds()

Array of tlds (lowercase, no starting or ending dot) handled by this registry

=head2 object_types()

Array of object types managed by this registry

=head2 periods()

Array of DateTime::Duration objects for valid domain name creation durations at registry

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,@r)=@_;
 my $self={ info => defined $r[0] ? $r[0] : {} };
 bless $self,$class;
 return $self;
}

sub info
{
 my ($self,$ndr,$key)=@_;
 $key=$ndr unless (defined $ndr && $ndr && (ref $ndr eq 'Net::DRI::Registry'));
 return unless defined $self->{info};
 return unless defined $key && exists $self->{info}->{$key};
 return $self->{info}->{$key};
}

sub is_my_tld
{
 my ($self,$ndr,$domain,$strict)=@_;
 ($domain,$strict)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));
 if (! defined($strict)) { $strict=1; }
 if ($domain=~m/\.e164\.arpa$/) { $strict=0; }
 my $tlds=join('|',map { quotemeta($_) } sort { length($b) <=> length($a) } $self->tlds());
 my $r=$strict? qr/^[^.]+\.(?:$tlds)$/i : qr/\.(?:$tlds)$/i;
 return ($domain=~$r)? 1 : 0;
}

sub _verify_name_rules
{
 my ($self,$domain,$op,$rules)=@_;

 if (exists $rules->{check_name} && $rules->{check_name})
 {
  my $dots=$rules->{check_name_dots};
  if (! defined $dots) { $dots=$self->dots(); }
  my $r=$self->check_name($domain,$dots,exists $rules->{check_name_unicode} ? $rules->{check_name_unicode} : 0);
  if (length $r) { return $r; }
 }

 if (exists $rules->{check_name_no_dots} && $rules->{check_name_no_dots})
 {
  my $r=$self->check_name($domain);
  if (length $r) { return $r; }
 }

 if (exists $rules->{my_tld} && $rules->{my_tld} && ! $self->is_my_tld($domain)) { return 'NAME_NOT_IN_TLD'; }
 if (exists $rules->{my_tld_not_strict} && $rules->{my_tld_not_strict} && ! $self->is_my_tld($domain,0)) { return 'NAME_NOT_IN_TLD'; }
 if (exists $rules->{icann_reserved} && $rules->{icann_reserved})
 {
  my $ri=Net::DRI::DRD::ICANN::is_reserved_name($domain,$op);
  return $ri if length $ri;
 }

 my @d=split(/\./,$domain);
 if (exists $rules->{min_length} && $rules->{min_length} && length($d[0]) < $rules->{min_length}) { return 'NAME_TOO_SHORT'; }
 if (exists $rules->{no_double_hyphen} && $rules->{no_double_hyphen} && substr($d[0],2,2) eq '--') { return 'NAME_WITH_TWO_HYPHENS'; }
 if (exists $rules->{no_double_hyphen_except_idn} && $rules->{no_double_hyphen_except_idn} && substr($d[0],2,2) eq '--' && substr($d[0],0,2) ne 'xn') { return 'NAME_WITH_TWO_HYPHENS_NOT_IDN'; }
 if (exists $rules->{no_country_code} && $rules->{no_country_code} && exists $Net::DRI::Util::CCA2{uc($d[0])}) { return 'NAME_WITH_COUNTRY_CODE'; }
 if (exists $rules->{no_digits_only} && $rules->{no_digits_only} && $d[0]=~m/^\d+$/) { return 'NAME_WITH_ONLY_DIGITS'; }

 if ($domain=~m/\.e164\.arpa$/ && $domain!~m/^(?:\d+\.)+e164\.arpa$/) { return 'NAME_INVALID_IN_E164'; }

 if (exists $rules->{excluded_labels})
 {
  my $n=join('|',ref $rules->{excluded_labels}? @{$rules->{excluded_labels}} : ($rules->{excluded_labels}));
  if (lc($d[0])=~m/^(?:$n)$/o) { return 'NAME_WITH_EXCLUDED_LABELS'; }
 }

 ## It seems all rules have passed successfully
 return '';
}

## Compute the number of dots for each tld in tlds(), returns a ref array and store it for later quick access
sub dots
{
 my ($self)=@_;
 if (! exists $self->{dots})
 {
  my %a=map { $_ => 1 } map { my $r=$_; my $c=($r=~tr/\././); 1+$c; } $self->tlds();
  $self->{dots}=[ sort { $a <=> $b } keys(%a) ];
 }
 return $self->{dots};
}

sub has_object
{
 my ($self,$ndr,$type)=@_;
 $type=$ndr unless (defined($type) && ref($ndr));
 return 0 unless (defined($type) && $type);
 $type=lc($type);
 return (grep { lc($_) eq $type } ($self->object_types()))? 1 : 0;
}

## TODO : use also protocol->has_action() ? (see end of domain_create)
sub registry_can
{
 my ($self,$ndr,$what)=@_;
 return (eval { $self->can($what); } && ! grep { $what eq $_ } $self->unavailable_operations())? 1 : 0;
}

## It would be probably more useful to know the list of available ones !
## An overhaul would be probably needed when more non domain names registries are added
sub unavailable_operations { return (); } ## will be overruled by BaseClass, as needed

####################################################################################################

## A common default, which should be fine for EPP & related ways of doing things
## (should it be done in the Protocol class instead ?)
sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 if (! defined $op) { return; }
 if ($op=~m/^(?:renew|update|delete)$/) { return 1; }
 if ($op eq 'transfer')                 { return 0; }
 return;
}

## This is the default basic one, it should get subclassed as needed
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name=>1,my_tld=>1});
}

sub verify_name_host
{
 my ($self,$ndr,$host,$checktld)=@_;
 $host=$host->get_names(1) if ref $host;
 my $r=$self->check_name($host);
 return $r if length $r;
 return 'HOST_NAME_NOT_IN_CORRECT_TLD' if (defined $checktld && $checktld && !$self->is_my_tld($host,0));
 return '';
}

sub check_name
{
 my ($self,$ndr,$data,$dots,$unicode)=@_;
 ($data,$dots,$unicode)=($ndr,$data,$dots) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 'UNDEFINED_NAME' unless defined $data;
 return 'NON_SCALAR_NAME' unless !ref($data);
 return 'ZERO_LENGTH_NAME' unless length $data;
 return 'INVALID_HOSTNAME' unless Net::DRI::Util::is_hostname($data,$unicode);
 if (defined($dots) && $data!~m/\.e164\.arpa$/)
 {
  my @d=split(/\./,$data);
  my @ok=ref($dots)? @$dots : ($dots);
  return 'INVALID_NUMBER_OF_DOTS_IN_NAME' unless grep { 1+$_== @d } @ok;
 }

 return ''; #everything ok
}

sub verify_duration_create
{
 my ($self,$ndr,$duration,$domain)=@_;

 my @d=$self->periods();
 return 1 unless @d;
 foreach my $d (@d) { return 0 if (0==Net::DRI::Util::compare_durations($d,$duration)) }
 return 2;
}

sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;

 my @d=$self->periods();
 if (defined($duration) && @d)
 {
  my $ok=0;
  foreach my $d (@d)
  {
   next unless (0==Net::DRI::Util::compare_durations($d,$duration));
   $ok=1;
   last;
  }
  return 1 unless $ok;

  if (defined $curexp && Net::DRI::Util::is_class($curexp,'DateTime'))
  {
   my $maxdelta=$d[-1];
   my $newexp=$curexp+$duration; ## New expiration
   my $now=DateTime->now(time_zone => $curexp->time_zone()->name());
   my $cmp=DateTime->compare($newexp,$now+$maxdelta);
   return 2 unless ($cmp == -1); ## we must have : curexp+duration < now + maxdelta
  }
 }

 return 0; ## everything ok
}

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;

 return 0; ## everything ok
}

## A common case; we can not start a transfer, if domain name has already been transfered less than 15 days ago.
sub _verify_duration_transfer_15days
{
 my ($self,$ndr,$duration,$domain,$op)=@_;

 return 0 unless ($op eq 'start'); ## we are not interested by other cases, they are always OK
 my $rc=$self->domain_info($ndr,$domain,{hosts=>'none'});
 return 1 unless ($rc->is_success());
 my $trdate=$ndr->get_info('trDate');
 return 0 unless ($trdate && $trdate->isa('DateTime'));

 my $now=DateTime->now(time_zone => $trdate->time_zone()->name());
 my $cmp=DateTime->compare($now,$trdate+DateTime::Duration->new(days => 15));
 return ($cmp == 1)? 0 : 1; ## we must have : now > transferdate + 15days
 ## we return 0 if OK, anything else if not
}

####################################################################################################

sub enforce_domain_name_constraints
{
 my ($self,$ndr,$domain,$op)=@_;
 my $err=$self->verify_name_domain($ndr,$domain,$op);
 Net::DRI::Exception->die(0,'DRD',1,'Invalid domain name (error '.$err.'): '.((defined($domain) && $domain)? $domain : '?')) if length $err;
 return;
}

sub enforce_host_name_constraints
{
 my ($self,$ndr,$dh,$checktld)=@_;
 my $err=$self->verify_name_host($ndr,$dh,$checktld);
 Net::DRI::Exception->die(0,'DRD',2,'Invalid host name (error '.$err.'): '.((Net::DRI::Util::is_class($dh,'Net::DRI::Data::Hosts'))? $dh->get_names(1) : (defined $dh? $dh : '?'))) if length $err;
 return;
}

sub err_invalid_contact
{
 my ($self,$c)=@_;
 Net::DRI::Exception->die(0,'DRD',6,'Invalid contact (should be a Contact object with a srid value): '.((defined $c && $c && eval { $c->can('srid'); } )? $c->srid() : '?'));
 return;
}

####################################################################################################
## Operations on DOMAINS
####################################################################################################

sub domain_create
{
 my ($self,$ndr,$domain,$rd)=@_;
 my @rs;

 $self->enforce_domain_name_constraints($ndr,$domain,'create');
 $rd=Net::DRI::Util::create_params('domain_create',$rd);
 my $pure=(Net::DRI::Util::has_key($rd,'pure_create') && $rd->{pure_create})? 1 : 0;
 delete $rd->{pure_create};

 if (! $pure)
 {
  my $rs=$self->domain_check($ndr,$domain,$rd);
  push @rs,$rs;
  return Net::DRI::Util::link_rs(@rs) unless ($rs->is_success() && defined $rs->local_get_data('domain',$domain,'exist') && $rs->local_get_data('domain',$domain,'exist')==0);
 }

 my $nsin=$ndr->local_object('hosts');
 my $nsout=$ndr->local_object('hosts');
 Net::DRI::Util::check_isa($rd->{ns},'Net::DRI::Data::Hosts') if Net::DRI::Util::has_key($rd,'ns'); ## test needed in both cases

 ## If not pure domain creation, separate nameservers (inside & outside of domain) and then create outside nameservers if needed
 if (! $pure && exists $rd->{ns} && $self->has_object('ns'))
 {
  foreach my $i (1..$rd->{ns}->count())
  {
   my @a=$rd->{ns}->get_details($i);
   if ($a[0]=~m/^(.+\.)?${domain}$/i)
   {
    $nsin->add(@a);
   } else
   {
    my $ns=$ndr->local_object('hosts')->set(\@a);
    my $e=$self->host_exist($ndr,$ns);
    unless (defined $e && $e==1)
    {
     my $rs=$self->host_create($ndr,$ns);
     push @rs,$rs;
     return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
    }
    $nsout->add(@a);
   }
  }
  $rd->{ns}=$nsout;
 }

 ## If not pure domain creation, and if contacts are used make sure they exist as objects in the registry if needed
 if (! $pure && exists $rd->{contact} && Net::DRI::Util::isa_contactset($rd->{contact}) && $self->has_object('contact'))
 {
  my %cd;
  foreach my $t ($rd->{contact}->types())
  {
   foreach my $co ($rd->{contact}->get($t))
   {
    next if exists $cd{$co->srid()};
    my $e=$self->contact_exist($ndr,$co);
    unless (defined $e && $e==1)
    {
     my $rs=$self->contact_create($ndr,$co);
     push @rs,$rs;
     return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
    }
    $cd{$co->srid()}=1;
   }
  }
 }

 Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if (Net::DRI::Util::has_key($rd,'duration') && ((ref $rd->{duration} ne 'DateTime::Duration') || $self->verify_duration_create($ndr,$rd->{duration},$domain)));
 my $rs=$ndr->process('domain','create',[$domain,$rd]);
 return $rs if $pure; ## pure domain creation we do not bother with other stuff and we stop here
 ## From now on, we are sure $rs is defined
 push @rs,$rs;
 return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();

 ## Create inside nameservers and add them to the domain
 unless ($nsin->is_empty())
 {
  foreach my $i (1..$nsin->count())
  {
   my @a=$nsin->get_details($i);
   my $ns=$ndr->local_object('hosts')->set(\@a);
   my $rs=$self->host_create($ndr,$ns);
   push @rs,$rs;
   return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
  }

  my $rs=$ndr->protocol_capable('domain_update','ns','add')? $self->domain_update_ns_add($ndr,$domain,$nsin) : $self->domain_update_ns_set($ndr,$domain,$nsin);
  push @rs,$rs;
  return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
 }

 ## Add status to domain, if provided
 if (Net::DRI::Util::has_key($rd,'status'))
 {
  my $rs=$ndr->protocol_capable('domain_update','status','add')? $self->domain_update_status_add($ndr,$domain,$rd->{status}) : $self->domain_update_status_set($ndr,$domain,$rd->{status});
  push @rs,$rs;
  return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
 }

 ## Do a final info to populate the local cache
 if ($ndr->protocol()->has_action('domain','info'))
 {
  my $rs=$self->domain_info($ndr,$domain);
  push @rs,$rs;
 }

 return Net::DRI::Util::link_rs(@rs);
}

sub domain_delete
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'delete');
 $rd=Net::DRI::Util::create_params('domain_delete',$rd);
 my $pure=(Net::DRI::Util::has_key($rd,'pure_delete') && $rd->{pure_delete})? 1 : 0;
 delete $rd->{pure_delete};

 my (@rs,$rs);

 ## This will make sure we get rid of in-bailiwick nameservers in some way, otherwise in their presence the domain delete would fail
 if (! $pure)
 {
  $rs=$self->domain_info($ndr,$domain);
  push @rs,$rs;
  return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();

  ## First remove all nameservers attached to domain name in case some of them are subordinates of the domain itself
  my $ns=$ndr->get_info('ns');
  if (defined $ns && !$ns->is_empty())
  {
   $rs=$self->domain_update_ns_del($ndr,$domain,$ns);
   push @rs,$rs;
   return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
  }

  ## Now try to delete all subordinate hosts, or else (deletion will fail if hosts are used as nameservers for other domain names at registry) rename them somewhere if possible
  $ns=$ndr->get_info('subordinate_hosts');
  if (defined $ns && !$ns->is_empty() && $self->has_object('ns'))
  {
   my $base=$rd->{subordinate_rename};
   foreach my $nsname ($ns->get_names())
   {
    $rs=$self->host_delete($ndr,$nsname);
    push @rs,$rs;
    return Net::DRI::Util::link_rs(@rs) unless ($rs->is_success() || ($rs->is('OBJECT_ASSOCIATION_PROHIBITS_OPERATION') && defined $base));
    if (! $rs->is_success())
    {
     $rs=$self->host_update_name_set($ndr,$nsname.'.'.$base);
     push @rs,$rs;
     return Net::DRI::Util::link_rs(@rs) unless $rs->is_success();
    }
   }
  }
 }

 $rs=$ndr->process('domain','delete',[$domain,$rd]);
 push @rs,$rs;
 return Net::DRI::Util::link_rs(@rs);
}

sub domain_info
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'info');
 my $rc=$ndr->try_restore_from_cache('domain',$domain,'info');
 if (! defined $rc)
 {
  $rd=Net::DRI::Util::create_params('domain_info',$rd);
  $rc=$ndr->process('domain','info',[$domain,$rd]);
 }
 return $rc;
}

sub domain_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in domain_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('domain_check',$p);
   next;
  }
  $self->enforce_domain_name_constraints($ndr,$p,'check');
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('domain_check needs at least one domain name to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seendom,%seenrc);
 foreach my $domain (@names)
 {
  next if exists $seendom{$domain};
  $seendom{$domain}=1;
  my $rs=$ndr->try_restore_from_cache('domain',$domain,'check');
  if (! defined $rs)
  {
   push @todo,$domain;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple domain names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }

 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('domain','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for domain_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('domain','check_multi',[\@lt,$rd]);
  }
 } else ## either one domain only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('domain','check',[$_,$rd]); } @todo;
 }

 return Net::DRI::Util::link_rs(@rs);
}

sub domain_exist ## 1/0/undef
{
 my ($self,$ndr,$domain,$rd)=@_;

 my $rc=$ndr->domain_check($domain,defined $rd ? $rd : ());
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub domain_update
{
 my ($self,$ndr,$domain,$tochange,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'update');
 $rd=Net::DRI::Util::create_params('domain_update',$rd);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
 Net::DRI::Exception->new(0,'DRD',4,'Registry does not handle contacts') if ($tochange->all_defined('contact') && ! $self->has_object('contact'));

 my $fp=$ndr->protocol->nameversion();
 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of domain_update/'.$t) unless $ndr->protocol_capable('domain_update',$t);

  my $add=$tochange->add($t);
  my $del=$tochange->del($t);
  my $set=$tochange->set($t);

  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of domain_update/'.$t.' (add)') if (defined($add) && ! $ndr->protocol_capable('domain_update',$t,'add'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of domain_update/'.$t.' (del)') if (defined($del) && ! $ndr->protocol_capable('domain_update',$t,'del'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of domain_update/'.$t.' (set)') if (defined($set) && ! $ndr->protocol_capable('domain_update',$t,'set'));
 }

 foreach ($tochange->all_defined('ns'))      { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach ($tochange->all_defined('status'))  { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }
 foreach ($tochange->all_defined('contact')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::ContactSet'); }

 my $rc=$ndr->process('domain','update',[$domain,$tochange,$rd]);
 return $rc;
}

sub domain_update_ns_add { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ns,$ndr->local_object('hosts'),$rd); }
sub domain_update_ns_del { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ndr->local_object('hosts'),$ns,$rd); }
sub domain_update_ns_set { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ns,undef,$rd); }

sub domain_update_ns
{
 my ($self,$ndr,$domain,$nsadd,$nsdel,$rd)=@_;
 Net::DRI::Util::check_isa($nsadd,'Net::DRI::Data::Hosts');
 if (defined($nsdel)) ## add + del
 {
  Net::DRI::Util::check_isa($nsdel,'Net::DRI::Data::Hosts');
  my $c=$ndr->local_object('changes');
  $c->add('ns',$nsadd) unless ($nsadd->is_empty());
  $c->del('ns',$nsdel) unless ($nsdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('ns',$nsadd),$rd);
 }
}

sub domain_update_status_add { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$s,$ndr->local_object('status'),$rd); }
sub domain_update_status_del { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$ndr->local_object('status'),$s,$rd); }
sub domain_update_status_set { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$s,undef,$rd); }

sub domain_update_status
{
 my ($self,$ndr,$domain,$sadd,$sdel,$rd)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('status',$sadd),$rd);
 }
}

sub domain_update_contact_add { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$c,$ndr->local_object('contactset'),$rd); }
sub domain_update_contact_del { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$ndr->local_object('contactset'),$c,$rd); }
sub domain_update_contact_set { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$c,undef,$rd); }

sub domain_update_contact
{
 my ($self,$ndr,$domain,$cadd,$cdel,$rd)=@_;
 Net::DRI::Util::check_isa($cadd,'Net::DRI::Data::ContactSet');
 if (defined($cdel)) ## add + del
 {
  Net::DRI::Util::check_isa($cdel,'Net::DRI::Data::ContactSet');
  my $c=$ndr->local_object('changes');
  $c->add('contact',$cadd) unless ($cadd->is_empty());
  $c->del('contact',$cdel) unless ($cdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('contact',$cadd),$rd);
 }
}

sub domain_renew
{
 my ($self,$ndr,$domain,$rd)=@_;

 $self->enforce_domain_name_constraints($ndr,$domain,'renew');
 $rd=Net::DRI::Util::create_params('domain_renew',$rd);
 Net::DRI::Util::check_isa($rd->{duration},'DateTime::Duration') if Net::DRI::Util::has_key($rd,'duration');
 Net::DRI::Util::check_isa($rd->{current_expiration},'DateTime') if Net::DRI::Util::has_key($rd,'current_expiration');
 Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if $self->verify_duration_renew($ndr,$rd->{duration},$domain,$rd->{current_expiration});

 return $ndr->process('domain','renew',[$domain,$rd]);
}

sub domain_transfer
{
 my ($self,$ndr,$domain,$op,$rd)=@_;

 $self->enforce_domain_name_constraints($ndr,$domain,'transfer');
 $rd=Net::DRI::Util::create_params('domain_transfer',$rd);
 Net::DRI::Exception::usererr_invalid_parameters('Transfer operation must be start,stop,accept,refuse or query') unless ($op=~m/^(?:start|stop|query|accept|refuse)$/);
 Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if Net::DRI::Util::has_key($rd,'duration') && $self->verify_duration_transfer($ndr,$rd->{duration},$domain,$op);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('domain','transfer_request',[$domain,$rd]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('domain','transfer_cancel',[$domain,$rd]);
 } elsif ($op eq 'query')
 {
  $rc=$ndr->process('domain','transfer_query',[$domain,$rd]);
 } else ## accept/refuse
 {
  $rd->{approve}=($op eq 'accept')? 1 : 0;
  $rc=$ndr->process('domain','transfer_answer',[$domain,$rd]);
 }

 return $rc;
}

sub domain_transfer_start   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'start',$rd); }
sub domain_transfer_stop    { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'stop',$rd); }
sub domain_transfer_query   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'query',$rd); }
sub domain_transfer_accept  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'accept',$rd); }
sub domain_transfer_refuse  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'refuse',$rd); }


sub domain_can
{
 my ($self,$ndr,$domain,$what,$rd)=@_;

 my $sok=$self->domain_status_allows($ndr,$domain,$what,$rd);
 return 0 unless ($sok);

 my $ismine=$self->domain_is_mine($ndr,$domain,$rd);
 my $n=$self->domain_operation_needs_is_mine($ndr,$domain,$what);
 return unless (defined($n));
 return ($ismine xor $n)? 0 : 1;
}

sub domain_status_allows_delete   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'delete',$rd); }
sub domain_status_allows_update   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'update',$rd); }
sub domain_status_allows_transfer { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'transfer',$rd); }
sub domain_status_allows_renew    { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'renew',$rd); }

sub domain_status_allows
{
 my ($self,$ndr,$domain,$what,$rd)=@_;

 return 0 unless ($what=~m/^(?:delete|update|transfer|renew)$/);
 my $s=$self->domain_current_status($ndr,$domain,$rd);
 return 0 unless defined $s;

 return $s->can_delete()   if ($what eq 'delete');
 return $s->can_update()   if ($what eq 'update');
 return $s->can_transfer() if ($what eq 'transfer');
 return $s->can_renew()    if ($what eq 'renew');
 return 0; ## failsafe
}

sub domain_current_status
{
 my ($self,$ndr,$domain,$rd)=@_;
 my $rc=$self->domain_info($ndr,$domain,$rd);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless Net::DRI::Util::isa_statuslist($s);
 return $s;
}

sub domain_is_mine
{
 my ($self,$ndr,$domain,$rd)=@_;
 my $clid=$self->info('client_id');
 return unless defined $clid;
 my $rc=$self->domain_info($ndr,$domain,$rd);
 return unless $rc->is_success();
 my $id=$ndr->get_info('clID');
 return unless defined $id;
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Operations on HOSTS
####################################################################################################

sub host_create
{
 my ($self,$ndr,$dh,$rh)=@_;
 $rh=Net::DRI::Util::create_params('host_create',$rh);
 my $name=Net::DRI::Util::isa_hosts('$dh')? $dh->get_details(1) : $dh;
 $self->enforce_host_name_constraints($ndr,$name,0);

 my $rc=$ndr->process('host','create',[$dh,$rh]);
 return $rc;
}

sub host_delete
{
 my ($self,$ndr,$dh,$rh)=@_;
 $rh=Net::DRI::Util::create_params('host_delete',$rh);
 my $name=Net::DRI::Util::isa_hosts('$dh')? $dh->get_details(1) : $dh;
 $self->enforce_host_name_constraints($ndr,$name);

 my $rc=$ndr->process('host','delete',[$dh,$rh]);
 return $rc;
}

sub host_info
{
 my ($self,$ndr,$dh,$rh)=@_;
 $rh=Net::DRI::Util::create_params('host_info',$rh);
 my $name=Net::DRI::Util::isa_hosts('$dh')? $dh->get_details(1) : $dh;
 $self->enforce_host_name_constraints($ndr,$name);

 my $rc=$ndr->try_restore_from_cache('host',$name,'info');
 if (! defined $rc) { $rc=$ndr->process('host','info',[$dh,$rh]); }

 return $rc unless $rc->is_success();
 return (wantarray())? ($rc,$ndr->get_info('self')) : $rc;
}

sub host_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (map { defined && Net::DRI::Util::isa_hosts($_,1) ? $_->get_names() : $_ } @p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in host_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('host_check',$p);
   next;
  }
  $self->enforce_host_name_constraints($ndr,$p);
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('host_check needs at least one domain name to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seenhost,%seenrc);
 foreach my $host (@names)
 {
  next if exists $seenhost{$host};
  $seenhost{$host}=1;
  my $rs=$ndr->try_restore_from_cache('host',$host,'check');
  if (! defined $rs)
  {
   push @todo,$host;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple host names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }

 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('host','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for host_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('host','check_multi',[\@lt,$rd]);
  }
 } else ## either one domain only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('host','check',[$_,$rd]); } @todo;
 }

 return Net::DRI::Util::link_rs(@rs);
}

sub host_exist ## 1/0/undef
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $rc=$ndr->host_check($dh,defined $rh ? $rh : ());
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub host_update
{
 my ($self,$ndr,$dh,$tochange,$rh)=@_;
 $rh=Net::DRI::Util::create_params('host_update',$rh);
 my $name=Net::DRI::Util::isa_hosts('$dh')? $dh->get_details(1) : $dh;
 $self->enforce_host_name_constraints($ndr,$name);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 my $fp=$ndr->protocol->nameversion();
 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of host_update/'.$t) unless $ndr->protocol_capable('host_update',$t);

  my $add=$tochange->add($t);
  my $del=$tochange->del($t);
  my $set=$tochange->set($t);

  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of host_update/'.$t.' (add)') if (defined($add) && ! $ndr->protocol_capable('host_update',$t,'add'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of host_update/'.$t.' (del)') if (defined($del) && ! $ndr->protocol_capable('host_update',$t,'del'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of host_update/'.$t.' (set)') if (defined($set) && ! $ndr->protocol_capable('host_update',$t,'set'));
 }

 foreach ($tochange->all_defined('ip'))     { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach ($tochange->all_defined('status')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }
 foreach ($tochange->all_defined('name'))   { $self->enforce_host_name_constraints($ndr,$_); }

 my $rc=$ndr->process('host','update',[$dh,$tochange,$rh]);
 return $rc;
}

sub host_update_ip_add { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ip,$ndr->local_object('hosts'),$rh); }
sub host_update_ip_del { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ndr->local_object('hosts'),$ip,$rh); }
sub host_update_ip_set { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ip,undef,$rh); }

sub host_update_ip
{
 my ($self,$ndr,$dh,$ipadd,$ipdel,$rh)=@_;
 Net::DRI::Util::check_isa($ipadd,'Net::DRI::Data::Hosts');
 if (defined($ipdel)) ## add + del
 {
  Net::DRI::Util::check_isa($ipdel,'Net::DRI::Data::Hosts');
  my $c=$ndr->local_object('changes');
  $c->add('ip',$ipadd) unless ($ipadd->is_empty());
  $c->del('ip',$ipdel) unless ($ipdel->is_empty());
  return $self->host_update($ndr,$dh,$c,$rh);
 } else ## just set
 {
  return $self->host_update($ndr,$dh,$ndr->local_object('changes')->set('ip',$ipadd),$rh);
 }
}

sub host_update_status_add { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$s,$ndr->local_object('status'),$rh); }
sub host_update_status_del { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$ndr->local_object('status'),$s,$rh); }
sub host_update_status_set { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$s,undef,$rh); }

sub host_update_status
{
 my ($self,$ndr,$dh,$sadd,$sdel,$rh)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->host_update($ndr,$dh,$c,$rh);
 } else ## just set
 {
  return $self->host_update($ndr,$dh,$ndr->local_object('changes')->set('status',$sadd),$rh);
 }
}

sub host_update_name_set
{
 my ($self,$ndr,$dh,$newname,$rh)=@_;
 $newname=$newname->get_names(1) if ($newname && Net::DRI::Util::is_class($newname,'Net::DRI::Data::Hosts'));
 $self->enforce_host_name_constraints($ndr,$newname);
 return $self->host_update($ndr,$dh,$ndr->local_object('changes')->set('name',$newname),$rh);
}

sub host_current_status
{
 my ($self,$ndr,$dh,$rh)=@_;
 my $rc=$self->host_info($ndr,$dh,$rh);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless Net::DRI::Util::isa_statuslist($s);
 return $s;
}

sub host_is_mine
{
 my ($self,$ndr,$dh,$rh)=@_;
 my $clid=$self->info('client_id');
 return unless defined $clid;
 my $rc=$self->host_info($ndr,$dh,$rh);
 return unless $rc->is_success();
 my $id=$ndr->get_info('clID');
 return unless defined $id;
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Operations on CONTACTS
####################################################################################################

sub contact_create
{
 my ($self,$ndr,$contact,$ep)=@_;
 $self->err_invalid_contact($contact) unless Net::DRI::Util::isa_contact($contact);
 $ep=Net::DRI::Util::create_params('contact_create',$ep);
 $contact->init('create',$ndr) if $contact->can('init');
 $contact->validate(); ## will trigger an Exception if validation not ok
 my $rc=$ndr->process('contact','create',[$contact,$ep]);
 return $rc;
}

sub contact_delete
{
 my ($self,$ndr,$contact,$ep)=@_;
 $self->err_invalid_contact($contact) unless (Net::DRI::Util::isa_contact($contact) && $contact->srid());
 $ep=Net::DRI::Util::create_params('contact_delete',$ep);
 my $rc=$ndr->process('contact','delete',[$contact,$ep]);
 return $rc;
}

sub contact_info
{
 my ($self,$ndr,$contact,$ep)=@_;
 $self->err_invalid_contact($contact) unless (Net::DRI::Util::isa_contact($contact) && $contact->srid());
 $ep=Net::DRI::Util::create_params('contact_info',$ep);
 my $rc=$ndr->try_restore_from_cache('contact',$contact->srid(),'info');
 if (! defined $rc) { $rc=$ndr->process('contact','info',[$contact,$ep]); }
 return $rc;
}

sub contact_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in contact_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('contact_check',$p);
   next;
  }
  $self->err_invalid_contact($p) unless (Net::DRI::Util::isa_contact($p) && length $p->srid());
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('contact_check needs at least one domain name to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seencon,%seenrc);
 foreach my $contact (@names)
 {
  next if exists $seencon{$contact};
  $seencon{$contact}=1;
  my $rs=$ndr->try_restore_from_cache('contact',$contact->srid(),'check');
  if (! defined $rs)
  {
   push @todo,$contact;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple contact names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }

 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('contact','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for contact_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('contact','check_multi',[\@lt,$rd]);
  }
 } else ## either one domain only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('contact','check',[$_,$rd]); } @todo;
 }

 return Net::DRI::Util::link_rs(@rs);
}

sub contact_exist ## 1/0/undef
{
 my ($self,$ndr,$contact,$ep)=@_;
 $self->err_invalid_contact($contact) unless (Net::DRI::Util::isa_contact($contact) && $contact->srid());

 my $rc=$ndr->contact_check($contact,defined $ep ? $ep : ());
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub contact_update
{
 my ($self,$ndr,$contact,$tochange,$ep)=@_;
 $self->err_invalid_contact($contact) unless (Net::DRI::Util::isa_contact($contact) && $contact->srid());
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
 $ep=Net::DRI::Util::create_params('contact_update',$ep);

 my $fp=$ndr->protocol->nameversion();
 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of contact_update/'.$t) unless $ndr->protocol_capable('contact_update',$t);

  my $add=$tochange->add($t);
  my $del=$tochange->del($t);
  my $set=$tochange->set($t);

  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of contact_update/'.$t.' (add)') if (defined($add) && ! $ndr->protocol_capable('contact_update',$t,'add'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of contact_update/'.$t.' (del)') if (defined($del) && ! $ndr->protocol_capable('contact_update',$t,'del'));
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of contact_update/'.$t.' (set)') if (defined($set) && ! $ndr->protocol_capable('contact_update',$t,'set'));
 }

 foreach ($tochange->all_defined('status')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }

 my $rc=$ndr->process('contact','update',[$contact,$tochange,$ep]);
 return $rc;
}

sub contact_update_status_add { my ($self,$ndr,$contact,$s,$ep)=@_; return $self->contact_update_status($ndr,$contact,$s,$ndr->local_object('status'),$ep); }
sub contact_update_status_del { my ($self,$ndr,$contact,$s,$ep)=@_; return $self->contact_update_status($ndr,$contact,$ndr->local_object('status'),$s,$ep); }
sub contact_update_status_set { my ($self,$ndr,$contact,$s,$ep)=@_; return $self->contact_update_status($ndr,$contact,$s,undef,$ep); }

sub contact_update_status
{
 my ($self,$ndr,$contact,$sadd,$sdel,$ep)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->contact_update($ndr,$contact,$c,$ep);
 } else
 {
  return $self->contact_update($ndr,$contact,$ndr->local_object('changes')->set('status',$sadd),$ep);
 }
}

sub contact_transfer
{
 my ($self,$ndr,$contact,$op,$ep)=@_;
 $self->err_invalid_contact($contact) unless (Net::DRI::Util::isa_contact($contact) && $contact->srid());
 Net::DRI::Exception::usererr_invalid_parameters('Transfer operation must be start,stop,accept,refuse or query') unless ($op=~m/^(?:start|stop|query|accept|refuse)$/);
 $ep=Net::DRI::Util::create_params('contact_transfer',$ep);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('contact','transfer_request',[$contact,$ep]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('contact','transfer_cancel',[$contact,$ep]);
 } elsif ($op eq 'query')
 {
  $rc=$ndr->process('contact','transfer_query',[$contact,$ep]);
 } else ## accept/refuse
 {
  $ep->{approve}=($op eq 'accept')? 1 : 0;
  $rc=$ndr->process('contact','transfer_answer',[$contact,$ep]);
 }

 return $rc;
}

sub contact_transfer_start   { my ($self,$ndr,$contact,$ep)=@_; return $self->contact_transfer($ndr,$contact,'start',$ep); }
sub contact_transfer_stop    { my ($self,$ndr,$contact,$ep)=@_; return $self->contact_transfer($ndr,$contact,'stop',$ep); }
sub contact_transfer_query   { my ($self,$ndr,$contact,$ep)=@_; return $self->contact_transfer($ndr,$contact,'query',$ep); }
sub contact_transfer_accept  { my ($self,$ndr,$contact,$ep)=@_; return $self->contact_transfer($ndr,$contact,'accept',$ep); }
sub contact_transfer_refuse  { my ($self,$ndr,$contact,$ep)=@_; return $self->contact_transfer($ndr,$contact,'refuse',$ep); }

sub contact_current_status
{
 my ($self,$ndr,$contact,$ep)=@_;
 my $rc=$self->contact_info($ndr,$contact,$ep);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless Net::DRI::Util::isa_statuslist($s);
 return $s;
}

sub contact_is_mine
{
 my ($self,$ndr,$contact,$ep)=@_;
 my $clid=$self->info('client_id');
 return unless defined $clid;
 my $rc=$self->contact_info($ndr,$contact,$ep);
 return unless $rc->is_success();
 my $id=$ndr->get_info('clID');
 return unless defined $id;
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Message commands (like POLL in EPP)
####################################################################################################

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','retrieve',[$id]);
 return $rc;
}

sub message_delete
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','delete',[$id]);
 return $rc;
}

sub message_waiting
{
 my ($self,$ndr)=@_;
 my $c=$self->message_count($ndr);
 return (defined($c) && $c)? 1 : 0;
}

sub message_count
{
 my ($self,$ndr)=@_;
 my $count=$ndr->get_info('count','message','info');
 return $count if defined($count);
 my $rc=$ndr->process('message','retrieve');
 return unless $rc->is_success();
 $count=$ndr->get_info('count','message','info');
 return (defined($count) && $count)? $count : 0;
}

####################################################################################################
## Extensions commands used by at least 2 DRDs so factorized here
## TODO: for now, this is kind of contradictory with make_exception_for_unavailable_operations()
##       this whole part would need to be redefined, see TODO file
####################################################################################################

## For AFNIC ARNES (subclassed) BE EURid LU
sub domain_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');
 return $ndr->process('domain','trade_request',[$domain,$rd]);
}

## For AFNIC LU
sub domain_trade_query
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');
 return $ndr->process('domain','trade_query',[$domain,$rd]);
}

## For AFNIC EURid LU
sub domain_trade_stop
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'trade');
 return $ndr->process('domain','trade_cancel',[$domain,$rd]);
}

## Used by AT & NO but not with same EPP command name => impossible to factorize here
##sub domain_withdraw
##sub domain_transfer_execute

## For BE EURid SIDN (subclassed)
sub domain_undelete
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'undelete');
 return $ndr->process('domain','undelete',[$domain,$rd]);
}

## For BE EUrid
sub domain_reactivate
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'reactivate');
 return $ndr->process('domain','reactivate',[$domain,$rd]);
}

## For BE EURid
## (no _stop in BE ?)
sub domain_transfer_quarantine
{
 my ($self,$ndr,$domain,$op,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_quarantine');
 Net::DRI::Exception::usererr_invalid_parameters('Transfer from quarantine operation must be start or stop') unless ($op=~m/^(?:start|stop)$/);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('domain','transferq_request',[$domain,$rd]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('domain','transferq_cancel',[$domain,$rd]);
 }
 return $rc;
}

sub domain_transfer_quarantine_start { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer_quarantine($ndr,$domain,'start',$rd); }
sub domain_transfer_quarantine_stop  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer_quarantine($ndr,$domain,'stop',$rd); }

## nsgroup_* + keygroup_* 
## For BE EUrid
sub nsgroup_create
{
 my ($self,$ndr,$nsg)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('nsgroup_create needs an hosts object') unless defined Net::DRI::Util::isa_nsgroup($nsg);
 return $ndr->process('nsgroup','create',[$nsg]);
}

sub nsgroup_delete
{
 my ($self,$ndr,$nsg)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('nsgroup_delete needs an hosts object') unless defined Net::DRI::Util::isa_nsgroup($nsg);
 return $ndr->process('nsgroup','delete',[$nsg]);
}

sub nsgroup_check
{
 my ($self,$ndr,@nsg)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('nsgroup_check needs at least an hosts object') unless grep { defined Net::DRI::Util::isa_nsgroup($_) } @nsg;
 return $ndr->process('nsgroup','check',[@nsg]);
}

sub nsgroup_info
{
 my ($self,$ndr,$nsg)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('nsgroup_info needs an hosts object') unless defined Net::DRI::Util::isa_nsgroup($nsg);
 return $ndr->process('nsgroup','info',[$nsg]);
}

sub nsgroup_update
{
 my ($self,$ndr,$nsg,$tochange)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('nsgroup_update needs an hosts object') unless defined Net::DRI::Util::isa_nsgroup($nsg);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
 return $ndr->process('nsgroup','update',[$nsg,$tochange]);
}

sub keygroup_create
{
 my ($self,$ndr,$kg,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('keygroup_create needs a keygroup name') unless defined $kg;
 return $ndr->process('keygroup','create',[$kg,$rd]);
}

sub keygroup_delete
{
 my ($self,$ndr,$kg,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('keygroup_delete needs a keygroup name') unless defined $kg;
 return $ndr->process('keygroup','delete',[$kg,$rd]);
}

sub keygroup_check
{
 my ($self,$ndr,@kgs)=@_;
 my $rd=(@kgs && ref $kgs[-1] eq 'HASH')? pop(@kgs) : {};
 Net::DRI::Exception::usererr_insufficient_parameters('keygroup_check needs at least a keygroup name') unless grep { defined } @kgs;
 return $ndr->process('keygroup','check',[\@kgs,$rd]);
}

sub keygroup_info
{
 my ($self,$ndr,$kg,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('keygroup_info needs a keygroup name') unless defined $kg;
 return $ndr->process('keygroup','info',[$kg,$rd]);
}

sub keygroup_update
{
 my ($self,$ndr,$kg,$tochange,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('keygroup_update needs a keygroup name') unless defined $kg;
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
 return $ndr->process('keygroup','update',[$kg,$tochange,$rd]);
}

# For BookMyName Gandi OVH

sub account_list_domains
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->try_restore_from_cache('account','domains','list');
 if (! defined $rc) { $rc=$ndr->process('account','list_domains'); }
 return $rc;
}

####################################################################################################
# Misc
####################################################################################################

sub ping
{
 my ($self,$ndr,$reconnect)=@_;
 my ($po,$to)=$ndr->protocol_transport();

 my $rc=$to->ping({protocol=>$po},$reconnect); ## this can die
 return $rc;
}

sub raw_command
{
 my ($self,$ndr,$cmd)=@_;

 my ($po,$to)=$ndr->protocol_transport();
 my $trid=$ndr->generate_trid();
 my $ctx={trid => $trid, otype => 'raw', oaction => 'command', phase => 'active' };
 my $count=1;

 my $tosend=Net::DRI::Data::Raw->new_from_string($cmd);
 $to->send($ctx,$tosend,$count,[]);
 my $res=$to->receive($ctx,$count);
 return $res->as_string();
}

####################################################################################################
1;
