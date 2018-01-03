## Domain Registry Interface, Handling of contact data for SKNIC
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::SKNIC;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(legal_form ident_value)); # they only have example for CORP on their technical documentation (nothing for PERS). So using ident_value instead of corp_ident

=pod

=head1 NAME

Net::DRI::Data::Contact::SKNIC - Handle Centralnic::SkContactIdent contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for SKNIC specific data.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

(c) 2017 Patrick Mevzek <netdri@dotandco.com>,

(c) 2017 Michael Holloway <michael@thedarkwinter.com>,

(c) 2017 Paulo Jorge <paullojorgge@gmail.com>.

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

 push @errs, 'legal_form is mandatory' unless $self->legal_form();
 Net::DRI::Exception::usererr_invalid_parameters('contact => '.join(' / ',@errs)) if @errs;

 return 1;
}

####################################################################################################
1;
