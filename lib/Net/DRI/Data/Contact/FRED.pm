## Domain Registry Interface, Handling of contact data for .FRED [https://www.nic.cz/files/nic/doc/constraints.pdf]
##
## Copyright (c) 2008-2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2017 David Makuni <d.makuni@live.co.uk>. All rights reserved.
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

package Net::DRI::Data::Contact::FRED;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

use Data::Dumper;

__PACKAGE__->register_attributes(qw(vat identity notify_email));

=pod

=head1 NAME

Net::DRI::Data::Contact::FRED - Handle FRED contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
FRED specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 vat()

  The VAT number of a legal entity.

=head2 identity({type=>'', value=>''})

  The identity of a contact. 'type' can be the following values:

  op - other
	passport - passport number
	mpsv - personal tax identification number
	ico - company registration number
	birthday - date of birth

	The 'value' attribute depends on what type is defined to be valid.

=head2 notify_email()

  The alternate notification email where registry messages will be sent to also.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>d.makuni@live.co.uk<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2008-2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2017 David Makuni <d.makuni@live.co.uk>. All rights reserved.

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

	$self->SUPER::validate($change); ## This will trigger exception if a problem is found.

	# the voice 'x' attribute is not allowed
	if ((defined $self->voice()) && ($self->voice() =~ m/(.+)(x)(.*)/)) {
			push @errs,'The FRED system does not support voice extensions.' if (defined $self->voice());
	}

	# 'identity' element data validation
  if (defined $self->identity()) {
		# missing / undefined fields
		foreach (("type", "value")) { push @errs,"The '$_' attribute is required for the contact identity element"
			  if ((!(defined $self->identity()->{$_})) || ($self->identity()->{$_} eq '')); }
		# field content validation
		push @errs,'Wrong value for contact identity "type" element. Accepted: op,passport,mpsv,ico,birthday'
			if ($self->identity()->{type} !~ m/^(op|passport|mpsv|ico|birthday)$/);
	}

	Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;

	return 1; ## everything is good!
}

####################################################################################################
1;
