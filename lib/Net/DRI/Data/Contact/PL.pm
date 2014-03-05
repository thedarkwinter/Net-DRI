## Domain Registry Interface, Handling of contact data for .PL
##
## Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::PL;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(individual consent_for_publishing));

=pod

=head1 NAME

Net::DRI::Data::Contact::PL - Handle .PL contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.PL specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 individual()

1 if the object represents a private person, 0 otherwise

=head2 consent_for_publishing()

1 if this person gave its assent for publishing personal details in WHOIS database, 0 otherwise.
This element has no meaning for a contact which does not represent a private person.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 push @errs,'individual'             if (defined($self->individual()) && $self->individual()!~m/^(?:0|1)$/);
 push @errs,'consent_for_publishing' if (defined($self->consent_for_publishing()) && $self->consent_for_publishing()!~m/^(?:0|1)$/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;
