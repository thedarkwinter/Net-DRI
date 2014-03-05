## Domain Registry Interface, EPP Domain commands (RFC5731)
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

package Net::DRI::Protocol::EPP::Core::Domain;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Domain - EPP Domain commands (RFC5731) for Net::DRI

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
           renew => [ \&renew, \&renew_parse ],
           transfer_request => [ \&transfer_request, \&transfer_parse ],
           transfer_cancel  => [ \&transfer_cancel,\&transfer_parse ],
           transfer_answer  => [ \&transfer_answer,\&transfer_parse ],
           update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'check',$domain);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_response('domain','chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('domain'),'cd'))
 {
  my $domain;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $domain=lc($c->textContent());
    $rinfo->{domain}->{$domain}->{action}='check';
    $rinfo->{domain}->{$domain}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   } elsif ($n eq 'reason')
   {
    $rinfo->{domain}->{$domain}->{exist_reason}=$c->textContent();
   }
  }
 }
 return;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $hosts=(defined $rd && ref $rd eq 'HASH' && exists $rd->{hosts} && $rd->{hosts}=~m/^(?:all|del|sub|none)$/)? $rd->{hosts} : 'all';
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'info',$domain,{'hosts'=> $hosts});
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('domain','infData');
 return unless defined $infdata;

 my (@s,@host);
 my $cs=$po->create_local_object('contactset');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'roid')
  {
   $rinfo->{domain}->{$oname}->{roid}=$c->textContent();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name eq 'registrant')
  {
   $cs->set($po->create_local_object('contact')->srid($c->textContent()),'registrant');
  } elsif ($name eq 'contact')
  {
   $cs->add($po->create_local_object('contact')->srid($c->textContent()),$c->getAttribute('type'));
  } elsif ($name eq 'ns')
  {
   $rinfo->{domain}->{$oname}->{ns}=Net::DRI::Protocol::EPP::Util::parse_ns($po,$c);
  } elsif ($name eq 'host')
  {
   push @host,$c->textContent();
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'authInfo') ## we only try to parse the authInfo version defined in the RFC, other cases are to be handled by extensions
  {
   $rinfo->{domain}->{$oname}->{auth}={pw => Net::DRI::Util::xml_child_content($c,$mes->ns('domain'),'pw')};
  }
 }

 $rinfo->{domain}->{$oname}->{contact}=$cs;
 $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{domain}->{$oname}->{subordinate_hosts}=$po->create_local_object('hosts')->set(@host) if @host;
 return;
}

sub transfer_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'query'}],$domain);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
 return;
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_response('domain','trnData');
 return unless defined $trndata;

 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='transfer';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(reDate|acDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'create',$domain);

 my $def=$epp->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) && (ref($def->{domain_create}) eq 'HASH'))
 {
  $rd={} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while(my ($k,$v)=each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k}=$v;
  }
 }

 ## Period, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 ## Nameservers, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Util::build_ns($epp,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 ## Contacts, all OPTIONAL
 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o && Net::DRI::Util::isa_contact($o[0]));
  push @d,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cs);
 }

 ## AuthInfo
 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth});
 $mes->command_body(\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('domain','creData');
 return unless defined $credata;

 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='create';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'delete',$domain);
 $mes->command_body(\@d);
 return;
}

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $curexp=Net::DRI::Util::has_key($rd,'current_expiration')? $rd->{current_expiration} : undef;
 Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
 $curexp=$curexp->clone()->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;

 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'renew',$domain);
 push @d,['domain:curExpDate',$curexp];
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 $mes->command_body(\@d);
 return;
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_response('domain','renData');
 return unless defined $rendata;

 foreach my $el (Net::DRI::Util::xml_list_children($rendata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='renew';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'request'}],$domain);
 push @d,Net::DRI::Protocol::EPP::Util::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
 return;
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>(Net::DRI::Util::has_key($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}],$domain);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
 return;
}

sub transfer_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
 push @d,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');

 my (@add,@del);
 push @add,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsadd,$domain)         if Net::DRI::Util::isa_hosts($nsadd);
 push @add,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cadd)       if Net::DRI::Util::isa_contactset($cadd);
 push @add,$sadd->build_xml('domain:status','core')                             if Net::DRI::Util::isa_statuslist($sadd);
 push @del,Net::DRI::Protocol::EPP::Util::build_ns($epp,$nsdel,$domain,undef,1) if Net::DRI::Util::isa_hosts($nsdel);
 push @del,Net::DRI::Protocol::EPP::Util::build_core_contacts($epp,$cdel)       if Net::DRI::Util::isa_contactset($cdel);
 push @del,$sdel->build_xml('domain:status','core') if Net::DRI::Util::isa_statuslist($sdel);

 my @d=Net::DRI::Protocol::EPP::Util::domain_build_command($mes,'update',$domain);
 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
 $chg=$todo->set('auth');
 push @chg,Net::DRI::Protocol::EPP::Util::domain_build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
 push @d,['domain:chg',@chg] if @chg;
 $mes->command_body(\@d);
 return;
}

####################################################################################################
## RFC4931 §3.3  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_response('domain','panData');
 return unless defined $pandata;

 foreach my $el (Net::DRI::Util::xml_list_children($pandata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='review';
   $rinfo->{domain}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
  } elsif ($name eq 'paTRID')
  {
   my $ns=$mes->ns('_main');
   my $tmp=Net::DRI::Util::xml_child_content($c,$ns,'clTRID');
   $rinfo->{domain}->{$oname}->{trid}=$tmp if defined $tmp;
   $rinfo->{domain}->{$oname}->{svtrid}=Net::DRI::Util::xml_child_content($c,$ns,'svTRID');
  } elsif ($name eq 'paDate')
  {
   $rinfo->{domain}->{$oname}->{date}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

####################################################################################################
1;
