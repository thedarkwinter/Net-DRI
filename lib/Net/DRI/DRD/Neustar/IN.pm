## Domain Registry Interface, Neustar (IN) policies
##
## Copyright (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::Neustar::IN;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::Neustar::IN - Neustar (IN) policies for Net::DRI
Supported TLDs: .in, .xn--gecrj9c, .xn--45brj9c, .xn--h2brj9c, .xn--xkc2dl3a5ee0h, .xn--s9brj9c, .xn--fpcrj9c3d, .xn--mgbbh1a71e

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2019 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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
 $self->{info}->{contact_i18n}=6; ## INT only or INT+LOC (but not LOC only)
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Neustar::IN'; }
# based on following documentation: "NSR - Migration Guide - 2.0.pdf" 
sub tlds {
    my @in = ( 'in', map { $_.'.in'} qw/ac co edu firm gen gov ind mil net org res/ );    
    my @xngecrj9c = ( 'xn--gecrj9c', map { $_.'.xn--gecrj9c'} qw/xn--0dc7cb3a6a xn--hdc1b4ch5i xn--iecsq2bc9f/ );
    my @xn45brj9c = ( 'xn--45brj9c', map { $_.'.xn--45brj9c'} qw/xn--b5b2au3c8d7b2b xn--p5b2bfp1g0b0b xn--r5b0alaxhm0qzbe/ );
    my @xnh2brj9c = ( 'xn--h2brj9c', map { $_.'.xn--h2brj9c'} qw/xn--11b7cb3a6a xn--i1b1b4ch5i xn--j2bsq2bc9f/ );
    my @xnxkc2dl3a5ee0h = ( 'xn--xkc2dl3a5ee0h', map { $_.'.xn--xkc2dl3a5ee0h'} qw/xn--clc2dj4b0d xn--vkc6b7c7c xn--vlccpku2dp3h/ );
    my @xns9brj9c = ( 'xn--s9brj9c', map { $_.'.xn--s9brj9c'} qw/xn--d9b2bf3g1k xn--d9b7cb3a6a xn--x8b5axg2ab21a xn--x8b7dzbzbb/ );
    my @xnfpcrj9c3d = ( 'xn--fpcrj9c3d', map { $_.'.xn--fpcrj9c3d'} qw/xn--goc1b4ch5i8a xn--goc1eramo6a1free xn--hpcsq2bc9f/ );
    my @xnmgbbh1a71e = ( 'xn--mgbbh1a71e', map { $_.'.xn--mgbbh1a71e'} qw/xn--pgb4a7ae88d xn--mgbtbf5f xn--fhbed7t1n/ );
    return ( @in, @xngecrj9c, @xn45brj9c, @xnh2brj9c, @xnxkc2dl3a5ee0h, @xns9brj9c, @xnfpcrj9c3d, @xnmgbbh1a71e );
}
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Neustar',{ 'brown_fee_version' => '0.6' }) if $type eq 'epp';
 return;
}

####################################################################################################

1;
