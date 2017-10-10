## Domain Registry Interface, NEWGTLD EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::NEWGTLD;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;


sub setup
{
 my ($self,$rp)=@_;
 $self->default_parameters()->{subproductid}=$rp->{default_product} || '_auto_'; ## VERISIGN - THIS SHOULD BE CLEANUP UP A BIT THO ?
 $self->default_parameters()->{whois_info}=0; ## VERISIGN - THIS SHOULD BE CLEANUP UP A BIT THO ?
 return;
}

sub default_extensions {
 my ($self,$pp) = @_;
 my @ext = qw/GracePeriod SecDNS LaunchPhase/;
 push @ext, 'IDN' unless (exists $pp->{disable_idn} && $pp->{disable_idn});
 $self->{brown_fee_version} = $pp->{brown_fee_version} if exists $pp->{brown_fee_version};
 $self->{fee_version} = $pp->{fee_version} if exists $pp->{fee_version};
 if (exists $pp->{custom} )
 {
  my @custom = (ref $pp->{custom} eq 'ARRAY') ? @{$pp->{custom}} : ($pp->{custom});
  foreach (@custom) { push @ext,$_; }
 }
 return @ext;
}

####################################################################################################

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NEWGTLD; NEWGTLD Standard Extensins for Net::DRI

=head1 DESCRIPTION

Additional domain extension for new Generic TLDs. This extension is intended to cover any registry that uses the Standard Extensions [below] only. Note, this unit may become useless, I can't tell the future.

=head2 Supported Registries

=head3
L<AFNIC|Net::DRI::DRD::AFNIC_GTLD>
L<Minds And Machines|Net::DRI::DRD::MAM>
L<Charleston Road Registry|Net::DRI::DRD::CRC>
L<GMO Registry|Net::DRI::DRD::GMO>
L<Charleston Road Registry|Net::DRI::DRD::CRR> (without idn)

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

1;
