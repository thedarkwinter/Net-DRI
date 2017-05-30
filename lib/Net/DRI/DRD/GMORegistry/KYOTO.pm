## Domain Registry Interface, GMO Registry (.KYOTO) Driver
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014,2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::GMORegistry::KYOTO;

use strict;
use warnings;

use base qw/Net::DRI::DRD::GMORegistry::GMORegistry/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::GMORegistry::GMORegistry - GMO Registry (.KYOTO) Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extensions for GMO Registry (.KYOTO) New Generic TLDs

KYOTO (Academic Institution: Kyoto Jyoho Gakuen) is operated by GMO Registry

This DRD extends the L<Net::DRI::DRD::GMORegistry::GMORegistry>

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2014,2017 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub name     { return 'GMORegistry::KYOTO'; }
sub tlds { return qw/kyoto/; }

1;
