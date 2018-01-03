## Domain Registry Interface, FICORA - .FI EPP Balance Extension
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::FICORA::Balance;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FICORA::Balance- Balance Extension for FI TLD registrar balance request.

=head1 DESCRIPTION

 # registrar_balance
 $rc = $dri->registrar_balance();
 print $dri->get_info('balanceamount');
 print $dri->get_info('timestamp');

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>;

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>.
(c) 2017 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           balance => [ \&info, \&info_parse],
        );
 return { 'registrar' => \%tmp };
}


####################################################################################################

sub info
{
 my ($epp,$domain,$rd,$cmd)=@_;
 my $mes=$epp->message();
 $mes->command(['check']);
 my @d = 'balance';
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->node_resdata();
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($name,$content)=@$el;
   $rinfo->{registrar}->{$oname}->{$name} = $content->textContent() if $name=~m/^(balanceamount|timestamp)$/;
 }
 return;
}

1;
