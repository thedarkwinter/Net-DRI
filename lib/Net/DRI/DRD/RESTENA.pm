## Domain Registry Interface, .LU policy from DocRegistrar-2.0.6.pdf
##
## Copyright (c) 2007-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::LU;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Data::Contact::LU;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_renew domain_transfer_accept domain_transfer_refuse contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::LU - .LU policies for Net::DRI

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

Copyright (c) 2007-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub periods  { return; } ## registry does not expect any duration at all
sub name     { return 'DNSLU'; }
sub tlds     { return ('lu'); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::LU',{})              if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.dns.lu'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::LU->new(@_); });
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               min_length => 3,
                                               no_double_hyphen => 1,
                                              });
}

sub domain_status_allows
{
 my ($self,$ndr,$domain,$what,$rd)=@_;

 return 0 unless ($what=~m/^(?:delete|update|transfer|renew|trade|transfer-trade|transfer-restore)$/);
 my $s=$self->domain_current_status($ndr,$domain,$rd);
 return 0 unless (defined($s));

 return !$s->is_pending() && $s->can_delete()   if ($what eq 'delete');
 return !$s->is_pending() && $s->can_update()   if ($what eq 'update'); ## no pendingCreate pendingUpdate pendingDelete
 return $s->can_transfer() if ($what eq 'transfer');
 return 0                  if ($what eq 'renew');
 return $s->has_not('serverTradeProhibited','pendingCreate','pendingDelete') if ($what eq 'trade');
 return $s->has_not('serverTransferProhibited','serverTradeProhibited') if ($what eq 'transfer-trade');
 return $s->has_not('serverTransferProhibited','serverRestoreProhibited') && $s->has_any('pendingDelete') if ($what eq 'transfer-restore');
 return 0; ## failsafe
}

sub domain_restore
{
 my ($self,$ndr,$domain)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'restore');
 return $ndr->process('domain','restore',[$domain]);
}

sub domain_transfer_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_trade');
 return $ndr->process('domain','transfer_trade_request',[$domain,$rd]);
}

sub domain_transfer_trade_query
{
 my ($self,$ndr,$domain)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_trade');
 return $ndr->process('domain','transfer_trade_query',[$domain]);
}

sub domain_transfer_trade_stop
{
 my ($self,$ndr,$domain)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_trade');
 return $ndr->process('domain','transfer_trade_cancel',[$domain]);
}

sub domain_transfer_restore_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_restore');
 return $ndr->process('domain','transfer_restore_request',[$domain,$rd]);
}

sub domain_transfer_restore_query
{
 my ($self,$ndr,$domain)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_restore');
 return $ndr->process('domain','transfer_restore_query',[$domain]);
}

sub domain_transfer_restore_stop
{
 my ($self,$ndr,$domain)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_restore');
 return $ndr->process('domain','transfer_restore_cancel',[$domain]);
}

####################################################################################################
1;
