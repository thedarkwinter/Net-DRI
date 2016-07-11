## Domain Registry Interface, .Generenic Neustar New gTLD policies
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
####################################################################################################

package Net::DRI::DRD::NEUSTAR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

####################################################################################################
=pod

=head1 NAME

Net::DRI::DRD::NEUSTAR - NEUSTAR Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension For Neustar New Generic TLDs

Neustar utilises the following standard, and custom extensions. Please see the test files for more examples.

Note: Neustar provides separate environments (including credentials) for each TLD, and all contact/host objects need to be created in each environmnet.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

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
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'NEUSTAR'; }
#sub tlds { return qw/fcfs multi lrclaims gaclaims ga/; } # OT&E
sub tlds     { 
 my @ro1 = qw/neustar/; # Neustar - is this a single registrant registry?
 my @ro2 = qw/xn--g2xx48c xn--nyqy26a xn--rhqv96g best bible buzz ceo club earth ferrero hoteles hsbc htc kinder moe nyc osaka pharmacy qpon rocher safety taipei tube uno whoswho/; # various
 my @ro3p1 = qw/accountant bid date download faith loan men review science trade webcam win/; # Famous Four Media - Phase 1
 #my @ro3p1 = qw/music movie/; # Famous Four Media - Phase 2, copy and paste another day! Not sure if these are contended etc...
 return (@ro1,@ro2,@ro3p1); 
}
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}) if $type eq 'epp';
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
