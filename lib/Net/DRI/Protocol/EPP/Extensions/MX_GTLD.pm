## Domain Registry Interface, .MX_GTLD policies from 'LAT Implementation Guide EPP.PDF'
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

package Net::DRI::Protocol::EPP::Extensions::MX_GTLD;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MX_GTLD

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008,2009,2012 Patrick Mevzek <netdri@dotandco.com>.
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
      rar         => ['http://www.nic.mx/rar-1.0','rar-1.0.xsd'],
      ext_msg     => ['http://www.nic.mx/niclat-msg-1.0','niclat-msg-1.0.xsd'],           # service messages
      ext_res     => ['http://www.nic.mx/nicmx-res-1.0','nicmx-res-1.0.xsd'],             # result codes
      ext_rar     => ['http://www.nic.mx/nicmx-rar-1.0','nicmx-rar-1.0.xsd'],             # rar
      ext_adm     => ['http://www.nic.mx/nicmx-admstatus-1.1','nicmx-admstatus-1.1.xsd'], # administrative status
      ext_idn     => ['http://www.nic.lat/nicmx-idn-1.0','nicmx-idn-1.0.xsd'],            # IDNs
    });

  return;
}

sub default_extensions { return qw/GracePeriod LaunchPhase MX::AdmStatus MX::Message MX::Rar MX::Domain MX::IDN SecDNS/; }

####################################################################################################
1;
