## Domain Registry Interface, .IN
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##           (c) 2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
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

package Net::DRI::DRD::IN;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::IN - .IN

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni E<lt>d.makuni@live.co.ukE<gt>;
Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>;
Michael Holloway E<lt>michael@thedarkwinter.comE<gt>;
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

David Makuni <d.makuni@live.co.uk>
Paulo Jorge <paullojorgge@gmail.com>;
Michael Holloway <michael@thedarkwinter.com>;
Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{contact_i18n}=1; ## LOC only
 $self->{info}->{force_native_idn}=1;

 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'IN'; }
sub tlds     { return ('in', map { $_.'.in'} qw/co gen ind net org/ ); }
sub object_types { return qw(domain contact ns); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::IN',{}) if $type eq 'epp';

 return;
}

####################################################################################################
1;
