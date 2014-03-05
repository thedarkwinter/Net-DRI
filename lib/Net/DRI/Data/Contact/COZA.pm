## Domain Registry Interface, Handling of contact data for .CO.ZA
##
## Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::COZA;

use strict;
use warnings;

use base qw(Net::DRI::Data::Contact);

use Net::DRI::Exception;
use Net::DRI::Util;

####################################################################################################

sub validate ## See http://registry.coza.net.za/doku.php?id=eppcontactconstraints
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 my @rs=($self->street());
 foreach my $i (0,1)
 {
  next unless defined $rs[$i];
  push @errs,'street' if ((ref($rs[$i]) ne 'ARRAY') || (@{$rs[$i]} > 3) || (grep { !Net::DRI::Util::xml_is_normalizedstring($_,8,255) } @{$rs[$i]}));
 }

 push @errs,'city'  if ($self->city()  && grep { !Net::DRI::Util::xml_is_normalizedstring($_,2,255) } ($self->city()));
 push @errs,'sp'    if ($self->sp()    && grep { !Net::DRI::Util::xml_is_normalizedstring($_,2,255) } ($self->sp()));

 my $ra=$self->auth();
 push @errs,'auth' if ($ra && (ref($ra) eq 'HASH') && exists($ra->{pw}) && !Net::DRI::Util::xml_is_normalizedstring($ra->{pw}));

 ## disclose not supported at all
 push @errs,'disclose' if defined $self->disclose();

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Data::Contact::COZA - Handle CO.ZA contact data for Net::DRI

=head1 SYNOPSIS

This module is never used directly, it is used by Net::DRI::Protocol::EPP::Extensions::COZA

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds validation based on .CO.ZA constraints.

=head1 EXAMPLES

See L<Net::DRI> documentation.

=head1 METHODS

This class does not define extra accessors/mutators.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This module has to be used inside the Net::DRI framework

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
