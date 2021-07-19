## Domain Registry Interface, Nomulus Superuser Extension Mapping for EPP
##
## Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nomulus::Superuser;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $cmds = { 'domain' => { delete => [ \&delete, undef ] , 'transfer_request' => [ \&transfer, undef] } };
 return $cmds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'superuser' => 'urn:google:params:xml:ns:superuser-1.0' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://github.com/google/nomulus/blob/4b83615513a7fafd6bbab6a0b65d1726dede1f7a/java/google/registry/xml/xsd/superuser.xsd'; }

####################################################################################################

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;

 return unless Net::DRI::Util::has_key($rd, 'superuser') && ref $rd->{'superuser'} eq 'HASH';
 my $superuser = $rd->{superuser};

 Net::DRI::Exception::usererr_insufficient_parameters('redemption_grace_period must be defined') unless Net::DRI::Util::has_key($superuser, 'redemption_grace_period');
 Net::DRI::Exception::usererr_invalid_parameters('redemption_grace_period must be of type XML nonNegativeInteger') unless Net::DRI::Util::is_class($superuser->{redemption_grace_period}, 'DateTime::Duration');
 Net::DRI::Exception::usererr_insufficient_parameters('pending_delete must be defined') unless Net::DRI::Util::has_key($superuser, 'pending_delete');
 Net::DRI::Exception::usererr_invalid_parameters('pending_delete must be of type XML nonNegativeInteger') unless Net::DRI::Util::is_class($superuser->{pending_delete}, 'DateTime::Duration');

 my @data=(['superuser:redemptionGracePeriodDays', $superuser->{redemption_grace_period}->in_units('days')],
           ['superuser:pendingDeleteDays', $superuser->{pending_delete}->in_units('days')]);

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('superuser', 'domainDelete');
 $mes->command_extension($eid, \@data);
 return;
}

sub transfer
{
 my ($epp,$domain,$rd)=@_;

 return unless Net::DRI::Util::has_key($rd, 'superuser') && ref $rd->{'superuser'} eq 'HASH';
 my $superuser = $rd->{superuser};

 Net::DRI::Exception::usererr_insufficient_parameters('duration must be defined') unless Net::DRI::Util::has_key($superuser, 'duration');
 Net::DRI::Exception::usererr_invalid_parameters('duration must be a DateTime::Duration object') unless Net::DRI::Util::is_class($superuser->{duration}, 'DateTime::Duration');
 Net::DRI::Exception::usererr_insufficient_parameters('transfer_length must be defined') unless Net::DRI::Util::has_key($superuser, 'transfer_length');
 Net::DRI::Exception::usererr_invalid_parameters('transfer_length must be of type XML nonNegativeInteger') unless Net::DRI::Util::verify_int($superuser->{transfer_length}, 0); # this does not get until infinity, but should be good enough

 my $period=Net::DRI::Protocol::EPP::Util::build_period($superuser->{duration});
 $period->[0] = 'superuser:renewalPeriod'; # using "period" like in core EPP would have been too simple...

 my @data=($period, ['superuser:automaticTransferLength', $superuser->{transfer_length}]);

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('superuser', 'domainTransferRequest');
 $mes->command_extension($eid, \@data);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nomulus::Superuser - EPP Superuser Nomulus Extension mapping for Net::DRI

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

Copyright (c) 2017-2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
