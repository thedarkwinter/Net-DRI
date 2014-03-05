## Domain Registry Interface, .RU/.SU/.XN--P1AI EPP Message Extension for Net::DRI
##
## Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
##               2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TCI::Message;

use strict;
use warnings;

use base qw(Net::DRI::Protocol::EPP::Message);

sub parse_greeting
{
 my ($self,$g)=@_;

 my $tmp = $self->SUPER::parse_greeting($g);
 delete $tmp->{svcext};

 my @svcs = map {(split(/\s+/, $_))[0]} @{$tmp->{svcs}};
 $tmp->{svcs} = \@svcs;

 return $tmp;
}

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TCI::Message - TCI EPP Message Extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Dmitry Belyavsky, E<lt>beldmit@gmail.comE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
