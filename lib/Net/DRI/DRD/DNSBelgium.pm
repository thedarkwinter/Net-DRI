## Domain Registry Interface, DNSBelgium (.BE) policies for Net::DRI
##
## Copyright (c) 2006-2011,2O16 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::DNSBelgium;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse domain_renew contact_check contact_transfer/);

=pod

=head1 NAME

Net::DRI::DRD::DNSBelgium - DNSBelgium (.BE) policies for Net::DRI

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

Copyright (c) 2006-2011,2016 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'DNSBelgium'; }
sub tlds     { return ('be'); } # In october 2017, they will be doing vlaanderen and .brussels, but no details yet
sub object_types { return (qw/domain contact nsgroup keygroup/); }
sub profile_types { return qw/epp das/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::DNSBE',{})                  if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.dns.be'},'Net::DRI::Protocol::DAS',{no_tld=>1}) if $type eq 'das';
 return;
}

####################################################################################################
## From §2 of Enduser_Terms_And_Conditions_fr_v3.1.pdf
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{ check_name => 1,
                                                my_tld => 1,
                                                min_length => 2,
                                              });
}


sub domain_request_authcode
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'request_authcode', [$dom, $rd]);
}


#####################################################################################################
1;
