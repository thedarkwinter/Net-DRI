## Domain Registry Interface, CentralNic Registry Driver
##
## Copyright (c) 2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::DRD::CentralNic::CentralNic;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::CentralNic::CentralNic - CentralNic (gTLD and SLD) Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

Additional domain extension used new Generic TLDs

CentralNic utilises the following standard extensions. Please see the test files for more examples.

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.5

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::AuxContact> urn:ietf:params:xml:ns:auxcontact-0.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::RegType> urn:ietf:params:xml:ns:regtype-0.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::COOP::Contact> http://www.nic.coop/contactCoopExt-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->{info}->{contact_i18n}=4;       ## INT & LOC
 return $self;
}

sub periods { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name { return 'CentralNic::CentralNic'; }
sub tlds {
  my @coms = (map { $_.'.com' } qw/africa ar br cn co de eu gb gr hu jpn kr mex no qc ru sa se uk us uy za/);
  my @nets = (map { $_.'.net' } qw/uk se gb jp hu in/);
  my @orgs = (map { $_.'.org' } qw/us ae/);
  my @others = qw/pw com.de com.se co.nl fm radio.fm radio.am gd vg/;
  my @ngtlds = qw/art auto autos baby bar beauty best blog boats bond budapest build cam car cars ceo cfd college cyou dealer desi fans feedback forum fun gent hair homes host icu inc london luxury makeup monster motorcycles online ooo pid press protection qpon quest reit rent rest saarland sbs security site skin space spreadbetting storage store tech theatre tickets uno website wme xn--4gbrim xyz yachts/;
  my @ngtlds_contested = qw/hotel mail/; # some of these might go to other registries
  my @cctlds = (qw/bh xn--mgbcpq6gpa1a/, map {$_.'.bh'} qw/biz cc com edu info me med name net org/);
  return (@coms,@nets,@orgs,@others,@ngtlds,@cctlds);
}

sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CentralNic',{'brown_fee_version' => '0.5'}) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 1,
                                              });
}

####################################################################################################

1;
