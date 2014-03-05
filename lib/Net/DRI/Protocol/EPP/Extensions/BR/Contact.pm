## Domain Registry Interface, .BR Contact EPP extension commands
## draft-neves-epp-brorg-03.txt
##
## Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::BR::Contact;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::ContactSet;
use Net::DRI::Data::Contact::BR;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::BR::Contact - .BR EPP Contact extension commands for Net::DRI

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

Copyright (c) 2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          check => [ \&check, \&check_parse ],
          info   => [ \&info, \&info_parse ],
          create => [ \&create, undef ],
          update => [ \&update, undef ],
          review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:brorg="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('brorg')));
}

sub check
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'brorg:check');
 my @n;
 foreach my $c ((ref($contact) eq 'ARRAY')? @$contact : ($contact))
 {
  Net::DRI::Exception::usererr_invalid_parameters('contact must be Net::DRI::Data::Contact::BR object') unless Net::DRI::Util::isa_contact($c,'Net::DRI::Data::Contact::BR');
  my $orgid=$c->orgid();
  if (defined($orgid))
  {
   Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($orgid,1,30);
   push @n,['brorg:cd',['brorg:id',$c->srid()],['brorg:organization',$orgid]];
  } else
  {
   push @n,['brorg:cd',['brorg:id',$c->srid()]];
  }
 }
 $mes->command_extension($eid,\@n);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('brorg','chkData');
 return unless $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('brorg'),'ticketInfo'))
 {
  my $c=$cd->getFirstChild();
  my ($orgid,$ticket,$domain);
  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'organization')
   {
    $orgid=$c->getFirstChild()->getData();
   } elsif ($n eq 'ticketNumber')
   {
    $ticket=$c->getFirstChild()->getData();
   } elsif ($n eq 'domainName')
   {
    $domain=$c->getFirstChild()->getData();
   }
  } continue { $c=$c->getNextSibling(); }

  $rinfo->{orgid}->{$orgid}->{ticket}=$ticket;
  $rinfo->{orgid}->{$orgid}->{domain}=$domain;
  $rinfo->{domain}->{$domain}->{ticket}=$ticket;
  $rinfo->{domain}->{$domain}->{orgid}=$orgid;
 }
 return;
}

sub info
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters('contact must be Net::DRI::Data::Contact::BR object') unless Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::BR');
 my $orgid=$contact->orgid();
 return unless defined($orgid); ## to be able to create pure contacts
 Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($orgid,1,30);

 my $eid=build_command_extension($mes,$epp,'brorg:info');
 my @n=(['brorg:organization',$orgid]);
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('brorg','infData');
 return unless $infdata;

 my $id=(keys(%{$rinfo->{contact}}))[0];
 my $co=$rinfo->{contact}->{$id}->{self};
 my $cs=Net::DRI::Data::ContactSet->new();
 my ($orgid,@d);
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $n=$c->localname() || $c->nodeName();
  if ($n eq 'organization')
  {
   $orgid=$c->getFirstChild()->getData();
   $co->orgid($orgid);
   $rinfo->{contact}->{$id}->{orgid}=$orgid;
  } elsif ($n eq 'contact')
  {
   my $co=Net::DRI::Data::Contact::BR->new();
   $co->srid($c->getFirstChild()->getData());
   $co->orgid($orgid);
   my $type=$c->getAttribute('type');
   $co->type($type);
   $cs->add($co,$type);
  } elsif ($n eq 'responsible')
  {
   $co->responsible($c->getFirstChild()->getData());
  } elsif ($n eq 'proxy')
  {
   $co->proxy($c->getFirstChild()->getData());
  } elsif ($n eq 'domainName')
  {
   push @d,$c->getFirstChild()->getData();
  }
 } continue { $c=$c->getNextSibling(); }
 $co->associated_contacts($cs) unless $cs->is_empty();
 $co->associated_domains(\@d) if @d;
 return;
}

sub build_contacts
{
 my $cs=shift;
 my @n;
 foreach my $t (sort($cs->types()))
 {
  push @n,map { ['brorg:contact',$_->srid(),{'type'=>$t}] } ($cs->get($t));
 }
 return @n;
}

sub create
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters('contact must be Net::DRI::Data::Contact::BR object') unless Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::BR');
 my $orgid=$contact->orgid();
 return unless defined($orgid); ## to be able to create pure contacts
 Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($orgid,1,30);
 my $cs=$contact->associated_contacts();
 Net::DRI::Exception::usererr_invalid_parameters('associated_contacts must be a ContactSet object') unless Net::DRI::Util::isa_contactset($cs);
 Net::DRI::Exception::usererr_insufficient_parameters('associated_contacts must not be empty') if $cs->is_empty();

 my $eid=build_command_extension($mes,$epp,'brorg:create');
 my @n=(['brorg:organization',$orgid]);
 push @n,build_contacts($cs);
 push @n,['brorg:responsible',$contact->responsible()] if $contact->responsible();
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters('contact must be Net::DRI::Data::Contact::BR object') unless Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::BR');
 my $orgid=$contact->orgid();
 return unless defined($orgid); ## to be able to update pure contacts
 Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($orgid,1,30);

 my $cadd=$todo->add('associated_contacts');
 my $cdel=$todo->del('associated_contacts');
 Net::DRI::Exception::usererr_invalid_parameters('associated_contacts to add must be a ContactSet object') if (defined($cadd) && !Net::DRI::Util::isa_contactset($cadd));
 Net::DRI::Exception::usererr_invalid_parameters('associated_contacts to del must be a ContactSet object') if (defined($cdel) && !Net::DRI::Util::isa_contactset($cdel));

 my $resp=$todo->set('responsible');

 return unless (defined($cadd) || defined($cdel) || defined($resp));

 my @n=(['brorg:organization',$orgid]);
 push @n,['brorg:add',build_contacts($cadd)] if defined($cadd);
 push @n,['brorg:rem',build_contacts($cdel)] if defined($cdel);
 push @n,['brorg:chg',['brorg:responsible',Net::DRI::Util::isa_contact($resp,'Net::DRI::Data::Contact::BR')? $resp->responsible() : $resp]] if defined($resp);
 my $eid=build_command_extension($mes,$epp,'brorg:update');
 $mes->command_extension($eid,\@n);
 return;
}

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_extension('brorg','panData');
 return unless $pandata;

 my $c=$pandata->firstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $n=$c->localname() || $c->nodeName();
  next unless $n;
  if ($n eq 'organization')
  {
   $rinfo->{$otype}->{$oname}->{orgid}=$c->getFirstChild()->getData();
  } elsif ($n eq 'reason')
  {
   $rinfo->{$otype}->{$oname}->{reason}=$c->textContent(); ## this may be empty
   $rinfo->{$otype}->{$oname}->{reason_lang}=$c->getAttribute('lang') || 'en';
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

####################################################################################################
1;
