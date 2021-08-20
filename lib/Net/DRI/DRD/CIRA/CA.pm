## Domain Registry Interface, CIRA (.CA) Registry Driver
##
## Copyright (c) 2010-2011,2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::CIRA::CA;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;
use DateTime::Duration;
use Net::DRI::Exception;

use Net::DRI::Data::Raw;
use Net::DRI::Protocol::EPP::Message;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse/);

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'CIRA::CA'; }
sub tlds          { return (qw/ca/); }
sub object_types  { return (qw/domain contact ns/); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CIRA',{}) if $type eq 'epp';
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
 Net::DRI::Exception::usererr_invalid_parameters('CIRA agreement language must be "en" or "fr"') if (defined $language && $language!~m/^(?:fr|en)$/);

 my $rc=$ndr->process('agreement', 'info', [ $language ]);
 return $rc;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::DRD::CIRA - CIRA (.CA) Registry driver for Net::DRI

=head1 SYNOPSIS

	$dri=Net::DRI->new();
	$dri->add_registry('CIRA');

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

Copyright (c) 2010-2011,2018-2019 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut