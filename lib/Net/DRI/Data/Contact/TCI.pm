## Domain Registry Interface, Handling of contact data for .RU/.SU/.XN--P1AI
##
## Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
##               2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::TCI;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(organization person verified unverified));

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;

 my @errs;
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Data::Contact::TCI - Handle TCI contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
TCI specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 organization()

=head2 person()

=head2 verified()

=head2 unverified()

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Dmitry Belyavsky, E<lt>beldmit@gmail.comE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
