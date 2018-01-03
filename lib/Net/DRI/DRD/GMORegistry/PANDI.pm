## Domain Registry Interface, PANDI Registry (.ID) Driver
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Stamatis Michas <don.matis@gmail.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::GMORegistry::PANDI;

use strict;
use warnings;

use base qw/Net::DRI::DRD::GMORegistry::GMORegistry/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::GMORegistry::GMORegistry - PANDI Registry (.ID) Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extensions for PANDI Registry (.ID) - Indonesian ccTLD

This DRD extends the L<Net::DRI::DRD::GMORegistry::GMORegistry>

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Stamatis Michas, E<lt>don.matis@gmail.comE<gt>
Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2017 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2017 Stamatis Michas <don.matis@gmail.com>.
          (c) 2017 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub name     { return 'GMORegistry::PANDI'; }
sub tlds     {
  my @ccTLDs = ('id',(map { $_.'.id'} qw/ac biz co desa go mil my net or sch web/));
  return (@ccTLDs);
}

1;
