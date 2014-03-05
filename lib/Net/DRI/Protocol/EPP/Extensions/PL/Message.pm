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
          plretrieve => [ \&poll, \&parse_poll ]
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub poll
{
 my ($epp,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In EPP, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'req'}]]);
 return;
}

sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my ($epp,$rep,$ext,$ctag,@conds,@tags);
 my $mes=$po->message();
 my $msgid=$mes->msg_id();
 my $domname;
 my $domauth;
 my $action;

 return unless $mes->is_success();
 return if $mes->result_is('COMMAND_SUCCESSFUL_QUEUE_EMPTY');
 return unless (defined($msgid) && $msgid);

 my $mesdata = $mes->node_resdata();
 return unless ($mesdata);

 $rinfo->{message}->{session}->{last_id}=$msgid;

 foreach my $cnode ($mesdata->childNodes) {
  my $cmdname = $cnode->localName || $cnode->nodeName;

  if ($cmdname eq 'pollAuthInfo') {
   my $ra = $rinfo->{message}->{$msgid}->{extra_info};
   push @{$ra}, $cnode->toString(); ### ???
   $action = 'pollAuthInfo';

   foreach my $cnode ($cnode->childNodes) {
    my $objname = $cnode->localName || $cnode->nodeName;

    if ($objname eq 'domain') {
     $otype = 'domain';

     foreach my $cnode ($cnode->childNodes) {
      my $infname = $cnode->localName || $cnode->nodeName;

      if ($infname eq 'name') {
       $domname = $cnode->getFirstChild()->getData();
      } elsif ($infname eq 'authInfo') {
       $domauth = $cnode;
      }
     }
    }
   }
  } else {
   # copied from Net/DRI/Protocol/EPP/Core/Domain.pm:transfer_parse
   my $trndata=$mes->get_response('domain','trnData');
   if ($trndata) {
    my $pd=DateTime::Format::ISO8601->new();
    my $c=$trndata->getFirstChild();
    while ($c) {
     next unless ($c->nodeType() == 1); ## only for element nodes
     my $name=$c->localname() || $c->nodeName();
     next unless $name;

     if ($name eq 'name') {
      $domname = lc($c->getFirstChild()->getData());
      $action = 'transfer';
     } elsif ($name=~m/^(trStatus|reID|acID)$/) {
      my $fc = $c->getFirstChild();
      $rinfo->{domain}->{$domname}->{$1}=$fc->getData() if (defined($fc));
     } elsif ($name=~m/^(reDate|acDate|exDate)$/) {
      $rinfo->{domain}->{$domname}->{$1}=$pd->parse_datetime($c->getFirstChild()->getData());
     }
    } continue { $c=$c->getNextSibling(); }
   }
  }
 }
 if (defined ($domname)) {
  $otype = 'domain';
  $oname = $domname;
  $rinfo->{domain}->{$domname}->{name} = $domname;
  $rinfo->{domain}->{$domname}->{exist} = 1;
  $rinfo->{message}->{$msgid}->{object_id} = $domname;
  if (defined ($domauth)) {
   my $c = $domauth->getFirstChild();

   while ($c)
   {
    my $typename;
    next unless ($c->nodeType == 1);	## only for element nodes
    $typename = $c->localName || $c->nodeName;
    $rinfo->{domain}->{$domname}->{auth} = {
     $typename => $c->getFirstChild()->getData()
    };
   } continue { $c = $c->getNextSibling(); }
  }
 }
 if (defined ($action)) {
  $rinfo->{message}->{$msgid}->{action} = $action;
  if (defined ($domname)) {
   $rinfo->{domain}->{$oname}->{action} = $action;
  }
 }
 $rinfo->{message}->{$msgid}->{object_type} = $otype;
 $rinfo->{$otype}->{$oname}->{message}=$mesdata;
 return;
}

####################################################################################################
1;
