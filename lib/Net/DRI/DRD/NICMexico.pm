## Domain Registry Interface, NICMexico (MX) policies from 'EPP Manual 2.0 MX.PDF'
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

package Net::DRI::DRD::NICMexico;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Duration;

# TODO: confirm those operations!!!
__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_delete contact_transfer contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::NICMexico - .MX policies from 'EPP Manual 2.0 MX.PDF'

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008-2012 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=1;	## LOC only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); } # the documentation doesn't mention the interval...
sub name     { return 'NICMexico'; }
sub tlds     { return ('mx',map { $_.'.mx'} qw/com gob net org edu/ ); } # .gob.mx, .net.mx, .edu.mx requires authorization from the Registry
sub object_types { return qw(domain contact ns); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket', {},'Net::DRI::Protocol::EPP::Extensions::MX',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub domain_restore
{
  my ($self,$ndr,$domain)=@_;
  $self->enforce_domain_name_constraints($ndr,$domain,'restore');
  return $ndr->process('domain','restore',[$domain]);
}

####################################################################################################
1;
