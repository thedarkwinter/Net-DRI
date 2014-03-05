## Domain Registry Interface, Dummy transport for tests & debug
##
## Copyright (c) 2005,2007,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Transport::Dummy;

use strict;
use warnings;

use base qw(Net::DRI::Transport);

use Net::DRI::Data::Raw;

=pod

=head1 NAME

Net::DRI::Transport::Dummy - Net::DRI dummy transport for tests & debug

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

Copyright (c) 2005,2007,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$ctx,$rh)=@_;
 my $self=$class->SUPER::new($ctx,$rh); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(0);
 $self->is_sync(1);
 $self->name('dummy');
 $self->version('0.1');

 $self->{f_send}=(exists($rh->{f_send}))? $rh->{f_send} : \&_print;
 $self->{f_recv}=(exists($rh->{f_recv}))? $rh->{f_recv} : \&_got_ok;

 return $self;
}

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend)=@_;
 return $self->SUPER::send($ctx,$tosend,$self->{f_send},\&handle_error);
}

sub handle_error
{
 my ($self,$err,$c,$is_timeout,$ok)=@_;
 die($err->as_string());
}

sub _print
{
 my ($self,$count,$tosend)=@_;
 print STDOUT ">>>>>>>>>>>>>>>>>> (Net::DRI::Transport::Dummy) (count=$count)\n";
 print STDOUT $tosend->as_string();
 print STDOUT ">>>>>>>>>>>>>>>>>>\n\n";
 return 1; ## very important
}

sub receive
{
 my ($self,$ctx,$count)=@_;
 return $self->SUPER::receive($ctx,$self->{f_recv});
}

sub _got_ok
{
 my ($self,$count)=@_;
 my $m="200 OK\r\n.\r\n";
 print STDOUT "<<<<<<<<<<<<<<<<<< (Net::DRI::Transport::Dummy) (count=$count)\n";
 print STDOUT $m;
 print STDOUT "<<<<<<<<<<<<<<<<<<\n\n";
 return Net::DRI::Data::Raw->new_from_string($m);
}

######################################################################################
1;
