## Domain Registry Interface, Example Driver for .EXAMPLE
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

package Net::DRI::DRD::Example;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'EXAMPLE'; }
sub tlds          { return qw/example/; }
sub object_types  { return qw/domain ns contact/; }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host=>'localhost', remote_port=>700},'Net::DRI::Protocol::EPP',{}) if $type eq 'epp';
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::DRD::Example - Example Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This driver will never match any existing registry, as .EXAMPLE
is reserved per RFC2606

It is however useful for local tests.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

