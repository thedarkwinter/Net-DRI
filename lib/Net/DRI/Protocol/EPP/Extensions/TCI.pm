## Domain Registry Interface, .RU/.SU/.XN--P1AI EPP Extension for Net::DRI
##
## Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
##               2011-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TCI;

use strict;
use warnings;

use base qw(Net::DRI::Protocol::EPP);
use Net::DRI::Protocol::EPP::Extensions::TCI::Message;
use Net::DRI::Data::Contact::TCI;

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({ domain    => ['http://www.ripn.net/epp/ripn-domain-1.0', 'ripn-domain-1.0.xsd'],
             _main     => ['http://www.ripn.net/epp/ripn-epp-1.0',    'ripn-epp-1.0.xsd'],
             contact   => ['http://www.ripn.net/epp/ripn-contact-1.0','ripn-contact-1.0.xsd'],
             host      => ['http://www.ripn.net/epp/ripn-host-1.0',   'ripn-host-1.0.xsd'],
             registrar => ['http://www.ripn.net/epp/ripn-registrar-1.0', 'ripn-registrar-1.0.xsd'],
             secDNS    => ['urn:ietf:params:xml:ns:secDNS-1.1', 'secDNS-1.1.xsd'],
          });
 $self->factories('message',sub { my $m= Net::DRI::Protocol::EPP::Extensions::TCI::Message->new(@_); $m->ns($self->ns()); $m->version($self->version() ); return $m; });
 $self->factories('contact',sub { return Net::DRI::Data::Contact::TCI->new(); });

 foreach my $o (qw/contact/) { $self->capabilities('contact_update',$o,['set']); }
 foreach my $o (qw/contact description/) { $self->capabilities('domain_update',$o,['set']); }
 foreach my $o (qw/ns/) { $self->capabilities('domain_update',$o,['add', 'del']); }
 return;
}

sub core_modules
{
 my ($self,$rp)=@_;
 my @c=map { 'Net::DRI::Protocol::EPP::Extensions::TCI::'.$_ } qw/Contact/;
 push @c, map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Host/;
 return @c;
}

sub default_extensions { return qw(TCI::Contact TCI::Domain TCI::Registrar SecDNS); }

####################################################################################################
1;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TCI - TCI EPP Extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Dmitry Belyavsky, E<lt>beldmit@gmail.comE<gt>
Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Dmitry Belyavsky <beldmit@gmail.com>
Copyright (c) 2011-2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
