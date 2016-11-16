## Domain Registry Interface, EURid Domain EPP extension commands
## (based on EURid EPP_Guidelines_2_1_09)
##
## Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##               2014 Michael Kefeder <michael.kefeder@world4you.com>. All rights reserved.
##               2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Domain - EURid EPP Domain extension commands for Net::DRI

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

Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>.
              2014 Michael Kefeder <michael.kefeder@world4you.com>.
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
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ \&info, \&info_parse ],
          delete            => [ \&delete, undef ],
          transfer_request  => [ \&transfer_request, undef ],
          #transfer_query   => [ undef, \&transfer_parse ], # TODO domain-ext 1.1 also adds trnData element
          renew             => [ undef, \&renew_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 foreach my $ns (qw/domain-ext/)
 {
  $po->ns({ $ns => [ 'http://www.eurid.eu/xml/epp/'.$ns.'-2.0',$ns.'-2.0.xsd' ] });
 }
 foreach my $ns (qw/authInfo/)
 {
  $po->ns({ $ns => [ 'http://www.eurid.eu/xml/epp/'.$ns.'-1.0',$ns.'-1.0.xsd' ] });
 }
 return;
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:eurid="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('eurid')));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $cs=$rd->{contact};

 my @n;
 push @n,map { ['domain-ext:contact',$_->srid(),{'type'=>'onsite'}] } $cs->get('onsite');
 push @n,map { ['domain-ext:contact',$_->srid(),{'type'=>'reseller'}] } $cs->get('reseller');
 push @n,add_nsgroup($rd->{nsgroup})             if Net::DRI::Util::has_key($rd,'nsgroup');
 push @n,['domain-ext:keygroup',$rd->{keygroup}] if Net::DRI::Util::has_key($rd,'keygroup') && Net::DRI::Util::xml_is_token($rd->{keygroup},1,100);
 ## TODO domain-ext-voucher

 return unless @n;

 my $eid=$mes->command_extension_register('domain-ext','create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 if (grep { ! /^(?:add|del)$/ } $todo->types('nsgroup'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only nsgroup add/del available for domain');
 }

 my $nsgadd=$todo->add('nsgroup');
 my $nsgdel=$todo->del('nsgroup');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');
 return unless ($nsgadd || $nsgdel || $cadd || $cdel);

 my @n;
 if ($nsgadd || $cadd)
 {
  my @todo;
  push @todo,add_nsgroup($nsgadd) if $nsgadd;
  push @todo,map { ['domain-ext:contact',$_->srid(),{'type'=>'onsite'}] } $cadd->get('onsite') if $cadd;
  push @todo,map { ['domain-ext:contact',$_->srid(),{'type'=>'reseller'}] } $cadd->get('reseller') if $cadd;
  push @n,['domain-ext:add',@todo] if @todo;
 }
 if ($nsgdel || $cdel)
 {
  my @todo;
  push @todo,add_nsgroup($nsgdel) if $nsgdel;
  push @todo,map { ['domain-ext:contact',$_->srid(),{'type'=>'onsite'}] } $cdel->get('onsite') if $cdel;
  push @todo,map { ['domain-ext:contact',$_->srid(),{'type'=>'reseller'}] } $cdel->get('reseller') if $cdel;
  push @n,['domain-ext:rem',@todo] if @todo;
 }
## TODO : handle domain-ext:keygroup

 return unless @n;

 my $eid=$mes->command_extension_register('domain-ext','update');
 $mes->command_extension($eid,\@n);
 return;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'authinfo_request') && $rd->{authinfo_request};

 my $eid=$mes->command_extension_register('authInfo','info');
 $mes->command_extension($eid,['authInfo:request']);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 return unless $mes->is_success();

 my $infdata=$mes->get_extension('domain-ext','infData');
 return unless defined $infdata;

 my @nsg;
 my $status=$rinfo->{domain}->{$oname}->{status};
 my $contact=$rinfo->{domain}->{$oname}->{contact};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(onHold|quarantined)$/) ## onHold here has nothing to do with EPP client|serverHold, unfortunately
  {
   $status->add($name) if Net::DRI::Util::xml_parse_boolean($c->textContent()); ## TODO : correct status name?
  } elsif ($name=~m/^(availableDate|deletionDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'contact')
  {
   $contact->add($po->create_local_object('contact')->srid($c->textContent()),$c->getAttribute('type'));
  } elsif ($name eq 'nsgroup')
  {
   push @nsg,$po->create_local_object('hosts')->name($c->textContent());
  } elsif ($name eq 'keygroup')
  {
   $rinfo->{domain}->{$oname}->{keygroup}=$c->textContent();
  } elsif ($name eq 'pendingTransfer')
  {
   $status->add('pendingTransfer');
   my %p;
   my $cs=$po->create_local_object('contactset');
   my %ccache;
   foreach my $subel (Net::DRI::Util::xml_list_children($c))
   {
    my ($subname,$subc)=@$subel;
    if ($subname eq 'registrant')
    {
     my $id=$subc->textContent();
     $ccache{$id}=$po->create_local_object('contact')->srid($id) unless exists $ccache{$id};
     $cs->set($ccache{$id},'registrant');
    } elsif ($subname eq 'contact')
    {
     my $id=$subc->textContent();
     $ccache{$id}=$po->create_local_object('contact')->srid($id) unless exists $ccache{$id};
     $cs->add($ccache{$id},$subc->getAttribute('type'));
    } elsif ($subname eq 'initiationDate')
    {
     $p{initiationDate}=$po->parse_iso8601($subc->textContent());
    }
   }
   $p{contact}=$cs;
   $rinfo->{domain}->{$oname}->{pending_transaction}=\%p;
  }
 }
 $rinfo->{domain}->{$oname}->{nsgroup}=\@nsg if @nsg;
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('domain-ext','chkData');
 return unless defined $chkdata;

 my $ns=$mes->ns('domain-ext');
 foreach my $cd ($chkdata->getChildrenByTagNameNS($ns,'domain'))
 {
  my $domain;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $domain=lc $c->textContent();
    $rinfo->{domain}->{$domain}->{action}='check';
   } elsif ($n eq 'availableDate')
   {
    $rinfo->{domain}->{$domain}->{availableDate}=$po->parse_iso8601($c->textContent());
   } elsif ($n eq 'status')
   {
    $rinfo->{domain}->{$domain}->{status}=$po->create_local_object('status')->add(Net::DRI::Protocol::EPP::Util::parse_node_status($c));
   }
  }
 }
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $hasdelete=Net::DRI::Util::has_key($rd,'deleteDate') ? 1 : 0;
 my $hascancel=(Net::DRI::Util::has_key($rd,'cancel') && $rd->{cancel}) ? 1 : 0;

 return unless $hasdelete || $hascancel;
 Net::DRI::Exception::usererr_invalid_parameters('For domain_delete, parameters deleteDate & cancel can not be set at the same time') if $hasdelete && $hascancel;

 my $eid=$mes->command_extension_register('domain-ext','delete');
 my @n;

 if ($hasdelete)
 {
  Net::DRI::Util::check_isa($rd->{deleteDate},'DateTime');
  @n=(['domain-ext:schedule',['domain-ext:delDate',$rd->{deleteDate}->set_time_zone('UTC')->strftime('%Y-%m-%dT%T.%NZ')]]);
 }
 if ($hascancel)
 {
  @n=(['domain-ext:cancel']);
 }

 $mes->command_extension($eid,\@n);
 return;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=$mes->command_extension_register('domain-ext','transfer',{'xmlns:domain'=>'urn:ietf:params:xml:ns:domain-1.0'});
 my @d;

 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my $creg=$cs->get('registrant');
  push @d,['domain-ext:registrant',$creg->srid()] if Net::DRI::Util::isa_contact($creg,'Net::DRI::Data::Contact::EURid');
  my $cbill=$cs->get('billing');
  push @d,['domain-ext:contact',$cbill->srid(),{type => 'billing'}] if Net::DRI::Util::isa_contact($cbill,'Net::DRI::Data::Contact::EURid');
  push @d,add_contact('tech',$cs,9) if $cs->has_type('tech');
  push @d,add_contact('onsite',$cs,5) if $cs->has_type('onsite');
  push @d,add_contact('reseller',$cs,5) if $cs->has_type('reseller');
 }

 push @d,Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain,'domain-ext') if Net::DRI::Util::has_ns($rd);
 push @d,add_nsgroup($rd->{nsgroup}) if Net::DRI::Util::has_key($rd,'nsgroup');
 ## TODO keygroup
 ##  push @n,['eurid:keygroup',$rd->{keygroup}] if Net::DRI::Util::has_key($rd,'keygroup') && Net::DRI::Util::xml_is_token($rd->{keygroup},1,100);

 $mes->command_extension($eid,['domain-ext:request',@d]);

 if ($epp->has_module('Net::DRI::Protocol::EPP::Extensions::SecDNS'))
 {
  my $ref=$epp->find_action_in_class('Net::DRI::Protocol::EPP::Extensions::SecDNS','domain','create');
  $ref->($epp,$domain,$rd) if defined $ref && ref $ref;
 }
 return;
}

sub add_nsgroup
{
 my ($nsg)=@_;
 return unless (defined($nsg) && $nsg);
 my @a=grep { defined($_) && $_ && !ref($_) && Net::DRI::Util::xml_is_normalizedstring($_,1,100) } map { Net::DRI::Util::isa_nsgroup($_)? $_->name() : $_ } (ref($nsg) eq 'ARRAY')? @$nsg : ($nsg);
 return map { ['domain-ext:nsgroup',$_] } grep {defined} @a[0..8];
}

sub add_contact
{
 my ($type,$cs,$max)=@_;
 my @r=grep { Net::DRI::Util::isa_contact($_,'Net::DRI::Data::Contact::EURid') } ($cs->get($type));
 return map { ['domain-ext:contact',$_->srid(),{type=>$type}] } grep { defined } @r[0..($max-1)];
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_extension('domain-ext','renData');
 return unless defined $rendata;

 foreach my $el (Net::DRI::Util::xml_list_children($rendata))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(removedDeletionDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=Net::DRI::Util::xml_parse_boolean($c->textContent());
  }
 }
 return;
}

####################################################################################################
1;
