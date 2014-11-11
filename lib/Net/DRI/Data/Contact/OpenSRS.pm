## Domain Registry Interface, Handling of contact data for OpenSRS
##
## Copyright (c) 2009,2013 Richard Siddall <netdri@elirion.net>. All rights reserved.
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

package Net::DRI::Data::Contact::OpenSRS;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(firstname url));

=pod

=head1 NAME

Net::DRI::Data::Contact::OpenSRS - Handle OpenSRS contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
OpenSRS specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 firstname()

Please note that for OpenSRS data, the name() must be only the lastname, hence this extra firstname() method

=head2 lastname()

Alias for name()

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Richard Siddall, E<lt>netdri@elirion.net<gt>

=head1 COPYRIGHT

Copyright (c) 2009,2013 Richard Siddall <netdri@elirion.net>.
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

 push @errs,'firstname' if ($self->firstname() && grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) } ($self->firstname()));

 push @errs,'voice' if ($self->voice() && !Net::DRI::Util::xml_is_token($self->voice(),undef,17) && $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,12}(?:x\d{1,4})?$/);
 push @errs,'fax'   if ($self->fax()   && !Net::DRI::Util::xml_is_token($self->fax(),undef,17)   && $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,12}(?:x\d{1,4})?$/);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub lastname {
 my ($self, $change) = @_;
 return $self->name($change);
}

####################################################################################################
1;
