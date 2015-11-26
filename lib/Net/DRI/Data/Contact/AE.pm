## Domain Registry Interface, Handling of contact data for .AE
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
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

package Net::DRI::Data::Contact::AE;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Data::Contact::AE - Handle .AE contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.AE specific data.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR(S)

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>
David Makuni E<lt>d.makuni@live.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk> All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub validate {
        my ($self,$change)=@_;
        $change||=0;
        my @errs;

        $self->SUPER::validate($change); ## will trigger an Exception if problem

		# auth_pw is required for all contacts...
		if (!$change) {
        	push @errs,'auth_pw for .AE contact is required' unless ((defined $self->auth()));
		}

        Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;

        return 1; ## everything good.
}

####################################################################################################
1;
