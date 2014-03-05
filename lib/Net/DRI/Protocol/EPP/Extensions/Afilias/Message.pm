## Domain Registry Interface, EPP Message for Afilias
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::Message;

use strict;
use warnings;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'message' => { 'result' => [ undef, \&parse ] } };
}

## Parse error message with a <value> node in the oxrs namespace to enhance what is reported back to application
sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my @r=$mes->results_extra_info();
 return unless @r;

 foreach my $r (@r)
 {
  foreach my $rinfo (@$r)
  {
   next unless $rinfo->{from} eq 'eppcom:value' && $rinfo->{type} eq 'rawxml' && $rinfo->{message}=~m!^<value xmlns:oxrs="urn:afilias:params:xml:ns:oxrs-1.[01]"><oxrs:xcp>(.+?)</oxrs:xcp></value>$!;
   $rinfo->{message}=$1;
   $rinfo->{from}='oxrs';
   $rinfo->{type}='text';
  }
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::Message - EPP Afilias Message for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
