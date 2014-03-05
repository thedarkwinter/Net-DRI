## Domain Registry Interface, AFNIC Email Message
##
## Copyright (c) 2006,2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AFNIC::Email::Message;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version trid email_from client_auth));

use MIME::Entity ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::Email::Message - AFNIC Email Message for Net::DRI

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

Copyright (c) 2006,2009,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 my $self={ version => '2.0.0', lines => {}, trid => $trid, generated_for => $otype.'_'.$oaction };

 bless($self,$class);
 return $self;
}

sub line
{
 my ($self,$champ,$data)=@_;
 return unless defined($champ) && $champ;

 if (defined($data))
 {
  $self->{lines}->{$champ}=$data;
 }
 return unless exists($self->{lines}->{$champ});
 return $self->{lines}->{$champ};
}

sub email_body
{
 my ($self)=@_;
 my @l;

 foreach my $c (sort {$a cmp $b} keys(%{$self->{lines}}))
 {
  push @l,sprintf('%s..: %s',$c,$self->{lines}->{$c});
 }

 return Net::DRI::Util::encode('iso-8859-15',join("\n",@l)."\n");
}

sub as_mime
{
 my ($self)=@_;

 my $m=MIME::Entity->build(From        => $self->email_from(),
                           To          => 'domain@nic.fr',
                           Data        => $self->email_body(),
                           Type        => 'text/plain',
                           Charset     => 'iso-8859-15',
                           Disposition => 'inline',
                           Encoding    => '8bit',
                          );
## Message-ID ? Reply-To ?
## If needed, then probably pass a ref hash as email header template, with keys from, to, message-id, reply-to, subject & so on
## Values would be a string or a code ref that generate the correct string based on some parameters (like the message itself)

 ## Subject : ClientID + Name of operation attempted + TRID
 $m->head->replace('Subject',sprintf('%s %s [%s]',$self->client_auth()->{id},$self->{generated_for},$self->trid()));
 $m->head->replace('X-Mailer',sprintf('Net::DRI/%s via %s',$Net::DRI::VERSION,$m->head->get('X-Mailer')));
 return $m;
}

sub as_string
{
 my $self=shift;
 my $m=$self->as_mime();
 return $m->as_string();
}

####################################################################################################
1;
