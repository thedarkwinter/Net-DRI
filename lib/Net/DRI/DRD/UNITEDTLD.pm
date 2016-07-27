## Domain Registry Interface, United TLD Driver
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::UNITEDTLD;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::MAM - United TLD Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension United TLD New Generic TLDs.

United TLDutilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom Extensions

=head3 L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

=head3 L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

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
(c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>.
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
sub name     { return 'UNITEDTLD'; }

#sub tlds     { return ('tld','claimsga','claimslandrush'); } # OT&E tlds
sub tlds     { return qw/dpml.pub actor airforce army attorney auction band consulting dance degree democrat dentist engineer family forsale futbol games gives haus immobilien kaufen lawyer live market moda mortgage navy news ninja pub rehab republican reviews rip rocks sale social software studio vet video/; } # http://rightside.co/rightside-registry/tld-portfolio/
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}) if $type eq 'epp';
 return;
}

####################################################################################################

1;
