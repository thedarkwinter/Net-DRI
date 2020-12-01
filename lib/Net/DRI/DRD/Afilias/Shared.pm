## Domain Registry Interface, Afilias (Shared) Driver
##
## Copyright (c) 2006-2009 Rony Meyer <perl@spot-light.ch>. All rights reserved.
##           (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved..
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

package Net::DRI::DRD::Afilias::Shared;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::Afilias::Shared - Afilias (Shared) Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extensions Afilias Shared Registry Platform

Afilias has extended their plaform to include these TLDs in a Shared Registry System

Afilias utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head2 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Rony Meyer <perl@spot-light.ch>.
          (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2017 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->{info}->{check_limit}=13;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Afilias::Shared'; }

sub tlds     {
 my @legacygTLDs = qw/asia/;
 my @newgTLDs = qw/xn--4gbrim xn--kput3i bnpparibas boats creditunion eco ged global homes indians ist istanbul ltda motorcycles onl rich srl vegas yachts zara/;
 my @ccTLDs = (
     'ag',(map { $_.'.ag'} qw/co com net nom org/),
     'bz',(map { $_.'.bz'} qw/co com net org/),
     'gi',
     'lc',(map { $_.'.lc'} qw/co com l net org p/),
     'me',
     'mn',
     'pr',(map { $_.'.pr'} qw/biz com info isla name net org pro/),
     'sc',(map { $_.'.sc'} qw/com net org/),
     'vc',(map { $_.'.vc'} qw/com net org/));
 return (@legacygTLDs, @newgTLDs, @ccTLDs);
}
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.8'}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.afilias-srs.net'},'Net::DRI::Protocol::Whois',{'NGTLD'=>1}) if $type eq 'whois';
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
