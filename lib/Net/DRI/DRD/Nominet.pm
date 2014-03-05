## Domain Registry Interface, .UK (Nominet) policies for Net::DRI
##
## Copyright (c) 2007-2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::Nominet;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;

use DateTime::Duration;

## No status at all with Nominet
## Only domain:check is available
## Only domain transfer op=req and refuse/accept
## The delete command applies only to domain names.  Accounts, contacts and nameservers cannot be explicitly deleted, but are automatically deleted when no longer referenced.
## No direct contact/host create
__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_update_status_add domain_update_status_del domain_update_status_set domain_update_status domain_status_allows_delete domain_status_allows_update domain_status_allows_transfer domain_status_allows_renew domain_status_allows domain_current_status host_update_status_add host_update_status_del host_update_status_set host_update_status host_current_status contact_update_status_add contact_update_status_del contact_update_status_set contact_update_status contact_current_status host_check host_exist contact_check contact_exist contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_transfer_stop domain_transfer_query host_delete contact_delete host_create contact_create/);

=pod

=head1 NAME

Net::DRI::DRD::Nominet - .UK (Nominet) policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (2); }
sub name     { return 'Nominet'; }
sub tlds     { return qw/co.uk ltd.uk me.uk net.uk org.uk plc.uk sch.uk/; } ## See http://www.nominet.org.uk/registrants/aboutdomainnames/rules/
sub object_types { return ('domain','contact','ns','account'); }
sub profile_types { return qw/epp epp_nominet epp_standard/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host => 'epp.nominet.org.uk'},'Net::DRI::Protocol::EPP::Extensions::Nominet',{}) if ($type eq 'epp' || $type eq 'epp_nominet');
 return ('Net::DRI::Transport::Socket',{remote_host => 'epp.nominet.org.uk'},'Net::DRI::Protocol::EPP',{})                      if ($type eq 'epp_standard');
 return;
}

sub transport_protocol_init
{
 my ($self,$type,$tc,$tp,$pc,$pp,$test)=@_;

 ## As seen on http://www.nominet.org.uk/registrars/systems/nominetepp/login/
 $tp->{client_login}='#'.$tp->{client_login} if ($type eq 'epp' && defined $tp->{client_login} && length $tp->{client_login}==2);
 return;
}

####################################################################################################

## http://www.nominet.org.uk/registrars/systems/epp/renew/
sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;

## +Renew commands will only be processed if the expiry date of the domain name is within 6 months.

 return 0 unless defined $duration;

 my ($y,$m)=$duration->in_units('years','months');
 return 1 unless ($y==2 && $m==0); ## Only 24m or 2y allowed
 return 0; ## everything ok
}

sub host_info
{
 my ($self,$ndr,$dh,$rh)=@_;
 my $roid=Net::DRI::Util::isa_hosts($dh)? $dh->roid() : $dh;

 ## when we do a domain:info we get all info needed to later on reply to a host:info (cache delay permitting) ; we do not take this information into account here
 my $rc=$ndr->try_restore_from_cache('host',$roid,'info');
 if (! defined $rc) { $rc=$ndr->process('host','info',[$dh,$rh]); }

 return $rc unless $rc->is_success();
 return (wantarray())? ($rc,$ndr->get_info('self')) : $rc;
}

sub host_update
{
 my ($self,$ndr,$dh,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 my $name=Net::DRI::Util::isa_hosts($dh)? $dh->get_details(1) : $dh;
 $self->enforce_host_name_constraints($ndr,$name);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${t} not handled") unless ($t=~m/^(?:ip|name)$/);
  next if $ndr->protocol_capable('host_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable of host_update/${t}");
 }

 my %what=('ip'     => [ $tochange->all_defined('ip') ],
           'name'   => [ $tochange->all_defined('name') ],
          );
 foreach (@{$what{ip}})     { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach (@{$what{name}})   { $self->enforce_host_name_constraints($ndr,$_); }

 foreach my $w (keys(%what))
 {
  my @s=@{$what{$w}};
  next unless @s; ## no changes of that type

  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'add'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'del'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'set'));
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('host','update',[$dh,$tochange]);
 return $rc;
}

sub account_info
{
 my ($self,$ndr,$c)=@_;
 return $ndr->process('account','info',[$c]);
 }

sub account_update
{
 my ($self,$ndr,$c,$cs)=@_;
 return $ndr->process('account','update',[$c,$cs]);
}

sub account_fork
{
 my ($self,$ndr,$c,$cs)=@_;
 return $ndr->process('account','fork',[$c,$cs]);
}

sub account_merge
{
 my ($self,$ndr,$c,$cs)=@_;
 return $ndr->process('account','merge',[$c,$cs]);
}

sub domain_unrenew
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'unrenew');
 return $ndr->process('domain','unrenew',[$domain,$rd]);
}

sub account_list_domains
{
 my ($self,$ndr,$rd,$rh)=@_;
 my $rc=$ndr->try_restore_from_cache('account','domains','list');
 if (! defined $rc) { $rc=$ndr->process('account','list_domains',[$rd,$rh]); }
 return $rc;
}

####################################################################################################
1;
