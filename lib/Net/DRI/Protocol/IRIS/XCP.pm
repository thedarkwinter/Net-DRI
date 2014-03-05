## Domain Registry Interface, IRIS XCP Connection handling
##
## Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::IRIS::XCP;

use utf8;
use strict;
use warnings;

use XML::LibXML ();

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Protocol::IRIS::Core;

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::XCP - IRIS XCP Connection Handling (RFC4992) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

This is only a preliminary basic implementation, with only SASL PLAIN support.

There is currently no known public server speaking this protocol.

=head1 CURRENT LIMITATIONS

=over

=item *

Nothing is parsed from server greeting message

=item *

Only SASL PLAIN is handled

=item *

Blocks split over multiple chunks are not handled, except for application data

=item *

Nothing is parsed in authentication success result from server

=item *

Only chunk types "application data", "authentication success" and "authentication failure"
are recognized and parsed.

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub parse_greeting ## §4.2
{
 my $dr=shift;
 ## TODO: really parse something ?
 return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Greeting OK','en');
}

sub read_data # §4
{
 my ($class,$to,$sock)=@_;

 my $data;
 $sock->sysread($data,1) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read registry reply (block header): '.$!,'en'));
 my $hdr=substr($data,0,1);

 my $keepopen=parse_block_header($hdr);
 $to->send_logout() unless ($keepopen); ## will not truly send anything, as there is no logout, but will properly close the socket and prepare everything as needed for next connection

 ## We do not handle blocks split over multiple chunks, except for application data
 my $m='';
 my ($lastchunk,$datacomplete,$chunktype);
 while(($lastchunk,$datacomplete,$chunktype,$data)=parse_chunk($sock))
 {
  if ($chunktype==4+2+1) ## ad=application data
  {
   $m.=$data;
  } elsif ($chunktype==4+0+0)
  {
   die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Extra SASL data returned by server, currently not handled','en'));
  } elsif ($chunktype==4+0+1) ## as=authentication success
  {
   ## We do not parse anything. If so needed, see §6 of RFC4991, and Core::parse_authentication
   next;
  } elsif ($chunktype==4+2+0) ## af=authentication failure
  {
   my $doc=XML::LibXML->new()->parse_string(Net::DRI::Util::decode_utf8($data));
   my $root=$doc->getDocumentElement();
   my ($msg,$lang,$ri)=Net::DRI::Protocol::IRIS::Core::parse_authentication($root);

   if (!defined $msg || !defined $lang) { die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Authentication failure without any data','en')); }
   die(Net::DRI::Protocol::ResultStatus->new_error('AUTHENTICATION_ERROR',$msg,$lang,$ri));
  } else
  {
   die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Chunk type not handled: '.$chunktype,'en'));
  }

  last if $lastchunk==1;
 }
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Last chunk does not have DC=1','en')) unless $datacomplete==1; ## TODO: does that happen IRL ?
 $m=Net::DRI::Util::decode_utf8($m); ## do it only once at end, when all chunks of application data were joined together again

 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',$m? 'Got unexpected reply message: '.$m : '<empty message from server>','en')) unless ($m=~m!</(?:\S+:)?response>\s*$!s); ## we do not handle other things than plain responses (see Message)
 return Net::DRI::Data::Raw->new_from_xmlstring($m);
}

sub write_message ## §5
{
 my ($self,$to,$msg)=@_;

 my $hdr='00100000'; ## V=0, KO=1 (Keep Open please)
 my $auth=Net::DRI::Util::encode_utf8($msg->authority()); 
 return pack('B8',$hdr).pack('C',length($auth)).$auth.write_chunk('sasl',$to).write_chunk('data',$msg->as_string());
}

sub keepalive
{
 my ($class,$cm)=@_;
 my $mes=$cm->();
 ## TODO: update IRIS/Message to handle this kind of messages
 return $mes; ## TODO: update write_message to handle various types (should be infered from content of message probably)
}

####################################################################################################

sub parse_block_header ## §5
{
 my $d=shift; ## one-octet
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read 1 byte block header','en')) unless $d;
 my $hdr=unpack('C',$d);
 my $ver=($hdr & (128+64)) >> 6;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Version unknown in block header: '.$ver,'en')) unless $ver==0;
 my $keepopen=($hdr & 32) >> 5;
 my $res=($hdr & (16+8+4+2+1));
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Reserved part unknown in block header: '.$res,'en')) unless $res==0;
 return $keepopen;
}

sub parse_chunk_header ## §6
{
 my $d=shift; ## one-octet
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read 1 byte chunk header','en')) unless $d;
 my $hdr=unpack('C',$d);

 my $lc=($hdr & 128) >> 7; ## is last chunk in reply ?
 my $dc=($hdr & 64)  >> 6; ## is data complete with this chunk ?
 my $res=($hdr & (32+16+8)) >> 3;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Reserved part unknown in chunk header: '.$res,'en')) unless $res==0;
 my $ct=($hdr & (4+2+1)); ## chunk type

 return ($lc,$dc,$ct);
}

sub parse_chunk ## §6
{
 my $sock=shift;
 my $data;

 $sock->sysread($data,3) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read registry reply (chunk header of 3 bytes): '.$!,'en'));
 my $hdr=substr($data,0,1);
 my @hdr=parse_chunk_header($hdr);
 my $length=unpack('n',substr($data,1,2));
 $data=undef;
 $sock->sysread($data,$length) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read registry reply (chunk data of '.$length.' bytes): '.$!,'en'));
 return (@hdr,$data);
}

## We handle only 'application data' type and sasl plain
sub write_chunk
{
 my ($type,$data)=@_;
 my $hdr;
 if ($type eq 'data')
 {
  $hdr='11000111'; ## LC=yes, DC=yes, CT=ad
  $data=Net::DRI::Util::encode_utf8($data);
 } elsif ($type eq 'nodata')
 {
  $hdr='11000000';
  $data='';
 } elsif ($type eq 'sasl')
 {
  my $t=$data->transport_data(); ## $data=$to here
  unless (exists $t->{client_login} && $t->{client_login} && exists $t->{client_password} && $t->{client_password}) { return ''; }
  $hdr='01000100'; ## LC=no, DC=yes, CT=sd
  ## Only SASL PLAIN is supported for now
  my $sasltype='PLAIN';
  $data=pack('C',length($sasltype)).$sasltype;
  my $sasldata=Net::DRI::Util::encode_utf8(sprintf('%s %s %s',$t->{client_login},chr(0),$t->{client_password})); ## authcid=LOGIN, authzid=NULL, password=PASSWORD
  $data.=pack('n',length($sasldata)).$sasldata;
 }
 return pack('B8',$hdr).pack('n',length($data)).$data;
}

sub transport_default
{
 my ($self,$tname)=@_;
 return (has_state => 1, type => 'tcp');
}

####################################################################################################
1;
