## Domain Registry Interface, Deloitte Registry Driver for TMCH (Trade Mark Clearing House)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::Deloitte;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_create contact_info contact_check contact_update contact_delete contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_transfer_accept domains_transfer_reject domains_transfer_cancel/);

=pod

=head1 NAME

Net::DRI::DRD::TMCH - Deloitte Trade Mark Clearing House Driver for Net::DRI

=head1 DESCRIPTION

Driver for Deloitte's TMCH conections. See L<Net::DRI::Protocol::TMCH> for more information on the protocol.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Deloitte'; }
sub tlds     { return qw /ngtld/; } # FIXME ? 
sub object_types { return ('mark'); }
sub profile_types { return qw/tmch/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::TMCH',{}) if $type eq 'tmch';
 return;
}

sub mark_check {
 my ($self,$ndr,$mark,$rd)=@_;
 my $rc=$ndr->process('mark','check',[$mark,$rd]);
 return $rc;
}

sub mark_info {
 my ($self,$ndr,$mark)=@_;
 my $rc=$ndr->process('mark','info',[$mark]);
 return $rc;
}

sub mark_info_smd {
 my ($self,$ndr,$mark)=@_;
 my $rc=$ndr->process('mark','info_smd',[$mark]);
 return $rc;
}

sub mark_info_enc {
 my ($self,$ndr,$mark)=@_;
 my $rc=$ndr->process('mark','info_enc',[$mark]);
 return $rc;
}

sub mark_create {
 my ($self,$ndr,$mark,$rd)=@_;
 my $rc=$ndr->process('mark','create',[$mark,$rd]);
 return $rc;
}

sub mark_update {
 my ($self,$ndr,$mark,$rd)=@_;
 my $rc=$ndr->process('mark','update',[$mark,$rd]);
 return $rc;
}

sub mark_renew {
 my ($self,$ndr,$mark,$rd)=@_;
 my $rc=$ndr->process('mark','renew',[$mark,$rd]);
 return $rc;
}


####################################################################################################

1;
