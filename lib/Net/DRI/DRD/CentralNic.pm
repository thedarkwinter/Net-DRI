## Domain Registry Interface, CentralNic Registry Driver
##
## Copyright (c) 2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::CentralNic;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::CentralNic - CentralNic (.LA .EU.COM .UK.COM etc.) Registry driver for Net::DRI

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

Copyright (c) 2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=2;       ## INT only
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (2..10); }
sub name         { return 'CentralNic'; }
sub tlds         { return (qw/la pw com.de/,
                           (map { $_.'.org' } qw/us ae/),
                           (map { $_.'.net' } qw/uk se gb jp hu/),
                           (map { $_.'.com' } qw/eu uk us cn de jpn kr no za br ar ru sa se hu gb qc uy gr/)
                          ); } ## see https://www.centralnic.com/portfolio/domains/registration

sub object_types { return ('domain','ns','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CentralNic',{}) if $type eq 'epp';
 return;
}

## From http://centralnicstatus.com/2011/07/01/mandatory-use-of-epp-client-ssl-certificates-2011-07-25/
## certificates are now mandatory
## (stolen from DRD/COOP, see comment in it)
sub transport_protocol_init
{
 my ($self,$type,$tc,$tp,$pc,$pp,$test)=@_;

 if ($type eq 'epp' && !$test)
 {
  my @n=grep { ! exists($tp->{$_}) || ! defined($tp->{$_}) || ! $tp->{$_}} qw/ssl_key_file ssl_cert_file ssl_ca_file/;
  Net::DRI::Exception::usererr_insufficient_parameters('These transport parameters must be defined: '.join(' ',@n)) if @n;
 }

 return;
}


####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 3,
                                              });
}

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;

 return $self->_verify_duration_transfer_15days($ndr,$duration,$domain,$op);
}

sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;

 return 0 unless (defined $duration && defined $curexp && Net::DRI::Util::is_class($curexp,'DateTime'));
 my $newexp=$curexp+$duration; ## New expiration
 my $max=DateTime->new(year => 2037, month => 1, day => 1, time_zone => $curexp->time_zone()->name());
 my $cmp=DateTime->compare($newexp,$max);
 return 2 unless ($cmp == -1); ## we must have curexp+duration < 2037
 return 0; ## everything ok
}

####################################################################################################

sub domain_release
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'release');

 return $ndr->process('domain','release',[$domain,$rd]);
}

####################################################################################################
1;
