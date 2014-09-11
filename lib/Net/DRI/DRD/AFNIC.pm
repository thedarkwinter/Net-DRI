## Domain Registry Interface, AFNIC Registry Driver for .FR/.RE/.TF/.YT/.WF/.PM
##
## Copyright (c) 2005-2006,2008-2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::AFNIC;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

__PACKAGE__->make_exception_for_unavailable_operations(qw/host_update host_current_status host_check host_exist host_delete host_create host_info contact_delete contact_check/);

=pod

=head1 NAME

Net::DRI::DRD::AFNIC - AFNIC (.FR/.RE/.TF/.WF/.PM/.YT) Registry Driver for Net::DRI

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

Copyright (c) 2005-2006,2008-2014 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{contact_i18n}=1; ## LOC only
 $self->{info}->{check_limit}=7;
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1); }
sub name         { return 'AFNIC'; }
sub tlds         { return (qw/fr re tf wf pm yt asso.fr com.fr tm.fr gouv.fr/); } ## see http://www.afnic.fr/doc/autres-nic/dom-tom
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp dchk/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host => 'epp.sandbox.nic.fr'},'Net::DRI::Protocol::EPP::Extensions::AFNIC',{})                                           if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{find_remote_server => ['fr.','DCHK1:iris.lwz']},'Net::DRI::Protocol::IRIS',{version=>'1.0',authority=>'fr',request_deflate=>1}) if $type eq 'dchk';
 return;
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->SUPER::domain_operation_needs_is_mine($ndr,$domain,$op) if ($ndr->protocol()->name() eq 'EPP');
 return;
}

sub domain_create
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $self->SUPER::domain_create($ndr,$domain,$rd) unless ($ndr->protocol()->name() eq 'EPP');
 return $self->SUPER::domain_create($ndr,$domain,$rd) unless (Net::DRI::Util::has_key($rd,'pure_create') && $rd->{pure_create}==1);
 my $ns;
 if (defined($rd) && (ref($rd) eq 'HASH'))
 {
  $ns=$rd->{ns};
  delete($rd->{ns});
 }
 my $rc=$self->SUPER::domain_create($ndr,$domain,$rd); ## create the domain without any nameserver
 return $rc unless $rc->is_success();
 return $rc unless (defined($ns) && Net::DRI::Util::isa_hosts($ns));
 return $self->domain_update_ns_add($ndr,$domain,$ns); ## Finally update domain to add nameservers
}

sub domain_recover_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'recover');
 return $ndr->process('domain','recover_request',[$domain,$rd]);
}

####################################################################################################
1;
