## Domain Registry Interface, .BR policies
##
## Copyright (c) 2008,2009,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::BR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::BR - .BR policies for Net::DRI

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

Copyright (c) 2008,2009,2011 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'RegistroBR'; }
## See http://registro.br/info/dpn.html
sub tlds     { return ('br',map { $_.'.br' } qw/com agr am art edu coop esp far fm g12 gov imb ind inf jus mil net org psi rec srv tmp tur tv etc adm adv arq ato bio bmd cim cng cnt ecn eng eti fnd fot fst ggf jor lel mat med mus not ntr odo ppg pro psc qql slg trd vet zlg blog flog nom vlog sec3 wiki/ ); }
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::BR',{}) if $type eq 'epp';
 return;
}

####################################################################################################
1;
