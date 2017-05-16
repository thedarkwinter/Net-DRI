## Domain Registry Interface, .AU policies
##
## Copyright (c) 2007,2008,2009 Distribute.IT Pty Ltd, www.distributeit.com.au, Rony Meyer <perl@spot-light.ch>. All rights reserved.
##           (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::AU;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::AU - .AU policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Rony Meyer, E<lt>perl@spot-light.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2009 Distribute.IT Pty Ltd, E<lt>http://www.distributeit.com.auE<gt>, Rony Meyer <perl@spot-light.ch>.
          (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (2..3); }
sub name     { return 'AU'; }
sub tlds     { return qw/com.au net.au org.au asn.au id.au vic.au tas.au nsw.au act.au qld.au sa.au nt.au wa.au/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp das/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AU',{}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::DAS::AU',{})             if $type eq 'das';
 return;
}

####################################################################################################
1;
