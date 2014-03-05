## Domain Registry Interface, SIDN EPP Notifications
##
## Copyright (c) 2009,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SIDN::Notifications;

use strict;
use warnings;

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           review_sidn => [ undef, \&parse_sidn ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse_sidn
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $node=$mes->get_response('sidn','pollData');
 return unless defined $node;

 $oname='_unknown'; ## some messages carry back very little useful information !
 my $id=$mes->msg_id();
 my $nsepp=$mes->ns('_main');
 my %h=(action => 'review_sidn');
 my $cmd;
 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$n)=@$el;
  if ($name eq 'command')
  {
   $cmd=$n->textContent();
   ($otype)=($cmd=~m/^(\S+):/);
   $h{object_type}=$otype;
  } elsif ($name eq 'data')
  {
   foreach my $subel (Net::DRI::Util::xml_list_children($n))
   {
    my ($subname,$subnode)=@$subel;
    if ($subname eq 'result')
    {
     $h{result_code}=$subnode->getAttribute('code');
     $h{result_msg}=Net::DRI::Util::xml_child_content($subnode,$nsepp,'msg');
    } elsif ($subname eq 'resData')
    {
     if ($cmd eq 'domain:create')
     {
      $oname=Net::DRI::Util::xml_child_content($subnode,$nsepp,'name');
      $h{crDate}=$po->parse_iso8601(Net::DRI::Util::xml_child_content($subnode,$nsepp,'crDate'));
      $h{exist}=1;
     } elsif ($cmd eq 'domain:transfer-token-reminder')
     {
      $oname=reminder_parse($po,$subnode,$mes->ns('sidn'),\%h);
      $h{exist}=1;
     } elsif ($cmd eq 'domain:transfer-token-supply')
     {
      $oname=supply_parse($po,$subnode,$mes->ns('sidn'),\%h);
      $h{exist}=1;
     } elsif ($cmd eq 'domain:transfer' || $cmd eq 'domain:transfer-start')
     {
      $oname=transfer_parse($po,$subnode,$mes->ns('domain'),\%h);
      $h{exist}=1;
     }
    } elsif ($subname eq 'trID')
    {
     $h{trid}=Net::DRI::Util::xml_child_content($subnode,$nsepp,'clTRID');
     $h{svtrid}=Net::DRI::Util::xml_child_content($subnode,$nsepp,'svTRID');
    }
   }
  }
 }

 ## Do not know if all of this is the good way to do, as these notifications are very strangely formatted
 $cmd=~s/:/_/;
 $cmd=~s/-/_/g;
 $h{command}=$cmd;
 while(my ($k,$v)=each(%h))
 {
  $rinfo->{$otype}->{$oname}->{$k}=$v;
 }

 return;
}

sub transfer_parse
{
 my ($po,$trndata,$ns,$rh)=@_;
 $trndata=Net::DRI::Util::xml_traverse($trndata,$ns,'trnData');

 my $oname;
 ## The following is basically a copy from Core/Domain::transfer_parse !
 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rh->{$1}=$c->textContent();
  } elsif ($name=~m/^(reDate|acDate|exDate)$/)
  {
   $rh->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return $oname;
}

sub reminder_parse
{
 my ($po,$trndata,$ns,$rh)=@_;
 $trndata=Net::DRI::Util::xml_traverse($trndata,$ns,'trnData');

 my $oname;
 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'domainname')
  {
   $oname=lc($c->textContent());
  } elsif ($name eq 'requestor')
  {
   $rh->{requestor}=$c->textContent();
  } elsif ($name eq 'requestDate')
  {
   $rh->{request_date}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'supplyDate')
  {
   $rh->{supply_date}=$po->parse_iso8601($c->textContent());
  }
 }
 return $oname;
}

sub supply_parse
{
 my ($po,$trndata,$ns,$rh)=@_;
 $trndata=Net::DRI::Util::xml_traverse($trndata,$ns,'trnData');

 my $oname;
 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'domainname')
  {
   $oname=lc($c->textContent());
  } elsif ($name eq 'pw')
  {
   $rh->{token}=$c->textContent();
  } elsif ($name eq 'requestDate')
  {
   $rh->{request_date}=$po->parse_iso8601($c->textContent());
  }
 }
 return $oname;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SIDN::Notifications - SIDN (.NL) EPP Notifications for Net::DRI

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

Copyright (c) 2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
