## Domain Registry Interface, IRIS Protocols (RFC 3981,3982,3983,4414,4698,4991,4992,4993,5144)
##
## Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::IRIS;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::IRIS::Message;
use Net::DRI::Protocol::IRIS::DCHK::Status;

=pod

=head1 NAME

Net::DRI::Protocol::IRIS - IRIS Protocols (RFC 3981,3982,3983,4414,4698,4991,4992,4993,5144) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

Currently only DCHK (RFC5144) over LWZ (RFC4993) is supported.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>.
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
 my $version=$rp->{version};
 my $authority=$rp->{authority};
 my $self=$c->SUPER::new($ctx);
 $self->name('IRIS');
 $version=Net::DRI::Util::check_equal($version,['1.0'],'1.0');
 $self->version($version);
 $self->ns({ iris1 => ['urn:ietf:params:xml:ns:iris1','iris1.xsd'],
             dchk1 => ['urn:ietf:params:xml:ns:dchk1','dchk1.xsd'],
          });
 my %o;
 $o{request_deflate}=exists $rp->{request_deflate} ? $rp->{request_deflate} : 1;
 $self->factories('message',sub { my $m=Net::DRI::Protocol::IRIS::Message->new(@_); $m->ns($self->ns()); $m->version($version); $m->authority($authority); $m->options(\%o); return $m; });
 $self->factories('status',sub { return Net::DRI::Protocol::IRIS::DCHK::Status->new(); });
 $self->_load('Net::DRI::Protocol::IRIS::DCHK::Domain');
 return $self;
}

sub ns
{
 my ($self,$add)=@_;
 $self->{ns}={ ref $self->{ns} ? %{$self->{ns}} : (), %$add } if (defined $add && ref $add eq 'HASH');
 return $self->{ns};
}

## This will need to be slightly re-engineered once we do other things than DCHK in IRIS
sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::IRIS::LWZ', protocol_version => '1.0');
}

####################################################################################################
1;
