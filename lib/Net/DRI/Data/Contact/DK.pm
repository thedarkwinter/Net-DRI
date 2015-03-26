## Domain Registry Interface, Handling of contact data for .DK
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::DK;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(vat userType));

=pod

=head1 NAME

Net::DRI::Data::Contact::DK - Handle DK contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
DK specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 #############################

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>d.makuni@live.co.uk<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
	
	Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;
	 
	return 1; # everything is as it should be!
}

sub init {
	my ($self,$what,$ndr)=@_;
	
    if ( $what eq 'create' ) {
    	my $a=$self->auth();
		$self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); #authInfo is not used!
        $self->srid('auto') unless defined( $self->srid() );    ## we can not choose the ID
    }
	
	return;
}

####################################################################################################
1;
