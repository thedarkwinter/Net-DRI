## Domain Registry Interface, Whois Protocol (RFC3912)
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

package Net::DRI::Protocol::Whois;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::Whois::Message;

=pod

=head1 NAME

Net::DRI::Protocol::Whois - Whois Protocol (RFC3912) for Net::DRI

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
 $self->name('whois');
 my $version=Net::DRI::Util::check_equal($rp->{version},['1.0'],'1.0');
 $self->version($version);

 my @tlds=$drd->tlds();
## Net::DRI::Exception::usererr_invalid_parameters('Whois can not be used for registry handling multiple TLDs: '.join(',',@tlds)) unless (@tlds==1 || lc($tlds[0]) eq 'com');
 $drd->set_factories($self) if $drd->can('set_factories');
 $self->factories('message',sub { return Net::DRI::Protocol::Whois::Message->new(@_)->version($version); });
 $self->_load(uc($tlds[0]));
 return $self;
}

sub _load
{
 my ($self,$tld)=@_;
 return $self->SUPER::_load('Net::DRI::Protocol::Whois::Domain::'.$tld);
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::Whois::Connection', protocol_version => 1);
}

####################################################################################################
1;
