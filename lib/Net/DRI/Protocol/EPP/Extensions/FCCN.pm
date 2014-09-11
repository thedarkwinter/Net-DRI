## Domain Registry Interface, FCCN (.PT) EPP extensions
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FCCN;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FCCN - FCCN (.PT) EPP extensions for Net::DRI

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

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($self,$rp,$params)=@_;
 my $namespace_base = (defined($params) && ref($params) eq "HASH" && defined($params->{"namespace_base"})) ? $params->{"namespace_base"} : "http://www.dns.pt/xml/epp";

 $self->ns({ ptdomain  => ["$namespace_base/ptdomain-1.0",'ptdomain-1.0.xsd'],
             ptcontact => ["$namespace_base/ptcontact-1.0",'ptcontact-1.0.xsd'],
           });
 $self->capabilities('contact_update','status',undef);
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## domain:authInfo is not used by FCCN
 return;
}

sub default_extensions { return qw/FCCN::Contact FCCN::Domain/; }

####################################################################################################
1;
