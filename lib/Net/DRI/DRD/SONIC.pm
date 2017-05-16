## Domain Registry Interface, .SO policies
##
## Copyright (c) 2009-2011 Cloud Registry Pty Ltd <http://www.cloudregistry.net>. All rights reserved.
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

package Net::DRI::DRD::SO;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::SO - .SO policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>open@cloudregistry.netE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://soregistry.so/E<gt> and
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Wil Tan E<lt>wil@cloudregistry.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2009-2011 Cloud Registry Pty Ltd <http://www.cloudregistry.net>.
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

 bless($self,$class);
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'SO'; }
sub tlds          { return (qw/so com.so net.so org.so/); }
sub object_types  { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; } ## { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CloudRegistry',{})   if $type eq 'epp';
## return ('Net::DRI::Transport::Socket',{remote_host=>'whois.nic.so'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

####################################################################################################
1;
