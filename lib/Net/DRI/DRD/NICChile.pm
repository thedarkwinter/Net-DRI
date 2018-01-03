## Domain Registry Interface, .CL
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI.
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::DRD::NICChile;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;
use Net::DRI::Exception;

# From documentation (NIC_Chile_EPP_Documentation_1.0.5.pdf) - 5.4. Transfers: "... (“cancel” and ”approve” not supported")"
__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domain_transfer_stop/);

=pod

=head1 NAME

Net::DRI::DRD::NICChile - .CL policies

=head1 DESCRIPTION

Important points from: NIC_Chile_EPP_Documentation_1.0.4.pdf

A Registrar will be able to set an AuthInfo to a domain object in this Registry as
plain text or using some cryptographic hash algorithm. At the moment, NIC CL only allow the
SHA256 hash algorithm, but COULD add more alternatives in the future.

NOTE: we keep the EPP standards for NET-DRI. Check domain create example in the test file for this Registry!


E.g.1, "SHA256::cf1aa1863d77023ada45447e87efda6e3f99c4bcdef2c4a767a5f451f5bb414c" is a
valid AuthInfo. Every AuthInfo, will be stored hashed in their database. They will never store the original value.
AuthInfo will not be displayed on responses to the Info command, even if the request comes from the Registrar that owns the domain name.

E.g.2, "PLAIN::ABCDE23456aa" is a valid AuthInfo.

Registrars requesting a domain transfer MUST send the AuthInfo without “PLAIN::” or “SHA256::” prefixes.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge <paullojorgge@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
	$self->{info}->{host_as_attr}=1;
	$self->{info}->{contact_i18n}=1;
	return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'NICChile'; }
sub tlds          { return ('cl', map { $_.'.cl'} qw/gob gov/ ); }
sub object_types  { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
	my ($self,$type)=@_;
	return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CL',{}) if $type eq 'epp';
	return;
}

####################################################################################################
1;
