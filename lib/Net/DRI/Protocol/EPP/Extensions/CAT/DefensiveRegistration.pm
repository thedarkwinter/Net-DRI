## Domain Registry Interface, .CAT Defensive Registration EPP extension commands
##
## Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CAT::DefensiveRegistration;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CAT::DefensiveRegistration - .CAT EPP Defensive Registration extension commands for Net::DRI

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

Copyright (c) 2006-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp1=( create => [ \&create ],
            check  => [ \&check, \&check_parse ],
            info   => [ \&info, \&info_parse ],
            delete => [ \&delete ],
	    update => [ \&update ],
            renew  => [ \&renew ],
          );

 $tmp1{check_multi}=$tmp1{check};
 
 return { 'defreg' => \%tmp1 };
}

sub ns
{
 my $mes=shift;
 return wantarray()? @{$mes->ns()->{'puntcat_defreg'}} : $mes->ns('puntcat_defreg');
}

sub build_command
{
 my ($epp,$command,$id)=@_;
 my $mes=$epp->message();

 my @id;
 foreach my $n ( grep { defined } (ref($id) eq 'ARRAY')? @$id : ($id))
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid defensive registration id '.$n) unless ($n && !ref($n) && Net::DRI::Util::xml_is_token($n,3,16));
  push @id,$n;
 }

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Defensive registration id needed') unless @id;

 my @ns=ns($mes);
 $mes->command([$command,'defreg:'.$command,sprintf('xmlns:defreg="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1])]);
 return map { ['defreg:id',$_] } @id;
}

sub build_pattern
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('pattern is mandatory') unless (defined($d) && $d);
 Net::DRI::Exception::usererr_invalid_parameters('pattern must be a XML token between 1 and 63 chars long') unless Net::DRI::Util::xml_is_token($d,1,63);
 return ['defreg:pattern',$d];
}

sub build_contact
{
 my ($d,$type)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters($type.' contact is mandatory') unless (defined($d) && $d);
 $d=$d->srid() if Net::DRI::Util::isa_contact($d,'Net::DRI::Data::Contact::CAT');
 Net::DRI::Exception->die(1,'protocol/EPP',10,"Invalid $type contact id: $d") unless Net::DRI::Util::xml_is_token($d,3,16);
 return ($type eq 'registrant')? ['defreg:registrant',$d] : ['defreg:contact',$d,{type => $type}];
}

sub build_contact_noregistrant
{
 my $cs=shift;
 my @d;
 foreach my $t (sort($cs->types()))
 {
  next if ($t eq 'registrant');
  my @o=$cs->get($t);
  push @d,map { ['defreg:contact',$_->srid(),{'type'=>$t}] } @o;
 }
 return @d;
}

sub build_authinfo
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('auth info is mandatory') unless (defined($d) && (ref($d) eq 'HASH') && exists($d->{pw}) && $d->{pw});
 Net::DRI::Exception::usererr_invalid_parameters('auth pw must be a XML normalized string') unless Net::DRI::Util::xml_is_normalizedstring($d->{pw});
 return ['defreg:authInfo',['defreg:pw',$d->{pw},exists($d->{roid})? { 'roid' => $d->{roid} } : undef]];
}

sub build_maintainer
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('maintainer is mandatory') unless (defined($d) && $d);
 Net::DRI::Exception::usererr_invalid_parameters('maintainer must be an XML token up to 128 chars long') unless Net::DRI::Util::xml_is_token($d,undef,128);
 return ['defreg:maintainer',$d];
}

sub build_trademark
{
 my ($d)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('trademark is mandatory') unless (defined($d) && (ref($d) eq 'HASH') && keys(%$d));
 my %t=%$d;
 my @n;
 if (exists($t{name}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('trademark name must be an XML token at least one char long') unless Net::DRI::Util::xml_is_token($t{name},1);
  push @n,['defreg:name',$t{name}];
 }
 if (exists($t{issue_date}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('trademark issueDate must be a valid DateTime object') unless Net::DRI::Util::check_isa($t{issue_date},'DateTime');
  push @n,['defreg:issueDate',$t{issue_date}->strftime('%Y-%m-%d')];
 }
 if (exists($t{country}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('trademark country must be a valid country code') unless ($t{country} && exists($Net::DRI::Util::CCA2{uc($t{country})}));
  push @n,['defreg:country',$t{country}];
 }
 if (exists($t{number}))
 {
  Net::DRI::Exception::usererr_invalid_parameters('trademark number must be an XML token at least one chat long') unless Net::DRI::Util::xml_is_token($t{number},1);
  push @n,['defreg:number',$t{number}];
 }
 return ['defreg:trademark',@n];
}

sub build_period
{
 my $p=Net::DRI::Protocol::EPP::Util::build_period(shift);
 $p->[0]='defreg:period';
 return $p;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,@id)=@_;
 my @d=build_command($epp,'check',\@id);
 $epp->message->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=ns($mes);
 my $chkdata=$mes->get_response($ns,'chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($ns,'cd'))
 {
  my $id;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'id')
   {
    $id=$c->textContent();
    $rinfo->{defreg}->{$id}->{action}='check';
    $rinfo->{defreg}->{$id}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   } elsif ($n eq 'reason')
   {
    $rinfo->{defreg}->{$id}->{exist_reason}=$c->textContent();
   }
  }
 }
 return;
}

sub info
{
 my ($epp,$id,$rd)=@_;
 my @d=build_command($epp,'info',$id);
 push @d,build_authinfo($rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $epp->message->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=ns($mes);
 my $infdata=$mes->get_response($ns,'infData');
 return unless defined $infdata;

 my (@s,%t);
 my $cs=$po->create_local_object('contactset');

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   $oname=$c->textContent();
   $rinfo->{defreg}->{$oname}->{id}=$oname;
  } elsif ($name eq 'roid')
  {
   $rinfo->{defreg}->{$oname}->{roid}=$c->textContent();
  } elsif ($name eq 'pattern')
  {
   $rinfo->{defreg}->{$oname}->{pattern}=$c->textContent();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name eq 'registrant')
  {
   $cs->set($po->create_local_object('contact')->srid($c->textContent()),'registrant');
  } elsif ($name eq 'contact')
  {
   $cs->add($po->create_local_object('contact')->srid($c->textContent()),$c->getAttribute('type'));
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{defreg}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|exDate)$/)
  {
   $rinfo->{defreg}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'authInfo')
  {
   $rinfo->{defreg}->{$oname}->{auth}={ pw => Net::DRI::Util::xml_child_content($c,$ns,'pw') };
  } elsif ($name eq 'maintainer')
  {
   $rinfo->{defreg}->{$oname}->{maintainer}=$c->textContent();
  } elsif ($name eq 'trademark')
  {
   foreach my $sel (Net::DRI::Util::xml_list_children($c))
   {
    my ($name2,$cc)=@$sel;
    if ($name2 eq 'name')
    {
     $t{name}=$cc->textContent();
    } elsif ($name2 eq 'issueDate')
    {
     $t{issue_date}=$po->parse_iso8601($cc->textContent());
    } elsif ($name2 eq 'country')
    {
     $t{country}=$cc->textContent();
    } elsif ($name2 eq 'number')
    {
     $t{number}=$cc->textContent();
    }
   }
  }
 }

 $rinfo->{defreg}->{$oname}->{action}='info';
 $rinfo->{defreg}->{$oname}->{exist}=1;
 $rinfo->{defreg}->{$oname}->{contact}=$cs;
 $rinfo->{defreg}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{defreg}->{$oname}->{trademark}=\%t;
 return;
}

####################################################################################################
############ Transform commands

sub create
{
 my ($epp,$id,$ri)=@_;
 my @d=build_command($epp,'create',$id);

 Net::DRI::Exception::usererr_invalid_parameters('A ref hash with all info must be provided alongside the id') unless (defined($ri) && (ref($ri) eq 'HASH') && keys(%$ri));

 ## Period, OPTIONAL
 if (exists($ri->{duration}))
 {
  my $period=$ri->{duration};
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  push @d,build_period($period);
 }

 Net::DRI::Exception::usererr_invalid_parameters('pattern must be an XML token between 1 and 63 chars long') unless (exists($ri->{pattern}) && $ri->{pattern} && Net::DRI::Util::xml_is_token($ri->{pattern},1,63));
 push @d,['defreg:pattern',$ri->{pattern}];
 Net::DRI::Exception::usererr_invalid_parameters('a valid contactset object must be given in contact attribute') unless Net::DRI::Util::has_contact($ri);
 my $cs=$ri->{contact};
 push @d,build_contact($cs->get('registrant'),'registrant');
 push @d,build_contact($cs->get('billing'),'billing');
 push @d,build_contact($cs->get('admin'),'admin');
 push @d,build_authinfo($ri->{auth});
 push @d,build_maintainer($ri->{maintainer}) if (exists($ri->{maintainer})); ## optional
 my $tmp=build_trademark($ri->{trademark});
 Net::DRI::Exception::usererr_insufficient_parameters('trademark must be a ref hash with 4 keys: name, issue_date, country, number') unless (@$tmp==5);
 push @d,$tmp;
 $epp->message->command_body(\@d);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$id)=@_;
 my @d=build_command($epp,'delete',$id);
 $epp->message->command_body(\@d);
 return;
}

sub renew
{
 my ($epp,$id,$rd)=@_;
 my $period=(defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{duration}))? $rd->{duration} : undef;
 my $curexp=(defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{current_expiration}))? $rd->{current_expiration} : undef;
 Net::DRI::Exception::usererr_insufficient_parameters('current expiration year') unless defined($curexp);
 $curexp=$curexp->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref $curexp && Net::DRI::Util::is_class($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('current expiration year must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;

 my @d=build_command($epp,'renew',$id);
 push @d,['defreg:curExpDate',$curexp];
 if (defined($period))
 {
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  push @d,build_period($period);
 }

 $epp->message->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$id,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

  if ((grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('contact')) ||
     (grep { ! /^set$/ } $todo->types('registrant')) ||
     (grep { ! /^set$/ } $todo->types('auth')) ||
     (grep { ! /^set$/ } $todo->types('maintainer')) ||
     (grep { ! /^set$/ } $todo->types('trademark'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only status/contact add/del or registrant/authinfo/maintainer/trademark set available for defreg');
 }

 my @d=build_command($epp,'update',$id);

 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');
 my (@add,@del);

 push @add,build_contact_noregistrant($cadd) if $cadd;
 push @add,$sadd->build_xml('defreg:status') if $sadd;
 push @del,build_contact_noregistrant($cdel) if $cdel;
 push @del,$sdel->build_xml('defreg:status') if $sdel;

 push @d,['defreg:add',@add] if @add;
 push @d,['defreg:rem',@del] if @del;

 my (@chg,$chg);

 $chg=$todo->set('registrant');
 push @chg,['defreg:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg,'Net::DRI::Data::Contact::CAT');
 $chg=$todo->set('auth');
 push @chg,build_authinfo($chg) if ($chg && ref($chg));
 $chg=$todo->set('maintainer');
 push @chg,build_maintainer($chg) if $chg;
 $chg=$todo->set('trademark');
 push @chg,build_trademark($chg) if ($chg && ref($chg));

 push @d,['defreg:chg',@chg] if @chg;
 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
