## Domain Registry Interface, CIRA IE
##
## Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::CIRA::IE;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use base qw/Net::DRI::DRD/;
use DateTime::Duration;
use Net::DRI::Exception;

# __PACKAGE__->make_exception_for_unavailable_operations(qw//);

=pod

=head1 NAME

Net::DRI::DRD::CIRA::IE - CIRA IE Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension for CIRA IE (Titan) Platform

CIRA  uses the following standard, and custom extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.11

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2020 Paulo Jorge <paullojorgge@gmail.com>.
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
 $self->{info}->{contact_i18n}=1; ## LOC only - "The only Registry-supported type is loc indicating that the address is in a localized form"
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'CIRA::IE'; }
sub tlds     { return qw/ie/; }
sub object_types  { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::IE',{ custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.11' }) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name=>1,check_name_dots=>[1,2,3],my_tld_not_strict=>1});
}

sub agreement_info
{
 my ($self,$ndr,$language)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('CIRA IE (Titan) agreement language must be "en" or "fr"') if (defined $language && $language!~m/^(?:fr|en)$/);

 my $rc=$ndr->process('agreement', 'info', [ $language ]);
 return $rc;
}

####################################################################################################
1;
