## Domain Registry Interface, DNSBelgium Registry Driver for GTLDs
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::DNSBelgium::GTLD;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_renew contact_transfer/); # based on: "gTLD manual - Part IV Registrar EPP - v1.0.pdf"

=pod

=head1 NAME

Net::DRI::DRD::DNSBelgium::GTLD - DNSBelgium Registry Driver for GTLDs policies - Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2017 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2017 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=2; ## They accept LOC *or* INT, but only one of them. Forcing INT!
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'DNSBelgium::GTLD'; }
sub tlds     { return ('brussels', 'dnsbelgium', 'vlaanderen'); } # README: dnsbelgium used on their OT&E only!
sub object_types { return (qw/domain contact/); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{ 'ssl_version'=>'TLSv12', 'ssl_cipher_list' => undef },'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{}) if $type eq 'epp';
 return;
}

#####################################################################################################
1;
