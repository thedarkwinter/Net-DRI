## Domain Registry Interface, .UK EPP Notifications
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Notifications;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Notifications - .UK EPP Notifications for Net::DRI

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

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=( notification => [ undef, \&parse ] );
 return { 'message' => \%tmp };
}

####################################################################################################

# Contact::info_parse fails so we do a small parse here and create the contact object
sub parse_contact
{
 my ($po,$data,$ns,$rinfo) = @_;
 return unless $data;
 my $nsc=$po->message()->ns('contact');
 my $id = Net::DRI::Util::xml_child_content($data,$ns,'id');
 return unless $id;
 my $cont = $po->create_local_object('contact')->srid($id);
 my $pi = {};
 Net::DRI::Protocol::EPP::Core::Contact::parse_postalinfo($po,$data->getChildrenByTagNameNS($ns,'postalInfo')->shift(),$pi);
 foreach ($cont->attributes()) {
   next if $_ eq 'srid';
   $cont->$_(Net::DRI::Util::xml_child_content($data,$ns,$_));
   $cont->$_($pi->{$_}) if $pi->{$_};
 }
 return $cont;
}

sub parse_domainlist
{
 my ($po,$data,$ns,$rinfo) = @_;
 return unless $data;
 my @d;
 return unless my $dl = $data->getChildrenByTagNameNS($ns,'domainListData')->shift();
 foreach my $el (Net::DRI::Util::xml_list_children($dl))
 {
  my ($name,$c)=@$el;
  push @d,$c->textContent() if $name eq 'domainName';
 }
 return \@d;
}

sub parse_rcdomainlist
{
 my ($po,$data,$ns,$rinfo) = @_;
 return unless $data;
 my $mes = $po->message();
 my $nsd=$mes->ns('domain');
 return unless my $dl =$data->getChildrenByTagNameNS($ns,'domainListData')->shift();
 my (@d,$clid);
 foreach my $d ($dl->getChildrenByTagNameNS($nsd,'infData'))
 {
  push @d,Net::DRI::Util::xml_child_content($d,$nsd,'name');
  $clid=Net::DRI::Util::xml_child_content($d,$nsd,'clID');
  ## TODO : parse other keys, using Domain::info_parse stuff extracted into some sort of parse_infdata
 }
 return ($clid,\@d);
}

sub parse_hostlist
{
 my ($po,$data,$ns,$rinfo) = @_;
 return unless $data;
 my @h;
 return unless my $hl = $data->getChildrenByTagNameNS($ns,'hostListData')->shift();
 foreach my $el (Net::DRI::Util::xml_list_children($hl))
 {
  my ($name,$c)=@$el;
  next unless $name eq 'hostObj';
  my $ho = $c->textContent();
  $ho =~ s/\.$//; # remove trailing .
  push @h,$ho;
 }
 return \@h;
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $msgid=$oname=$mes->msg_id();
 return unless (defined($msgid) && $msgid);

 my ($n,$nsstr,$data);
 my %actions=(
               hosts_cancelled => { n=>'hostCancData' },
               contact_deleted => { n=>'contactDelData' },
               registrar_change => { n=> 'rcData'}, # also handshake_request, changed later
               registrant_change=> { n=> 'trnData'},
               registrant_change_auth_request => { n=> 'trnAuthData'}, # should probably be dealt with as a handshake_request, but no change of Tag
               domains_released => { n=> 'relData'}, # also handshake_rejected, changed later
               domains_suspended => { n=> 'suspData'},
               cancelled => { n=> 'cancData', ot=>'domain'},
               fail => { n=> 'domainFailData', ot=>'domain'},
               poor_quality => { n=> 'processData'},
               abuse => { n=> 'infData', ns=>'nom-abuse-feed'},
               #info => { n=> 'infData', ns =>'contact', ot => 'contact'},# this is processed correctly by contact::info_parse so dont need to do anything here
               #create => {n => 'creData', ns => 'domain', 'ot => 'domain'},  # this is processed correctly by domain::create_parse  so dont need to do anything here
           );

 while (my ($ac, $nd) = each(%actions))
 {
    $n = $nd->{n};
    $nsstr = ($nd->{ns})?$nd->{ns}:'std-notifications';
    $otype = ($nd->{ot}) ? ($nd->{ot}):'message';
    next unless ( ($data=$mes->get_response($nsstr,$n)) && (my $ns=$mes->ns($nsstr)));

    # abuse feed seems to come from an old Nominet EPP schema and has to be treated differently - this is likely to change some day
    if ($ac eq 'abuse')
    {
      $oaction =  $rinfo->{$otype}->{$oname}->{action}=$ac;
      foreach my $f (qw/key activity source hostname url date ip nameserver dnsAdmin target wholeDomain/)
      { $rinfo->{$otype}->{$oname}->{$f}=Net::DRI::Util::xml_child_content($data,$ns,$f); }
      return;
    }

    # set oname/exist for domain
    if ($otype eq 'domain')
    {
      $oname=Net::DRI::Util::xml_child_content($data,$ns,'domainName');
      $rinfo->{$otype}->{$oname}->{exist}=0;
    }

    # action
    $oaction =  $rinfo->{$otype}->{$oname}->{action}=$ac;

    # plain text fields
    $rinfo->{$otype}->{$oname}->{orig}=Net::DRI::Util::xml_child_content($data,$ns,'orig');
    $rinfo->{$otype}->{$oname}->{reason}=Net::DRI::Util::xml_child_content($data,$ns,'reason');
    $rinfo->{$otype}->{$oname}->{registrar_to}=Net::DRI::Util::xml_child_content($data,$ns,'registrarTag');
    $rinfo->{$otype}->{$oname}->{contact} = Net::DRI::Util::xml_child_content($data,$ns,'contactId');
    $rinfo->{$otype}->{$oname}->{account_from}=Net::DRI::Util::xml_child_content($data,$ns,'oldAccountId');
    $rinfo->{$otype}->{$oname}->{account_to}=Net::DRI::Util::xml_child_content($data,$ns,'accountId');
    $rinfo->{$otype}->{$oname}->{process_type} = Net::DRI::Util::xml_child_content($data,$ns,'processType');
    $rinfo->{$otype}->{$oname}->{poor_quality_stage}=$data->getAttribute('stage') if $data->hasAttribute('stage');
    $rinfo->{$otype}->{$oname}->{case_id}=Net::DRI::Util::xml_child_content($data,$ns,'caseId');


    # relData (release/handshake rejected has account data)
    if (($n eq 'relData') && (my $acid=$data->getChildrenByTagNameNS($ns,'accountId')->shift()))
    {
     $rinfo->{$otype}->{$oname}->{account_id}=$acid->textContent();
     $rinfo->{$otype}->{$oname}->{action}='handshake_rejected' unless $acid->hasAttribute('moved'); # NOT VERIFIED - but since we don't have the message content <msg> we cant determine the action here
     $rinfo->{$otype}->{$oname}->{account_moved}=$acid->getAttribute('moved') eq 'Y'? 1 : 0 if $acid->hasAttribute('moved');
     $rinfo->{$otype}->{$oname}->{registrar_from}=Net::DRI::Util::xml_child_content($data,$ns,'from');
    }

    # if casId then this is a handshake_request
    if ( ($n eq 'rcData') && ($data->getChildrenByTagNameNS($ns,'caseId')->size()) )
    {
     $rinfo->{$otype}->{$oname}->{action}='handshake_request';
     $rinfo->{$otype}->{$oname}->{case_id}=Net::DRI::Util::xml_child_content($data,$ns,'caseId');
    }
    # rcData return different data structures
    ($rinfo->{$otype}->{$oname}->{registrar_from},$rinfo->{$otype}->{$oname}->{domains}) = parse_rcdomainlist($po,$data,$ns,$rinfo) if ($n eq 'rcData');

    # domain / host lists
    $rinfo->{$otype}->{$oname}->{domains}=parse_domainlist($po,$data,$ns,$rinfo) unless ($n eq 'rcData');
    $rinfo->{$otype}->{$oname}->{hosts}=parse_hostlist($po,$data,$ns,$rinfo);

     # contact data
     my $nsc=$mes->ns('contact');
     if (my $cont=parse_contact($po,$data->getChildrenByTagNameNS($nsc,'infData')->shift(),$nsc,$rinfo))
     {
      $rinfo->{$otype}->{$oname}->{contact}=$cont->srid();
      $rinfo->{$otype}->{$oname}->{contact_data}=$cont if $n eq 'rcData';
      $rinfo->{message}->{$msgid}->{poor_quality_account}=$cont if $n eq 'processData';
     }

     # dates
     my $d;
     if ( ($d=$data->getChildrenByTagNameNS($ns,'cancelDate')) && ($d->size()) )
     {
       $rinfo->{$otype}->{$msgid}->{poor_quality_cancel}=$po->parse_iso8601($d->get_node(1)->textContent()) if $oaction eq 'poor_quality';
       $rinfo->{$otype}->{$msgid}->{cancel_date}=$po->parse_iso8601($d->get_node(1)->textContent());
     }
     if ( ($d=$data->getChildrenByTagNameNS($ns,'suspendDate')) && ($d->size()) )
     {
       $rinfo->{$otype}->{$msgid}->{poor_quality_suspend}=$po->parse_iso8601($d->get_node(1)->textContent());
     }

     # cleanup
     my %onames = %{$rinfo->{$otype}->{$oname}};
     foreach ( keys %onames)
     {
       delete $rinfo->{$otype}->{$oname}->{$_} unless defined $rinfo->{$otype}->{$oname}->{$_}; 
     }
 }
 return;
}


sub ammed_account
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('nom-abuse-feed','infData');
 return unless defined $infdata;
 return;
}

####################################################################################################
1;
