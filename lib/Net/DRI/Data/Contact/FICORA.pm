## Domain Registry Interface, Handling of contact data for .FI
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::FICORA;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(role type firstname lastname birthdate identity registernumber legalemail isfinnish));

=pod

=head1 NAME

Net::DRI::Data::Contact::FICORA - Handle .FI contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.FI specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 role()

contact role: (2=>'admin', 3=>'reseller', 4=>'tecnicalContact', 5=>'Registrant/Holder')

=head2 type()

contact type: (0=>'Private person', 1=>'Company', 2=>'Assocation', 3=>'Institution', 4=>'Political party', 5=>'Municipality', 6=>'Government', 7=>'Public community')

=head2 firstname()

contact firstname

=head2 lastname()

contact lastname

=head2 legalemail()

contact legalemail


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
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

 if ( $change != 1 ) # not mandatory for contact_update()
 {
   # Contact role is mandatory with value between 2-5
   push @errs, 'contact role mandatory and can only be between: 2-5' unless ( defined($self->role()) && $self->role() >= 2 && $self->role() <= 5 );

   # Contact type is mandatory with value between 0-7
   push @errs, 'contact type mandatory and can only be between: 0-7' unless ( defined($self->type()) && $self->type() >= 0 && $self->type() <= 7 );

   # <contact:sp> is not mandatory, other address fields are mandatory
   push @errs, 'address fields: city, pc an cc are mandatory (except sp)' unless ( defined($self->city()) && defined($self->pc()) && defined($self->cc()) );


   # For contact role 5, <contact:legalemail> is mandatory, for others  <contact:email> is mandatory
   if (defined($self->role()) && $self->role() eq '5')
   {
    push @errs, 'legal email is mandatory (if role eq 5: Registrant/Holder)' unless ( defined($self->legalemail()) );
   } else {
    push @errs, 'email is mandatory' unless ( defined($self->email()) );
   }

   # For a Finnish person, (role=5, type=0, isfinnish=1) <contact:identity> is mandatory and is validated as a Finnish identity
   # For a Finnish company, (role=5, type=1-7, isfinnish=1) <contact:registernumber> is mandatory and is validated
   # For a foreign person, (role=5, type=0, isfinnish=0) <contact:birthDate> is mandatory and is validated
   # For a foreign company, (role=5, type=1-7, isfinnish=0) <contact:registernumber> is mandatory
   if ($self->role() eq '5' && $self->type() eq '0' && $self->isfinnish() eq '1')
   {
    push @errs, 'identity is mandatory and is validated by Registry for (role=5, type=0, isfinnish=1)' unless ( defined($self->identity()) );
   } elsif ($self->role() eq '5' && $self->type() >= 1 && $self->type() <= 7 && $self->isfinnish() eq '1')
   {
    push @errs, 'registernumber is mandatory and is validated by Registry for (role=5, type=1-7, isfinnish=1)' unless ( defined($self->registernumber()) );
   } elsif ($self->role() eq '5' && $self->type() eq '0' && $self->isfinnish eq '0') {
    push @errs, 'birthDate is mandatory and is validated by Registry for (role=5, type=0, isfinnish=0)' unless ( defined($self->birthdate()) );
   } elsif ($self->role() eq '5' && $self->type() >= 1 && $self->type() <= 7 && $self->isfinnish() eq '0') {
    push @errs, 'registernumber is mandatory and is validated by Registry for (role=5, type=1-7, isfinnish=0)' unless ( defined($self->registernumber()) );
   }
 }

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}


sub init
{
 my ($self,$what,$ndr)=@_;
 if ($what eq 'create' || $what eq 'update')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## authInfo is not used
  # fax is not saves - makes no sense. their tech doc contact create example has this field. lets keep next line commented for now
  # delete $self->{fax};
 }

 return;
}

####################################################################################################
1;
