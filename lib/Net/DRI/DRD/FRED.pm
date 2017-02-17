## Domain Registry Interface, .FRED policies
##
## Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::FRED;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Data::Contact::FRED;
use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domains_transfer_reject domains_transfer_cancel domains_transfer_query host_create host_check host_update host_delete host_info/);

=pod

=head1 NAME

Net::DRI::DRD::FRED - .FRED policies for Net::DRI

=head1 DESCRIPTION

Additional domain extension to manage nameservers & technical contact NSSET, see FRED.t for examples.

Additional contact extension with 'vat', 'notify_email' and 'identity' fields, see L<Net::DRI::Data::Contact::FRED>

The FRED system powers the following TLD's:

.MW - Malawi
.CZ - Czech Republic
.AO - Angola
.TZ - Tanzania
.CR - Costa Rica
.AL - Albania
.MK - Macedonia
.AR - Argentina

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::FRED:NSSET>

=head3 L<Net::DRI::Protocol::EPP::Extensions::FRED:KeySET>

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
           (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new {
  my $class=shift;
  my $self=$class->SUPER::new(@_);
  $self->{info}->{host_as_attr}=0;
  $self->{info}->{contact_i18n}=2;
  return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'FRED'; }
sub tlds          { return (
                      'mw',(map { $_.'.mw'} qw/ac co com coop edu gov int museum net org/),
                      'cz',
                      'ao',
                      'tz',(map { $_.'.tz'} qw/co ac go or mil sc ne hotel mobi tv info me/),
                      'cr',(map { $_.'.cr'} qw/ac co ed fi go or sa/),
                      'al',(map { $_.'.al'} qw/com net org edu/),
                      'mk',(map { $_.'.mk'} qw/com org net edu gov inf/),
                      'ar',(map { $_.'.ar'} qw/com edu gob int mil net org tur/)
                   ); }
sub object_types  { return ('domain','contact','ns','nsset','keyset'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
  my ($self,$type)=@_;
  return ('Net::DRI::Transport::Socket',{'ssl_version' => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::FRED',{}) if $type eq 'epp';
  return;
}

sub set_factories {
   my ($self,$po)=@_;
   $po->factories('contact',sub { return Net::DRI::Data::Contact::FRED->new(@_); });
   return;
}

####################################################################################################

####################################################################################################

sub nsset_check {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('nsset','check',[$keyset,$rd]);
}

sub nsset_create {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('nsset','create',[$keyset,$rd]);
}

sub nsset_info {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('nsset','info',[$keyset,$rd]);
}

sub nsset_delete {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('nsset','delete',[$keyset,$rd]);
}

sub nsset_update {
   my ($self,$ndr,$domain,$tochange,$rd)=@_;
   $rd=Net::DRI::Util::create_params('nsset_update',$rd);
   Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
   Net::DRI::Exception->new(0,'DRD',4,'Registry does not handle contacts')
     if ($tochange->all_defined('contact') && ! $self->has_object('contact'));

   my $fp=$ndr->protocol->nameversion();
     foreach my $t ($tochange->types()) {
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of nsset_update/'.$t)
        unless $ndr->protocol_capable('nsset_update',$t);
      my $add=$tochange->add($t);
      my $del=$tochange->del($t);
      my $set=$tochange->set($t);
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of nsset_update/'.$t.' (add)')
        if (defined($add) && ! $ndr->protocol_capable('nsset_update',$t,'add'));
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of nsset_update/'.$t.' (del)')
        if (defined($del) && ! $ndr->protocol_capable('nsset_update',$t,'del'));
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of nsset_update/'.$t.' (set)')
        if (defined($set) && ! $ndr->protocol_capable('nsset_update',$t,'set'));
     }

   foreach ($tochange->all_defined('contact')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::ContactSet'); }

   my $rc=$ndr->process('nsset','update',[$domain,$tochange,$rd]);
   return $rc;
}

sub keyset_create {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('keyset','create',[$keyset,$rd]);
}

sub keyset_check {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('keyset','check',[$keyset,$rd]);
}

sub keyset_info {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('keyset','info',[$keyset,$rd]);
}

sub keyset_transfer {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('keyset','transfer',[$keyset,$rd]);
}

sub keyset_delete {
  my ($self,$ndr,$keyset,$rd)=@_;
  return $ndr->process('keyset','delete',[$keyset,$rd]);
}

sub keyset_update {
   my ($self,$ndr,$domain,$tochange,$rd)=@_;
   $rd=Net::DRI::Util::create_params('keyset_update',$rd);
   Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');
   Net::DRI::Exception->new(0,'DRD',4,'Registry does not handle contacts')
     if ($tochange->all_defined('contact') && ! $self->has_object('contact'));

   my $fp=$ndr->protocol->nameversion();
     foreach my $t ($tochange->types()) {
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of keyset_update/'.$t)
        unless $ndr->protocol_capable('keyset_update',$t);
      my $add=$tochange->add($t);
      my $del=$tochange->del($t);
      my $set=$tochange->set($t);
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of keyset_update/'.$t.' (add)')
        if (defined($add) && ! $ndr->protocol_capable('keyset_update',$t,'add'));
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of keyset_update/'.$t.' (del)')
        if (defined($del) && ! $ndr->protocol_capable('keyset_update',$t,'del'));
      Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of keyset_update/'.$t.' (set)')
        if (defined($set) && ! $ndr->protocol_capable('keyset_update',$t,'set'));
     }

   foreach ($tochange->all_defined('contact')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::ContactSet'); }

   my $rc=$ndr->process('keyset','update',[$domain,$tochange,$rd]);
   return $rc;
}

####################################################################################################
1;
