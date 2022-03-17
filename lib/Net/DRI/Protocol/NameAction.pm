## Domain Registry Interface, NameAction Protocol
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

package Net::DRI::Protocol::NameAction;;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Protocol::NameAction::Message;
use Net::DRI::Data::Contact::NameAction;

=pod

=head1 NAME

Net::DRI::Protocol::NameAction - NameAction Protocol for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

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
 my ($c,$ctx,$rp)=@_;
 my $drd=$ctx->{registry}->driver();
 my $self=$c->SUPER::new($ctx);
 $self->name('nameaction');
 $self->version('1.0.4');
 $self->factories('message',sub { return Net::DRI::Protocol::NameAction::Message->new(); });
 $self->factories('contact',sub { return Net::DRI::Data::Contact::NameAction->new(); });
 $self->capabilities('domain_update','contact',['set']);
 $self->capabilities('domain_update','ns',['set']);
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
