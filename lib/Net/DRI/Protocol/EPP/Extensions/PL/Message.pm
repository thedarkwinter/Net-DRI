## Domain Registry Interface, .PL Message EPP extension commands
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
## Copyright (c) 2008 Thorsten Glaser for Sygroup GmbH
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Message;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Message - .PL EPP Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/project/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>
Thorsten Glaser

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2008 Thorsten Glaser for Sygroup GmbH
Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
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
          notification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

# parse additional notifications not handled elsewhere, at the mo this is just doing extdom
sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_; 
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless my $msgid=$mes->msg_id();

 if (my $data=$mes->get_response('pl_domain','pollAuthInfo'))
 {
  $oaction = 'pollAuthInfo';
  $otype = 'domain';

  my $domain=$data->getFirstChild();
  foreach my $el (Net::DRI::Util::xml_list_children($domain))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $oname = $c->textContent();
    $rinfo->{$otype}->{$oname}->{name}=$oname;
    $rinfo->{$otype}->{$oname}->{exist}=1;
    $rinfo->{$otype}->{$oname}->{action}=$oaction;
   } elsif ($n eq 'authInfo')
   {
    foreach my $el2 (Net::DRI::Util::xml_list_children($c))
    {
     my ($n2,$c2)=@$el2;
     $rinfo->{$otype}->{$oname}->{auth} = {pw=>$c2->textContent()} if $n2 eq 'pw';
    }
   }
  }
 }

 return;
}

####################################################################################################
1;
