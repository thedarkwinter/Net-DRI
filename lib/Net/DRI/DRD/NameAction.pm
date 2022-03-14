## Domain Registry Interface, NameAction Registry Driver
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::NameAction;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::NameAction - NameAction Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
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
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'NameAction'; }
sub tlds         { 
 #my @tlds = qw/ai ar aw bo br cl co cr cu ec ga gt jm kn ng ni pa pe pr py sv uy ve/;
 my @tlds = qw/ai ar aw bo cl co cr cu ec ga gt kn ni pa pe sv uy/;
 my @ar = map {$_.'.ar'} qw/com net org/;
 my @bo = map {$_.'.bo'} qw/com net org/;
 my @br = map {$_.'.br'} qw/com eco emp esp etc ind inf net org radio rec srv tmp tv/;
 my @cr = map {$_.'.cr'} qw/co/;
 my @cu = map {$_.'.cu'} qw/com/;
 my @jm = map {$_.'.jm'} qw/com/;
 my @kn = map {$_.'.kn'} qw/com net org/;
 my @ng = map {$_.'.ng'} qw/com/;
 my @ni = map {$_.'.ni'} qw/biz co com/;
 my @pa = map {$_.'.pa'} qw/com/;
 my @pe = map {$_.'.pe'} qw/com org/;
 my @pr = map {$_.'.pr'} qw/com/;
 my @py = map {$_.'.py'} qw/com/;
 my @sv = map {$_.'.sv'} qw/com/;
 my @uy = map {$_.'.uy'} qw/com/;
 my @ve = map {$_.'.ve'} qw/co com firm info net org rec web/;
 
 return @tlds,@ar,@bo,@br,@cr,@cu,@jm,@kn,@ng,@ni,@pa,@pe,@pr,@py,@sv,@uy,@ve;
}
sub object_types { return ('domain'); }
sub profile_types { return qw/nameaction/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{},'Net::DRI::Protocol::NameAction',{}) if $type eq 'nameaction';
 return;
}

####################################################################################################
1;
