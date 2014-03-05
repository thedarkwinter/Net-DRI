## Domain Registry Interface, EPP Status for .LU
##
## Copyright (c) 2007,2008,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU::Status;

use base qw!Net::DRI::Protocol::EPP::Core::Status!;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU::Status - EPP .LU Status for Net::DRI

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

Copyright (c) 2007,2008,2011 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$data)=@_;
 my $self=$class->SUPER::new($data);

 ## .LU accepts only some EPP status, and adds inactive, serverTradeProhibited, serverRestoreProhibited
 my %s=(
        'renew'    => 'clientRenewProhibited',
        'publish'  => 'clientHold',
	'active'     => 'inactive',
       );
 $self->_register_pno(\%s); ## this will overwrite what has been done in SUPER::new
 return $self;
}

sub is_core_status
{
 return (shift=~m/^(?:client(?:Hold|(?:Delete|Renew|Update|Transfer)Prohibited)|inactive)$/);
}

sub is_active { return shift->has_not('inactive'); }

####################################################################################################
1;
