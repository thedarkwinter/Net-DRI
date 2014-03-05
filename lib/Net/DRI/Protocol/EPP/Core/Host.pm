## Domain Registry Interface, EPP Host commands (RFC5732)
##
## Copyright (c) 2005-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Host;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Host - EPP Host commands (RFC5732) for Net::DRI

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
 my %tmp=( create => [ \&create, \&create_parse ],
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           delete => [ \&delete ],
	   update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'host' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$hostname)=@_;
 my @n=map { Net::DRI::Util::isa_hosts($_)? $_->get_names() : $_ } ((ref($hostname) eq 'ARRAY')? @$hostname : ($hostname));

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Host name needed') unless @n;
 foreach my $n (@n)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Host name needed') unless (defined($n) && $n && !ref($n));
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$n) unless Net::DRI::Util::is_hostname($n);
 }

 $msg->command([$command,'host:'.$command,sprintf('xmlns:host="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('host'))]);

 my @d=map { ['host:name',$_] } @n;
 return @d;
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$ns);
 $mes->command_body(\@d);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_response('host','chkData');
 return unless defined $chkdata;
 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('host'),'cd'))
 {
  my $host;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $host=lc($c->textContent());
    $rinfo->{host}->{$host}->{action}='check';
    $rinfo->{host}->{$host}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'reason')
   {
    $rinfo->{host}->{$host}->{exist_reason}=$c->textContent();
   }
  }
 }
 return;
}

sub info
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$ns);
 $mes->command_body(\@d);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_response('host','infData');
 return unless defined $infdata;

 my (@s,@ip4,@ip6);
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{host}->{$oname}->{action}='info';
   $rinfo->{host}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'roid')
  {
   $rinfo->{host}->{$oname}->{roid}=$c->textContent();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::Util::parse_node_status($c);
  } elsif ($name eq 'addr')
  {
   my $ip=$c->textContent();
   my $ipv=$c->getAttribute('ip');
   $ipv='v4' unless (defined($ipv) && $ipv);
   push @ip4,$ip if ($ipv eq 'v4');
   push @ip6,$ip if ($ipv eq 'v6');
  }
 }

 $rinfo->{host}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{host}->{$oname}->{self}=$po->create_local_object('hosts',$oname,\@ip4,\@ip6,1);
 return;
}

############ Transform commands

sub create
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$ns);
 push @d,add_ip($ns) if Net::DRI::Util::isa_hosts($ns);
 $mes->command_body(\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('host','creData');
 return unless defined $credata;

 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{host}->{$oname}->{action}='create';
   $rinfo->{host}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub delete ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$ns);
 $mes->command_body(\@d);
 return;
}

sub update
{
 my ($epp,$ns,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a non empty Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $nsadd=$todo->add('ip');
 my $nsdel=$todo->del('ip');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $newname=$todo->set('name');

 unless (defined($ns) && $ns)
 {
  $ns=$nsadd->get_names(1) if Net::DRI::Util::isa_hosts($nsadd);
  $ns=$nsdel->get_names(1) if Net::DRI::Util::isa_hosts($nsdel);
 }

 my (@add,@rem);
 push @add,add_ip($nsadd)                  if Net::DRI::Util::isa_hosts($nsadd);
 push @add,$sadd->build_xml('host:status') if Net::DRI::Util::isa_statuslist($sadd);
 push @rem,add_ip($nsdel)                  if Net::DRI::Util::isa_hosts($nsdel);
 push @rem,$sdel->build_xml('host:status') if Net::DRI::Util::isa_statuslist($sdel);

 my @d=build_command($mes,'update',$ns);
 push @d,['host:add',@add] if @add;
 push @d,['host:rem',@rem] if @rem;

 if (defined($newname) && length $newname)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$newname) unless Net::DRI::Util::is_hostname($newname);
  push @d,['host:chg',['host:name',$newname]];
 }
 $mes->command_body(\@d);
 return;
}

sub add_ip
{
 my ($ns)=@_;
 my @ip;
 my ($name,$r4,$r6)=$ns->get_details(1);
 push @ip,map { ['host:addr',$_,{ip=>'v4'}] } @$r4 if @$r4;
 push @ip,map { ['host:addr',$_,{ip=>'v6'}] } @$r6 if @$r6;
 return @ip;
}

####################################################################################################
## RFC4932 §3.3  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_response('host','panData');
 return unless defined $pandata;

 foreach my $el (Net::DRI::Util::xml_list_children($pandata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{host}->{$oname}->{action}='review';
   $rinfo->{host}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
  } elsif ($name eq 'paTRID')
  {
   my $ns=$mes->ns('_main');
   my $tmp=Net::DRI::Util::xml_child_content($c,$ns,'clTRID');
   $rinfo->{host}->{$oname}->{trid}=$tmp if defined $tmp;
   $rinfo->{host}->{$oname}->{svtrid}=Net::DRI::Util::xml_child_content($c,$ns,'svTRID');
  } elsif ($name eq 'paDate')
  {
   $rinfo->{host}->{$oname}->{date}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

####################################################################################################
1;
