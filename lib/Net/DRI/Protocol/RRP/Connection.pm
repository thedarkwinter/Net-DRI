## Domain Registry Interface, RRP Connection handling
##
## Copyright (c) 2005,2007-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::RRP::Connection;

use strict;
use warnings;

use Net::DRI::Protocol::RRP::Message;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Data::Raw;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Connection - RRP Connection handling for Net::DRI

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

Copyright (c) 2005,2007-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub login
{
 my ($class,$cm,$id,$pass,$cltrid,$dr,$newpass)=@_;
 my %h=(Id => $id, Password => $pass);
 $h{NewPassword}=$newpass if (defined($newpass) && $newpass);
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'session', options => \%h});
 return $mes;
}

sub logout
{
 my ($class,$cm,$cltrid)=@_;
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'quit' });
 return $mes;
}

sub keepalive
{
 my ($class,$cm,$cltrid)=@_;
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'describe' });
 return $mes;
}

####################################################################################################

sub read_data
{
 my ($class,$to,$sock)=@_;

 my (@l);
 while(my $l=$sock->getline())
 {
  push @l,$l;
  last if ($l=~m/^\.\s*\n?$/);
 }
 @l=map { Net::DRI::Util::decode_ascii($_); } @l;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING',@l? $l[0] : '<empty message from server>','en')) unless (@l && $l[-1]=~m/^\.\s*\n?$/);
 return Net::DRI::Data::Raw->new_from_array(\@l);
}

sub write_message
{
 my ($self,$to,$msg)=@_;
 return Net::DRI::Util::encode_ascii($msg);
}

sub parse_greeting
{
 my ($class,$dc)=@_;
 my ($code,$msg)=find_code($dc);
 unless (defined($code) && ($code==0))
 {
  return Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',($msg || '?').' ('.($code || '?').')','en');
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Greeting OK','en');
 }
}

sub parse_login
{
 my ($class,$dc)=@_;
 my ($code,$msg)=find_code($dc);
 unless (defined($code) && ($code==200))
 {
  my $eppcode=(defined($code))? Net::DRI::Protocol::RRP::Message::_eppcode($code) : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,($msg || 'Login failed').' ('.($code || '?').')','en');
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',$msg || 'Login OK','en');
 }
}

sub parse_logout
{
 my ($class,$dc)=@_;
 my ($code,$msg)=find_code($dc);
 unless (defined($code) && ($code==220))
 {
  my $eppcode=(defined($code))? Net::DRI::Protocol::RRP::Message::_eppcode($code) : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,($msg || 'Logout failed').' ('.($code || '?').')','en');
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL_END',$msg || 'Logout OK','en');
 }
}

sub find_code
{
 my $dc=shift;
 my @a=$dc->as_array();
 return (0,'LOGIN') if ($a[0]=~m/^.+ RRP Server version/); ## initial login
 return () unless $#a>0; ## at least 2 lines
 return () unless $a[-1]=~m/^\.\s*\n?$/;
 return () unless $a[0]=~m/^(\d+) (\S.+)$/;
 return (0+$1,$2);
}

sub transport_default
{
 my ($self,$tname)=@_;
 return (defer => 0, socktype => 'ssl', ssl_version => 'TLSv1', remote_port => 648);
}

####################################################################################################
1;
