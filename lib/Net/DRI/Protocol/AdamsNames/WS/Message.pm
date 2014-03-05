## Domain Registry Interface, AdamsNames Web Services Message
##
## Copyright (c) 2009-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AdamsNames::WS::Message;

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version method params result errcode errmsg));

=pod

=head1 NAME

Net::DRI::Protocol::AdamsNames::WS::Message - AdamsNames Web Services Message for Net::DRI

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

Copyright (c) 2009-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$trid,$otype,$oaction)=@_;
 my $self={errcode => undef, errmsg => undef};
 bless($self,$class);

 $self->params([]); ## empty default
 return $self;
}

sub as_string
{
 my ($self)=@_;
 my @p=@{$self->params()};
 my @pr;
 foreach my $i (0..$#p)
 {
  push @pr,sprintf 'PARAM%d=%s',$i+1,$p[$i];
 }
 return sprintf "METHOD=%s\n%s\n",$self->method(),join("\n",@pr);
}

sub parse
{
 my ($self,$dr,$rinfo,$otype,$oaction,$sent)=@_; ## $sent is the original message, we could copy its method/params value into this new message
 my ($res)=@{$dr->data()}; ## $dr is a Data::Raw object, type=1
 if (! defined($res->result()) || $res->fault())
 {
  $self->result(undef);
  $self->errcode($res->faultcode());
  $self->errmsg($res->faultstring());
 } else
 {
  $self->result($res->result());
  ## TODO: properly parse all error messages
  my $err=$res->result()->{error};
  if (defined $err && @$err)
  {
   $self->errcode($err->[0]->[0]);
   $self->errmsg($err->[0]->[1]);
  } else
  {
   $self->errcode(0); ## probably success
   $self->errmsg('No error');
  }
 }
 return;
}

sub is_success { return (shift->errcode()==0)? 1 : 0; }

## See http://www.adamsnames.tc/api/xmlrpc-doc/common.html
## Some values depend on the command issued
sub result_status
{
 my $self=shift;
 my $code=$self->errcode();
 my $msg=$self->errmsg() || '';
 my $ok=$self->is_success();

 return Net::DRI::Protocol::ResultStatus->new('adamsnames_ws',$code,'COMMAND_SUCCESSFUL',1,$msg,'en') if $ok;

 my $eppcode='COMMAND_FAILED';
 if ($code=~m/^30/)
 {
  $eppcode='AUTHORIZATION_ERROR';
 } elsif ($code=~m/^31/)
 {
  $eppcode='COMMAND_SYNTAX_ERROR';
 } elsif ($code=~m/^32/)
 {
  $eppcode='PARAMETER_VALUE_SYNTAX_ERROR';
 } elsif ($code=~m/^4/)
 {
  $eppcode='COMMAND_SUCCESSFUL'; ## ?
 } elsif ($code=~m/^5/)
 {
  $eppcode='COMMAND_FAILED';
 }

 return Net::DRI::Protocol::ResultStatus->new('adamsnames_ws',$code,$eppcode,0,$msg,'en');
}

####################################################################################################
1;
