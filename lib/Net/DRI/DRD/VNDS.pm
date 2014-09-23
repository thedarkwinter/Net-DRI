## Domain Registry Interface, "Verisign Naming and Directory Services" Registry Driver for .COM .NET .CC .TV .BZ .JOBS
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

package Net::DRI::DRD::VNDS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::VNDS - Verisign .COM/.NET/.CC/.TV/.BZ/.JOBS Registry driver for Net::DRI

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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{check_limit}=13;
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'VNDS'; }
sub tlds          { return qw/com net cc tv bz jobs xn--pssy2u xn--c1yn36f xn--11b4c3d xn--t60b56a xn--c2br7g xn--42c2d9a xn--j1aef xn--3pxu8k xn--hdb9cza1b xn--mk1bu44c xn--fhbei xn--tckwe career ooo/; } ## If this changes, VeriSign/NameStore will need to be updated also
sub object_types  { return qw/domain ns registry/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::RRP',{})                                        if $type eq 'rrp'; ## this is used only for internal tests
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::VeriSign',{})                  if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.verisign-grs.com'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1,
                                              });
}

## We can not start a transfer, if domain name has already been transfered less than 15 days ago.
sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;

 return $self->_verify_duration_transfer_15days($ndr,$duration,$domain,$op);
}

####################################################################################################

sub domain_whowas
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'whowas');

 my $rc=$ndr->try_restore_from_cache('domain',$domain,'whowas');
 if (! defined $rc) { $rc=$ndr->process('domain','whowas',[$domain,$rd]); }
 return $rc;
}

sub domain_suggest
{
 my ($self,$ndr,$domain,$rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('domain_suggestion domain/key must be a string of 2 to 32 characters') unless Net::DRI::Util::xml_is_string($domain,2,32);
 $self->enforce_domain_name_constraints($ndr,$domain,'suggestion') unless $domain=~m/\s/; ## if we have a space, then $domain is a list of keywords
 my $rc=$ndr->try_restore_from_cache('domain',$domain,'suggesion');
 if (! defined $rc) { $rc=$ndr->process('domain','suggestion',[$domain,$rd]); }
 return $rc;
}

sub twofactorauth_create
{
 my ($self,$ndr,$rd)=@_;
 return $ndr->process('authsession','create',[$rd]);
}

sub balance_info
{
 my ($self,$ndr)=@_;
 return $ndr->process('balance','info');
}

sub registry_check
{
  my ($self,$ndr,@p)=@_;
  my (@names,$rd);
  foreach my $p (@p)
  {
    if (defined $p && ref $p eq 'HASH')
    {
      Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in registy_check') if defined $rd;
      $rd=Net::DRI::Util::create_params('registry_check',$p);
    }
    push @names,$p;
  }
  Net::DRI::Exception::usrerr_insuficient_parameters('registry_check needs at least one registry name zone to check') unless @names;
  $rd={} unless defined $rd;

  my (@rs,@todo);
  my (%seendom,%seenrc);
  foreach my $zone (@names)
  {
    next if exists $seendom{$zone};
    $seendom{$zone}=1;
    my $rs=$ndr->try_restore_from_cache('registry',$zone,'check');
    if (!defined $rs)
    {
      push @todo,$zone;
    } else
    {
      push @rs,$rs unless exists $seenrc{''.$rs};
      $seenrc{''.$rs}=1;
    }
  }
  return Net::DRI::Util::link_rs(@rs) unless @todo;

  if (@todo > 1 && $ndr->protocol()->has_action('registry','check_multi'))
  {
    my $l=$self->info('check_limit');
    if (!defined $l)
    {
      $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for registry_check action. Please report if you know the correct value'); # TODO: doc say maxOccurs="unbounded". Because of performance should we limit or not?
      $l=10;
    }
    while (@todo)
    {
      my @lt=splice(@todo,0,$l);
      push @rs,$ndr->process('registry','check_multi',[\@lt,$rd]);
    }
  }  else
  {
    push @rs,map { $ndr->process('registry','check',[$_,$rd]); } @todo;
  }
  return Net::DRI::Util::link_rs(@rs);
}

sub registry_info
{
  my ($self,$reg,$id,$rd)=@_;
  return $reg->process('registry','info',[$id,$rd]);
}

sub registry_create
{
  my ($self,$reg,$id,$rd)=@_;
  return $reg->process('registry','create',[$id,$rd]);
}

sub registry_delete
{
  my ($self,$reg,$id)=@_;
  return $reg->process('registry','delete',[$id]);
}

sub registry_update
{
  my ($self,$reg,$id,$todo)=@_;
  return $reg->process('registry','update',[$id,$todo]);
}

####################################################################################################
1;
