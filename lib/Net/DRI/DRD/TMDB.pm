## Domain Registry Interface, IBM Registry Driver for TMDB (Trade Mark Database)
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

package Net::DRI::DRD::TMDB;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_create contact_info contact_check contact_update contact_delete contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_transfer_accept domains_transfer_reject domains_transfer_cancel/);

=pod

=head1 NAME

Net::DRI::DRD::TMDB - IBM Trade Mark Database Driver for Net::DRI

=head1 DESCRIPTION

Driver for IBM's TMCH conections. See L<Net::DRI::Protocol::TMDB> for more information on the protocol.

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
sub name     { return 'TMDB'; }
sub tlds     { return qw /ngtld/; } # FIXME ? 
sub object_types { return qw/smdrl cnis/; }
sub profile_types { return qw/tmdb/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::HTTP',{'ssl_version'=>'TLSv12', 'ssl_cipher_list' => undef},'Net::DRI::Protocol::TMDB',{}) if $type eq 'tmdb';
 return;
}

# TODO: verify the sig
sub smdrl_fetch_sig {
 my ($self,$ndr)=@_;
 return $ndr->process('smdrl','fetch_sig',['sig']);
}

sub smdrl_fetch {
 my ($self,$ndr)=@_;
 return $ndr->process('smdrl','fetch',['current']);
}

sub cnis_lookup {
 my ($self,$ndr,$lookup_key)=@_;
 return $ndr->process('cnis','lookup',[$lookup_key]);
}

####################################################################################################

1;
