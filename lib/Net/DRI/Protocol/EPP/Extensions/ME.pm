## Domain Registry Interface, .ME EPP extensions
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ME;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({
             ipr  => ['urn:afilias:params:xml:ns:ipr-1.1','ipr-1.1.xsd'],
             oxrs => ['urn:afilias:params:xml:ns:oxrs-1.1','oxrs-1.1.xsd'],
           });
 ## What else ?
 return;
}

sub default_extensions { return qw/Afilias::IPR Afilias::Message/; } ## What else ?

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ME - .ME EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This extension is currently a placeholder to document at least that .ME needs
the Afilias::IPR extension. Other needs are unknown for now, please contribute
if you know what is needed for .ME

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
