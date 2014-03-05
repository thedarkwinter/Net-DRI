## Domain Registry Interface, BookMyName Web Services Domain commands
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

package Net::DRI::Protocol::BookMyName::WS::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::BookMyName::WS::Domain - BookMyName Web Services Domain commands for Net::DRI

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
		info  => [\&info, \&info_parse ],
		check => [\&check, \&check_parse ],
	  );

 return { 'domain' => \%tmp };
}

## From http://api.doc.free.org/revendeur-de-nom-de-domaine#status
sub parse_status
{
 my $s=shift;
 my @s;
 push @s,'clientDeleteProhibited' if ($s & 0x01);
 push @s,'serverDeleteProhibited' if ($s & 0x02);
 push @s,'clientHold' if ($s & 0x04);
 push @s,'serverHold' if ($s & 0x08);
 push @s,'clientRenewProhibited' if ($s & 0x10);
 push @s,'serverRenewProhibited' if ($s & 0x20);
 push @s,'clientTransferProhibited' if ($s & 0x40);
 push @s,'serverTransferProhibited' if ($s & 0x80);
 push @s,'clientUpdateProhibited' if ($s & 0x100);
 push @s,'serverUpdateProhibited' if ($s & 0x200);
 push @s,'pendingCreate' if ($s & 0x400);
 push @s,'pendingDelete' if ($s & 0x800);
 push @s,'pendingRenew' if ($s & 0x1000);
 push @s,'pendingTransfer' if ($s & 0x2000);
 push @s,'pendingUpdate' if ($s &0x4000);
 return @s? @s : ('ok');
}

sub build_msg
{
 my ($msg,$command,$domain)=@_;
 Net::DRI::Exception->die(1,'protocol/bookmyname/ws',2,'Domain name needed') unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/bookmyname/ws',10,'Invalid domain name') unless Net::DRI::Util::is_hostname($domain);

 $msg->method($command) if defined($command);
 return;
}

sub info
{
 my ($po,$domain)=@_;
 my $msg=$po->message();
 build_msg($msg,'domain_info',$domain);
 $msg->params([ $domain ]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $r=$mes->result();
 Net::DRI::Exception->die(1,'protocol/bookmyname/ws',1,'Unexpected reply for domain_info: '.$r) unless (ref($r) eq 'HASH');

 my %r=%$r;
 $oname=lc($r{domain});
 $rinfo->{domain}->{$oname}->{action}='info';
 $rinfo->{domain}->{$oname}->{exist}=1;
 $rinfo->{domain}->{$oname}->{roid}=$r{id};
 my %d=(registrar_creation => 'crDate', lastupdate => 'upDate', registrar_expiration => 'exDate');
 while (my ($k,$v)=each(%d))
 {
  next unless exists($r{$k});
  $rinfo->{domain}->{$oname}->{$v}=$po->parse_iso8601($r{$k});
 }
 $rinfo->{domain}->{$oname}->{upIP}=$r{lastupdate_ip};
 my %c=(owner_id => 'registrant', admin_id => 'admin', tech_id => 'tech', bill_id => 'billing');
 my $cs=$po->create_local_object('contactset');
 while (my ($k,$v)=each(%d))
 {
  next unless exists($r{$k});
  my $c=$po->create_local_object('contact')->srid($r{$k});
  $cs->add($c,$v);
 }
 $rinfo->{domain}->{$oname}->{contact}=$cs;
 $rinfo->{domain}->{$oname}->{auth}={pw => $r{authinfo}};

 foreach my $k (qw/service ip_dns_master/)
 {
  $rinfo->{domain}->{$oname}->{$k}=$r{$k} if (exists($r{$k}) && defined($r{$k}));
 }
 my $sl=$po->create_local_object('status');
 foreach my $s (parse_status($r{registry_status})) { $sl->add($s); }
 $rinfo->{domain}->{$oname}->{status}=$sl;
 ## $r{status} is not used, what is it ?

 my $ns=$po->create_local_object('hosts');
 foreach my $nsk (sort { ($a=~m/^ns(\d+)/)[0] <=> ($b=~m/^ns(\d+)/)[0] }  grep { /^ns\d+$/ } keys(%r)) { $ns->add($r{$nsk}); }
 $rinfo->{domain}->{$oname}->{ns}=$ns;
 return;
}

sub check
{
 my ($po,$domain)=@_;
 my $msg=$po->message();
 build_msg($msg,'domain_check',$domain);
 $msg->params([ $domain ]);
 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 if ($mes->retcode()==-1 && ($mes->retval()==-2 || $mes->retval()==-4)) ## domain does not exist
 {
  $mes->retcode(1); ## fake a success
 }
 return unless $mes->is_success();

 $rinfo->{domain}->{$oname}->{action}='check';
 $rinfo->{domain}->{$oname}->{exist}=($mes->retcode()==1 && $mes->retval()==1)? 1 : 0;
 return;
}

####################################################################################################
1;
