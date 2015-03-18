## Domain Registry Interface, ES Domain EPP extension commands
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ES::Host;

use strict;
use warnings;

use Net::DRI::Util;


=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ES::Host - .ES Host extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

  (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
  (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
  (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
  my ( $class, $version ) = @_;
  my %tmp = (
    create => [ \&create, undef ],
  );
  return { 'host' => \%tmp };
}

####################################################################################################

sub create
{
  my ($epp, $host) = @_;
  my $ipv4 = $host->{'list'}[0][1];
  my $ipv6 = $host->{'list'}[0][2];
  # This Registry require IP to create a domain. If the host to be created is outside the .ES zone, they ignore the IP provided
  Net::DRI::Exception::usererr_insufficient_parameters('RED.ES require and IP (v4 or v6) to create a host object') if ( (@{$ipv4} || @{$ipv6}) == 0 );
  return;
}

####################################################################################################
1;
