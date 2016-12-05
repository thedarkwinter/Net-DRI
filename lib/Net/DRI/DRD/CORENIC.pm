## Domain Registry Interface, CORENIC Driver
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013,2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::CORENIC;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::CORENIC - CORENIC Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension CoreNIC New Generic TLDs

CoreNIC utilises the following standard, and custom extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head2 Custom extensions: (From TANGO-RS but with CoreNIC namespaces)

=head3 L<Net::DRI::Protocol::EPP::Extensions::TANGO::IDN> : http://xmlns.corenic.net/epp/idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::TANGO::Auction> : http://xmlns.corenic.net/epp/auction-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::LaunchPhase> : http://xmlns.corenic.net/epp/mark-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::ContactEligibility> : http://xmlns.corenic.net/epp/contact-eligibility-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Promotion> : http://xmlns.corenic.net/epp/promotion-1.0

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
(c) 2013,2015 Michael Holloway <michael@thedarkwinter.com>.
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
sub name     { return 'CORENIC'; }
sub tlds     { return ('xn--80asehdb','xn--80aswg','xn--mgbab2bd','barcelona','eurovision','erni','eurovision','eus','gal','lacaixa','madrid','mango','museum','quebec','radio','scot','sport','swiss'); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORENIC',{}) if $type eq 'epp';
 return;
}

####################################################################################################

1;
