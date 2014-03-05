## Domain Registry Interface, IRIS LWZ Connection handling
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

package Net::DRI::Protocol::IRIS::LWZ;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

use Net::DNS ();

use IO::Uncompress::RawInflate (); ## RFC1951 per the LWZ RFC
use IO::Compress::RawDeflate ();

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::LWZ - IRIS LWZ connection handling (RFC4993) for Net::DRI

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

Copyright (c) 2008-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub read_data # §3.1.2
{
 my ($class,$to,$sock)=@_;

 my $data;
 $sock->recv($data,4000) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read registry reply: '.$!,'en'));
 my $hdr=substr($data,0,1);
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read 1 byte header','en')) unless $hdr;
 # §3.1.3
 $hdr=unpack('C',$hdr);
 my $ver=($hdr & (128+64)) >> 6;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Version unknown in header: '.$ver,'en')) unless $ver==0;
 my $rr=($hdr & 32) >> 5;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','RR Flag is not response in header: '.$rr,'en')) unless $rr==1;
 my $deflate=($hdr & 16) >> 4; ## if 1, the payload is compressed with the deflate algorithm (RFC1951)
 my $type=($hdr & 3); ## §3.1.4
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unexpected response type in header: '.$type,'en')) unless $type==0; ## TODO : handle size info, version, etc.

 my $tid=substr($data,1,2);
 $tid=unpack('n',$tid);
 my $load=substr($data,3);
 if ($deflate)
 {
  my $load2;
  IO::Uncompress::RawInflate::rawinflate(\$load,\$load2) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Unable to uncompress payload: '.$IO::Uncompress::RawInflate::RawInflateError,'en'));
  $load=$load2;
 }

 my $m=Net::DRI::Util::decode_utf8($load);
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',$m? 'Got unexpected reply message: '.$m : '<empty message from server>','en')) unless ($m=~m!</(?:\S+:)?response>\s*$!s); ## we do not handle other things than plain responses (see Message)
 return Net::DRI::Data::Raw->new_from_xmlstring($m);
}

sub write_message
{
 my ($self,$to,$msg)=@_;
 my $m=Net::DRI::Util::encode_utf8($msg);
 my $hdr='00001000'; ## §3.1.3 : V=0 RR=Request PD=no DS=yes Reserved PT=xml

 ## If not specificed in DRD, other option is to try anyway & fallback based on reply (this will need multiple exchanges, so probably some changes in Net::DRI::Registry::process)
 my $deflate=$msg->options()->{request_deflate};
 if ($deflate==2 || ($deflate==1 && length $m > 1500)) ## Deflate if forced or if message is over 1500 bytes (per RFC)
 {
  my $mm;
  IO::Compress::RawDeflate::rawdeflate( \$m,\$mm);
  $m=$mm;
  $hdr='00011000';
 }

 my ($tid)=($msg->tid()=~m/(\d{6})$/); ## 16 digits, we need to convert to a 16-bit value, we take the microsecond part modulo 65535 (since 0xFFFF is reserved)
 $tid%=65535;
 my $auth=$msg->authority();
 return pack('B8',$hdr).pack('n',$tid).pack('n',4000).pack('C',length($auth)).$auth.$m; ## §3.1.1
}

## TODO: move that someway into IRIS/Core probably (as needed for all transports)
sub find_remote_server
{
 my ($class,$to,$rd)=@_;
 my ($authority,$service)=@$rd;

 my $res=Net::DNS::Resolver->new(domain=>'', search=>''); ## make sure to start from clean state (otherwise we inherit the system defaults !)
 my $query=$res->send($authority,'NAPTR');
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to perform NAPTR DNS query for '.$authority.': '.$res->errorstring()) unless $query;

 my @r=sort { $a->order() <=> $b->order() || $a->preference() <=> $b->preference() } grep { $_->type() eq 'NAPTR' } $query->answer(); ## RFC3958 §2.2.1
 @r=grep { $_->service() eq $service } @r; ## RFC3958 §2.2.2
 @r=grep { $_->flags() eq 's' } @r; ## RFC3958 §2.2.3
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to retrieve NAPTR records with service='.$service.' and flags=s for authority='.$authority) unless @r;

 my $srv=$r[0]->replacement();
 $query=$res->query($srv,'SRV');
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to perform SRV DNS query for '.$srv.': '.$res->errorstring()) unless $query;

 @r=$query->answer();
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to retrieve SRV records for '.$srv) unless @r;

 ## TODO: provide load balancing/fail over when not using only one SRV record / This would probably need changes in Transport or Transport::Socket
 @r=Net::DRI::Util::dns_srv_order(@r) if @r > 1;
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to find valid SRV record for '.$srv) if ($r[0]->target() eq '.');
 return ($r[0]->target(),$r[0]->port());
}

sub transport_default
{
 my ($self,$tname)=@_;
 ## RFC4993 Section 4 gives recommandation for timeouts and retry algorithm
 ## retry=5 is computed so that the whole sequence stops after 60 seconds: t,p+2t,3/2*(p+2)-2+4t,3/2*3/2*(p+2)-2+8t, ...
 return (defer => 1, close_after => 1, socktype=>'udp', timeout => 1, pause => 2, retry => 5);
}

####################################################################################################
1;
