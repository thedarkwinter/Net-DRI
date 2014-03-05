## Domain Registry Interface, IRIS DCHK Status
##
## Copyright (c) 2008,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::IRIS::DCHK::Status;

use base qw!Net::DRI::Data::StatusList!;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::DCHK::Status - IRIS DCHK Domain Status for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new('iris-dchk','1.0');
 my $msg=shift;
 return $self unless defined $msg;
 Net::DRI::Exception::err_invalid_parameters('new() expects a ref array') unless ref $msg eq 'ARRAY';
 $self->add(@$msg);
 return $self;
}

sub is_active    { my $s; return $s->has_any('active') && $s->has_not('inactive'); }
sub is_published { return shift->has_not('inactive'); }
sub is_pending   { return shift->has_any('dispute'); }

####################################################################################################
1;
