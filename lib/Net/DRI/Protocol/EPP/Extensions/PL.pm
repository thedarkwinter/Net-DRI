## Domain Registry Interface, NASK (.PL) EPP extensions (draft-zygmuntowicz-epp-pltld-03)
##
## Copyright (c) 2006,2008,2009,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::PL;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL - .PL EPP extensions (draft-zygmuntowicz-epp-pltld-03) for Net::DRI

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
 $self->ns({ pl_domain  => ['http://www.dns.pl/NASK-EPP/extdom-1.0','extdom-1.0.xsd'],
             pl_contact => ['http://www.dns.pl/NASK-EPP/extcon-1.0','extcon-1.0.xsd'],
            # future     => ['http://www.dns.pl/NASK-EPP/future-1.0','future-1.0.xsd'], ## TODO
          });
 $self->capabilities('host_update','name',undef); ## No change of hostnames
 $self->factories('contact',sub { return Net::DRI::Data::Contact::PL->new(); });
 return;
}

sub default_extensions { return qw/PL::Domain PL::Contact PL::Message PL::Report/; } ## TODO: PL::Future

####################################################################################################
1;
