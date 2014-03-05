## Domain Registry Interface, RRP Host commands
##
## Copyright (c) 2005,2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::RRP::Core::Host;

use strict;
use warnings;

use Net::DRI::Protocol::RRP;
use Net::DRI::Data::Hosts;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Core::Host - RRP Host commands for Net::DRI

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

Copyright (c) 2005,2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#########################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( create => [ \&add ],
           check  => [ \&check, \&check_parse  ],
           info   => [ \&status, \&status_parse ],
           delete => [ \&del ],
           update => [ \&mod ],
         );

 return { 'host' => \%tmp };
}

sub build_msg
{
 my ($msg,$command,$hostname)=@_;
 ($hostname)=$hostname->get_names(1) if (defined($hostname) && ref($hostname));
 Net::DRI::Exception->die(1,'protocol/RRP',3,"Host name needed") unless defined($hostname) && $hostname;
 Net::DRI::Exception->die(1,'protocol/RRP',10,"Invalid host name") unless ($hostname=~m/^([a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.)*[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?$/i); ## from RRP grammar
 $msg->command($command) if defined($command);
 $msg->entities('EntityName','NameServer');
 $msg->entities('NameServer',uc $hostname);
 return;
}

sub add
{
 my ($rrp,$ns)=@_;
 my $mes=$rrp->message();
 build_msg($mes,'add',$ns);
 add_ip($mes,$ns,$rrp->version());
 return;
}

sub _basic_command
{
 my ($command,$rrp,$ns)=@_;
 my $mes=$rrp->message();
 build_msg($mes,$command,$ns);
 return;
}

sub check  { my (@args)=@_; return _basic_command('check',@args);  }
sub status { my (@args)=@_; return _basic_command('status',@args); }
sub del    { my (@args)=@_; return _basic_command('del',@args);    }

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 $rinfo->{host}->{$oname}->{action}='check';
 if ($mes->errcode() == 213) ## nameserver exists
 {
  my @ip=$mes->entities('ipaddress');
  $rinfo->{host}->{$oname}->{self}=Net::DRI::Data::Hosts->new($oname,\@ip);
  $rinfo->{host}->{$oname}->{exist}=1;
 } elsif ($mes->errcode() == 212) ## nameserver available
 {
  $rinfo->{host}->{$oname}->{exist}=0;
 }
 return;
}

sub status_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success(); ## if operation succeeds, information should be there

 $rinfo->{host}->{$oname}->{exist}=1;
 $rinfo->{host}->{$oname}->{action}='info';
 while(my ($k,$v)=each(%Net::DRI::Protocol::RRP::DATES))
 {
  my $d=$mes->entities($k);
  next unless $d;
  $rinfo->{host}->{$oname}->{$v}=$po->{dt_parse}->parse_datetime($d);
 }

 while(my ($k,$v)=each(%Net::DRI::Protocol::RRP::IDS))
 {
  my $d=$mes->entities($k);
  next unless $d;
  $rinfo->{host}->{$oname}->{$v}=$d;
 }

 my @ip=$mes->entities('ipaddress');
 $rinfo->{host}->{$oname}->{self}=Net::DRI::Data::Hosts->new($oname,\@ip);
 return;
}

sub mod
{
 my ($rrp,$hostname,$todo)=@_;
 my $mes=$rrp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 if ((grep { ! /^(?:ip|name)$/ } $todo->types()) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('ip')) ||
     (grep { ! /^(?:set)$/ } $todo->types('name'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/RRP',11,'Only IP add/del or name set available for host');
 }

 my $nsadd=$todo->add('ip');
 my $nsdel=$todo->del('ip');
 my $newname=$todo->set('name');
 
 unless (defined($hostname) && $hostname)
 {
  $hostname=$nsadd->get_names(1) if (defined($nsadd) && ref($nsadd) && $nsadd->can('get_names'));
  $hostname=$nsdel->get_names(1) if (defined($nsdel) && ref($nsdel) && $nsdel->can('get_names'));
 }
 build_msg($mes,'mod',$hostname);

 my $version=$rrp->version();
 add_ip($mes,$nsadd,$version);
 add_ip($mes,$nsdel,$version,'=');
 $mes->entities('NewNameServer',ref($newname)? $newname->get_names(1) : $newname) if (defined($newname) && $newname);
 return;
}

sub add_ip
{
 my ($mes,$ns,$version,$extra)=@_;
 $extra||='';
 return unless (defined($ns) && ref($ns));
 my ($name,$r4,$r6)=$ns->get_details(1);
 my $c=1;
 foreach my $ip (@$r4) { last if $c++>13; $mes->entities('IPAddress',$_.$extra); };
 $c=1;
 if ($version eq '2.0') { foreach my $ip (@$r6) { last if $c++>13; $mes->entities('IPAddress',$_.$extra); } }
 return;
}

#########################################################################################
1;
