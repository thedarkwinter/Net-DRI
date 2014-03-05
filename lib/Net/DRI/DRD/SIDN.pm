## Domain Registry Interface, SIDN (.NL) Registry Driver
##
## Copyright (c) 2009-2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::SIDN;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_renew domain_transfer_stop domain_update_status domain_update_status_add domain_update_status_del domain_update_status_set contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse contact_update_status contact_update_status_add contact_update_status_del contact_update_status_set host_update_status host_update_status_add host_update_status_del host_update_status_set host_update_name_set/);

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub name          { return 'SIDN'; }
sub tlds          { return (qw/nl/); }
sub periods       { return; } ## registry does not expect any duration at all
sub object_types  { return (qw/domain contact ns/); }
sub profile_types { return qw/das epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::DAS::SIDN',{}) if $type eq 'das';
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::SIDN',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub domain_undelete
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'delete_cancel');

 my $rc=$ndr->process('domain','delete_cancel',[$domain,$rd]);
 return $rc;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::DRD::SIDN - SIDN (.NL) Registry driver for Net::DRI

=head1 SYNOPSIS

	$dri=Net::DRI->new();
	$dri->add_registry('SIDN');

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

Copyright (c) 2009-2011 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
