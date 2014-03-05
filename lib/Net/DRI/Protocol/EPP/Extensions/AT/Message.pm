## Domain Registry Interface, nic.at domain transactions extension
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
## Extended by Tonnerre Lombard
##
## Copyright (c) 2006-2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Message;

use strict;
use warnings;

use Net::DRI::Exception;

our $NS='http://www.nic.at/xsd/at-ext-message-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Message - NIC.AT Message EPP Mapping for Net::DRI

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

Copyright (c) 2006-2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           atretrieve => [ \&pollreq, \&parse_poll ],
           atdelete   => [ \&pollack, undef ],
         );

 return { 'message' => \%tmp };
}

sub pollack
{
 my ($epp,$msgid)=@_;
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'ack',msgID=>$msgid}]]);
 return;
}

sub pollreq
{
 my ($epp,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In EPP, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'req'}]]);
 return;
}


## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $eppNS = $mes->ns('_main');
 my $resNS = 'http://www.nic.at/xsd/at-ext-result-1.0';

 return unless $mes->is_success();
 return if $mes->result_is('COMMAND_SUCCESSFUL_QUEUE_EMPTY');

 my $msgid=$mes->msg_id();
 $rinfo->{message}->{session}->{last_id}=$msgid;

 my $mesdata=$mes->get_response($NS,'message');
 $rinfo->{$otype}->{$oname}->{message}=$mesdata;
 return unless $mesdata;

 my ($epp,$rep,$ext,$ctag,@conds,@tags);
 my $command=$mesdata->getAttribute('type');
 @tags = $mesdata->getElementsByTagNameNS($NS, 'desc');

 $rinfo->{message}->{$msgid}->{content} = $tags[0]->getFirstChild()->getData() if @tags;
 @tags = $mesdata->getElementsByTagNameNS($NS, 'data');
 return unless @tags;

 my $data = $tags[0];
 @tags = $data->getElementsByTagNameNS($NS, 'entry');

 foreach my $entry (@tags)
 {
  next unless (defined($entry->getAttribute('name')));

  if ($entry->getAttribute('name') eq 'objecttype')
  {
   $rinfo->{message}->{$msgid}->{object_type} = $entry->getFirstChild()->getData();
  }
  elsif ($entry->getAttribute('name') eq 'command')
  {
   $rinfo->{message}->{$msgid}->{action} = $entry->getFirstChild()->getData();
  }
  elsif ($entry->getAttribute('name') eq 'objectname')
  {
   $rinfo->{message}->{$msgid}->{object_id} = $entry->getFirstChild()->getData();
  }
  elsif ($entry->getAttribute('name') =~ /^(domain|contact|host)$/)
  {
   my $text = $entry->getFirstChild();
   $rinfo->{message}->{$msgid}->{object_type}=$1;
   $rinfo->{message}->{$msgid}->{object_id} = $text->getData() if (defined($text));
  }
 }

 $rinfo->{message}->{$msgid}->{action} ||= $command;
 @tags = $data->getElementsByTagNameNS($eppNS, 'epp');
 return unless (@tags);
 $epp = $tags[0];

 @tags = $epp->getElementsByTagNameNS($eppNS, 'response');
 return unless (@tags);
 $rep = $tags[0];

 @tags = $rep->getElementsByTagNameNS($eppNS, 'extension');
 return unless (@tags);
 $ext = $tags[0];

 foreach my $node ($ext->childNodes())
 {
  my $name = $node->localName() || $node->nodeName();
   
  if ($name eq 'conditions')
  {
   @tags = $node->getElementsByTagNameNS($resNS, 'condition');

   foreach my $cond (@tags)
   {
    my %con;
    my $c = $cond->getFirstChild();

    $con{code} = $cond->getAttribute('code') if ($cond->getAttribute('code'));
    $con{severity} = $cond->getAttribute('severity') if ($cond->getAttribute('severity'));

    while ($c)
    {
     next unless ($c->nodeType() == 1); ## only for element nodes
     my $cname = $c->localname() || $c->nodeName();
     next unless $cname;
  
     if ($cname =~ m/^(msg|details)$/)
     {
      $con{$1} = $c->getFirstChild()->getData();
     }
     elsif ($cname eq 'attributes')
     {
      foreach my $attr ($c->getChildrenByTagNameNS($NS,'attr'))
      {
       my $attrname = $attr->getAttribute('name');
       $con{'attr ' . $attrname} = $attr->getFirstChild()->getData();
      }
     }
    } continue { $c = $c->getNextSibling(); }

    push(@conds, \%con);
   }
  }
  elsif ($name eq 'keydate')
  {
   $rinfo->{message}->{$msgid}->{keydate} = $node->getFirstChild()->getData();
  }
 }

 $rinfo->{message}->{$msgid}->{conditions} = \@conds;
 return;
}

####################################################################################################
1;
