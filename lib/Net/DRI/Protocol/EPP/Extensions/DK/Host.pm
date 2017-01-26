## Host Registry Interface, .DK Host EPP extension commands
##
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DK::Host;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Format::ISO8601;
use Net::DRI::Protocol::EPP::Util;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK::Host - .DK EPP Host extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
	my ( $class, $version)=@_;

	my %tmp=(
	  'create' => [ \&create, undef],
		'update' => [ \&update, undef],
	);

	return { 'host' => \%tmp };
}

####################################################################################################
## HELPERS
sub _build_dkhm_host
{
	my ($epp,$host,$rd)=@_;
	my $mes=$epp->message();
	my $ns = $mes->ns('dkhm');
	return unless Net::DRI::Util::has_key($rd,'requested_ns_admin');

	my $eid=$mes->command_extension_register('dkhm:requestedNsAdmin','xmlns:dkhm="'.$ns.'"');
	$mes->command_extension($eid,$rd->{requested_ns_admin});

	return;
}

####################################################################################################

sub create {
  return _build_dkhm_host(@_);
}

sub update {
	my ($epp,$host,$todo)=@_;
	my $requested_ns_admin = $todo->set('requested_ns_admin');
	return unless $requested_ns_admin;
  return _build_dkhm_host($epp,$host, {'requested_ns_admin' => $requested_ns_admin});
}

1;
