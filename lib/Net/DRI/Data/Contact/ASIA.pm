## Domain Registry Interface, Handling of contact data for .ASIA
##
## Copyright (c) 2007,2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Data::Contact::ASIA;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

__PACKAGE__->register_attributes(qw(cedcc cedsp cedcity cedetype cediform cedinum cedothertype cedoiform));

=pod

=head1 NAME

Net::DRI::Data::Contact::ASIA - Handle .ASIA contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.AERO specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 cedcc()

Stores the CED Country Code.

=head2 cedsp()

Stores the CED State/Province.

=head2 cedcity()

Stores the CED City.

=head2 cedetype()

Stores the CED Legal Entity Type.

=head2 cediform()

Stores the CED Identification Form.

=head2 cedinum()

Stores the CED Identification Number.

=head2 cedothertype()

Stores the CED other legal entity type.

=head2 cedoiform()

Stores the CED other identification form.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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


