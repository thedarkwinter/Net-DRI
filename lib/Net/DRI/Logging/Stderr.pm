## Domain Registry Interface, STDERR Logging operations for Net::DRI
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

package Net::DRI::Logging::Stderr;

use strict;
use warnings;

use base qw/Net::DRI::Logging/;

use IO::Handle;

*STDERR->autoflush();

####################################################################################################

sub name { return 'stderr'; }
sub setup_channel { my ($self,$source,$type,$data)=@_; return; } ## nothing to do really

sub output
{
 my ($self,$level,$type,$data)=@_;
 if ($self->should_log($level)) { *STDERR->print($self->tostring($level,$type,$data),"\n"); }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Logging::Stderr - STDERR Logging Operations for Net::DRI

=head1 SYNOPSIS

See L<Net::DRI::Logging>

=head1 DESCRIPTION

This class dumps all logging information to STDERR.

=head1 EXAMPLES

	$dri->new({..., logging => 'stderr' ,...});

=head1 SUBROUTINES/METHODS

All mandated by superclass L<Net::DRI::Logging>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This modules has to be used inside the Net::DRI framework and needs the following composants:

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
