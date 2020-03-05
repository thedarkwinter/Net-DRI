## Domain Registry Interface, .DK Contact EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::DK::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use DateTime::Format::ISO8601;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK::Contact - .DK EPP Contact extension commands for Net::DRI

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
  my ( $class, $version ) = @_;
  my %tmp = (
    create => [ \&create, undef ],
    update => [ \&update, undef ],
    info => [ undef, \&_parse_dkhm_contact ],
  );

  return { 'contact' => \%tmp };
}

####################################################################################################
## HELPERS
sub _build_dkhm_contact {
  my ( $epp, $c ) = @_;
  my @dkhm;

  if (defined $c->type()) {
		push @dkhm,['dkhm:userType',$c->type()];
	}

  if (defined $c->ean()) {
		push @dkhm,['dkhm:EAN',$c->ean()];
	}

	if (defined $c->vat()) {
		push @dkhm,['dkhm:CVR',$c->vat()];
	}

  if (defined $c->pnumber()) {
		push @dkhm,['dkhm:pnumber',$c->pnumber()];
	}

  if (defined $c->alt_email()) {
		push @dkhm,['dkhm:secondaryEmail',$c->alt_email()];
	}

  if (defined $c->mobile()) {
		push @dkhm,['dkhm:mobilephone',$c->mobile()];
	}
  $epp->message()->command_extension('dkhm', @dkhm);

  return;
}

sub _parse_dkhm_contact {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();

  my $c=$rinfo->{contact}->{$oname}->{self};
  my $data;

	if ($data = $mes->get_extension('dkhm','contact_validated')) {
  	$c->contact_validated($data->getFirstChild()->textContent());
	}
	if ($data = $mes->get_extension('dkhm','mobilephone')) {
  	$c->mobile($data->getFirstChild()->textContent());
	}
  if ($data = $mes->get_extension('dkhm','secondaryEmail')) {
  	$c->alt_email($data->getFirstChild()->textContent());
	}
  if ($data = $mes->get_extension('dkhm','CVR')) {
  	$c->var($data->getFirstChild()->textContent());
	}
  if ($data = $mes->get_extension('EAN','secondaryEmail')) {
  	$c->ean($data->getFirstChild()->textContent());
	}
  if ($data = $mes->get_extension('dkhm','userType')) {
  	$c->type($data->getFirstChild()->textContent());
	}

  return;
}

####################################################################################################

sub create {
  my ( $epp, $c ) = @_;
  return _build_dkhm_contact(@_);
}

sub update
{
  my ($epp,$contact,$todo)=@_;
  my $mes=$epp->message();
  my $newc=$todo->set('info');
  return defined $newc ? _build_dkhm_contact($epp, $newc) : undef;
}

####################################################################################################
1;
