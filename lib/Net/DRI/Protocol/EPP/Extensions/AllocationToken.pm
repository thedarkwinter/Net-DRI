## Allocation Token Mapping for EPP (draft-gould-allocation-token-01)
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AllocationToken;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rd={ 'domain' => { check            => [ \&command, undef ],
                           check_multi      => [ \&command, undef ],
                           info             => [ \&command, \&info_parse ],
                           create           => [ \&command, undef ],
                           transfer_request => [ \&command, undef ],
                           update           => [ \&command, undef ],
                         },
           };

 return $rd;
}

sub setup
{
 my ($class,$po,$version)=@_;

 state $ns = { 'allocationToken' => [ 'urn:ietf:params:xml:ns:allocationToken-1.0','allocationToken-1.0.xsd' ] };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-gould-allocation-token-02'; }

####################################################################################################

sub command
{
 my ($epp,$domain,@rd)=@_;
 my $mes=$epp->message();
 my $operation=$mes->operation()->[1];
 my $rd=$rd[$operation eq 'update' ? 1 : 0];

 return unless Net::DRI::Util::has_key($rd,'allocation_token');
 my $token=$rd->{allocation_token};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for allocation token: '.$token) unless Net::DRI::Util::xml_is_token($token);

 if ($operation eq 'info')
 {
  return unless $rd->{allocation_token}; ## any true value will be enough for us here
  my $eid=$mes->command_extension_register('allocationToken','info');
 } else
 {
  my $eid=$mes->command_extension_register('allocationToken','allocationToken');
  $mes->command_extension($eid,$token);
 }
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('allocationToken','allocationToken');
 return unless defined $data;
 $rinfo->{domain}->{$oname}->{allocation_token}=$data->textContent();

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AllocationToken - EPP Allocation Token mapping (draft-gould-allocation-token-02) for Net::DRI

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

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
