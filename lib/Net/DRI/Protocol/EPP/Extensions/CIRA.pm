## Domain Registry Interface, CIRA (.CA) EPP extensions
##
## Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CIRA;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Util;
use Net::DRI::Data::Contact::CIRA;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 my $version=$self->version();
 $self->ns({cira=>['urn:ietf:params:xml:ns:cira-1.0','cira-1.0.xsd'],
            poll=>['urn:ietf:params:xml:ns:poll-1.0','poll-1.0.xsd']});

 $self->factories('contact',sub { return Net::DRI::Data::Contact::CIRA->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## authInfo not used by CIRA
 return;
}

sub core_contact_types { return ('admin','tech'); } ## No billing contact in .CA
sub default_extensions { return qw/CIRA::Domain CIRA::Contact CIRA::Agreement CIRA::Notifications/; }

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA - CIRA (.CA) EPP extensions for Net::DRI

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

Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
