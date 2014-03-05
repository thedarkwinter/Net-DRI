## Domain Registry Interface, DAS Protocol (.BE & .EU)
##
## Copyright (c) 2007-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::DAS::Message;

=pod

=head1 NAME

Net::DRI::Protocol::DAS - DAS Protocol (.BE & .EU Domain Availability Service) for Net::DRI

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

Copyright (c) 2007-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->name('DAS');
 my $version=Net::DRI::Util::check_equal($rp->{version},['1.0','2.0'],'1.0');
 $self->version($version);
 $self->default_parameters({ tld => (exists $rp->{no_tld} && $rp->{no_tld})? ($drd->tlds())[0] : undef });
 $self->factories('message',sub { return Net::DRI::Protocol::DAS::Message->new(@_)->version($version); });
 $self->_load($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 return $self->SUPER::_load('Net::DRI::Protocol::DAS::Domain');
}

sub tld { return shift->{default_parameters}->{tld}; }

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::DAS::Connection', protocol_version => 1);
}

####################################################################################################
1;
