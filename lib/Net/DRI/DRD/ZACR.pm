## Domain Registry Interface, ZACR (*.ZA and gTLD) policies for Net::DRI
##
## Copyright (c) 2011,2012,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013,2016,2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::ZACR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Data::Contact::ZACR;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse host_update host_current_status host_check host_exist host_delete host_create host_inf/);

=pod

=head1 NAME

Net::DRI::DRD::ZACR - ZACR (*.ZA and gTLD) policies for Net::DRI

=head1 DESCRIPTION

Additional domain extension ZACR TLDs.

ZACR utilises the following standard, and custom extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::ZACR::Domain> http://co.za/epp/extensions/cozadomain-1-0

=head3 L<Net::DRI::Protocol::EPP::Extensions::ZACR::Contact> http://co.za/epp/extensions/cozacontact-1-0

=head3 L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011,2012,2016 Patrick Mevzek <netdri@dotandco.com>.
Copyright (c) 2013,2016,2017 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'ZACR'; }
sub tlds     { return qw/co.za net.za org.za web.za joburg durban capetown africa wien/; }
sub object_types { return (qw/domain contact/); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ZACR',{}) if $type eq 'epp';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::ZACR->new(@_); });
 return;
}
######################################################################################

sub registrar_balance
{
 my ($self,$ndr,$rd)=@_;
 if (!defined $rd) {
   $rd = ( defined($self->info('client_id'))?$self->info('client_id') :$self->info('clid') );
 }
 my $rc=$ndr->process('contact','info',[$ndr->local_object('contact')->srid($rd),{balance=>1}]);
 return $rc;
}

######################################################################################

1;
