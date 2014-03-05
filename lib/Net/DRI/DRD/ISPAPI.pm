## Domain Registry Interface, ISPAPI (aka HEXONET) Registry Driver
##
## Copyright (c) 2010-2011 HEXONET GmbH, http://www.hexonet.net, Jens Wagner <info@hexonet.net>. All rights reserved.
##           (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::ISPAPI;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::ISPAPI - ISPAPI Registry driver for Net::DRI

=head1 DESCRIPTION

The ISPAPI Registry driver for Net::DRI enables you to connect HEXONET's EPP server and gives you 
the possibility to manage a wide range of gTLDs and ccTLDs.

In addition to the EPP 1.0 compliant commands there is a Key-Value mapping for additional domain related
parameters which are required by several registries. The driver also supports all other HEXONET commands like 
queries for domain and contact lists. It is also possible to access additional HEXONET products 
like virtual servers and ssl certificates.

=head1 CURRENT LIMITATIONS

The list of supported TLDs is currently static. If a new TLD is available the list has to be completed. 

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>support@hexonet.netE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.hexonet.net/E<gt>

=head1 AUTHOR

Alexander Biehl, E<lt>abiehl@hexonet.netE<gt>
Jens Wagner, E<lt>jwagner@hexonet.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2010-2011 HEXONET GmbH, E<lt>http://www.hexonet.netE<gt>,
Alexander Biehl <abiehl@hexonet.net>,
Jens Wagner <jwagner@hexonet.net>,
and Patrick Mevzek <netdri@dotandco.com>.
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
 return $self;
}

sub periods  { return (map { DateTime::Duration->new(years => $_) } (1..10)), (map { DateTime::Duration->new(months => $_) } (1..12)); }
sub name { return 'ISPAPI'; }
sub tlds { return qw/com net org aero asia biz info jobs mobi name pro tel travel at be ca ch cz de dk es eu fr hk im in it jp lt lu mx nl nu pl pt re ru se sg tk me.uk co.uk org.uk us/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host=>'epp.ispapi.net',remote_port=>700},'Net::DRI::Protocol::EPP::Extensions::ISPAPI',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return;
}

sub account_list_domains
{
 my ($self,$ndr,$hash)=@_;
 my $rc;
 $rc=$ndr->try_restore_from_cache('account','domains','list') if !$hash;
 if (! defined $rc) { $rc=$ndr->process('account','list_domains', [$hash]); }
 return $rc;
}

####################################################################################################
1;
