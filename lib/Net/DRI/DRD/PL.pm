## Domain Registry Interface, .PL policies
##
## Copyright (c) 2006,2008-2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::PL;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_accept domain_transfer_refuse contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::PL - .PL policies for Net::DRI

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

Copyright (c) 2006,2008-2012 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{contact_i18n}=1;	## LOC only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'NASK'; }
## See http://www.dns.pl/english/dns-funk.html
sub tlds     { return ('pl',map { $_.'.pl'} qw/aid agro atm auto biz com edu gmina gsm info mail miasta media mil net nieruchomosci nom org pc powiat priv realestate rel sex shop sklep sos szkola targi tm tourism travel turystyka/ ); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP'},'Net::DRI::Protocol::EPP::Extensions::PL',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

####################################################################################################

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','plretrieve',[$id]);
 return $rc;
}

sub report_create
{
 my ($self,$ndr,$id,$rp)=@_;
 my $rc=$ndr->process('report','create',[$id,$rp]);
 return $rc;
}

####################################################################################################
1;
