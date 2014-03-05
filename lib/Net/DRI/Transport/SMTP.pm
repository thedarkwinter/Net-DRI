## Domain Registry Interface, SMTP Transport
##
## Copyright (c) 2006,2007,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Transport::SMTP;

use strict;
use warnings;

use base qw/Net::DRI::Transport/;

use Net::SMTP;
use Email::Valid;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Transport::SMTP - SMTP transport for Net::DRI

=head1 DESCRIPTION

The following options are available at creation:

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2007,2009,2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$ctx,$rp)=@_;
 my %opts=%$rp;
 my $self=$class->SUPER::new($ctx,\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(0); ## We could be stateful by keeping a live connection to the SMTP host. But it would be useful only for high volumes
 $self->is_sync(0);
 $self->name('smtp');
 $self->version('0.1');
 $self->current_state(0);

 ## Now deal with specifics for this transport
 my %t;
 $t{smtphost}=exists($opts{smtphost})? $opts{smtphost} : 'localhost';
 $t{cc}=$opts{cc}   if (exists($opts{cc})  && Email::Valid->rfc822($opts{cc})); ## Will be added as Cc: to all messages
 $t{bcc}=$opts{bcc} if (exists($opts{bcc}) && Email::Valid->rfc822($opts{bcc})); ## Ditto as Bcc:

 $self->{transport}=\%t;

 return $self;
}

####################################################################################################

sub end { }

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend)=@_;
 return $self->SUPER::send($ctx,$tosend,\&_send,undef);
}

sub _send
{
 my ($self,$count,$tosend)=@_;
 my $rt=$self->{transport};

 my $mime=$tosend->as_mime();
 my $head=$mime->head();
 $head->add('Cc',$rt->{cc})   if exists($rt->{cc});
 $head->add('Bcc',$rt->{bcc}) if exists($rt->{bcc});

 my %rcpts=map { $_ => 1 } map { $head->get_all($_) } ('To','Cc','Bcc');
 $head->delete('Bcc');

 my $smtp=Net::SMTP->new($rt->{smtphost});
 my $ok=$smtp->mail($head->get('From'),Bits=>8) && $smtp->to(keys(%rcpts)) && $smtp->data($mime->stringify()) && $smtp->quit();

 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send message') unless $ok;
 return 1;
}

sub receive
{
 my ($self,$ctx,$count)=@_;
 return;
}

####################################################################################################
1;
