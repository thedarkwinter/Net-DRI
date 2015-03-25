## Domain Registry Interface, Handling of contact data for .LV [http://www.nic.lv/eppdoc/html/index.html]
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

package Net::DRI::Data::Contact::LV;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(vat orgno));

=pod

=head1 NAME

Net::DRI::Data::Contact::LV - Handle LV contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
LV specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 orgno() 

Latvian Organisation / Company Registration Number (if contact->org() is specified), or

Latvian Person Code (if no org() is supplied). Expected format: 'DDMMYY-NNNNN'

=head2 vat()

VAT number for organisation (EU only, including Latvia)

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

  # we validate these fields for Latvian contacts only. orgno is ignored outside LV
  if ($self->cc() eq 'LV') {
	  if ( defined $self->org() && defined $self->vat() && $self->orgno() ) {
    # Validation only applicable for organisations when both fields are present.
	  # For Latvian legal persons, vatNr should match regNr field, with 'LV' prepended.
	
		  push @errs,'vat must begin with "LV" for latvian entities' if ($self->vat() && $self->vat()!~m/^(LV)(.+)/); # Field must start with LV. No character limit.
		  push @errs,'orgno must be numerical characters only when vat is present for Latvian entities' if ($self->orgno() && $self->orgno()!~m/^(\d+)/); # Only numerical characters allowed. No character limit.
		
		  my $vat=$self->vat();
		  $vat =~ s/^(LV)(.+)/$2/g;
		  my $reg=$self->orgno();
		
		  push @errs,'vat should match orngo field, with "LV" prepended for Latvian entities' if ( $vat ne $reg ); # vatNr should match regNr field, with "LV" prepended
	  }
	
    # Latvian person code (orgno) format. Expected: 'DDMMYY-NNNNN'
	  if ( !defined $self->org() && defined $self->orgno() ) {
      push @errs,'orngo must be in this format "DDMMYY-NNNNN" for Latvian entities' if ($self->orgno() && $self->orgno()!~m/^(\d{6})(-)(\d{5})/);
	  }
	
	  # Cat field should be empty for private person. 
	  if ( !defined $self->org() && defined $self->vat() ) {
		  push @errs,'vat should be empty for a private Latvian individual' if ($self->vat() && $self->vat()=~m/^(?!\s*$).+/);
	  }
	}
	 
	Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join(' / ',@errs)) if @errs;
	 
	return 1; ## everything is good!
}

sub init {
	my ($self,$what,$ndr)=@_;
	
	if ($what eq 'create') {
		my $a=$self->auth();
		$self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); #authInfo is not used and ignored if used!
	}
	
	return;
}

####################################################################################################
1;
