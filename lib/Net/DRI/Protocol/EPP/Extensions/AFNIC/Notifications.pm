## Domain Registry Interface, AFNIC EPP Notifications
##
## Copyright (c) 2008-2010,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications - AFNIC (.FR/.RE/.TF/.WF/.PM/.YT) EPP Notifications for Net::DRI

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

Copyright (c) 2008-2010,2012 Patrick Mevzek <netdri@dotandco.com>.
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
           review_zonecheck      => [ undef, \&parse_zonecheck ],
           review_identification => [ undef, \&parse_identification ],
           review_qualification  => [ undef, \&parse_qualification ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse_zonecheck
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless $mes->node_msg(); ## this is the <msg> node in the EPP header

 ## For now there is no namespace
 #my $zc=$mes->node_msg()->getChildrenByTagNameNS($mes->ns('frnic'),'resZC');
 my $zc=$mes->node_msg()->getChildrenByTagName('resZC');
 return unless $zc->size();
 $zc=$zc->shift();
 return unless ($zc->getAttribute('type') eq 'plain-text'); ## we do not know what to do with other types

 $rinfo->{domain}->{$oname}->{review_zonecheck}=$zc->textContent(); ## a blob for now
 $rinfo->{domain}->{$oname}->{action}='review_zonecheck';
 $rinfo->{domain}->{$oname}->{exist}=1;

 return;
}

sub parse_identification
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $idt=$mes->get_extension('frnic','ext');
 return unless defined $idt;

 my $ns=$mes->ns('frnic');
 $idt=Net::DRI::Util::xml_traverse($idt,$ns,'resData','idtData');
 return unless defined $idt;

 my $c=Net::DRI::Util::xml_traverse($idt,$ns,'domain');
 return unless defined $c;

 $oname=lc Net::DRI::Util::xml_child_content($c,$ns,'name');
 $rinfo->{domain}->{$oname}->{action}='review_identification';
 $rinfo->{domain}->{$oname}->{exist}=1;
 $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(Net::DRI::Protocol::EPP::Util::parse_node_status(Net::DRI::Util::xml_traverse($c,$ns,'status')));
 $rinfo->{domain}->{$oname}->{contact}=$po->create_local_object('contactset')->set($po->create_local_object('contact')->srid(Net::DRI::Util::xml_child_content($c,$ns,'registrant')),'registrant');

 return;
}

sub parse_qualification
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $qua=$mes->get_extension('frnic','ext');
 return unless defined $qua;

 my $ns=$mes->ns('frnic');
 $qua=Net::DRI::Util::xml_traverse($qua,$ns,'resData','quaData');
 return unless defined $qua;

 my $c=Net::DRI::Util::xml_traverse($qua,$ns,'contact');
 return unless defined $c;

 my ($co,@reasons);
 my %q;
 foreach my $el (Net::DRI::Util::xml_list_children($c))
 {
  my ($name,$node)=@$el;
  if ($name eq 'id')
  {
   $oname=$node->textContent();
   $rinfo->{contact}->{$oname}->{action}='review_qualification';
   $rinfo->{contact}->{$oname}->{exist}=1;
   $co=$po->create_local_object('contact')->srid($oname);
   $rinfo->{contact}->{$oname}->{self}=$co;
  } elsif ($name eq 'qualificationProcess')
  {
   $rinfo->{contact}->{$oname}->{qualification_process_status}=$q{'process_status'}=$node->getAttribute('s');
  } elsif ($name eq 'legalEntityInfos')
  {
   Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact::parse_legalentityinfos($po,$otype,$oaction,$oname,$rinfo,$node,$co,$mes,\%q);
  } elsif ($name eq 'individualInfos')
  {
   Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact::parse_individualinfos($po,$otype,$oaction,$oname,$rinfo,$node,$co,$mes,\%q);
  } elsif ($name eq 'reachability')
  {
   my %r;
   $r{status}=Net::DRI::Util::xml_child_content($node,$ns,'reStatus');
   foreach my $v (qw/voice email/)
   {
    my $tmp=Net::DRI::Util::xml_child_content($node,$ns,$v);
    next unless defined $tmp;
    $r{$v}=$tmp;
   }
   $q{reachable}=\%r;
  }
 }
 $co->qualification(\%q);

 return;
}

####################################################################################################
1;
