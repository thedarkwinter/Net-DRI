## Domain Registry Interface, .PL EPP Report extension commands
##
## Copyright (c) 2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Report;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'report' => { create => [ \&create, \&create_parse ] } };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'extreport' => [ 'urn:ietf:params:xml:ns:extreport-1.0','extreport-1.0.xsd' ] });
 return;
}

####################################################################################################

sub create
{
 my ($epp,$id,$rp)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('An ID must be provided to track this report results') unless defined $id && length $id;
 Net::DRI::Exception::usererr_insufficient_parameters('An hash ref must be provided with at least a type key') unless Net::DRI::Util::has_key($rp,'type');
 Net::DRI::Exception::usererr_invalid_parameters('Type value must be domain,contact,host,future,payment or funds') unless $rp->{type}=~m/^(?:domain|contact|host|future|payment|funds)$/;

 my @n;
 if ($rp->{type} eq 'domain')
 {
  push @n,['extreport:domain',_create_domain($rp)];
 } elsif ($rp->{type} eq 'contact')
 {
  push @n,['extreport:contact',_create_contact($rp)];
 } elsif ($rp->{type} eq 'host')
 {
  push @n,['extreport:host',_create_host($rp)];
 } elsif ($rp->{type} eq 'future')
 {
  push @n,['extreport:future',_create_future($rp)];
 } elsif ($rp->{type} eq 'payment')
 {
  push @n,['extreport:prepaid',['extreport:payment',_create_payment($rp)]];
 } elsif ($rp->{type} eq 'funds')
 {
  push @n,['extreport:prepaid',['extreport:paymentFunds',_create_payment($rp)]];
 }

 push @n,['extreport:offset',$rp->{offset}] if Net::DRI::Util::has_key($rp,'offset') && $rp->{offset}=~m/^\d+$/;
 push @n,['extreport:limit',$rp->{limit}]   if Net::DRI::Util::has_key($rp,'limit')  && $rp->{limit}=~m/^\d+$/;

 my $eid=$mes->command_extension_register('extreport','report');
 $mes->command_extension($eid,\@n);
 return;
}

sub _create_domain
{
 my ($rp)=@_;
 my @n;
 if (Net::DRI::Util::has_key($rp,'state'))
 {
  my $state=$rp->{state};
  Net::DRI::Exception::usererr_invalid_parameters('Domain state must be from list of registry states') unless $state=~m/^(?:STATE_)?(?:REGISTERED|EXPIRED|BLOCKED|RESERVED|BOOK_BLOCKED|DELETE_BLOCKED|TASTED|TASTED_BLOCKED)$/i;
  $state=uc $state;
  $state='STATE_'.$state unless $state=~m/^STATE_/;
  push @n,['extreport:state',$state];
 }
 if (Net::DRI::Util::has_key($rp,'exDate'))
 {
  my $date=$rp->{exDate};
  $date=Net::DRI::Util::dto2zstring($date) if Net::DRI::Util::is_class($date,'DateTime');
  Net::DRI::Exception::usererr_invalid_parameters('exDate must be in ISO8601 format') unless $date=~m/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?$/;
  $date.='Z' unless $date=~m/Z$/;
  push @n,['extreport:exDate',$date];
 }
 if (Net::DRI::Util::has_key($rp,'status'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('status must be a StatusList object') unless Net::DRI::Util::is_class($rp->{status},'Net::DRI::Data::StatusList');
  my %s;
  if (Net::DRI::Util::has_key($rp,'status_in'))
  {
   $s{statusesIn}=$rp->{status_in} ? 'true' : 'false';
  }
  push @n,['extreport:statuses',\%s,map { ['extreport:status',$_] } $rp->{status}->list_status()];
 }
 return @n;
}

sub _create_contact
{
 my ($rp)=@_;
 my @n;
 if (Net::DRI::Util::has_key($rp,'id'))
 {
  push @n,['extreport:conId',Net::DRI::Util::is_class($rp->{id},'Net::DRI::Data::Contact')? $rp->{id}->srid() : $rp->{id} ];
 }
 return @n;
}

sub _create_host
{
 my ($rp)=@_;
 my @n;
 if (Net::DRI::Util::has_key($rp,'name'))
 {
  push @n,['extreport:name',Net::DRI::Util::is_class($rp->{name},'Net::DRI::Data::Hosts')? $rp->{name}->get_names(1) : $rp->{name} ];
 }
 return @n;
}

sub _create_future
{
 my ($rp)=@_;
 my @n;

 if (Net::DRI::Util::has_key($rp,'exDate'))
 {
  my $date=$rp->{exDate};
  $date=Net::DRI::Util::dto2zstring($date) if Net::DRI::Util::is_class($date,'DateTime');
  Net::DRI::Exception::usererr_invalid_parameters('exDate must be in ISO8601 format') unless $date=~m/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?$/;
  $date.='Z' unless $date=~m/Z$/;
  push @n,['extreport:exDate',$date];
 }

 return @n;
}

sub _create_payment
{
 my ($rp)=@_;
 my @n;

 Net::DRI::Exception::usererr_insufficient_parameters('account_type value is mandatory for payment reports') unless Net::DRI::Util::has_key($rp,'account_type') && length $rp->{account_type};
 push @n,['extreport:accountType',$rp->{account_type}];

 return @n;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('extreport','reportData');
 return unless defined $data;

 my $ns=$mes->ns('extreport');
 my @nodes=Net::DRI::Util::xml_list_children($data);
 my ($name,$c)=@{shift @nodes};

 if ($name eq 'domDataRsp')
 {
  _parse_domain($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='domain';
 } elsif ($name eq 'conDataRsp')
 {
  _parse_contact($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='contact';
 } elsif ($name eq 'hosDataRsp')
 {
  _parse_host($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='host';
 } elsif ($name eq 'futDataRsp')
 {
  _parse_future($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='future';
 } elsif ($name eq 'paymentDataRsp')
 {
  _parse_payment($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='payment';
 } elsif ($name eq 'paymentFundsDataRsp')
 {
  _parse_funds($po,$otype,$oaction,$oname,$rinfo,$c);
  $rinfo->{report}->{$oname}->{type}='funds';
 }

 foreach my $el (@nodes)
 {
  my ($name,$node)=@$el;
  if ($name=~m/^(?:offset|limit|size)$/)
  {
   $rinfo->{report}->{$oname}->{$name}=$node->textContent();
  }
 }
 return;
}

sub _parse_domain
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my @r;
 foreach my $el (map { $_->[1] } grep { $_->[0] eq 'domData' } Net::DRI::Util::xml_list_children($c))
 {
  my %r;
  foreach my $subel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$node)=@$subel;
   if ($name=~m/^(?:name|roid)$/)
   {
    $r{$name}=$node->textContent();
   } elsif ($name eq 'exDate')
   {
    $r{$name}=$po->parse_iso8601($node->textContent());
   } elsif ($name eq 'statuses')
   {
    my @s=map { $_->[1]->textContent() } grep { $_->[0] eq 'status' } Net::DRI::Util::xml_list_children($node);
    $r{status}=$po->create_local_object('status')->add(@s);
   }
  }
  push @r,\%r;
 }

 $rinfo->{report}->{$oname}->{results}=\@r;
 return;
}

sub _parse_contact
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my @r;
 foreach my $el (map { $_->[1] } grep { $_->[0] eq 'conData' } Net::DRI::Util::xml_list_children($c))
 {
  my $c=$po->create_local_object('contact');
  foreach my $subel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$node)=@$subel;
   if ($name eq 'conId')
   {
    $c->srid($node->textContent());
   } elsif ($name eq 'roid')
   {
    $c->roid($node->textContent());
   }
  }
  push @r,$c;
 }

 $rinfo->{report}->{$oname}->{results}=\@r;
 return;
}

sub _parse_host
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my $h=$po->create_local_object('hosts');
 foreach my $el (map { $_->[1] } grep { $_->[0] eq 'hosData' } Net::DRI::Util::xml_list_children($c))
 {
  my ($hostname,$hostroid);
  foreach my $subel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$node)=@$subel;
   if ($name eq 'name')
   {
    $hostname=$node->textContent();
   } elsif ($name eq 'roid')
   {
    $hostroid=$node->textContent();
   }
  }
  $h->add($hostname,undef,undef,{roid => $hostroid});
 }

 $rinfo->{report}->{$oname}->{results}=$h;
 return;
}

sub _parse_future
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my @r;
 foreach my $el (map { $_->[1] } grep { $_->[0] eq 'futData' } Net::DRI::Util::xml_list_children($c))
 {
  my %r;
  foreach my $subel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$node)=@$subel;
   if ($name=~m/^(?:name|roid)$/)
   {
    $r{$name}=$node->textContent();
   } elsif ($name eq 'exDate')
   {
    $r{$name}=$po->parse_iso8601($node->textContent());
   }
  }
  push @r,\%r;
 }

 $rinfo->{report}->{$oname}->{results}=\@r;
 return;
}

sub _parse_payment
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my @r;
 foreach my $el (map { $_->[1] } grep { $_->[0] eq 'paymentData' } Net::DRI::Util::xml_list_children($c))
 {
  my %r;
  foreach my $subel (Net::DRI::Util::xml_list_children($el))
  {
   my ($name,$node)=@$subel;
   if ($name eq 'roid')
   {
    $r{$name}=$node->textContent();
   } elsif ($name eq 'crDate')
   {
    $r{$name}=$po->parse_iso8601($node->textContent());
   } elsif ($name=~m/^(?:grossValue|vatPercent|vatValue|initialFunds|currentFunds)$/)
   {
    $r{Net::DRI::Util::remcam($name)}=0+$node->textContent();
   }
  }
  push @r,\%r;
 }

 $rinfo->{report}->{$oname}->{results}=\@r;
 return;
}

sub _parse_funds
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c)=@_;

 my %r;
 my ($el)=(map { $_->[1] } grep { $_->[0] eq 'paymentFundsData' } Net::DRI::Util::xml_list_children($c)); ## only one of them
 foreach my $subel (Net::DRI::Util::xml_list_children($el))
 {
  my ($name,$node)=@$subel;
  if ($name eq 'currentBalance')
  {
   $r{Net::DRI::Util::remcam($name)}=0+$node->textContent();
  }
 }

 $rinfo->{report}->{$oname}->{results}=\%r;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Report - .PL Report EPP Extension for Net::DRI

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

Copyright (c) 2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
