## Domain Registry Interface, GoDaddy::MZB Driver
##
## Copyright (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::GoDaddy::MZB;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

####################################################################################################
=pod

=head1 NAME

Net::DRI::DRD::GoDaddy::MZB - GoDaddy::MZB Driver for Net::DRI

=head1 DESCRIPTION

Additional MZB extension GoDaddy::MZB
GoDaddy::MZB use a dedicated server and the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::AllocationToken> urn:ietf:params:xml:ns:allocationToken-1.0

=head2 Custom extensions (NeuLevel)

=head3 L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::Message> urn:ietf:params:xml:ns:neulevel-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact> urn:ietf:params:xml:ns:neulevel-1.0 (For .NYC Only)

=head3 L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::WhoisType> urn:ietf:params:xml:ns:neulevel-1.0 (For .TEL Only)

=head2 Custom extensions (ex-ARI .To use these, set profile type to 'epp_ari')

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Application> urn:ar:params:xml:ns:application-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Trademark> urn:ar:params:xml:ns:tmch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::IDN> urn:ar:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Variant> urn:ar:params:xml:ns:variant-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Price> urn:ar:params:xml:ns:price-1.2

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail> urn:ar:params:xml:ns:exAvail-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Block> urn:ar:params:xml:ns:block-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
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
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=4; ## LOC+INT

 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'GoDaddy::MZB'; }

sub tlds     { return ('adultblock', 'adultblockplus'); }
sub object_types { return ('mzb'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::GoDaddy',{'default_product'=>'GODADDY_MZB'}) if $type eq 'epp';
 return;
}

####################################################################################################
sub mzb_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in mzb_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('mzb_check',$p);
  }
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('mzb_check needs at least one label to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seenlab,%seenrc);
 foreach my $label (@names)
 {
  next if exists $seenlab{$label};
  $seenlab{$label}=1;
  my $rs=$ndr->try_restore_from_cache('mzb',$label,'check');
  if (! defined $rs)
  {
   push @todo,$label;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple labels (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }
 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('mzb','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for mzb_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('mzb','check_multi',[\@lt,$rd]);
  }
 } else ## either one label only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('mzb','check',[$_,$rd]); } @todo;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub mzb_info
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','info',[$id,$rd]);
}

sub mzb_exempt
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in mzb_exempt') if defined $rd;
   $rd=Net::DRI::Util::create_params('mzb_exempt',$p);
  }
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('mzb_exempt needs at least one label to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seenlab,%seenrc);
 foreach my $label (@names)
 {
  next if exists $seenlab{$label};
  $seenlab{$label}=1;
  my $rs=$ndr->try_restore_from_cache('mzb',$label,'check');
  if (! defined $rs)
  {
   push @todo,$label;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple labels (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }
 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('mzb','exempt_multi'))
 {
  my $l=$self->info('exempt_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No exempt_limit specified in driver, assuming 10 for mzb_exempt action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('mzb','exempt_multi',[\@lt,$rd]);
  }
 } else ## either one label only, or more than one but no exempt_multi available at protocol level
 {
  push @rs,map { $ndr->process('mzb','exempt',[$_,$rd]); } @todo;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub mzb_create
{
 my ($self,$reg,$id,$rd)=@_;
 $id = $id->[0] if ref($id) eq 'ARRAY' && scalar(@$id) eq 1;
 return $reg->process('mzb','create',[$id,$rd]);
}

sub mzb_delete
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','delete',[$id,$rd]);
}

sub mzb_renew
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','renew',[$id,$rd]);
}

# by documentation only op="request" is supported for mzb objects
sub mzb_transfer_request
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','transfer_request',[$id,$rd]);
}

sub mzb_update
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','update',[$id,$rd]);
}

# used to set a password to permit the registration of a domain object blocked by an mzb object
sub mzb_release_create
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','release_create',[$id,$rd]);
}

# used to delete a password set to permit the registration of a domain object blocked by an mzb object
sub mzb_release_delete
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('mzb','release_delete',[$id,$rd]);
}

####################################################################################################
1;