## Domain Registry Interface, AdamsNames DAS Message
##
## Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS::AdamsNames::Message;

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg command_param cltrid response));

=pod

=head1 NAME

Net::DRI::Protocol::DAS::AdamsNames::Message - AdamsNames DAS Message for Net::DRI

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

Copyright (c) 2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my $trid=shift;

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
 my $c=$self->errcode();
 my $rs=Net::DRI::Protocol::ResultStatus->new('das',$c,'COMMAND_SUCCESSFUL_END',$self->is_success());
 $rs->_set_trid([ $self->cltrid(),undef ]);
 return $rs;
}

sub as_string
{
 my ($self)=@_;
 my $s=sprintf("testdomain %s\x0d\x0a",$self->command_param());
 return $s;
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my @d=$dc->as_array();
 Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, not exactly 2 lines in server reply') unless (@d==2);
 my $e=($d[0]=~m/Yes/)? 1 : 0;
 my ($dom)=($d[1]=~m/^(\S+) is /);
 $self->errcode(0);
 $self->errmsg($d[0].', '.$d[1]);
 $self->response([$dom,$e]);
 return;
}

####################################################################################################
1;
