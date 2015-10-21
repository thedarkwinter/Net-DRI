## Domain Registry Interface, Handling of contact data for CN 
##
## Copyright (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::CN;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);
__PACKAGE__->register_attributes(qw(type contact contact_type purveyor mobile));

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Data::Contact::CN - Handle CN contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for CN specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type()

One of I (domestic individual contact) or E (domestic enterprise contact)

=head2 cont_type()

One of SFZ, HZ, JGZ, ORG, YYZZ or QT

=head2 cont_code()

String between 1 and 50 characters

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
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

 push @errs, 'type should be: I (individual) or E (enterprise)' if ( $self->type() && $self->type() !~ m/^(?:I|E)$/ );
 push @errs, 'contact type should be one of these: SFZ, HZ, JGZ, ORG, YYZZ or QT' if ( $self->contact_type && $self->contact_type() !~ m/^(?:SFZ|HZ|JGZ|ORG|YYZZ|QT)$/ );
 push @errs, 'contact code should be a token between 1 and 50 characters' if ( $self->contact() && !Net::DRI::Util::xml_is_token($self->contact(),1,50) );
 push @errs, 'purveyor should be a token between 3 and 16 characters' if ( $self->purveyor() &&!Net::DRI::Util::xml_is_token($self->purveyor(),3,16) );
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;

 return 1; ## everything ok
}

####################################################################################################

1;
