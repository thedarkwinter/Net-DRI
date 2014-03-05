## Domain Registry Interface, .UK EPP Account commands
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Account;

use strict;
use warnings;

use Net::DRI::Protocol::EPP::Core::Contact;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Contact;
use Net::DRI::Util;
use Net::DRI::Exception;;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Account - .UK EPP Account commands for Net::DRI

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
 		info   => [ \&info, \&info_parse ],
		update => [ \&update ],
                fork   => [ \&fork, \&fork_parse ],
		merge  => [ \&merge ],
		list_domains => [\&list_domains, \&list_domains_parse ],
	);

 return { 'account' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($contact));

 my $id=extract_contact_id($contact);
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($id) && $id && !ref($id));
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16); ## inherited from Core EPP
 my $tcommand=(ref($command))? $command->[0] : $command;
 my $ns=($command eq 'update')? sprintf('xmlns:contact="%s" xmlns:account="%s" xsi:schemaLocation="%s %s"',$msg->ns('contact'),$msg->nsattrs('account')) : sprintf('xmlns:account="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('account'));
 $msg->command([$command,'account:'.$tcommand,$ns]);
 return (['account:roid',$id]);
}

sub extract_contact_id
{
 my $contact=shift;
 my $id;
 if (Net::DRI::Util::isa_contactset($contact))
 {
  my $c=$contact->get('registrant');
  Net::DRI::Exception->die(1,'protocol/EPP',2,'ContactSet must contain a registrant contact object') unless (Net::DRI::Util::isa_contact($c,'Net::DRI::Data::Contact::Nominet'));
  $id=$c->roid();
 } elsif (Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::Nominet'))
 {
  $id=$contact->roid();
 } else
 {
  $id=$contact;
 }
 return $id;
}


####################################################################################################
########### Query commands

sub info
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$c);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('account','infData');
 return unless defined $infdata;

 parse_infdata($po,$mes,$infdata,$oname,$rinfo);
 return;
}

sub parse_infdata
{
 my ($po,$mes,$infdata,$oname,$rinfo)=@_;
 my %c;
 my $addr=0;
 my $cs=$po->create_local_object('contactset');
 my $ca=$po->create_local_object('contact');

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'roid')
  {
   $oname=$c->textContent();
   $ca->roid($oname);
   $cs->set($ca,'registrant');
   $rinfo->{account}->{$oname}->{roid}=$rinfo->{contact}->{$oname}->{roid}=$oname;
   $rinfo->{account}->{$oname}->{action}=$rinfo->{contact}->{$oname}->{roid}='info';
   $rinfo->{account}->{$oname}->{exist}=$rinfo->{contact}->{$oname}->{roid}=1;
  } elsif (my ($w)=($name=~m/^(name|trad-name|type|co-no|opt-out)$/))
  {
   $w=~s/-/_/;
   $w='org' if $w eq 'trad_name';
   $ca->$w($c->textContent());
  } elsif ($name eq 'addr')
  {
   if ($addr)
   {
    ## Creating a second registrant contact to hold optional billing address
    my $ca2=$po->create_local_object('contact');
    parse_addr($c,$ca2);
    $cs->add($ca2,'registrant');
   } else
   {
    parse_addr($c,$ca);
    $addr++;
   }
  } elsif ($name eq 'contact')
  {
   my $type=$c->getAttribute('type'); ## admin or billing
   my $order=$c->getAttribute('order'); ## 1 or 2 or 3
   my $co=$po->create_local_object('contact');
   if ($c->getChildrenByTagNameNS($mes->ns('contact'),'infData'))
   {
    Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::parse_infdata($po,$c->getChildrenByTagNameNS($mes->ns('contact'),'infData')->get_node(1),$co,undef,$rinfo);
   }
   $c{$type}->{$order}=$co;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{account}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate)$/)
  {
   $rinfo->{account}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }

 $cs->set([ map { $c{'admin'}->{$_} } sort { $a <=> $b } keys(%{$c{'admin'}}) ],'admin') if (exists($c{'admin'}));
 $cs->set([ map { $c{'billing'}->{$_} } sort { $a <=> $b } keys(%{$c{'billing'}}) ],'billing') if (exists($c{'billing'}));
 $rinfo->{account}->{$oname}->{self}=$cs;
 return $cs;
}

sub parse_addr
{
 my ($n,$c)=@_;
 my @street;

 foreach my $el (Net::DRI::Util::xml_list_children($n))
 {
  my ($name,$n)=@$el;
  if ($name eq 'street')
  {
   push @street,$n->textContent();
  } elsif ($name eq 'locality')
  {
   push @street,$n->textContent();
  } elsif ($name eq 'city')
  {
   $c->city($n->textContent());
  } elsif ($name eq 'county')
  {
   $c->sp($n->textContent());
  } elsif ($name eq 'postcode')
  {
   $c->pc($n->textContent());
  } elsif ($name eq 'country')
  {
   $c->cc($n->textContent());
  }
 }

 $c->street(\@street);
 return;
}

sub build_addr
{
 my ($c,$type)=@_;
 my @d;
 my @s=$c->street();
 if (@s)
 {
  @s=@{$s[0]};
  push @d,['account:street',$s[0]];
  push @d,['account:locality',$s[1]];
 }
 push @d,['account:city',$c->city()] if $c->city();
 push @d,['account:county',$c->sp()] if $c->sp();
 push @d,['account:postcode',$c->pc()] if $c->pc();
 push @d,['account:country',$c->cc()] if $c->cc();
 return @d? ['account:addr',{type=>$type},@d] : ();
}

sub add_account_data
{
 my ($mes,$cs,$ischange)=@_;
 my $modtype=$ischange? 'update' : 'create';
 my @a;
 my @o=$cs->get('registrant');
 if (Net::DRI::Util::isa_contact($o[0],'Net::DRI::Data::Contact::Nominet'))
 {
  $o[0]->validate($ischange);
  push @a,['account:name',$o[0]->name()] unless $ischange;
  push @a,['account:trad-name',$o[0]->org()] if $o[0]->org();
  push @a,['account:type',$o[0]->type()] if (!$ischange || $o[0]->type());
  push @a,['account:co-no',$o[0]->co_no()] if $o[0]->co_no();
  push @a,['account:opt-out',$o[0]->opt_out()] if (!$ischange || $o[0]->opt_out());
  push @a,build_addr($o[0],'admin');
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters('registrant data is mandatory') unless $ischange;
 }

 if (Net::DRI::Util::isa_contact($o[1],'Net::DRI::Data::Contact::Nominet'))
 {
  $o[1]->validate() unless $ischange;
  my @t=build_addr($o[1],'billing');
  push @a,($ischange && !@t)? ['account:addr',{type=>'billing'}] : @t;
 }

 @o=$cs->get('admin');
 Net::DRI::Exception::usererr_insufficient_parameters('admin data is mandatory') unless ($ischange || Net::DRI::Util::isa_contact($o[0],'Net::DRI::Data::Contact::Nominet'));
 foreach my $o (0..2)
 {
   last unless defined($o[$o]);
   my @t=Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::build_cdata($o[$o]);
   my $contype=$ischange? (($o[$o]->srid())? 'update' : 'create') : $modtype;
   push @a,['account:contact',{type=>'admin',order=>$o+1},($ischange && !@t)? () : ['contact:'.$contype,@t]];
 }
 @o=$cs->get('billing');
 foreach my $o (0..2)
 {
   last unless defined($o[$o]);
   my @t=Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::build_cdata($o[$o]);
   my $contype=$ischange? (($o[$o]->srid())? 'update' : 'create') : $modtype;
   push @a,['account:contact',{type=>'billing',order=>$o+1},($ischange && !@t)? () : ['contact:'.$contype,@t]];
 }
 return @a;
}

sub update
{
 my ($epp,$c,$todo)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 my $cs=$todo->set('contact');
 Net::DRI::Exception::usererr_invalid_parameters($cs.' must be a Net::DRI::Data::ContactSet object') unless Net::DRI::Util::isa_contactset($cs);
 my @d=build_command($mes,'update',$c);
 push @d,add_account_data($mes,$cs,1);
 $mes->command_body(\@d);
 return;
}

sub fork ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$c,$rh)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('For account fork, a domains key must be there with a ref array of domain names to fork') unless (Net::DRI::Util::has_key($rh,'domains') && (ref($rh->{domains}) eq 'ARRAY'));

 my $mes=$epp->message();
 $mes->command(['update','account:fork',sprintf('xmlns:account="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('account'))]);
 my @d;
 my $id=extract_contact_id($c);
 push @d,['account:roid',$id] if (defined($id) && $id);
 foreach my $d (@{$rh->{domains}})
 {
  next unless (defined($d) && $d && Net::DRI::Util::is_hostname($d));
  push @d,['account:domain-name',$d];
 }
 $mes->command_body(\@d);
 return;
}

sub parse_credata
{
 my ($mes,$node,$po,$cs,$rinfo)=@_;
 my %c;
 my $nsa=$mes->ns('account');
 my $roid=$node->getChildrenByTagNameNS($nsa,'roid')->get_node(1)->textContent();
 my $name=$node->getChildrenByTagNameNS($nsa,'name')->get_node(1)->textContent();
 my $co=$po->create_local_object('contact')->srid($roid)->name($name);
 $cs->set($co,'registrant');
 $rinfo->{contact}->{$roid}->{exist}=1;
 $rinfo->{contact}->{$roid}->{roid}=$roid;
 $rinfo->{contact}->{$roid}->{self}=$co;
 my $nsc=$mes->ns('contact');
 foreach my $ac ($node->getChildrenByTagNameNS($nsa,'contact'))
 {
  my $type=$ac->getAttribute('type');
  my $order=$ac->getAttribute('order');
  my $credata=$ac->getChildrenByTagNameNS($nsc,'creData')->get_node(1);
  my $roid2=$credata->getChildrenByTagNameNS($nsc,'roid')->get_node(1)->textContent();
  my $name2=$credata->getChildrenByTagNameNS($nsc,'name')->get_node(1)->textContent();
  $co=$po->create_local_object('contact')->srid($roid2)->name($name2);
  $c{$type}->{$order}=$co;
  $rinfo->{contact}->{$roid2}->{exist}=1;
  $rinfo->{contact}->{$roid2}->{roid}=$roid2;
  $rinfo->{contact}->{$roid2}->{self}=$co;
 }
 $cs->set([ map { $c{'admin'}->{$_} } sort { $a <=> $b } keys(%{$c{'admin'}}) ],'admin') if (exists($c{'admin'}));
 $cs->set([ map { $c{'billing'}->{$_} } sort { $a <=> $b } keys(%{$c{'billing'}}) ],'billing') if (exists($c{'billing'}));
 $rinfo->{account}->{$roid}->{self}=$cs;
 $rinfo->{account}->{$roid}->{exist}=1;
 return $roid;
}

sub fork_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('account','creData');
 return unless $credata;

 my $cs=$po->create_local_object('contactset');
 my $roid=parse_credata($mes,$credata,$po,$cs,$rinfo);
 $rinfo->{account}->{$roid}->{action}='fork';
 $rinfo->{account}->{$oname}->{fork_to}=$roid if defined($oname); ## roid not mandatory during fork call
 return;
}

sub merge
{
 my ($epp,$c,$rh)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'merge',$c);
 my $cmd=$mes->command();
 shift(@$cmd);
 $mes->command(['update',@$cmd]);
 $mes->command_body(\@d);

 if (Net::DRI::Util::has_key($rh,'roid_source') && (ref($rh->{roid_source}) eq 'ARRAY'))
 {
  push @d,map { ['account:roid',{source=>'y'},$_] } @{$rh->{roid_source}};
 }

 if (Net::DRI::Util::has_key($rh,'names') && (ref($rh->{names}) eq 'ARRAY'))
 {
  push @d,map { ['account:name',$_] } @{$rh->{names}};
 }

 Net::DRI::Exception::usererr_invalid_parameters('For account merge, a domains key must be there with a ref array of domain names to fork') unless (Net::DRI::Util::has_key($rh,'domains') && (ref($rh->{domains}) eq 'ARRAY'));
 foreach my $d (@{$rh->{domains}})
 {
  next unless (defined($d) && $d && Net::DRI::Util::is_hostname($d));
  push @d,['account:domain-name',$d];
 }

 $mes->command_body(\@d);
 return;
}

####################################################################################################
## In Nominet documentation this is listed as an operation acting on *one* domain
## See http://www.nominet.org.uk/registrars/systems/nominetepp/list/

sub list_domains
{
 my ($epp,$rd,$rh)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('list_domains needs a ref hash with a registration or expiration key') unless Net::DRI::Util::has_key($rd,'registration') || Net::DRI::Util::has_key($rd,'expiration');

 $mes->command(['info','domain:list',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain'))]);
 my @d;
 if (Net::DRI::Util::has_key($rd,'registration'))
 {
  Net::DRI::Util::check_isa($rd->{registration},'DateTime');
  push @d,['domain:month',$rd->{registration}->set_time_zone('UTC')->strftime('%Y-%m')];
 } else
 {
  Net::DRI::Util::check_isa($rd->{expiration},'DateTime');
  push @d,['domain:expiry',$rd->{registration}->set_time_zone('UTC')->strftime('%Y-%m')];
 }
 push @d,['domain:fields','none']; ## with that we get only domain names back, if 'all' instead we get full infData for each domain, as in domain_info reply
 $mes->command_body(\@d);
 return;
}

sub list_domains_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 ## This should be the same as poll messages: registrar change, domains released, poor quality. TODO: some factorization
 my $list=$mes->get_response('domain','listData');
 $rinfo->{account}->{domains}->{action}='list';
 $rinfo->{account}->{domains}->{list}=defined $list ? [ map { $_->textContent() } $list->getChildrenByTagNameNS($mes->ns('domain'),'name') ] : [];
 return;
}

####################################################################################################
1;
