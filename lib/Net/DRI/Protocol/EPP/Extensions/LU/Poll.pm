## Domain Registry Interface, EPP DNS-LU Poll extensions
##
## Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU::Poll;

use strict;
use warnings;

use Net::DRI::Util;
use DateTime::Format::ISO8601;


=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU::Poll - EPP DNS-LU Poll extensions (DocRegistrar-2.0.6.pdf pages 35-37) for Net::DRI

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

Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           dnslu => [ undef, \&parse ],
         );
 return { 'message' => \%tmp };
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->node_msg();
 return unless $infdata;

 my (%w,%ns,%e);

 # something very wrong is happening. Even if the test file work with legacy code while
 # testing on OT&E can't get any of <dnslu:pollmsg> elements - problem related with type attribute!
 # this solve the problem!
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   $w{action} = 'dnslu_notification';
   $w{type} = $c->getAttribute("type") if $c->getAttribute("type"); ## list of types p.36
   if ($n && $n eq 'pollmsg') {
     foreach my $el_pollmsg (Net::DRI::Util::xml_list_children($c)) {
       my ($n_pollmsg,$c_pollmsg)=@$el_pollmsg;
       if ($n_pollmsg=~m/^(roid|object|clTRID|svTRID|reason)$/) {
         $w{$n_pollmsg}=$c_pollmsg->textContent() if $c_pollmsg->textContent();
       } elsif ($n_pollmsg eq 'exDate') {
         $w{$n_pollmsg}=DateTime::Format::ISO8601->new()->parse_datetime($c_pollmsg->textContent()) if $c_pollmsg->textContent();
       } elsif ($n_pollmsg eq 'ns') {
         $ns{$c_pollmsg->getAttribute("name")}=$c_pollmsg->textContent() if $c_pollmsg->textContent() && $c_pollmsg->getAttribute("name");
       } elsif ($n_pollmsg eq 'extra') {
         $e{$c_pollmsg->getAttribute("name")}=$c_pollmsg->textContent() if $c_pollmsg->textContent() && $c_pollmsg->getAttribute("name");
       }
     }
   }
 }

 $w{ns}=\%ns if %ns;
 $w{extra}=\%e if %e;

 $rinfo->{session}->{notification}=\%w;
 return;
}

####################################################################################################
1;
