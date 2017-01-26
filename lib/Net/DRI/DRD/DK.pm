## Domain Registry Interface, .DK Policies for EPP
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

package Net::DRI::DRD::DK;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Data::Contact::DK;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_delete contact_transfer contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse contact_renew domain_delete domain_transfer domain_transfer_accept domains_transfer_reject domains_transfer_cancel/);

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK - .DK EPP Contact extension commands for Net::DRI

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

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
	$self->{info}->{host_as_attr}=0;
	$self->{info}->{contact_i18n}=6; ## LOC OR INT (Loc for .dk contacts, int for rest of world)
	$self->{info}->{force_native_idn}=1;
	return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'DK'; }
sub tlds     { return 'dk'; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
  my ($self,$type)=@_;
	return ('Net::DRI::Transport::Socket',{ 'ssl_version' => 'TLSv12', 'ssl_cipher_list' => undef },'Net::DRI::Protocol::EPP::Extensions::DK',{}) if $type eq 'epp';
	return;
}

sub set_factories {
	my ($self,$po)=@_;
	$po->factories('contact',sub { return Net::DRI::Data::Contact::DK->new(@_); });
	return;
}

####################################################################################################
1;
