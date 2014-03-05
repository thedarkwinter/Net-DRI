## Domain Registry Interface, .IT EPP extensions
##
## Copyright (c) 2009-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::IT;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::IT;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IT - .IT EPP extensions for Net::DRI

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

Copyright (c) 2009-2010 Patrick Mevzek <netdri@dotandco.com>.
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
               'it_epp'        => [ 'http://www.nic.it/ITNIC-EPP/extepp-1.0', 'extepp-1.0.xsd' ],
               'it_contact'    => [ 'http://www.nic.it/ITNIC-EPP/extcon-1.0', 'extcon-1.0.xsd' ],
               'it_domain'     => [ 'http://www.nic.it/ITNIC-EPP/extdom-1.0', 'extdom-1.0.xsd' ],
       });

 $self->factories('contact', sub { return Net::DRI::Data::Contact::IT->new(); });
 return;
}

sub default_extensions { return qw/GracePeriod IT::Contact IT::Domain IT::Notifications/; }

####################################################################################################
1;
