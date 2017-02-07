## Domain Registry Interface, .DK Domain EPP extension commands
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DK::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Format::ISO8601;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Data::Hosts;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK::Domain - .DK EPP Domain extension commands for Net::DRI

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
	  'check'  => [ undef, \&check_parse ],
	  'info'   => [ undef, \&_parse_dkhm_domain ],
	  'create' => [ \&create, \&_parse_dkhm_domain ],
	  'renew'  => [ undef, \&_parse_dkhm_domain ],
	  'update' =>	[ undef, \&_parse_dkhm_domain ]
	);

	return { 'domain' => \%tmp };
}

####################################################################################################
## HELPERS
sub _build_dkhm_domain
{
	my ($epp,$domain,$rd)=@_;
	my $mes=$epp->message();
	my $ns = $mes->ns('dkhm');

	return unless Net::DRI::Util::has_key($rd,'confirmation_token');

	my $eid=$mes->command_extension_register('dkhm:orderconfirmationToken','xmlns:dkhm="'.$ns.'"');
	$mes->command_extension($eid,$rd->{confirmation_token});

	return;
}

sub _parse_dkhm_domain
{
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;

	my $mes=$po->message();
	return unless $mes->is_success();
	my $data;

	if ($data = $mes->get_extension('dkhm','trackingNo')) {
		$rinfo->{domain}->{$oname}->{tracking_no} = $data->getFirstChild()->textContent();
	}
	if ($data = $mes->get_extension('dkhm','domain_confirmed')) {
		$rinfo->{domain}->{$oname}->{domain_confirmed} = $data->getFirstChild()->textContent();
	}
	if ($data = $mes->get_extension('dkhm','registrant_validated')) {
		$rinfo->{domain}->{$oname}->{registrant_validated} = $data->getFirstChild()->textContent();
	}

	return;
}

####################################################################################################

sub create {
  return _build_dkhm_domain(@_);
}

sub check_parse {
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	my $adata = $mes->get_extension('dkhm','domainAdvisory');
  return unless $adata;

  if ($adata->hasAttribute('domain') && $adata->getAttribute('advisory'))
  {
   $rinfo->{domain}->{$adata->getAttribute('domain')}->{advisory} = $adata->getAttribute('advisory');
	}

  return;
}

1;
