## Domain Registry Interface, EPP Contact commands (RFC5733)
##
## Copyright (c) 2005-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Contact;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Contact - EPP Contact commands (RFC5733) for Net::DRI

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

Copyright (c) 2005-2010,2012-2013 Patrick Mevzek <netdri@dotandco.com>.
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
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           transfer_query  => [ \&transfer_query, \&transfer_parse ],
           create => [ \&create, \&create_parse ],
           delete => [ \&delete ],
           transfer_request => [ \&transfer_request, \&transfer_parse ],
           transfer_cancel  => [ \&transfer_cancel,\&transfer_parse ],
           transfer_answer  => [ \&transfer_answer,\&transfer_parse ],
	   update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'contact' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 my @contact=(ref($contact) eq 'ARRAY')? @$contact : ($contact);
 my @c=map { Net::DRI::Util::isa_contact($_)? $_->srid() : $_ } @contact;

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless @c;
 foreach my $n (@c)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless defined($n) && $n;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$n) unless Net::DRI::Util::xml_is_token($n,3,16);
 }

 my $tcommand=(ref($command))? $command->[0] : $command;
 $msg->command([$command,'contact:'.$tcommand,sprintf('xmlns:contact="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('contact'))]);

 my @d=map { ['contact:id',$_] } @c;

 if (($tcommand=~m/^(?:info|transfer)$/) && ref($contact[0]) && Net::DRI::Util::isa_contact($contact[0]))
 {
  push @d,build_authinfo($contact[0]);
 }

 return @d;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$c);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_response('contact','chkData');
 return unless defined $chkdata;
 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('contact'),'cd'))
 {
  my $contact;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'id')
   {
    $contact=$c->textContent();
    $rinfo->{contact}->{$contact}->{action}='check';
    $rinfo->{contact}->{$contact}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'reason')
   {
    $rinfo->{contact}->{$contact}->{exist_reason}=$c->textContent();
   }
  }
 }
 return;
}

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

 my $infdata=$mes->get_response('contact','infData');
 return unless defined $infdata;

 my %cd=map { $_ => [] } qw/name org city sp pc cc/;
 $cd{street}=[[],[]];
 my $contact=$po->create_local_object('contact');
 my @s;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   $oname=$c->textContent();
   $rinfo->{contact}->{$oname}->{action}='info';
   $rinfo->{contact}->{$oname}->{exist}=1;
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $contact->srid($oname);
  } elsif ($name eq 'roid')
  {
   $contact->roid($c->textContent());
   $rinfo->{contact}->{$oname}->{roid}=$contact->roid();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'email')
  {
   $contact->email($c->textContent());
  } elsif ($name eq 'voice')
  {
   $contact->voice(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  } elsif ($name eq 'fax')
  {
   $contact->fax(Net::DRI::Protocol::EPP::Util::parse_tel($c));
  } elsif ($name eq 'postalInfo')
  {
   parse_postalinfo($po,$c,\%cd);
  } elsif ($name eq 'authInfo') ## we only try to parse the authInfo version defined in the RFC, other cases are to be handled by extensions
  {
   $contact->auth({pw => Net::DRI::Util::xml_child_content($c,$mes->ns('contact'),'pw')});
  } elsif ($name eq 'disclose')
  {
   $contact->disclose(parse_disclose($c));
  }
 }

 $contact->name(@{$cd{name}});
 $contact->org(@{$cd{org}});
 $contact->street(@{$cd{street}});
 $contact->city(@{$cd{city}});
 $contact->sp(@{$cd{sp}});
 $contact->pc(@{$cd{pc}});
 $contact->cc(@{$cd{cc}});

 $rinfo->{contact}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{contact}->{$oname}->{self}=$contact;
 return;
}

sub parse_postalinfo
{
 my ($epp,$c,$rcd)=@_;
 my $type=$c->getAttribute('type'); ## int or loc, mandatory in EPP !
 $type=$epp->{defaulti18ntype} if (!defined($type) && defined($epp->{defaulti18ntype}));
 my $ti={loc=>0,int=>1}->{$type};

 foreach my $el (Net::DRI::Util::xml_list_children($c))
 {
  my ($name,$n)=@$el;
  if ($name eq 'name')
  {
   $rcd->{name}->[$ti]=$n->textContent();
  } elsif ($name eq 'org')
  {
   $rcd->{org}->[$ti]=$n->textContent();
  } elsif ($name eq 'addr')
  {
   my @street;
   foreach my $sel (Net::DRI::Util::xml_list_children($n))
   {
    my ($name2,$nn)=@$sel;
    if ($name2 eq 'street')
    {
     push @street,$nn->textContent();
    } elsif ($name2 eq 'city')
    {
     $rcd->{city}->[$ti]=$nn->textContent();
    } elsif ($name2 eq 'sp')
    {
     $rcd->{sp}->[$ti]=$nn->textContent();
    } elsif ($name2 eq 'pc')
    {
     $rcd->{pc}->[$ti]=$nn->textContent();
    } elsif ($name2 eq 'cc')
    {
     $rcd->{cc}->[$ti]=$nn->textContent();
    }
   }
   $rcd->{street}->[$ti]=\@street;
  }
 }
 return;
}

sub parse_disclose ## RFC 4933 §2.9
{
 my $c=shift;
 my $flag=Net::DRI::Util::xml_parse_boolean($c->getAttribute('flag'));
 my %tmp;
 foreach my $el (Net::DRI::Util::xml_list_children($c))
 {
  my ($name,$n)=@$el;
  if ($name=~m/^(name|org|addr)$/)
  {
   my $t=$n->getAttribute('type');
   $tmp{$1.'_'.$t}=$flag;
  } elsif ($name=~m/^(voice|fax|email)$/)
  {
   $tmp{$1}=$flag;
  }
 }
 return \%tmp;
}

sub transfer_query
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'query'}],$c);
 $mes->command_body(\@d);
 return;
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_response('contact','trnData');
 return unless defined $trndata;

 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   $oname=$c->textContent();
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $rinfo->{contact}->{$oname}->{action}='transfer';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(reDate|acDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

############ Transform commands

sub build_authinfo
{
 my $contact=shift;
 my $az=$contact->auth();
 return () unless ($az && ref($az) && exists($az->{pw}));
 return ['contact:authInfo',['contact:pw',$az->{pw}]];
}

sub build_disclose
{
 my $contact=shift;
 my $d=$contact->disclose();
 return () unless ($d && ref($d));
 my %v=map { $_ => 1 } values(%$d);
 return () unless (keys(%v)==1); ## 1 or 0 as values, not both at same time
 my @d;
 push @d,['contact:name',{type=>'int'}] if (exists($d->{name_int}) && !exists($d->{name}));
 push @d,['contact:name',{type=>'loc'}] if (exists($d->{name_loc}) && !exists($d->{name}));
 push @d,['contact:name',{type=>'int'}],['contact:name',{type=>'loc'}] if exists($d->{name});
 push @d,['contact:org',{type=>'int'}] if (exists($d->{org_int}) && !exists($d->{org}));
 push @d,['contact:org',{type=>'loc'}] if (exists($d->{org_loc}) && !exists($d->{org}));
 push @d,['contact:org',{type=>'int'}],['contact:org',{type=>'loc'}] if exists($d->{org});
 push @d,['contact:addr',{type=>'int'}] if (exists($d->{addr_int}) && !exists($d->{addr}));
 push @d,['contact:addr',{type=>'loc'}] if (exists($d->{addr_loc}) && !exists($d->{addr}));
 push @d,['contact:addr',{type=>'int'}],['contact:addr',{type=>'loc'}] if exists($d->{addr});
 push @d,['contact:voice'] if exists($d->{voice});
 push @d,['contact:fax']   if exists($d->{fax});
 push @d,['contact:email'] if exists($d->{email});
 return ['contact:disclose',@d,{flag=>(keys(%v))[0]}];
}

sub build_cdata
{
 my ($contact,$v)=@_;
 my $hasloc=$contact->has_loc();
 my $hasint=$contact->has_int();
 if ($hasint && !$hasloc && (($v & 5) == $v))
 {
  $contact->int2loc();
  $hasloc=1;
 } elsif ($hasloc && !$hasint && (($v & 6) == $v))
 {
  $contact->loc2int();
  $hasint=1;
 }

 my (@postl,@posti,@addrl,@addri);
 _do_locint(\@postl,\@posti,$contact,'name');
 _do_locint(\@postl,\@posti,$contact,'org');
 _do_locint(\@addrl,\@addri,$contact,'street');
 _do_locint(\@addrl,\@addri,$contact,'city');
 _do_locint(\@addrl,\@addri,$contact,'sp');
 _do_locint(\@addrl,\@addri,$contact,'pc');
 _do_locint(\@addrl,\@addri,$contact,'cc');
 push @postl,['contact:addr',@addrl] if @addrl;
 push @posti,['contact:addr',@addri] if @addri;

 my @d;
 push @d,['contact:postalInfo',@postl,{type=>'loc'}] if (($v & 5) && $hasloc); ## loc+int OR loc
 push @d,['contact:postalInfo',@posti,{type=>'int'}] if (($v & 6) && $hasint); ## loc+int OR int

 push @d,Net::DRI::Protocol::EPP::Util::build_tel('contact:voice',$contact->voice()) if defined($contact->voice());
 push @d,Net::DRI::Protocol::EPP::Util::build_tel('contact:fax',$contact->fax()) if defined($contact->fax());
 push @d,['contact:email',$contact->email()] if defined($contact->email());
 push @d,build_authinfo($contact);
 push @d,build_disclose($contact);

 return @d;
}

sub _do_locint
{
 my ($rl,$ri,$contact,$what)=@_;
 my @tmp=$contact->$what();
 return unless @tmp;
 if ($what eq 'street')
 {
  if (defined($tmp[0])) { foreach (@{$tmp[0]}) { push @$rl,['contact:street',$_]; } };
  if (defined($tmp[1])) { foreach (@{$tmp[1]}) { push @$ri,['contact:street',$_]; } };
 } else
 {
  if (defined($tmp[0])) { push @$rl,['contact:'.$what,$tmp[0]]; }
  if (defined($tmp[1])) { push @$ri,['contact:'.$what,$tmp[1]]; }
 }
 return;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$contact);

 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$contact) unless Net::DRI::Util::isa_contact($contact);
 $contact->validate(); ## will trigger an Exception if needed
 push @d,build_cdata($contact,$epp->{contacti18n});
 $mes->command_body(\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('contact','creData');
 return unless defined $credata;

 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   my $new=$c->textContent();
   $rinfo->{contact}->{$oname}->{id}=$new if (defined $oname && ($oname ne $new)); ## registry may give another id than the one we requested or not take ours into account at all !
   $oname=$new;
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $rinfo->{contact}->{$oname}->{action}='create';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$contact);
 $mes->command_body(\@d);
 return;
}

sub transfer_request
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'request'}],$c);
 $mes->command_body(\@d);
 return;
}

sub transfer_cancel
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'cancel'}],$c);
 $mes->command_body(\@d);
 return;
}

sub transfer_answer
{
 my ($epp,$c,$ep)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>((Net::DRI::Util::has_key($ep,'approve') && $ep->{approve})? 'approve' : 'reject' )}],$c);
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');

 my @d=build_command($mes,'update',$contact);
 push @d,['contact:add',$sadd->build_xml('contact:status')] if Net::DRI::Util::isa_statuslist($sadd);
 push @d,['contact:rem',$sdel->build_xml('contact:status')] if Net::DRI::Util::isa_statuslist($sdel);

 my $newc=$todo->set('info');
 if (defined $newc)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc);
  $newc->validate(1); ## will trigger an Exception if needed
  my @c=build_cdata($newc,$epp->{contacti18n});
  push @d,['contact:chg',@c] if @c;
 }
 $mes->command_body(\@d);
 return;
}

####################################################################################################
## RFC4933 §3.3 Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_response('contact','panData');
 return unless defined $pandata;

 foreach my $el (Net::DRI::Util::xml_list_children($pandata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   $oname=$c->textContent();
   $rinfo->{contact}->{$oname}->{action}='review';
   $rinfo->{contact}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
  } elsif ($name eq 'paTRID')
  {
   my $ns=$mes->ns('_main');
   my $tmp=Net::DRI::Util::xml_child_content($c,$ns,'clTRID');
   $rinfo->{contact}->{$oname}->{trid}=$tmp if defined $tmp;
   $rinfo->{contact}->{$oname}->{svtrid}=Net::DRI::Util::xml_child_content($c,$ns,'svTRID');
  } elsif ($name eq 'paDate')
  {
   $rinfo->{contact}->{$oname}->{date}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

####################################################################################################
1;
