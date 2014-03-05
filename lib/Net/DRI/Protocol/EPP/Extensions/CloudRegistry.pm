## Domain Registry Interface, Cloud Registry EPP extensions
##
## Copyright (c) 2009-2011 Cloud Registry Pty Ltd <http://www.cloudregistry.net>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CloudRegistry;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CloudRegistry - Cloud Registry EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>wil@cloudregistry.netE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.cloudregistry.net/E<gt> and
E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Wil Tan E<lt>wil@cloudregistry.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2009-2011 Cloud Registry Pty Ltd <http://www.cloudregistry.net>.
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
 $self->ns({ lp => ['http://www.cloudregistry.net/ns/launchphase-1.0','launchphase-1.0.xsd'],
           });
 return;
}

sub default_extensions { return qw/CloudRegistry::LaunchPhase GracePeriod/; }

####################################################################################################
1;
