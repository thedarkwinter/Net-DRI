## Domain Registry Interface, AFNIC (.FR/.RE/.TF/.WF/.PM/.YT) Contact EPP extension commands
##
## Copyright (c) 2008,2009,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact - AFNIC (.FR/.RE/.TF/.WF/.PM/.YT) EPP Contact extensions for Net::DRI

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

Copyright (c) 2008,2009,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, \&create_parse ],
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:frnic="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('frnic')));
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

## validate() has been called
 my @n;
 my $qual=$contact->qualification();
 if ($contact->legal_form()) # PM
 {
  my @d;
  push @d,build_q_idtstatus($qual);

  Net::DRI::Exception::usererr_insufficient_parameters('legal_form data mandatory') unless ($contact->legal_form());
  Net::DRI::Exception::usererr_invalid_parameters('legal_form_other data mandatory if legal_form=other') if (($contact->legal_form() eq 'other') && !$contact->legal_form_other());

  push @d,['frnic:legalStatus',{'s' => $contact->legal_form()},$contact->legal_form() eq 'other'? $contact->legal_form_other() : ''];
  my @id;

  if ($contact->legal_id() && $contact->legal_id_type())
  {
   push @d,['frnic:siren',$contact->legal_id()]  if $contact->legal_id_type() eq 'siren';
   push @id,['frnic:DUNS',$contact->legal_id()]  if $contact->legal_id_type() eq 'duns';
   push @id,['frnic:local',$contact->legal_id()] if $contact->legal_id_type() eq 'local';
  }
  push @d,['frnic:VAT',$contact->vat()] if $contact->vat();
  push @d,['frnic:trademark',$contact->trademark()] if $contact->trademark();
  my $jo=$contact->jo();
  if (defined($jo) && (ref($jo) eq 'HASH'))
  {
   my @j;
   push @j,['frnic:waldec',$jo->{waldec}] if exists $jo->{waldec};
   push @j,['frnic:waldec',$contact->legal_id()] if (defined $contact->legal_id() && defined $contact->legal_form_other() && $contact->legal_form_other() eq 'asso'); ## not sure API ok
   push @j,['frnic:decl',$jo->{date_declaration}];
   push @j,['frnic:publ',{announce=>$jo->{number},page=>$jo->{page}},$jo->{date_publication}];
   push @d,['frnic:asso',@j];
  }
  push @d,@id if @id;
  push @n,['frnic:legalEntityInfos',@d];
 } else # PP
 {
  my @d;
  push @d,build_q_idtstatus($qual);

  my $b=$contact->birth();
  if (Net::DRI::Util::has_key($b,'date') && Net::DRI::Util::has_key($b,'place'))
  {
   push @d,['frnic:birthDate',ref $b->{date} ? $b->{date}->strftime('%Y-%m-%d') : $b->{date}];
   if ($b->{place}=~m/^[A-Z]{2}$/i) ## country not France
   {
    push @d,['frnic:birthCc',$b->{place}];
   } else
   {
    my @p=($b->{place}=~m/^\s*(\S.*\S)\s*,\s*(\S.+\S)\s*$/);
    push @d,['frnic:birthCity',$p[1]];
    push @d,['frnic:birthPc',$p[0]];
    push @d,['frnic:birthCc','FR'];
   }
  }
  if (@d)
  {
   push @n,['frnic:list','restrictedPublication'] if (defined $contact->disclose() && $contact->disclose() eq 'N');
   push @n,['frnic:individualInfos',@d];
  }
  push @n,['frnic:firstName',$contact->firstname()];
 }

 push @n,build_q_reachable($qual);

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:create',['frnic:contact',@n]]);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_extension('frnic','ext');
 return unless defined $credata;

 my $ns=$mes->ns('frnic');
 $credata=Net::DRI::Util::xml_traverse($credata,$ns,'resData','creData');
 return unless defined $credata;

 $oname=$rinfo->{contact}->{$oname}->{id}; ## take into account true ID (the one returned by the registry)
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'nhStatus')
  {
   $rinfo->{contact}->{$oname}->{new_handle}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('new'));
  } elsif ($name eq 'idStatus')
  {
   $rinfo->{contact}->{$oname}->{qualification}={ identification => parse_q_idtstatus($po,$c) };
  }
 }
 return;
}

sub build_q_idtstatus
{
 my ($qual)=@_;
 my @d;
 if (Net::DRI::Util::has_key($qual,'identification') && Net::DRI::Util::has_key($qual->{identification},'status'))
 {
  push @d,['frnic:idStatus',$qual->{identification}->{status}];
 }
 return @d;
}

sub build_q_reachable
{
 my ($qual)=@_;
 my @n;
 if (Net::DRI::Util::has_key($qual,'reachable') && Net::DRI::Util::has_key($qual->{reachable},'value') && Net::DRI::Util::has_key($qual->{reachable},'media'))
 {
  push @n,['frnic:reachable',{media=>$qual->{reachable}->{media}},$qual->{reachable}->{value} ? 1 : 0];
 }
 return @n;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $dadd=$todo->add('disclose');
 my $ddel=$todo->del('disclose');
 my $qadd=$todo->add('qualification');
 my $qdel=$todo->del('qualification');
 return unless ($dadd || $ddel || $qadd || $qdel);

 my (@add,@del);
 push @add,['frnic:list',$dadd] if $dadd;
 push @del,['frnic:list',$ddel] if $ddel;

 if ($qadd)
 {
  push @add,build_q_idtstatus($qadd);
  push @add,build_q_reachable($qadd);
 }
 if ($qdel)
 {
  push @del,build_q_idtstatus($qdel);
  push @del,build_q_reachable($qdel);
 }

 my @n;
 push @n,['frnic:add',@add] if @add;
 push @n,['frnic:rem',@del] if @del;

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:update',['frnic:contact',@n]]);
 return;
}

sub parse_q_idtstatus
{
 my ($po,$c)=@_;
 my %i;
 $i{when}=$po->parse_iso8601($c->getAttribute('when')) if $c->hasAttribute('when');
 $i{source}=$c->getAttribute('source') if $c->hasAttribute('source');
 $i{value}=$c->textContent();
 return \%i;
}

sub parse_q_reachable
{
 my ($po,$c)=@_;
 my %r;
 $r{when}=$po->parse_iso8601($c->getAttribute('when')) if $c->hasAttribute('when');
 $r{media}=$c->getAttribute('media') if $c->hasAttribute('media');
 $r{source}=$c->getAttribute('source') if $c->hasAttribute('source');
 $r{value}=Net::DRI::Util::xml_parse_boolean($c->textContent());
 return \%r;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('frnic','ext');
 return unless defined $infdata;

 my $ns=$mes->ns('frnic');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'resData','infData','contact');
 return unless defined $infdata;

 my $co=$rinfo->{contact}->{$oname}->{self};
 my %q;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'firstName')
  {
   $co->firstname($c->textContent());
  } elsif ($name eq 'list')
  {
   $co->disclose($c->textContent() eq 'restrictedPublication'? 'N' : 'Y');
  } elsif ($name eq 'individualInfos')
  {
   parse_individualinfos($po,$otype,$oaction,$oname,$rinfo,$c,$co,$mes,\%q);
  } elsif ($name eq 'legalEntityInfos')
  {
   parse_legalentityinfos($po,$otype,$oaction,$oname,$rinfo,$c,$co,$mes,\%q);
  } elsif ($name eq 'obsoleted')
  {
   my %o;
   $o{value}=Net::DRI::Util::xml_parse_boolean($c->textContent());
   $o{when}=$po->parse_iso8601($c->getAttribute('when')) if $c->hasAttribute('when');
   $co->obsoleted(\%o);
  } elsif ($name eq 'reachable')
  {
   $q{reachable}=parse_q_reachable($po,$c);
  }
 }
 $co->qualification(\%q) if %q;

 return;
}

sub parse_individualinfos
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c,$co,$mes,$rq)=@_;

 my %birth;
 foreach my $sel (Net::DRI::Util::xml_list_children($c))
 {
  my ($nn,$cc)=@$sel;
  if ($nn eq 'idStatus')
  {
   $rq->{identification}=parse_q_idtstatus($po,$c);
  } elsif ($nn eq 'birthDate')
  {
   $birth{date}=$cc->textContent();
  } elsif ($nn eq 'birthCity')
  {
   $birth{place}=$cc->textContent();
  } elsif ($nn eq 'birthPc')
  {
   $birth{place}=sprintf('%s, %s',$cc->textContent(),$birth{place});
  } elsif ($nn eq 'birthCc')
  {
   my $v=$cc->textContent();
   $birth{place}=$v unless ($v eq 'FR');
  }
 }
 $co->birth(\%birth);

 return;
}

sub parse_legalentityinfos
{
 my ($po,$otype,$oaction,$oname,$rinfo,$c,$co,$mes,$rq)=@_;

 foreach my $sel (Net::DRI::Util::xml_list_children($c))
 {
  my ($nn,$cc)=@$sel;
  if ($nn eq 'idStatus')
  {
   $rq->{identification}=parse_q_idtstatus($po,$cc);
  } elsif ($nn eq 'legalStatus')
  {
   $co->legal_form($cc->getAttribute('s'));
   my $v=$cc->textContent();
   $co->legal_form_other($v) if $v;
  } elsif ($nn=~m/^(?:siren|DUNS|local)$/)
  {
   $co->legal_id($cc->textContent());
   $co->legal_id_type(lc $nn);
  } elsif ($nn eq 'trademark')
  {
   $co->trademark($cc->textContent());
  } elsif ($nn eq 'asso')
  {
   my %jo;
   my $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'decl');
   $jo{date_declaration}=$ccc->get_node(1)->textContent() if $ccc->size();
   $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'publ');
   if ($ccc->size())
   {
    my $p=$ccc->get_node(1);
    $jo{number}=$p->getAttribute('announce');
    $jo{page}=$p->getAttribute('page');
    $jo{date_publication}=$p->textContent();
   }
   $co->jo(\%jo);
  }
 }

 return;
}

####################################################################################################
1;
