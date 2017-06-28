## Domain Registry Interface, VeriSign Naming Registry Driver for .COM .NET
##
## Copyright (c) 2005-2013,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::VeriSign::COM_NET;

use strict;
use warnings;

use base qw/Net::DRI::DRD::VeriSign::VeriSign/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::VeriSign::COM_NET - VeriSign .COM/.NET Registry driver for Net::DRI

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

Copyright (c) 2005-2013,2016 Patrick Mevzek <netdri@dotandco.com>.
Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->{info}->{check_limit}=13;
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'VeriSign::COM_NET'; }
sub tlds          { return qw/com net/; }
sub object_types  { return qw/domain ns registry/; }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::RRP',{}) if $type eq 'rrp'; ## this is used only for internal tests
 return ('Net::DRI::Transport::Socket',{remote_host=>'epp-ote.verisign-grs.com', remote_port=>700},'Net::DRI::Protocol::EPP::Extensions::VeriSign::Platforms::COM_NET',{}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.verisign-grs.com'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

####################################################################################################

1;
