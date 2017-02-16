## Domain Registry Interface, ARI Driver
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

package Net::DRI::DRD::ARI;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::ARI - ARI Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension ARIs New Generic TLDs

ARI utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Application> urn:ar:params:xml:ns:application-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Trademark> urn:ar:params:xml:ns:tmch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::IDN> urn:ar:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Variant> urn:ar:params:xml:ns:variant-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Price> urn:ar:params:xml:ns:price-1.2

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail> urn:ar:params:xml:ns:exAvail-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Block> urn:ar:params:xml:ns:block-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::Message> urn:ietf:params:xml:ns:neulevel-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::AllocationToken> urn:ietf:params:xml:ns:allocationToken-1.0

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
sub name     { return 'ARI'; }

#sub tlds     { return ('example','xn--mgbh0fb','keyvalue','sunrise','landrush'); } # FIXME : these are OT&E tlds!
sub tlds     { return qw/xn--1ck2e1b xn--bck1b9a5dre4c xn--cck2b3b xn--eckvdtc9d xn--fct429k xn--gckr3f0f xn--gk3at1e xn--jvr189m xn--kcrx77d1x4a xn--kpu716f xn--mgba7c0bbn0a xn--ngbc5azd xn--pbt977c xn--rovu88b aaa afl americanexpress amex analytics anz athleta audible author aws banamex bananarepublic barclaycard barclays bond book booking boots bot bridgestone build buy buzz call cancerresearch cartier cba cbn chase chintai chloe circle citadel citi cloud commbank compare coupon courses cuisinella deal dell discover doha duns dupont farmers fast ferrero film fire firestone flickr ford fox free ftr gap giving got gucci homegoods homesense honeywell hot hsbc hyatt ibm icu ieee iinet imdb intel intuit iselect iwc jlc jmp jnj jot joy jpmorgan kinder kindle kpmg krd latrobe like lilly lincoln luxury marshalls mcd mcdonalds melbourne men menu mint mlb moi monash montblanc mtn mutual netbank nfl now olayan olayangroup oldnavy one open panerai pay philips physio piaget pin ping playstation praxi prime quest qvc read rocher room safe sandvik sandvikcoromant sas save saxo schmidt scor secure seek select seven silk smile song sony spot starhub statefarm study sucks swiftcover sydney tab talk tdk teva tjmaxx tjx tkmaxx trust tunes tushu virgin vista vistaprint vivo walter wanggou watches weather weatherchannel winners woodside wow wtc yahoo yamaxun yandex you zappos zero zippo/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}) if $type eq 'epp';
 return;
}

####################################################################################################

1;
