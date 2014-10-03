## Domain Registry Interface, Handling of contact data for CNNIC 
##
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

package Net::DRI::Data::Contact::CNNIC;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Util;
__PACKAGE__->register_attributes(qw(type code));

=pod

=head1 NAME

Net::DRI::Data::Contact::CNNIC - Handle CNNIC contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for CNNIC specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 type()

One of YYZZ,ZZJGDMZ,SFZ,JGZ,HZ,QT

=head2 code()

String between 1 and 20 characters

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->SUPER::validate($change); ## will trigger an Exception if problem
 if ($self->type() || $self->code()) {
  Net::DRI::Exception::usererr_invalid_parameters('contact type should be one of YYZZ,ZZJGDMZ,SFZ,JGZ,HZ,QT') unless $self->type() =~ m/^(?:YYZZ|ZZJGDMZ|SFZ|JGZ|HZ|QT)$/;
  Net::DRI::Exception::usererr_invalid_parameters('contact code should be a string between 1 and 20 characters') unless Net::DRI::Util::xml_is_token($self->code(),1,20);
 }
 return 1;
}

####################################################################################################

1;
