## Domain Registry Interface, Afilias SRS Driver
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

package Net::DRI::DRD::AfiliasSRS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::AfiliasSRS - Afilias SRS Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension AfiliasSRS New Generic TLDs

AfiliasSRS utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1 

=head3 L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0 

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
sub name     { return 'AfiliasSRS'; }

sub tlds     { 
 my @pro = qw/pro law.pro jur.pro bar.pro med.pro cpa.pro aca.pro eng.pro/; # in afilias main complex
 my @afilias = qw/info mobi xn--6frz82g bet black blue green kim lgbt lotto meet organic pet pink poker red shiksha vote voto/; # info / main complex
 my @afilias_clients = qw/xxx xn--4gbrim xn--kput3i adult bnpparibas creditunion ged global indians irish ist istanbul ltda onl porn rich sex srl storage vegas/; # xxx / clients complex
 return (@pro, @afilias, @afilias_clients);
}
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{}) if $type eq 'epp';
 return;
}

####################################################################################################

1;
