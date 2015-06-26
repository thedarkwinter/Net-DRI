## Domain Registry Interface, .RO Policies for EPP [https://epp2-test.rotld.ro/epp/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI.
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::DRD::RO;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;
use Net::DRI::Exception;
use Net::DRI::Data::Contact::RO;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_delete host_update host_current_status host_check host_exist host_delete host_create host_info contact_delete contact_transfer contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::RO - .RO EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>d.makuni@live.co.uk<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
	$self->{info}->{host_as_attr}=2;
	$self->{info}->{contact_i18n}=2;
	return $self;
}

sub periods         { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name            { return 'RO'; }
sub tlds            { return ('ro',map { $_.'.ro'} qw/arts com firm info org rec store tm www nt/ ); }
sub object_types    { return ('domain','contact','ns'); }
sub profile_types   { return qw/epp/; }

sub transport_protocol_default {
	my ($self,$type)=@_;
	return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RO',{}) if $type eq 'epp';
	return;
}

sub set_factories {
	my ($self,$po)=@_;
	$po->factories('contact',sub { return Net::DRI::Data::Contact::RO->new(@_); });
	return;
}

sub domain_trade_approve {
	my ($self,$ndr,$domain,$rd)=@_;
	$self->enforce_domain_name_constraints($ndr,$domain,'trade');
	return $ndr->process('domain','trade_approve',[$domain,$rd]);
}

####################################################################################################
1;
