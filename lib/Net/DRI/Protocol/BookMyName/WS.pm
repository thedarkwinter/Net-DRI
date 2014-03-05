## Domain Registry Interface, BookMyName Web Services Protocol
## As seen on http://api.doc.free.org/revendeur-de-nom-de-domaine
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::BookMyName::WS;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);
use Net::DRI::Protocol::BookMyName::WS::Message;

=pod

=head1 NAME

Net::DRI::Protocol::BookMyName::WS - BookMyName (aka Free/ProXad/Online/Dedibox/Iliad) Web Services Protocol for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $self=$c->SUPER::new($ctx);
 $self->name('bookmyname_ws');
 $self->version('0.1');
 $self->factories('message',sub { my $m=Net::DRI::Protocol::BookMyName::WS::Message->new(); $m->version('0.1'); return $m; });
 $self->_load($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 my @class=map { 'Net::DRI::Protocol::BookMyName::WS::'.$_ } (qw/Account Domain/);
 return $self->SUPER::_load(@class);
}

sub transport_default
{
 my ($self)=@_;
 return (has_login=>0,has_logout=>0,defer=>1);
}

####################################################################################################
1;
