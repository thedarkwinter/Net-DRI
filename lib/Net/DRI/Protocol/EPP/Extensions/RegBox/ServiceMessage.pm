## Domain Registry Interface, RegBox ServiceMessage EPP extension for ResData poll messages based on http://www.ietf.org/internet-drafts/draft-mayrhofer-eppext-servicemessage-00.txt
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::RegBox::ServiceMessage;

use strict;
use warnings;
use Net::DRI::Util;
use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::RegBox::ServiceMessage - Message extensions based on http://www.ietf.org/internet-drafts/draft-mayrhofer-eppext-servicemessage-00.txt

=head1 DESCRIPTION

Adds the ServiceMessage extension (http://tld-box.at/xmlns/resdata-1.0) for parsing poll messages.
 
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
 my %tmp=(
          retrieve => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 ## FIXME : the draft doc says 1.0 but i am seeing 1.1 in action ??
 $po->ns({ 'service_message' => [ 'http://tld-box.at/xmlns/resdata-1.1','resdata-1.1.xsd' ]});
 return;
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $msgid=$mes->msg_id();

 my $resdata=$mes->get_response($mes->ns('service_message'),'message');
 return unless defined $resdata;
 
 $rinfo->{message}->{$msgid}->{message_type} = $resdata->getAttribute('type') if $resdata->hasAttribute('type');
 my @entries;
 foreach my $el (Net::DRI::Util::xml_list_children($resdata))
 {
   my ($n,$c)=@$el;
   $rinfo->{message}->{$msgid}->{description} = $c->textContent() if ($n eq 'desc');
   if ($n eq 'reftrID') # TODO
   {
    
   } elsif ($n eq 'data') 
   {
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     if ($n2 eq 'entry') {
      push @entries, { 'key' => $c2->getAttribute('name'), 'value' => $c2->textContent() }; # FIXME, maybe just do ?? { $c2->getAttribute('name') => $c2->textContent() };
     }
    }
    $rinfo->{message}->{$msgid}->{entries} = \@entries;
   }
 }
 
 return;
}

####################################################################################################
1;
