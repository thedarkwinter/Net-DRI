## Domain Registry Interface, Handling of contact data for SIDN
##
## Copyright (c) 2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::SIDN;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Net::DRI::Exception;

__PACKAGE__->register_attributes(qw(legal_form legal_id limited));

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;

 $self->SUPER::validate(1); ## will trigger an Exception if problem

 if (!$change)
 {
  my @missing=grep { my $r=scalar $self->$_(); (defined $r && length $r)? 0 : 1 } qw/legal_form/;
  Net::DRI::Exception::usererr_insufficient_parameters('Mandatory contact information missing: '.join('/',@missing)) if @missing;
 }

 my @errs;
 push @errs,'legal_form' if (defined $self->legal_form() && $self->legal_form()!~m!^(?:ANDERS|BGG|BRO|BV|BVI/O|COOP|CV|EENMANSZAAK|EESV|KERK|MAATSCHAP|NV|OWM|PERSOON|REDR|STICHTING|VERENIGING|VOF)$!o);

 ## Changes from core EPP
 push @errs,'pc' if (defined $self->cc() && $self->cc() eq 'NL' && ! $self->pc());
 push @errs,'voice' if (!$change && ! $self->voice());

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;
 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## authInfo is not used
  $self->srid('ABCD') unless defined $self->srid(); ## we can not choose the ID
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Data::Contact::SIDN - Handle SIDN contact data for Net::DRI

=head1 SYNOPSIS

This module is not used directly, but objects will be created in this class
automatically when needed.

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
SIDN specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 legal_form()

legal form

=head2 legal_id()

legal form registration number

=head2 limited()

SIDN status limited, set by registry

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
