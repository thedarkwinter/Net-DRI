## Domain Registry Interface, .SI Domain EPP extension commands
##
## Copyright (c) 2007,2008,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARNES::Domain;

use strict;
use warnings;
use feature 'state';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARNES::Domain - .SI EPP Domain extension commands for Net::DRI

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

Copyright (c) 2007,2008,2016 Patrick Mevzek <netdri@dotandco.com>.
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
 state $rcmds = { 'domain' => { 'info' => [ undef, \&info_parse ] } };
 return $rcmds;
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('dnssi','ext');
 return unless $infdata;

 $infdata=$infdata->getChildrenByTagName('dnssi:infData');
 return unless ($infdata && $infdata->size()==1);
 $infdata=$infdata->shift()->getChildrenByTagName('dnssi:domain');
 return unless ($infdata && $infdata->size()==1);
 $infdata=$infdata->pop();

 my $cs=$rinfo->{domain}->{$oname}->{status};
 foreach my $s (qw/pendingLegislativeReturn pendingLegislativeReturnQuarantine pendingQuarantine serverTransferRegistrantProhibited/)
 {
  if ( $infdata =~ /\"$s\"/ ) {
    $cs->add($s);
  }
 }

 return;
}

####################################################################################################
1;
