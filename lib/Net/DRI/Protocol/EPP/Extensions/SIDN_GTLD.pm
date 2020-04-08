## Domain Registry Interface, .SIDN_GTLD policies from 'DRS_amsterdam_Manual_EPP_EN_v1.0.PDF'
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SIDN_GTLD;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Util;
use Net::DRI::Data::Contact::SIDN;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SIDN_GTLD

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2015 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup
{
  my ($self,$rp)=@_;
  $self->ns({
      sidn  => 'http://rxsd.domain-registry.nl/sidn-ext-epp-1.0',   # sidn-ext-epp
    });

  return;
}

sub default_extensions { return qw/GracePeriod LaunchPhase SIDN::Contact SIDN::Domain SIDN::Host SIDN::Message SIDN::Notifications SecDNS/; }

####################################################################################################
1;