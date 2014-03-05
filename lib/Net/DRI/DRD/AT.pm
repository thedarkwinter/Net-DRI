## Domain Registry Interface, .AT policy
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::AT;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Data::Contact::AT;
use Net::DRI::Util;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domain_transfer_refuse domain_renew contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse contact_check/);

=pod

=head1 NAME

Net::DRI::DRD::AT - .AT policies for Net::DRI

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

Copyright (c) 2006-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{host_as_attr}=2; ## this means we want IPs in all cases (even for nameservers in domain name)
 $self->{info}->{contact_i18n}=2; ## INT only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'NICAT'; }
sub tlds     { return ('at'); }
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AT',{})              if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.nic.at'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::AT->new(@_); });
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name_no_dots => 1, ## is this correct?
                                               my_tld_not_strict => 1, ## is this correct?
                                              });
}

sub domain_withdraw
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'withdraw');
 $rd=Net::DRI::Util::create_params('domain_withdraw',$rd);
 $rd->{transactionname}='withdraw';

 my $rc=$ndr->process('domain','nocommand',[$domain,$rd]);
 return $rc;
}

sub domain_transfer_execute
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'transfer_execute');
 $rd=Net::DRI::Util::create_params('domain_transfer_execute',$rd);
 $rd->{transactionname}='transfer_execute';

 my $rc=$ndr->process('domain','nocommand',[$domain,$rd]);
 return $rc;
}

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','atretrieve',[$id]);
 return $rc;
}

sub message_delete
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','atdelete',[$id]);
 return $rc;
}

sub message_count
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->process('message','atretrieve');
 return unless $rc->is_success();
 my $count=$ndr->get_info('count','message','info');
 return (defined($count) && $count)? $count : 0;
}

####################################################################################################
1;
