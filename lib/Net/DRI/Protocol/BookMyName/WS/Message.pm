## Domain Registry Interface, BookMyName Web Services Message
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::BookMyName::WS::Message;

use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version method params operation result retcode retval));

=pod

=head1 NAME

Net::DRI::Protocol::BookMyName::WS::Message - BookMyName Web Services Message for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 $self->params([]); ## default
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

sub add_session
{
 my ($self,$sd)=@_;
 my $rp=$self->params();
 unshift(@$rp,$sd->{id},$sd->{pass});
 return;
}

sub parse
{
 my ($self,$dr,$rinfo,$otype,$oaction,$sent)=@_; ## $sent is the original message, we could copy its method/params value into this new message
 $self->operation($otype.'_'.$oaction);
 my ($res)=@{$dr->data()}; ## $dr is a Data::Raw object, type=1
 $self->result($res->{retfields}) if exists($res->{retfields});
 $self->retcode($res->{retcode}); ## integer
 $self->retval($res->{retval}); ## integer
 return;
}

## See http://api.doc.free.org/revendeur-de-nom-de-domaine
our %CODES=(	domain_info => {	'-1,-1' => 2200,
					'-1,-2' => 2201,
					'-1,-3' => 2003,
					'0,0' => 2303,
				},
		domain_check => {	'-1,-1' => 2200,
					'-1,-2' => 2303,
					'-1,-3' => 2103,
					'-1,-4' => 2303,
					'-1,-5' => 2003,
				},
		account_list_domains =>	{
					'-1,-1' => 2200,
					},
	);

sub is_success { return (shift->retcode()==1)? 1 : 0; }

sub result_status
{
 my $self=shift;
 my ($op,$rc,$rv)=($self->operation(),$self->retcode(),$self->retval());
 my $ok=$self->is_success();
 my $k=$rc.','.$rv;
 my $eppcode=(exists $CODES{$op} && ref $CODES{$op} eq 'HASH' && keys(%{$CODES{$op}}) && exists $CODES{$op}->{$k})? $CODES{$op}->{$k} : 'COMMAND_FAILED';
 return Net::DRI::Protocol::ResultStatus->new('bookmyname_ws',100*$rc+$rv,$ok ? 'COMMAND_SUCCESSFUL' : $eppcode,$ok,'retcode='.$rc.' retval='.$rv,'en');
}

####################################################################################################
1;
