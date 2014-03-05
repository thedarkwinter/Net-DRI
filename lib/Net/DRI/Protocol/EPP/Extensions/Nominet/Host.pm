## Domain Registry Interface, .UK EPP Host commands
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Host;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Host - .UK EPP Host commands for Net::DRI

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
	);

 return { 'host' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$hostname)=@_;
 my $roid=(Net::DRI::Util::isa_hosts($hostname))? $hostname->get_details(1)->[-1]->{roid} : $hostname;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Roid of NS object needed') unless (defined($roid) && $roid && !ref($roid));
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Invalid ROID: '.$roid) unless ($roid=~m/^NS\d+(?:-UK)?$/);

 $msg->command([$command,'ns:'.$command,sprintf('xmlns:ns="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('ns'))]);
 return (['ns:roid',$roid]);
}

####################################################################################################
########### Query commands

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
 my $infdata=$mes->get_response('ns','infData');
 return unless defined $infdata;
 parse_infdata($po,$mes,$infdata,$oname,$rinfo);
 return;
}

sub parse_infdata
{
 my ($po,$mes,$infdata,$oname,$rinfo)=@_;
 my ($hostname,@ip4,@ip6);
 my %i;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'roid')
  {
   $oname=$c->textContent();
   $i{action}='info';
   $i{exist}=1;
   $i{roid}=$oname;
  } elsif ($name eq 'name')
  {
   $hostname=lc($c->textContent());
   $i{name}=$hostname;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $i{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate)$/)
  {
   $i{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'addr')
  {
   my $ip=$c->textContent();
   my $ipv=$c->getAttribute('ip');
   push @ip4,$ip if ($ipv eq 'v4');
   push @ip6,$ip if ($ipv eq 'v6');
  }
 }

 while(my ($k,$v)=each(%i))
 {
  $rinfo->{host}->{$hostname}->{$k}=$rinfo->{host}->{$oname}->{$k}=$v;
 }
 $rinfo->{host}->{$hostname}->{self}=$rinfo->{host}->{$oname}->{self}=$po->create_local_object('hosts',$hostname,\@ip4,\@ip6,1,{roid=>$oname});
 return $rinfo->{host}->{$hostname}->{self};
}

############ Transform commands

sub update
{
 my ($epp,$ns,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 if ((grep { ! /^(?:set)$/ } $todo->types('ip')) ||
     (grep { ! /^(?:set)$/ } $todo->types('name'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only IP/name set available for host');
 }

 my $ipset=$todo->set('ip');
 my $newname=$todo->set('name');

 my @d=build_command($mes,'update',$ns);
 if (defined($newname) && $newname)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$newname) unless Net::DRI::Util::is_hostname($newname);
  push @d,['ns:name',$newname];
 }

 if (defined($ipset) && $ipset)
 {
  Net::DRI::Exception::usererr_invalid_parameters($ipset.' must be a Net::DRI::Data::Hosts object') unless Net::DRI::Util::isa_hosts($ipset);
  my ($name,$r4,$r6)=$ipset->get_details(1);
  push @d,['ns:addr',{ip=>'v4'},$r4->[0]] if @$r4; ## it seems only one IP is allowed
  push @d,['ns:addr',{ip=>'v6'},$r6->[0]] if @$r6; ## ditto
 }

 $mes->command_body(\@d);
 return;
}

####################################################################################################
1;
