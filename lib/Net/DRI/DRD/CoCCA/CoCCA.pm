## Domain Registry Interface, CoCCA Registry Driver for multiple TLDs
##
## Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
#########################################################################################

package Net::DRI::DRD::CoCCA::CoCCA;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::CoCCA::GTLD - CoCCA Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This is only a prototype for testing purpose. Each TLD registry should have its own DRD module
implementing local policies.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>.
Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'CoCCA::CoCCA'; }

# README: this is not a shared platform!
sub tlds         {
    my @others = qw/cx gs tl ki mu nf ht na ng cc cm sb mg/;
    my @ph = (map { $_.'.ph' } qw/com net org/);
    my @so = qw/so com.so edu.so gov.so me.so net.so org.so/;
    return (@others,@ph,@so);
}

sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CoCCA::Notifications', 'CentralNic::Fee'], 'brown_fee_version' => '0.8'}) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;

 return $self->_verify_duration_transfer_15days($ndr,$duration,$domain,$op);
}

####################################################################################################

1;
