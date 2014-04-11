## Domain Registry Interface, Handling of contact data for UNIREG
##
## Copyright (c) 2006,2008-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::UNIREG;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(challenge alt_email mobile));

=pod

=head1 NAME

Net::DRI::Data::Contact::UNIREG - Handle UNIREG contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for UNIREG specific data. See the extension for more information: L<Net::DRI::Protocol::EPP::Extensions::UNIREG::Centric>

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 alt_email()

Optional alternative email address

=head2 mobile()

Optional mobile phone number

=head2 challenge()

An array of challenge qusetions an answers, minumum of 3, maximum of 5.
  my @ch = ( {question=>'my question',answer=>'my answer'}, {}, {})

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

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
 $self->SUPER::validate(1); ## will trigger an Exception if problem

 Net::DRI::Exception::usererr_insufficient_parameters('Mandatory contact information missing: challenge') unless defined $self->challenge(); 
 Net::DRI::Exception::usererr_invalid_parameters('challenge requires between 3 and 5 questions+answers') unless ($#{$self->challenge()} > 1 && $#{$self->challenge()}<5 );

 my @errs;
 push @errs,'alt_email' if ($self->alt_email() && ! (Net::DRI::Util::xml_is_token($self->alt_email(),1,undef)  && Email::Valid->rfc822($self->alt_email())));
 push @errs,'mobile' if ($self->mobile() && ! ($self->mobile()=~m/^\+[0-9]{1,3}\.[0-9]{1,14}$/));
 
 foreach my $c (@{$self->challenge()})
 {
  if (!exists $c->{'question'} || !exists $c->{'answer'} || grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) }  ($c->{'question'},$c->{'answer'}) )
  {
   push @errs,'challenge';
   last;
  }
 }
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1;
}

####################################################################################################
1;
