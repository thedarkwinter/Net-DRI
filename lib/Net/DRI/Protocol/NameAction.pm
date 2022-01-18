## Domain Registry Interface, OpenSRS XCP Protocol
##
## Copyright (c) 2008-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::NameAction;;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Protocol::NameAction::Message;

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP - OpenSRS XCP Protocol for Net::DRI

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

Copyright (c) 2008-2010,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($c,$ctx,$rp)=@_;
 my $drd=$ctx->{registry}->driver();
 my $self=$c->SUPER::new($ctx);
 $self->name('nameaction');
 $self->version('1.0.4'); ## Specification March 17, 2008
 $self->factories('message',sub { my $m=Net::DRI::Protocol::NameAction::Message->new(); return $m; });
 $self->_load($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 my @class=map { 'Net::DRI::Protocol::NameAction::'.$_ } (qw/Domain/);
 return $self->SUPER::_load(@class);
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::NameAction::Connection', protocol_version => '1.0');
}

####################################################################################################
1;
