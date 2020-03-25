## Domain Registry Interface, EPP ARI Extended Availalability Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail - Extended Availalability Extension for ARI : L<http://ausregistry.github.io/doc/exAvail-1.0/exAvail-1.0.html>

=head1 DESCRIPTION

Adds the Extended Availalability Extension (urn:ar:params:xml:ns:exAvail-1.0) to domain commands. The extension is built by by setting a true value to the ex_avail flag in a check command. This information is returned instead of the standard information of a check command.

=item ex_avail 

 eg. 
 $rc = $dri->domain_check('domain.tld',{... ex_avail => 1} );
 
=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 my %tmp=(check=> [ \&check, \&check_parse ]);
 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'exAvail' => 'urn:ar:params:xml:ns:exAvail-1.0' });
 return;
}

####################################################################################################

sub check
{
 my ($epp,$domain,$rd)=@_;
 return unless (Net::DRI::Util::has_key($rd,'ex_avail') && $rd->{'ex_avail'});
 $epp->message()->command_extension('exAvail', ['check']);

 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $chkdata=$mes->get_extension('exAvail','chkData');
 return unless defined $chkdata;
 
 foreach my $el (Net::DRI::Util::xml_list_children($chkdata))
 {
   my ($n,$c)=@$el;
   if ($n eq 'cd')
   {
    my $dn = '';
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     $dn = $c2->textContent() if $n2 eq 'name';
     $rinfo->{domain}->{$dn}->{action}='check';
     if ($n2 eq 'state') {
      $rinfo->{domain}->{$dn}->{ex_avail}->{state} = $c2->getAttribute('s');
      $rinfo->{domain}->{$dn}->{exist}= ($c2->getAttribute('s') eq 'available')?0:1;
       foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
      {
       my ($n3,$c3)=@$el3;
       $rinfo->{domain}->{$dn}->{ex_avail}->{Net::DRI::Util::xml2perl($n3)} = $c3->textContent() if $n3 =~ m/^(reason|phase|primaryDomainName)$/;
       $rinfo->{domain}->{$dn}->{ex_avail}->{date} = $po->parse_iso8601($c3->textContent()) if $n3 eq 'date';
      }
     }
    }
   }
 }
  return;
}

####################################################################################################
1;
