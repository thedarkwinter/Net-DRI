## Domain Registry Interface, Handling of contact data for Neustar::Narwal
##
## Copyright (c) 2006,2008-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Data::Contact::Narwal;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(ext_contact nexus_category));

=pod

=head1 NAME

Net::DRI::Data::Contact::Narwal - Handle Neustar::Narwal contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for ARI specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 nexus_category()

One of the contacts must be based in New York, and the nexus category must be one of INDIV or ORG

=head2 ext_contact()

Y/N defining whether or not this is the nexus contact. This will default to Y if not set and nexus_category is set.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 $self->SUPER::validate(1); ## will trigger an Exception if problem
 return 1 unless $self->nexus_category();
 Net::DRI::Exception::usererr_insufficient_parameters('Nexus Contact must be in New York (sp)') if defined $self->sp() && uc($self->sp()) !~ m/^(?:NY|NEW YORK)$/;
 Net::DRI::Exception::usererr_insufficient_parameters('Nexus Category must be INDIV or ORG') if defined $self->nexus_category() && uc($self->nexus_category()) !~ m/^(?:INDIV|ORG)$/;
 return 1;
}

####################################################################################################
1;
