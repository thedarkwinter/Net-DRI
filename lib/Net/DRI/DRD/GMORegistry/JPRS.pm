## Domain Registry Interface, JPRS GMO Registry (.jp) Driver
##
## Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::GMORegistry::JPRS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_renew/);

=pod

=head1 NAME

Net::DRI::DRD::GMORegistry::JPRS - JPRS GMO Registry (.JP) Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extensions for JPRS GMO Registry (.JP) ccTLDs

JP is operated by JPRS GMO Registry

Terms

- JPRS : Japan Registry Service

- o-JP : Organizational Type JP Domain Name (co.jp, or.jp, ed.jp, ac.jp)

- g-JP : General-use JP Domain name (.jp)

This DRD extends the L<Net::DRI::DRD::GMORegistry::JPRS>

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head3 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.5

=head3 L<Net::DRI::Protocol::EPP::Extensions::JP::JPEX> urn:ietf:params:xml:ns:jpex-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2021 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
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

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); } # only 1 year period
sub name     { return 'GMORegistry::JPRS'; }
sub tlds { return qw/jp co.jp or.jp ed.jp ac.jp/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::JP',{'brown_fee_version' => '0.5'}) if $type eq 'epp';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::JP->new(@_); });
 return;
}

####################################################################################################

1;
