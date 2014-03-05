## Domain Registry Interface, .MOBI EPP extensions
##
## Copyright (c) 2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MOBI;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MOBI - .MOBI EPP extensions for Net::DRI

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

Copyright (c) 2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->ns({mobi      => ['urn:afilias:params:xml:ns:ext:mobi-1.0','mobi-1.0.xsd'],
            trademark => ['urn:afilias:params:xml:ns:ext:mobi-trademark-1.0','mobi-trademark-1.0.xsd'],
            oxrs      => ['urn:afilias:params:xml:ns:oxrs-1.1','oxrs-1.1.xsd'],
           });
 $self->capabilities('domain_update','maintainer_url',['set']);
 return;
}

sub default_extensions { return qw/MOBI::Domain Afilias::Trademark/; }

####################################################################################################
1;
