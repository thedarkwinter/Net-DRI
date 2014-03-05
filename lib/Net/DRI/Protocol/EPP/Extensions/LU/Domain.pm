## Domain Registry Interface, .LU Domain EPP extension commands
##
## Copyright (c) 2007,2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

use DateTime::Format::ISO8601;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU::Domain - .LU EPP Domain extension commands for Net::DRI

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

Copyright (c) 2007,2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
          info    => [ undef, \&info_parse ],
          create  => [ \&create,  undef    ],
          update  => [ \&update,  undef    ],
          delete  => [ \&delete,  undef    ],
          restore => [ \&restore, undef    ],
          transfer_request => [ \&transfer_request, \&transfer_parse ],
          transfer_query   => [ undef             , \&transfer_parse ],
          trade_request    => [ \&trade_request   , \&trade_parse    ],
          trade_query      => [ \&trade_query     , \&trade_parse    ],
          trade_cancel     => [ \&trade_cancel    , undef            ],
          transfer_trade_request => [ \&transfer_trade_request, \&transfer_trade_parse ],
          transfer_trade_query   => [ \&transfer_trade_query  , \&transfer_trade_parse ],
          transfer_trade_cancel  => [ \&transfer_trade_cancel , undef ],
          transfer_restore_request => [ \&transfer_restore_request, \&transfer_restore_parse ],
          transfer_restore_query   => [ \&transfer_restore_query  , \&transfer_restore_parse ],
          transfer_restore_cancel  => [ \&transfer_restore_cancel , undef ],
         );

 return { 'domain' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:dnslu="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('dnslu')));
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('dnslu','ext');
 return unless $infdata;
 my $ns=$mes->ns('dnslu');
 $infdata=$infdata->getChildrenByTagNameNS($ns,'resData');
 return unless $infdata->size();
 $infdata=$infdata->shift()->getChildrenByTagNameNS($ns,'infData');
 return unless $infdata->size();
 $infdata=$infdata->shift()->getChildrenByTagNameNS($ns,'domain');
 return unless $infdata->size();

 my $pd=DateTime::Format::ISO8601->new();
 my $c=$infdata->shift()->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'idn')
  {
   ## currently not used
  } elsif ($name eq 'status')
  {
   $rinfo->{domain}->{$oname}->{status}->add($c->getFirstChild()->getData());
  } elsif ($name eq 'crReqID')
  {
   $rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData();  
  } elsif ($name=~m/^(crReqDate|delReqDate|delDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$pd->parse_datetime($c->getFirstChild()->getData());
  }

 } continue { $c=$c->getNextSibling(); }
 return;
}

sub verify_contacts
{
 my $rd=shift;
 Net::DRI::Exception::usererr_invalid_parameters('.LU needs contact for domain_create/domain_transfer/domain_trade') unless Net::DRI::Util::has_contact($rd);
 my @t=$rd->{contact}->types();
 Net::DRI::Exception::usererr_invalid_parameters('.LU needs registrant, admin and tech contacts only') unless ($t[0] eq 'admin' && $t[1] eq 'registrant' && $t[2] eq 'tech');
 foreach my $t (qw/registrant admin tech/)
 {
  my @t=$rd->{contact}->get($t);
  Net::DRI::Exception::usererr_invalid_parameters('.LU needs only one contact of type '.$t) unless @t==1;
 }
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 verify_contacts($rd);

 ## idn is not handled

 return unless Net::DRI::Util::has_key($rd,'status');
 my @n=map { ['dnslu:status',{ s => $_ }] } (Net::DRI::Util::isa_statuslist($rd->{status})? $rd->{status}->list_status() : @{$rd->{status}});

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:create',['dnslu:domain',@n]]);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my @n;
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my (@add,@del);
 push @add,$sadd->build_xml('dnslu:status','dnslu') if $sadd;
 push @del,$sdel->build_xml('dnslu:status','dnslu') if $sdel;
 push @n,['dnslu:add',@add] if @add;
 push @n,['dnslu:rem',@del] if @del;
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:update',['dnslu:domain',@n]]);
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (defined($rd) && ref($rd) && exists($rd->{delDate}) && ($rd->{delDate}=~m/^(?:immediate|cancel)$/ || Net::DRI::Util::is_class($rd->{delDate},'DateTime')));

 my @n;
 if ($rd->{delDate}=~m/^(?:immediate|cancel)$/)
 {
  @n=['dnslu:op',$rd->{delDate}];
 } else
 {
  @n=['dnslu:op','setDate'];
  push @n,['dnslu:delDate',$rd->{delDate}->set_time_zone('UTC')->strftime('%Y-%m-%dT%TZ')];
 }

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:delete',['dnslu:domain',@n]]);
 return;
}

sub build_command
{
 my ($domain)=@_;

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless (defined($domain) && $domain && !ref($domain));
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Domain name not in .LU: '.$domain) unless $domain=~m/\.LU$/i;

 return ['dnslu:name',$domain];
}

sub restore
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:restore',['dnslu:domain',build_command($domain)]]]);
 return;
}

sub build_transfer_trade_restore
{
 my ($rd)=@_;
 my @n;

 verify_contacts($rd);
 
 push @n,['dnslu:ns',map { ['dnslu:hostObj',$_] } $rd->{ns}->get_names() ] if Net::DRI::Util::has_ns($rd);
 my $cs=$rd->{contact};
 push @n,['dnslu:registrant',$cs->get('registrant')->srid()];
 push @n,['dnslu:contact',{type => 'admin'},$cs->get('admin')->srid()];
 push @n,['dnslu:contact',{type => 'tech'},$cs->get('tech')->srid()];
 push @n,map { ['dnslu:status',{ s => $_ }] } (Net::DRI::Util::isa_statuslist($rd->{status})? $rd->{status}->list_status() : @{$rd->{status}}) if Net::DRI::Util::has_key($rd,'status');
 ## IDN not used
 push @n,['dnslu:trDate',$rd->{trDate}->set_time_zone('UTC')->strftime('%Y-%m-%d')] if (exists($rd->{trDate}) && defined($rd->{trDate}) && Net::DRI::Util::check_isa($rd->{trDate},'DateTime'));
 return @n;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:transfer',['dnslu:domain',build_transfer_trade_restore($rd)]]);
 return;
}

sub transfer_parse ## for request & query
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_transfer_trade_restore($po,$otype,$oaction,$oname,$rinfo,'trnData');
 return;
}

sub parse_transfer_trade_restore
{
 my ($po,$otype,$oaction,$oname,$rinfo,$s)=@_;
 my $mes=$po->message();

 my $infdata=$mes->get_extension('dnslu','ext');
 return unless $infdata;
 my $ns=$mes->ns('dnslu');
 $infdata=$infdata->getChildrenByTagNameNS($ns,'resData');
 return unless $infdata->size();
 $infdata=$infdata->shift()->getChildrenByTagNameNS($ns,$s);
 return unless $infdata->size();
 $infdata=$infdata->shift()->getChildrenByTagNameNS($ns,'domain');
 return unless $infdata->size();

 my $pd=DateTime::Format::ISO8601->new();
 my $c=$infdata->shift->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'idn')
  {
   ## currently not used
  } elsif ($name=~m/^(trStatus|reID)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(reDate|acDate|trDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$pd->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

sub trade_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:trade',{op=>'request'},['dnslu:domain',build_command($domain),build_transfer_trade_restore($rd)]]]);
 return;
}

sub trade_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_transfer_trade_restore($po,$otype,$oaction,$oname,$rinfo,'traData');
 return;
}

sub trade_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:trade',{op=>'query'},['dnslu:domain',build_command($domain)]]]);
 return;
}

sub trade_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:trade',{op=>'cancel'},['dnslu:domain',build_command($domain)]]]);
 return;
}

sub transfer_trade_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferTrade',{op=>'request'},['dnslu:domain',build_command($domain),build_transfer_trade_restore($rd)]]]);
 return;
}

sub transfer_trade_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_transfer_trade_restore($po,$otype,$oaction,$oname,$rinfo,'trnTraData');
 return;
}

sub transfer_trade_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferTrade',{op=>'query'},['dnslu:domain',build_command($domain)]]]);
 return;
}

sub transfer_trade_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferTrade',{op=>'cancel'},['dnslu:domain',build_command($domain)]]]);
 return;
}

sub transfer_restore_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferRestore',{op=>'request'},['dnslu:domain',build_command($domain),build_transfer_trade_restore($rd)]]]);
 return;
}

sub transfer_restore_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_transfer_trade_restore($po,$otype,$oaction,$oname,$rinfo,'trnResData');
 return;
}

sub transfer_restore_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferRestore',{op=>'query'},['dnslu:domain',build_command($domain)]]]);
 return;
}

sub transfer_restore_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:command',['dnslu:transferRestore',{op=>'cancel'},['dnslu:domain',build_command($domain)]]]);
 return;
}

####################################################################################################
1;
