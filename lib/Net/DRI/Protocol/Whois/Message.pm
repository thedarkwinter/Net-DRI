## Domain Registry Interface, Whois Message
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

package Net::DRI::Protocol::Whois::Message;

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg errlang command cltrid response response_raw));

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Message - Whois Message for Net::DRI

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
 my %C=( 0 => 1500, ## Command successful + connection closed
       );
 my $c=$self->errcode();
 my $rs=Net::DRI::Protocol::ResultStatus->new('whois',$c,exists($C{$c})? $C{$c} : 'COMMAND_FAILED',$self->is_success(),$self->errmsg(),$self->errlang(),undef);
 $rs->_set_trid([ $self->cltrid(),undef ]);
 return $rs;
}

sub as_string
{
 my ($self)=@_;
 my $s=sprintf("%s\x0d\x0a",$self->command());
 return $s;
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my @d=$dc->as_array();
 my %info;
 foreach my $l (grep { /:/ } @d)
 {
  my ($k,$v)=($l=~m/^\s*(\S[^:]*\S)\s*:\s*(\S.*\S)\s*$/);
  next unless ($k && $v);
  if (exists($info{$k}))
  {
   push @{$info{$k}},$v;
  } else
  {
   $info{$k}=[$v];
  }
 }

 $self->errcode(0);
 $self->response(\%info);
 $self->response_raw(\@d);
 return;
}

####################################################################################################
1;
