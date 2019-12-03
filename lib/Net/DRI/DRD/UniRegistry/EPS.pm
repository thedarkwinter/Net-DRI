## Domain Registry Interface, UniRegistry::EPS Driver
##
## Copyright (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::UniRegistry::EPS;

use strict;
use warnings;

use base qw/Net::DRI::DRD::UniRegistry::UniRegistry/;
use Net::DRI::Data::Contact::UniRegistry;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::UniRegistry::EPS - UniRegistry::EPS Driver for Net::DRI

=head1 DESCRIPTION

Additional EPS extension UniRegistry::EPS

UniRegistry::EPS use a dedicated server and the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric> http://ns.uniregistry.net/centric-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::eps> http://ns.uniregistry.net/eps-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::eps> (poll parser suppliment)

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::EPS> (Extended Protection Service)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2019 Paulo Jorge <paullojorgge@gmail.com>.
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
sub name     { return 'UniRegistry::EPS'; }

sub tlds     { return ('adultblock', 'adultblockplus'); }
sub object_types { return ('eps'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{'ssl_version'=>'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::UniRegistry',{'default_product'=>'ICM_EPS'}) if $type eq 'epp';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); });
 return;
}

####################################################################################################

1;
