## Domain Registry Interface, SK-NIC (ccTLD: .sk) Driver
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::CentralNic::SKNIC;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Data::Contact::SKNIC;
use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::DRD::CentralNic::SKNIC -  SK-NIC (ccTLD: .sk) Driver for Net::DRI

=head1 DESCRIPTION

SK-NIC ccTLDs: sk

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

(c) 2017 Patrick Mevzek <netdri@dotandco.com>,

(c) 2017 Michael Holloway <michael@thedarkwinter.com>,

(c) 2017 Paulo Jorge <paullojorgge@gmail.com>.

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
 $self->{info}->{contact_i18n}=2; ## INT => based on: https://docs.test.sk-nic.sk
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'CentralNic::SKNIC'; }
sub tlds     { return (qw/sk/); }
sub object_types { return qw(domain contact ns); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CentralNic',{'brown_fee_version' => '0.5'}) if $type eq 'epp';

 return;
}

sub set_factories {
   my ($self,$po)=@_;
   $po->factories('contact',sub { return Net::DRI::Data::Contact::SKNIC->new(@_); });
   return;
}

####################################################################################################

1;
