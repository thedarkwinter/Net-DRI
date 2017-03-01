## Domain Registry Interface, DONUTS Driver
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

=head3 L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

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
sub name     { return 'DONUTS'; }
sub tlds  {
 my @dp = qw/dpml.zone/; # DPML
 my @all = qw/academy accountants agency apartments architect associates bargains bike bingo boutique builders business cab cafe camera camp capital cards care careers cash casino catering center chat cheap church city claims cleaning clinic clothing coach codes coffee community company computer condos construction contractors cool coupons credit creditcard cruises dating deals delivery dental diamonds digital direct directory discount doctor dog domains education email energy engineering enterprises equipment estate events exchange expert exposed express fail farm finance financial fish fitness flights florist football foundation fund furniture fyi gallery gifts gold golf glass gmbh graphics gratis gripe group guide guru healthcare hockey holdings holiday hospital house immo industries institute insure international investments irish jetzt jewelry kitchen land lease legal life lighting limited limo loans ltd maison management mba marketing media medical memorial money movie network partners parts pets photography photos pictures pizza place plumbing plus productions properties recipes reise reisen rentals repair report restaurant run salon sarl school schule services shoes shopping show singles soccer solar solutions sports style supplies supply support surgery systems tax taxi team technology tennis theater tienda tips tires today tools tours town toys training university vacations ventures viajes villas vin vision voyage watch wine world works wtf xn--czrs0t xn--unup4y xn--vhquv zone/;
 return (@dp,@all);
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
