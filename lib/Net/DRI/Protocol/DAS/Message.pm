## Domain Registry Interface, DAS Message
##
## Copyright (c) 2007-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS::Message;

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg errlang command command_param cltrid response));

=pod

=head1 NAME

Net::DRI::Protocol::DAS::Message - DAS Message for Net::DRI

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

Copyright (c) 2007-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,$trid)=@_;
 my $self={
           errcode => -1000,
	   response => {},
          };

 bless($self,$class);
 $self->cltrid($trid) if (defined($trid) && $trid);
 return $self;
}

sub is_success { return (shift->errcode()==0)? 1 : 0; }

sub result_status
{
 my $self=shift;
 ## From http://www.dns.be/en/home.php?n=317
 ## See also http://www.dns.be/en/home.php?n=44
 my %C=( 0 => 1500, ## Command successful + connection closed
        -9 => 2201, ## IP address blocked => Authorization error
        -8 => 2400, ## Timeout => Command failed
        -7 => 2005, ## Invalid pattern => Parameter value syntax error
        -6 => 2005, ## Invalid version => Parameter value syntax error
       );
 my $c=$self->errcode();
 my $rs=Net::DRI::Protocol::ResultStatus->new('das',$c,exists $C{$c} ? $C{$c} : 'COMMAND_FAILED',$self->is_success(),$self->errmsg(),$self->errlang(),undef);
 $rs->_set_trid([ $self->cltrid(),undef ]);
 return $rs;
}

sub as_string
{
 my ($self)=@_;
 my $s=sprintf("%s %s %s\x0d\x0a",$self->command(),$self->version(),$self->command_param());
 return $s;
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my @d=$dc->as_array();
 my $rc;
 my @tmp=grep { /^%% RC\s*=\s*\S+/ } @d;
 if (@tmp)
 {
  ($rc)=($tmp[0]=~m/^%% RC\s*=\s*(\S+)\s*$/);
  $self->errcode($rc);
 }

 if ((defined $rc && $rc==0) || grep { /^Status: /} @d) ## success
 {
  $self->errcode(0);
  my %info=map { m/^(\S+):\s+(.*\S)\s*$/; $1 => $2 } grep { /^\S+: / } @d;
  Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, missing key Domain') unless exists $info{Domain};
  Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, missing key Status') unless exists $info{Status};
  $self->response(\%info);
 } else
 {
  $self->errlang('en'); ## really ?
  my ($msg)=($d[-1]=~m/^%\s*(\S.+\S)\s*$/);
  $self->errmsg($msg);
 }
 return;
}

####################################################################################################
1;
