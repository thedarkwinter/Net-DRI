## Domain Registry Interface, .AE [EPP - 1.0 Specification]
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
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

package Net::DRI::DRD::AE;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;
use Net::DRI::Exception;
use Net::DRI::Data::Contact::AE;

=pod

=head1 NAME

Net::DRI::DRD::AE - .AE policies

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

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.

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
	$self->{info}->{contact_i18n}=1;
	return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'AE'; }
sub tlds          { return ('ae',map { $_.'.ae'} qw/net co/ ); }
sub object_types  { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
	my ($self,$type)=@_;
	return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP',{}) if $type eq 'epp';
	return;
}

sub set_factories {
	my ($self,$po)=@_;
	$po->factories('contact',sub { return Net::DRI::Data::Contact::AE->new(@_); });
	return;
}

####################################################################################################
1;
