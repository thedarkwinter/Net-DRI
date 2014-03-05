## Domain Registry Interface, DONUTS Driver
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

package Net::DRI::DRD::DONUTS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::DONUTS - DONUTS Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension DONUTS New Generic TLDs

Donuts utilises the following standard, and custom extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

=head2 DPML Blocks / Overrides:

In order to submit DPML blocks OR DMPL Overrides, submit a domain_create with the correct TLD (.dpml.zone for block) and the LaunchPhase extensions should contain the [Encoded] Signed Mark, along with the phase name 'dpml'

  $dri->domain_create('mylabel.dpml.zone',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   });# DPML Block
  $dri->domain_create('mylabel.energy',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   }); # DPML Override

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
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'DONUTS'; }

#sub tlds     { return ('dpml.zone','energy','xn‐‐hx814e','ote','earlyaccess','sunrise'); } # FIXME : these are OT&E tlds!
sub tlds  { 
 my @dp = qw/dpml.zone/; # DPML
 my @ga = qw/bike clothing guru holdings plumbing singles ventures camera equipment estate gallery graphics lighting photography contractors construction directory kitchen land today technology diamonds enterprises tips voyage careers photos recipes shoes/; # GA
 my @s6 = qw/limo domains cab company/; #SR 31-12-13
 my @s7 = qw/computer systems academy management center/; #SR 07-01-14
 my @s8 = qw/builders email solutions support training/; #SR 14-01-14
 my @s9 = qw/education institute repair camp glass/; #SR 21-01-14
 my @s10 = qw/solar coffee international house florist/; #SR 28-01-14
 my @s11 = qw/holiday marketing/; #SR 04-02-14
 my @s12 = qw/viajes farm codes/; #SR 11-02-14
 my @s13 = qw/cheap zone agency bargains boutique/; # SR 18-02-14
 my @s14 = qw/cool watch/; # SR 25-02-14
 my @s15 = qw/expert works/; # SR 04-03-14
 my @s16 = qw/foundation exposed/; # SR 11-03-13 - TBC
 my @s17 = qw/villas flights rentals cruises vacations/; # SR 18-03-14 - TBC
 my @s18 = qw/condos properties maison tienda/; # SR 25-03-14 - TBC
return (@dp,@ga,@s6,@s7,@s8,@s9,@s10,@s11,@s12,@s13,@s14,@s15,@s16,@s17,@s18);
}
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
