## Domain Registry Interface, Neustar (Narwhal) policies
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014-2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::Neustar::Narwhal;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;
use Net::DRI::Data::Contact::Neustar;

####################################################################################################
=pod

=head1 NAME

Net::DRI::DRD::Neustar::Narwhal - Neustar Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension For Neustar Narwhal platform. Most Neustar TLDs are now operated on this shared platform, including all ARI TLDs, most of the
ngTLDs that Neustar operated on its legacy platform, as well as older gTLDs and ccTLDs, which are gradually getting moved to this platform.

Neustar utilises the following standard, and custom extensions, in many cases supporting two versions for the same functionallity.
Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::AllocationToken> urn:ietf:params:xml:ns:allocationToken-1.0

=head2 Custom extensions (NeuLevel)

=head3 L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::Message> urn:ietf:params:xml:ns:neulevel-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact> urn:ietf:params:xml:ns:neulevel-1.0 (For .NYC Only)

=head3 L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::WhoisType> urn:ietf:params:xml:ns:neulevel-1.0 (For .TEL Only)

=head2 Custom extensions (ex-ARI .To use these, set profile type to 'epp_ari')

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Application> urn:ar:params:xml:ns:application-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Trademark> urn:ar:params:xml:ns:tmch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::IDN> urn:ar:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Variant> urn:ar:params:xml:ns:variant-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Price> urn:ar:params:xml:ns:price-1.2

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail> urn:ar:params:xml:ns:exAvail-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ARI::Block> urn:ar:params:xml:ns:block-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014-2017 Michael Holloway <michael@thedarkwinter.com>.
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

sub name     { return 'Neustar::Narwhal'; }

sub tlds     { return qw/aaa able accountant aetna afl aig americanexpress amex amica analytics anz aramco athleta auspost axa banamex bananarepublic bank barclaycard barclays baseball bible bid biz booking boots box buzz calvinklein cancerresearch caravan cartier catholic cba cbn cbre chase chintai chloe cisco citadel citi cloud club co com.co net.co nom.co commbank compare coupon courses cricket cuisinella date dell discover doha download duns dupont earth everbank faith farmers ferrero film flickr flir ford fox frontier ftr gap giving grainger gucci hbo health homegoods homesense honeywell hoteles hotels hsbc htc hyatt ibm ieee insurance intel intuit ipiranga iselect itau iwc jlc jmp jnj jpmorgan kinder kpmg krd kred lanxess latrobe lifeinsurance lilly lincoln loan loft luxury marshalls mattel mcd mcdonalds melbourne men menu mint mlb mobily moe monash montblanc moto mtn mutual nba netbank netflix neustar nfl nike northwesternmutual nyc office olayan olayangroup oldnavy one open osaka pamperedchef panerai party passagens pfizer pharmacy philips physio piaget ping pramerica praxi pru prudential qpon qvc racing review rmit rocher safety sandvik sandvikcoromant sas saxo schmidt science scor seek select seven skype song staples starhub statefarm stream study sucks swiftcover sydney tab taipei taobao target tdk tel teva tjmaxx tjx tkmaxx tmall trade travel trust tube us virgin vista vistaprint vivo voting vu vuelos walter watches weather weatherchannel webcam williamhill win winners woodside wtc xn--1ck2e1b xn--80aqecdr1a xn--bck1b9a5dre4c xn--cck2b3b xn--eckvdtc9d xn--fct429k xn--g2xx48c xn--gckr3f0f xn--gk3at1e xn--jvr189m xn--kcrx77d1x4a xn--kpu716f xn--mgba3a3ejt xn--mgba7c0bbn0a xn--mgbb9fbpob xn--mgbi4ecexp xn--ngbc5azd xn--pbt977c xn--rovu88b xn--tiq49xqyj yahoo yandex zero zippo/; }

sub object_types { return ('domain','contact','ns'); }

sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Neustar',{ 'brown_fee_version' => '0.6' }) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}) if $type eq 'epp_ari';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::Neustar->new(@_); });
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1,
                                              });
}

####################################################################################################
1;
