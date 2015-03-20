## Domain Registry Interface, .LV Policies for EPP [http://www.nic.lv/eppdoc/html/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::LV;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Data::Contact::LV;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->make_exception_for_unavailable_operations(qw/host_update host_current_status host_check host_exist host_delete host_create host_info domain_renew domain_transfer contact_transfer contact_renew contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_transfer_accept domains_transfer_reject domains_transfer_cancel/);

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LV - .LV EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>d.makuni@live.co.uk<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
 $self->{info}->{contact_i18n}=1;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'LV'; }
sub tlds     { return ('lv',map { $_.'.lv'} qw/com id net org edu asn conf/ ); } # .edu.lv requires authorization from the Registry.
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::LV',{}) if $type eq 'epp';
 
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::LV->new(@_); });
 
 return;
}

####################################################################################################
1;