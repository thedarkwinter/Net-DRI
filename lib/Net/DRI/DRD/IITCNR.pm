## Domain Registry Interface, IIT CNR (.IT) policies
##
## Copyright (c) 2009-2011,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::IITCNR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/host_check host_info host_update host_delete host_create contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_renew/);

=pod

=head1 NAME

Net::DRI::DRD::IITCNR - IIT CNR (.IT) policies for Net::DRI

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

Copyright (c) 2009-2011,2016 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 $self->{info}->{force_native_idn}=1;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'IITCNR'; }
sub tlds     { return qw /it co.it/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{ check_name => 0, ## FIXME, is there a batter way to allow native IDNs?
                                                my_tld => 1,
                                                min_length => 2,
                                              });
}

sub transport_protocol_default
{
 my ($self,$type)=@_;
 # enforce only_local_extensions to check if need to parse SecDNS and IT::SecDNS
 my $secdns_accredited = 0; ## TODO: if SecDNS accredited set variable to 1 in order to parse SecDNS and IT::SecDNS in EPP login command :)
 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP', 'only_local_extensions' => 1},'Net::DRI::Protocol::EPP::Extensions::IT',{custom=>{secdns_accredited=>$secdns_accredited}}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

####################################################################################################
1;
