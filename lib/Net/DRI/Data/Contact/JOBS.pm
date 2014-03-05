## Domain Registry Interface, Handling of contact data for .JOBS
##
## Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::Data::Contact::JOBS;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

__PACKAGE__->register_attributes(qw(jobinfo));

=pod

=head1 NAME

Net::DRI::Data::Contact::JOBS - Handle .JOBS contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.JOBS specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 jobinfo()

Stores the additional .JOBS information. This is a hash possibly containing:

=over 4

=item title - The title of the person.

=item website - The web site of the company this contact belongs to.

=item industry - The type of industry the contact works in; see the
	.JOBS registrar documentation for possible values.

=item admin - Boolean flag to indicate whether or not the contact is
	administrative.

=item member - Boolean flag to indicate whether or not the contact is
	an association member.

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/ or
http://oss.bsdprojects.net/projects/netdri/

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################


####################################################################################################
1;
