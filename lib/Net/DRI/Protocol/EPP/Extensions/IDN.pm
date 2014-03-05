## Domain Registry Interface, EPP IDN (draft-obispo-epp-idn-02)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::IDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef         , \&info_parse ],
           create => [ \&create_build, undef ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'idn' => [ 'urn:ietf:params:xml:ns:idn-1.0','idn-1.0.xsd' ],
         });
 return;
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('idn','data');
 return unless defined $data;

 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'table')
  {
   $rinfo->{domain}->{$oname}->{idn_table}=$node->textContent();
  } elsif ($name eq 'uname')
  {
   $rinfo->{domain}->{$oname}->{uname}=$node->textContent(); ## domain name in unicode NFC form
  }
 }

 return;
}

sub create_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'idn_table') && Net::DRI::Util::has_key($rd,'uname');

 Net::DRI::Exception::usererr_invalid_parameters('idn_table must be of type XML schema token with at least 1 character') unless Net::DRI::Util::xml_is_token($rd->{idn_table},1);
 Net::DRI::Exception::usererr_invalid_parameters('uname must be of type XML schema token from 1 to 255 characters') unless Net::DRI::Util::xml_is_token($rd->{uname},1,255);

 my $eid=$mes->command_extension_register('idn','data');
 $mes->command_extension($eid,[['idn:table',$rd->{idn_table}],['idn:uname',$rd->{uname}]]);

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IDN - EPP IDN commands (draft-obispo-epp-idn-02) for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

