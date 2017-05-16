## Domain Registry Interface, GL Registry Driver
##
## Copyright (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::GL;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;

=pod

=head1 NAME

Net::DRI::DRD::GL - GL Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

As .GL is not yet in production, modifications may be needed.

Only little testing has been done, but basic contact and domain functions are working.

However, .GL is currently implementing a vanilla CoCCA system.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..5); }
sub name         { return 'GL'; }
sub tlds         { return (qw/gl co.gl com.gl net.gl edu.gl org.gl/); }
sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host => 'registry.nic.gl'},'Net::DRI::Protocol::EPP::Extensions::GL',{}) if $type eq 'epp';
 return;
}

####################################################################################################

####################################################################################################
1;
