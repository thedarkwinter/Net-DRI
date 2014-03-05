## Domain Registry Interface, Null Logging operations for Net::DRI
##
## Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Logging::Null;

use strict;
use warnings;

use base qw/Net::DRI::Logging/;

####################################################################################################

sub name { return 'null'; }
sub setup_channel { return; }
sub output { return; }

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Logging::Null - Null Logging Operations for Net::DRI

=head1 SYNOPSIS

See L<Net::DRI::Logging>

=head1 DESCRIPTION

This is the default logging class used by L<Net::DRI> if nothing else is specified,

It discards everything (no logging at all).

=head1 EXAMPLES

	$dri->new({..., logging => 'null' ,...});

If not provided during C<new()>, this is the default behaviour.

=head1 SUBROUTINES/METHODS

All mandated by superclass L<Net::DRI::Logging>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This module has to be used inside the Net::DRI framework and needs the following components:

=over

=item L<Net::DRI::Logging>

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
