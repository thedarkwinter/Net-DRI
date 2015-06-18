## Domain Registry Interface, ES policies
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::ES;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/login contact_update contact_delete contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_transfer_accept domains_transfer_reject domains_transfer_cancel host_delete/);

=pod

=head1 NAME

Net::DRI::DRD::ES - .ES policies for Net::DRI

=head1 DESCRIPTION

Driver for .ES conections. 

When initialising, you need to send the credentials in the protocol paramaters.
$rc=$dri->add_current_profile('profile','epp'},{%tp},'client_login'=>'login','client_password'=>'pass'}

Additional contact fields (See Contact.pm for more information)
 tipo_identificacion
 identificacion
 form_juridica
 
Additional domain fields
ip_maestra
marca
inscripcion
accion_comercial
codaux
auto_renew

Addtional command tray_info, see Tray.pm for mor information

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT
Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new # FIXME - check these valies
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_ns}=1;
 $self->{info}->{contact_i18n}=1;	## LOC only
 $self->{info}->{force_native_idn}=1;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'ES'; }
sub tlds     { return ('es',map { $_.'.es'} qw/com nom org gob edu/ ); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP',has_state=>0},'Net::DRI::Protocol::EPP::Extensions::ES',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

sub tray_info
{
  my ($self, $reg, $rd) = @_;
  use Data::Dumper;
  return $reg->process('tray', 'info', [$rd]);
}

sub host_create
{
  my ($self, $ndr, $host) = @_;
  my $ipv4 = $host->{'list'}[0][1];
  my $ipv6 = $host->{'list'}[0][2];
  # This Registry requires an IP to create a host. If the host to be created is outside the .ES zone, they ignore the IP provided.
  Net::DRI::Exception::usererr_insufficient_parameters('RED.ES require an IP address (v4 or v6) to create a host object') if ( (@{$ipv4} || @{$ipv6}) == 0 );
  return $ndr->process('host', 'create', [$host]);
}

####################################################################################################

1;
