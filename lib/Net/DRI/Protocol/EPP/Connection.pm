## Domain Registry Interface, EPP Connection handling
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

package Net::DRI::Protocol::EPP::Connection;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

use Net::SSLeay;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Connection - EPP over TCP/TLS Connection Handling (RFC5734) for Net::DRI

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

sub read_fragments
{
 my ($sock,$length)=@_;
 my $data='';
 while($length > 0)
 {
  my $new;
  my $read=$sock->sysread($new,$length);
  die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Error reading socket','en')) unless $read;
  $length-=$read;
  $data.=$new;
 }
 return $data;
}

sub read_data
{
 my ($class,$to,$sock)=@_;
 my $header=read_fragments($sock,4); ## first 4 bytes are the packed length
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unable to read frame length','en')) unless length $header;
 my $length=unpack('N',$header)-4; ## Length of the XML frame
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unable to decode frame length','en')) unless $length > 0;
 my $frame=Net::DRI::Util::decode_utf8(read_fragments($sock,$length));
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','<empty message from server>','en')) unless length $frame;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Got unexpected EPP message: '.$frame,'en')) unless $frame=~m!</epp>\s*$!s;
 return Net::DRI::Data::Raw->new_from_xmlstring($frame);
}

sub write_message
{
 my ($self,$to,$msg)=@_;

 my $m=Net::DRI::Util::encode_utf8($msg);
 my $l=pack('N',4+length($m)); ## RFC 4934 §4
 return $l.$m; ## We do not support EPP "0.4" at all (which lacks length before data)
}

sub transport_default
{
 my ($self,$tname)=@_;
 return (defer => 0, socktype => 'ssl', ssl_version => 'TLSv1', remote_port => 700);
}

#  SSL_verify_callback
#              If you want to verify certificates yourself, you can pass a sub reference along with this parameter to do so.  When the
#              callback is called, it will be passed: 1) a true/false value that indicates what OpenSSL thinks of the certificate, 2)
#              a C-style memory address of the certificate store, 3) a string containing the certificate's issuer attributes and owner
#              attributes, and 4) a string containing any errors encountered (0 if no errors).  The function should return 1 or 0,
#              depending on whether it thinks the certificate is valid or invalid.  The default is to let OpenSSL do all of the busy
#              work.
##
## (seems to be called twice)
##
## See also IO::Socket::SSL verify_hostname()

## TODO: implement TLS checkings as defined in RFC5734 §9 (test that $po->name() eq 'EPP' !)
sub tls_verifications
{
 my ($to,$status,$store,$certowner,$errors)=@_;

 ## From internals of IO::Socket::SSL :
 my $cert=Net::SSLeay::X509_STORE_CTX_get_current_cert($store);
 my $issuer= Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($cert));
 my $subject=Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($cert));

 print STDERR "TODO WIP\n";
 print STDERR "ISSUER=$issuer\n";
 print STDERR "SUBJECT=$subject\n";
 print STDERR "STATUS=$status\n";
 print STDERR "ERRORS=$errors\n"; ## self signed certificate is considered an error

 return 1; ## 1 if certificate is valid, 0 otherwise
}

####################################################################################################
1;
