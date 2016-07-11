## Domain Registry Interface, Handling of contact data for .NZ
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::NZ;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
__PACKAGE__->register_attributes(qw(org street));

=pod

=head1 NAME

Net::DRI::Data::Contact::NZ - Handle .NZ contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.NZ specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>;
Michael Holloway E<lt>michael@thedarkwinter.comE<gt>;
Patrick Mevzek E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2016: Paulo Jorge <paullojorgge@gmail.com>; 
Michael Holloway <michael@thedarkwinter.com>;
Patrick Mevzek <netdri@dotandco.com>.
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

 push @errs, 'org not supported for .nz' if $self->org();
 push @errs, 'only 2 street elements allowed for .nz' if @{$self->street()} > 2;
 Net::DRI::Exception::usererr_invalid_parameters('contact => '.join(' / ',@errs)) if @errs;

 return 1; ## everything ok
}

####################################################################################################
1;
