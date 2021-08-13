## Domain Registry Interface, Kanton Zurich (gTLD .zuerich) Registry Driver
##
## Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2021 PauloCastanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::CentralNic::CentralNic;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::CentralNic::Zurich - Kanton Zurich (gTLD .zuerich) Registry driver for Net::DRI

=head1 DESCRIPTION

Kanton Zurich gTLDs: .zuerich

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Castanheira, paulo.s.castanheira@gmail.com 

=head1 COPYRIGHT

(c) 2021 Patrick Mevzek <netdri@dotandco.com>.
(c) 2021 Michael Holloway <michael@thedarkwinter.com>.e
(c) 2021 PauloCastanheira <paulo.s.castanheira@gmail.com>.
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
 $self->{info}->{contact_i18n}=4;       ## INT & LOC
 return $self;
}

sub periods { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name { return 'CentralNic::CentralNic'; }
sub tlds { return qw/zuerich/; } 
sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::
',{'brown_fee_version' => '0.5'}) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 1,
                                              });
}

####################################################################################################

1;
