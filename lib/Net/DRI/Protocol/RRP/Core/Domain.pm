## Domain Registry Interface, RRP Domain commands
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

package Net::DRI::Protocol::RRP::Core::Domain;

use strict;
use warnings;

use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::RRP::Core::Status;
use Net::DRI::Protocol::RRP;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Core::Domain - RRP Domain commands for Net::DRI

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


##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( create => [ \&add, \&add_parse ],
           check  => [ \&check, \&check_parse ],
           info   => [ \&status, \&status_parse ],
           delete => [ \&del ],
	   renew  => [ \&renew, \&renew_parse ],
	   update => [ \&mod ],
	   transfer_request => [ \&transfer_request ],
	   transfer_answer  => [ \&transfer_answer ],
         );

 $tmp{transfer_cancel}=[ \&transfer_answer ] if ($version eq "2.0");
 return { 'domain' => \%tmp };
}

sub build_msg
{
 my ($msg,$command,$domain)=@_;
 Net::DRI::Exception->die(1,'protocol/RRP',2,"Domain name needed") unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/RRP',10,"Invalid domain name") unless ($domain=~m/^[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?$/i); ## from RRP grammar
 $msg->command($command) if defined($command);
 $msg->entities('EntityName','Domain');
 $msg->entities('DomainName',uc $domain);
 return;
}

sub add
{
 my ($rrp,$domain,$rd)=@_;
 my $mes=$rrp->message();
 build_msg($mes,'add',$domain);

 ## (MAY)
 if (Net::DRI::Util::has_duration($rd))
 {
  my $period=$rd->{duration}->years();
  Net::DRI::Exceptions::usererr_invalid_parameters('period must be an integer') unless Net::DRI::Util::isint($period);
  $mes->options('Period',$period);
 }
 ## (MAY) 1 to 13 nameservers
 if (Net::DRI::Util::has_ns($rd))
 {
  foreach ($rd->{ns}->get_names(13)) { $mes->entities('NameServer',$_); }
 }
 return;
}

sub add_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 ## Create a new DataTime object
 my $d='registration expiration date';
 $rinfo->{domain}->{$oname}->{$Net::DRI::Protocol::RRP::DATES{$d}}=$po->{dt_parse}->parse_datetime($mes->entities($d));
 $rinfo->{domain}->{$oname}->{status}=Net::DRI::Protocol::RRP::Core::Status->new($mes);
 $rinfo->{domain}->{$oname}->{exist}=1;
 $rinfo->{domain}->{$oname}->{action}='create';
 return;
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 add_parse($po,$otype,$oaction,$oname,$rinfo);
 $rinfo->{domain}->{$oname}->{action}='renew' if (exists($rinfo->{domain}->{$oname}->{action}));
 return;
}

sub _basic_command
{
 my ($command,$rrp,$domain)=@_;
 my $mes=$rrp->message();
 build_msg($mes,$command,$domain);
 return;
}

sub check            { my (@args)=@_; return _basic_command('check',@args);    }
sub status           { my (@args)=@_; return _basic_command('status',@args);   }
sub del              { my (@args)=@_; return _basic_command('del',@args);      }
sub transfer_request { my (@args)=@_; return _basic_command('transfer',@args); }

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 if ($mes->errcode() == 211) ## domain exists
 {
  $rinfo->{domain}->{$oname}->{exist}=1;
 } elsif ($mes->errcode() == 210) ## domain available
 {
  $rinfo->{domain}->{$oname}->{exist}=0;
 }
 $rinfo->{domain}->{$oname}->{action}='check';
 return;
}

sub status_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 $rinfo->{domain}->{$oname}->{exist}=1;
 $rinfo->{domain}->{$oname}->{action}='info';

 while(my ($k,$v)=each(%Net::DRI::Protocol::RRP::DATES))
 {
  my $d=$mes->entities($k);
  next unless $d;
  $rinfo->{domain}->{$oname}->{$v}=$po->{dt_parse}->parse_datetime($d);
 }

 while(my ($k,$v)=each(%Net::DRI::Protocol::RRP::IDS))
 {
  my $d=$mes->entities($k);
  next unless $d;
  $rinfo->{domain}->{$oname}->{$v}=$d;
 }
 
 $rinfo->{domain}->{$oname}->{status}=Net::DRI::Protocol::RRP::Core::Status->new($mes);

 my @ns=$mes->entities('nameserver');
 $rinfo->{domain}->{$oname}->{ns}=Net::DRI::Data::Hosts->new_set(@ns);
 return;
}

sub transfer_answer
{
 my ($rrp,$domain,$rd)=@_;
 my $mes=$rrp->message();
 build_msg($mes,'transfer',$domain);

 $mes->entities('Approve',(defined($rd) && ref($rd) && exists($rd->{approve}) && $rd->{approve})? 'Yes' : 'No');
 return;
}

sub mod
{
 my ($rrp,$domain,$todo)=@_;
 my $mes=$rrp->message();
 build_msg($mes,'mod',$domain);

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 if ((grep { ! /^(?:ns|status)$/ } $todo->types()) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('ns')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('status'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/RRP',11,'Only ns/status add/del available for domain');
 }

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $statadd=$todo->add('status');
 my $statdel=$todo->del('status');
 
 ## $nsadd/$nsdel are Net::DRI::Data::Hosts objects
 ## Up to 13 nameservers only
 if (defined($nsadd) && !$nsadd->is_empty()) { foreach ($nsadd->get_names(13)) { $mes->entities('NameServer',$_) } }
 if (defined($nsdel) && !$nsdel->is_empty()) { foreach ($nsdel->get_names(13)) { $mes->entities('NameServer',$_.'=') } }

 ## $statadd/$statdel are Net::DRI::Protocol::RRP::Core::Status objects
 if (defined($statadd)) { foreach ($statadd->list_status()) { $mes->entities('Status',$_)     } }
 if (defined($statdel)) { foreach ($statdel->list_status()) { $mes->entities('Status',$_.'=') } }
 return;
}

sub renew
{
 my ($rrp,$domain,$rd)=@_;
 my ($period,$curexp);
 if (defined($rd) && (ref($rd) eq 'HASH') && keys(%$rd))
 {
  $period=$rd->{duration};
  $curexp=$rd->{current_expiration};
 }
 Net::DRI::Exceptions::usererr_insufficient_parameters("current expiration year and period must be both defined or not at all") if (defined($curexp) xor defined($period)); ## both or none should be defined
 if (defined($curexp))
 {
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  $period=$period->years();
  Net::DRI::Exceptions::usererr_invalid_parameters("period must be an integer") unless Net::DRI::Util::isint($period);
  $curexp=$curexp->year() if (ref($curexp) && $curexp->can('year')); ## for DateTime objects
  Net::DRI::Exceptions::usererr_invalid_parameters("current expiration year must be a 4 digits integer") unless $curexp=~m/^\d{4}$/;
 }
 
 my $mes=$rrp->message();
 build_msg($mes,'renew',$domain);
 $mes->options({Period=>$period,CurrentExpirationYear=>$curexp}) if (defined($period) && defined($curexp));
 return;
}

####################################################################################################
1;
