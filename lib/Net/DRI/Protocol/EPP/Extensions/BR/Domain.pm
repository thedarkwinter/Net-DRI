## Domain Registry Interface, .BR Domain EPP extension commands
## draft-neves-epp-brdomain-03.txt
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

package Net::DRI::Protocol::EPP::Extensions::BR::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::BR::Domain - .BR EPP Domain extension commands for Net::DRI

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
          create => [ \&create, \&create_parse ],
          renew => [ undef, \&renew_parse ],
          update => [ \&update, \&update_parse ],
          review_complete => [ undef, \&pandata_parse ], ## needs to have same name for key as in Core/Domain to make sure this will be called after Core parsing !
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:brdomain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('brdomain')));
}

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'orgid');
 Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($rd->{orgid},1,30);

 my $eid=build_command_extension($mes,$epp,'brdomain:check');
 my @n=('brdomain:organization',$rd->{orgid});
 $mes->command_extension($eid,\@n);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('brdomain','chkData');
 return unless $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('brdomain'),'cd'))
 {
  my $hc=$cd->getAttribute('hasConcurrent');
  my $irp=$cd->getAttribute('inReleaseProcess');
  my $c=$cd->getFirstChild();
  my $domain;
  my @tn;
  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $domain=lc($c->getFirstChild()->getData());
    $rinfo->{domain}->{$domain}->{has_concurrent}=Net::DRI::Util::xml_parse_boolean($hc) if defined($hc);
    $rinfo->{domain}->{$domain}->{in_release_process}=Net::DRI::Util::xml_parse_boolean($irp) if defined($irp);
   } elsif ($n eq 'equivalentName')
   {
    $rinfo->{domain}->{$domain}->{equivalent_name}=$c->getFirstChild()->getData();
   } elsif ($n eq 'organization')
   {
    $rinfo->{domain}->{$domain}->{orgid}=$c->getFirstChild()->getData();
   } elsif ($n eq 'ticketNumber')
   {
    push @tn,$c->getFirstChild()->getData();
   }
  } continue { $c=$c->getNextSibling(); }
  $rinfo->{domain}->{$domain}->{ticket}=\@tn;
 }
 return;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'ticket');
 Net::DRI::Exception::usererr_invalid_parameters('ticket parameter must be an integer') unless Net::DRI::Util::isint($rd->{ticket});

 my $eid=build_command_extension($mes,$epp,'brdomain:info');
 my @n=('brdomain:ticketNumber',$rd->{ticket});
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('brdomain','infData');
 return unless $infdata;
 parse_extra_data($po,$oname,$rinfo,$mes,$infdata);
 return;
}

sub parse_extra_data
{
 my ($po,$oname,$rinfo,$mes,$c)=@_;
 my $ns=$mes->ns('brdomain');
 $c=$c->getFirstChild();
 my @tnc;
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $n=$c->localname() || $c->nodeName();
  if ($n eq 'ticketNumber')
  {
   $rinfo->{domain}->{$oname}->{ticket}=$c->getFirstChild()->getData();
  } elsif ($n eq 'organization')
  {
   $rinfo->{domain}->{$oname}->{orgid}=$c->getFirstChild()->getData();
  } elsif ($n eq 'releaseProcessFlags')
  {
   my %f;
   foreach my $f (1..3)
   {
    next unless $c->hasAttribute('flag'.$f);
    $f{'flag'.$f}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('flag'.$f));
   }
   $rinfo->{domain}->{$oname}->{release_process}=\%f;
  } elsif ($n eq 'pending')
  {
   my $cc=$c->getFirstChild();
   my %p;
   my $pd=DateTime::Format::ISO8601->new();
   while($cc)
   {
    next unless ($cc->nodeType() == 1);
    my $nn=$cc->localName() || $c->nodeName();
    if ($nn eq 'doc')
    {
     my $d=$cc->getChildrenByTagNameNS($ns,'description')->shift();
     push @{$p{doc}}, { status => $cc->getAttribute('status'),
                        type   => $cc->getChildrenByTagNameNS($ns,'docType')->shift()->getFirstChild()->getData(),
                        limit  => $pd->parse_datetime($cc->getChildrenByTagNameNS($ns,'limit')->shift()->getFirstChild()->getData()),
                        description => $d->getFirstChild()->getData(),
                        lang => $d->getAttribute('lang'),
                      };
    } elsif ($nn eq 'dns')
    {
     push @{$p{dns}},{ status   => $cc->getAttribute('status'),
                       hostname => $cc->getChildrenByTagNameNS($ns,'hostName')->shift()->getFirstChild()->getData(),
                       limit    => $pd->parse_datetime($cc->getChildrenByTagNameNS($ns,'limit')->shift()->getFirstChild()->getData()),
                     };
    } elsif ($nn eq 'releaseProc')
    {
     $p{release}={ status => $cc->getAttribute('status'), 
                   limit  => $pd->parse_datetime($cc->getChildrenByTagNameNS($ns,'limit')->shift()->getFirstChild()->getData()),
                 };
    }
   } continue { $cc=$cc->getNextSibling(); }
   $rinfo->{domain}->{$oname}->{pending}=\%p;
  } elsif ($n eq 'ticketNumberConc')
  {
   push @tnc,$c->getFirstChild()->getData();
  } elsif ($n eq 'publicationStatus')
  {
   $rinfo->{domain}->{$oname}->{publication}=parse_publication($ns,$c);
  } elsif ($n eq 'autoRenew')
  {
   $rinfo->{domain}->{$oname}->{auto_renew}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('active'));
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ticket_concurrent}=\@tnc;
 return;
}

sub parse_publication
{
 my ($ns,$c)=@_;
 my %s;
 $s{flag}=$c->getAttribute('publicationFlag');
 foreach my $r ($c->getChildrenByTagNameNS($ns,'onHoldReason'))
 {
  push @{$s{onhold_reason}},$r->getFirstChild()->getData();
 }
 return \%s;
}

sub build_release
{
 my $rh=shift;
 my %f=map { $_ => (defined($rh->{$_}) && $rh->{$_})? 1 : 0 } grep { exists($rh->{$_}) } qw/flag1 flag2 flag3/;
 return keys(%f)? ['brdomain:releaseProcessFlags',\%f] : ();
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('orgid is mandatory for domain_create') unless Net::DRI::Util::has_key($rd,'orgid');
 Net::DRI::Exception::usererr_invalid_parameters('orgid must be an xml token string with 1 to 30 characters') unless Net::DRI::Util::xml_is_token($rd->{orgid},1,30);

 my @n=(['brdomain:organization',$rd->{orgid}]);
 push @n,build_release($rd->{release}) if (Net::DRI::Util::has_key($rd,'release') && (ref($rd->{release}) eq 'HASH'));
 push @n,['brdomain:autoRenew',{active => $rd->{auto_renew}? 1 : 0 }] if (Net::DRI::Util::has_key($rd,'auto_renew'));

 my $eid=build_command_extension($mes,$epp,'brdomain:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_extension('brdomain','creData');
 return unless $credata;
 parse_extra_data($po,$oname,$rinfo,$mes,$credata);
 return;
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_extension('brdomain','renData');
 return unless $rendata;
 my $ns=$mes->ns('brdomain');
 my $pub=$rendata->getChildrenByTagNameNS($ns,'publicationStatus');
 return unless $pub->size();

 $rinfo->{domain}->{$oname}->{publication}=parse_publication($ns,$pub->shift());
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $ticket=$todo->set('ticket');
 my $release=$todo->set('release');
 my $autorenew=$todo->set('auto_renew');

 return unless (defined($ticket) || defined($release) || defined($autorenew));

 my @n;
 push @n,['brdomain:ticketNumber',$ticket] if (defined($ticket) && Net::DRI::Util::isint($ticket));
 my @c;
 push @c,build_release($release) if (defined($release) && (ref($release) eq 'HASH'));
 push @c,['brdomain:autoRenew',{active => $autorenew? 1 : 0}] if defined($autorenew);
 push @n,['brdomain:chg',@c] if @c;

 return unless @n;
 my $eid=build_command_extension($mes,$epp,'brdomain:update');
 $mes->command_extension($eid,\@n);
 return;
}

sub update_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $upddata=$mes->get_extension('brdomain','updData');
 return unless $upddata;
 parse_extra_data($po,$oname,$rinfo,$mes,$upddata);
 return;
}

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_extension('brdomain','panData');
 return unless $pandata;

 my $c=$pandata->firstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $n=$c->localname() || $c->nodeName();
  next unless $n;
  if ($n eq 'ticketNumber')
  {
   $rinfo->{$otype}->{$oname}->{ticket}=$c->getFirstChild()->getData();
  } elsif ($n eq 'reason')
  {
   $rinfo->{$otype}->{$oname}->{reason}=$c->getFirstChild()->getData();
   $rinfo->{$otype}->{$oname}->{reason_lang}=$c->getAttribute('lang') || 'en';
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

####################################################################################################
1;
