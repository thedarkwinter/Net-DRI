## Domain Registry Interface, RRI Protocol (DENIC-11)
##
## Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::RRI;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::RRI::Message;
use Net::DRI::Data::StatusList;
use Net::DRI::Data::Contact::DENIC;

=pod

=head1 NAME

Net::DRI::Protocol::RRI - RRI Protocol (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->name('RRI');
 my $version=Net::DRI::Util::check_equal($rp->{version},['2.0'],'2.0');
 $self->version($version);

 foreach my $o (qw/ip status/) { $self->capabilities('host_update',$o,['set']); }
 $self->capabilities('host_update','name',['set']);
 $self->capabilities('contact_update','info',['set']);
 foreach my $o (qw/ns status contact/) { $self->capabilities('domain_update',$o,['add','del']); }
 foreach my $o (qw/registrant auth/)   { $self->capabilities('domain_update',$o,['set']); }

 $self->{ns}={ _main	=> ['http://registry.denic.de/global/1.0'],
		tr	=> ['http://registry.denic.de/transaction/1.0'],
		contact	=> ['http://registry.denic.de/contact/1.0'],
		domain	=> ['http://registry.denic.de/domain/1.0'],
		dnsentry=> ['http://registry.denic.de/dnsentry/1.0'],
                msg	=> ['http://registry.denic.de/msg/1.0'],
		xsi	=> ['http://www.w3.org/2001/XMLSchema-instance'],
             };

 $self->factories('message',sub { my $m=Net::DRI::Protocol::RRI::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m; });
 $self->factories('status',sub { return Net::DRI::Data::StatusList->new(); });
 $self->factories('contact',sub { return Net::DRI::Data::Contact::DENIC->new(); });
 $self->_load($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;

 my @core=('Session','RegistryMessage','Domain','Contact');
 my @class=map { 'Net::DRI::Protocol::RRI::'.$_ } @core;

 return $self->SUPER::_load(@class);
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::RRI::Connection', protocol_version => '2.0');
}

####################################################################################################
1;
