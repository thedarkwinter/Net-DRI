## Domain Registry Interface, RRP Protocol
##
## Copyright (c) 2005,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::RRP;

use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Exception;
use Net::DRI::Util;

use Net::DRI::Protocol::RRP::Message;
use Net::DRI::Protocol::RRP::Core::Status;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

=pod

=head1 NAME

Net::DRI::Protocol::RRP - RRP 1.1/2.0 Protocol for Net::DRI

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

Copyright (c) 2005,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


our %DATES=('registration expiration date' => 'exDate',
            'created date'                 => 'crDate',
            'updated date'                 => 'upDate',
            'registrar transfer date'      => 'trDate',
           );

our %IDS=('registrar'  => 'clID',
          'created by' => 'crID',
          'updated by' => 'upID',
         );

###############################################################################

sub new
{
 my ($c,$ctx,$rp)=@_;
 my $drd=$ctx->{registry}->driver();
 my $self=$c->SUPER::new($ctx);
 $self->name('RRP');
 my $version=Net::DRI::Util::check_equal($rp->{version},['1.1','2.0'],'2.0'); ## 1.1 (RFC #2832) or 2.0 (RFC #3632)
 $self->version($version);
 $self->capabilities('host_update','ip',['add','del']);
 $self->capabilities('host_update','name',['set']);
 $self->capabilities('domain_update','ns',['add','del']);
 $self->capabilities('domain_update','status',['add','del']);
 $self->factories('message',sub { my $m=Net::DRI::Protocol::RRP::Message->new(@_); $m->version($version); return $m; });
 $self->factories('status',sub { return Net::DRI::Protocol::RRP::Core::Status->new(); });

 ## Verify that we have the timezone of the registry, since dates in RRP are local to registries
 my $tzname=$drd->info('tz');
 Net::DRI::Exception::usererr_insufficient_parameters('no registry timezone') unless (defined($tzname));
 my $tz;
 eval { $tz=DateTime::TimeZone->new(name => $tzname); };
 Net::DRI::Exception::usererr_invalid_parameters("invalid registry timezone ($tzname), unable to instantiate") unless (defined $tz && ref $tz);
 my $dtp;
 eval { $dtp=DateTime::Format::Strptime->new(time_zone=>$tz, pattern=>'%Y-%m-%d %H:%M:%S.0'); };
 Net::DRI::Exception::usererr_invalid_parameters("invalid registry timezone ($tzname), unable to create parser") unless (defined $dtp && ref $dtp);
 $self->{dt_parse}=$dtp;

 $self->_load($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 my $extramods=$rp->{extensions};
 my @class=map { 'Net::DRI::Protocol::RRP::Core::'.$_ } ('Session','Domain','Host');
 push @class,map { my $f=$_; $f='Net::DRI::Protocol::EPP::Extensions::'.$f unless ($f=~s/^\+//); $f; } (ref($extramods)? @$extramods : ($extramods)) if defined $extramods && $extramods;
 return $self->SUPER::_load(@class);
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::RRP::Connection', protocol_version => 1);
}

###############################################################################################
1;
