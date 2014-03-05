## Domain Registry Interface, OpenSRS Registry Driver
##
## Copyright (c) 2008-2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::OpenSRS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::OpenSRS - OpenSRS Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head2 CURRENT LIMITATIONS

Only domain_info and account_list_domains are available.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2012 Patrick Mevzek <netdri@dotandco.com>.
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
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'OpenSRS'; }
sub tlds         { return (qw/example com net org info biz mobi name asia at au be bz ca cc ch cn co de dk es eu fr in it li me com.mx mx nl tel tv co.uk org.uk uk us ws/); } ## see http://www.opensrs.com/services/domains/domains-pricing
sub object_types { return ('domain','host'); }
sub profile_types { return qw/xcp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{},'Net::DRI::Protocol::OpenSRS::XCP',{}) if $type eq 'xcp';
 return;
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return;
}

sub account_list_domains
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->try_restore_from_cache('account','domains','list');
 if (! defined $rc) { $rc=$ndr->process('account','list_domains'); }
 return $rc;
}

sub domain_info
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'info');

 my $rc=$ndr->try_restore_from_cache('domain',$domain,'info');
 if (! defined $rc)
 {
  ## First grab a cookie, if needed
  unless (Net::DRI::Util::has_key($rd,'cookie'))
  {
   $rd=Net::DRI::Util::create_params('domain_info',$rd); ## will fail in set_cookie because other params needed, but at least this will be ok for next line ; otherwise do true checks of value needed
   $rd->{domain}=$domain;
   $rc=$ndr->process('session','set_cookie',[$rd]);
   return $rc unless $rc->is_success();
   $rd->{cookie}=$ndr->get_info('value','session','cookie'); ## Store cookie somewhere (taking into account date of expiry or some TTLs) ?
  }
  ## Now do the real info
  $rc=$ndr->process('domain','info',[$domain,$rd]); ## the $domain is not really used here, as it was used during set_cookie above
 }
 return $rc;
}

sub domain_update
{
 my ($self,$ndr,$domain,$changes,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'update');

 ## First grab a cookie, if needed
 unless (Net::DRI::Util::has_key($rd,'cookie'))
 {
  $rd=Net::DRI::Util::create_params('domain_update',$rd); ## will fail in set_cookie because other params needed, but at least this will be ok for next line ; otherwise do true checks of value needed
  $rd->{domain}=$domain;
  my $rc=$ndr->process('session','set_cookie',[$rd]);
  return $rc unless $rc->is_success();
  $rd->{cookie}=$ndr->get_info('value','session','cookie'); ## Store cookie somewhere (taking into account date of expiry or some TTLs) ?
 }
 ## Now do the real update
 my $rc=$ndr->process('domain','update',[$domain,$changes,$rd]); ## the $domain is not really used here, as it was used during set_cookie above
 return $rc;
}

sub domain_is_mine
{
 my ($self,$ndr,$domain,$rd)=@_;
 my $clid=$self->info('client_id');
 return unless defined $clid;
 my $rc=$ndr->process('domain','is_mine',[$domain,$rd]);
 return unless $rc->is_success();
 my $mine=$ndr->get_info('mine');
 return unless defined $mine;
 return $mine;
}

sub domain_send_authcode
{
 my ($self,$ndr,$domain)=@_;
 my $rc=$ndr->process('domain','send_authcode',[$domain]);
 return $rc;
}

sub host_registry_check
{
 my ($self,$ndr,$hostname,$registry)=@_;

 return $ndr->process('nameserver', 'registry_check', [$hostname, $registry]);
}

sub host_registry_add
{
 my ($self,$ndr,$hostname,$rd)=@_;

 return $ndr->process('nameserver', 'registry_add', [$hostname, $rd]);
}

####################################################################################################
1;
