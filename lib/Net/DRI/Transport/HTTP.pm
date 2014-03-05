## Domain Registry Interface, HTTP/HTTPS Transport
##
## Copyright (c) 2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Transport::HTTP;

use strict;
use warnings;

use base qw(Net::DRI::Transport);

use Net::DRI::Exception;
use Net::DRI::Util;

use LWP::UserAgent 6.02;

=pod

=head1 NAME

Net::DRI::Transport::HTTP - HTTP/HTTPS Transport for Net::DRI

=head1 DESCRIPTION

This module implements an HTTP/HTTPS transport for establishing connections in Net::DRI

=head1 METHODS

At creation (see Net::DRI C<new_profile>) you pass a reference to an hash, with the following available keys:

=head2 timeout

time to wait (in seconds) for server reply

=head2 ssl_key_file ssl_cert_file ssl_ca_file ssl_ca_path ssl_cipher_list ssl_version ssl_passwd_cb

if C<remote_url> begins with https://, all key materials, see IO::Socket::SSL documentation for corresponding options

=head2 ssl_verify

see IO::Socket::SSL documentation about verify_mode (by default 0x00 here)

=head2 ssl_verify_callback

see IO::Socket::SSL documentation about verify_callback, it gets here as first parameter the transport object
then all parameter given by IO::Socket::SSL; it is explicitly verified that the subroutine returns a true value,
and if not the connection is aborted.

=head2 remote_url

URL to access

=head2 client_login client_password

protocol login & password

=head2 client_newpassword

(optional) new password if you want to change password on login for registries handling that at connection

=head2 protocol_connection

Net::DRI class handling protocol connection details. Specifying it should not be needed, as the registry driver should have correct default values.

=head2 protocol_data

(optional) opaque data given to protocol_connection class.
For EPP, a key login_service_filter may exist, whose value is a code ref. It will be given an array of services, and should give back a
similar array; it can be used to filter out some services from those given by the registry.

=head2 verify_response

(optional) a callback (code ref) executed after each exchange with the registry, being called with the following parameters: the transport object,
the phase (1 for greeting+login, 2 for all normal operations, 3 for logout), the count (if we retried multiple times to send the same message),
the message sent (HTTP::Request object) and the response received (HTTP::Response object). This can be used to verify/diagnose SSL details,
see example in file t/704opensrs_xcp_live.t

=head2 local_host

(optional) the local address (hostname or IP) you want to use to connect (if you are multihomed)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $ndr=$ctx->{registry};
 my $pname=$ctx->{profile};
 my $po=$ctx->{protocol};

 my %t=(message_factory => $po->factories()->{message});
 Net::DRI::Exception::usererr_insufficient_parameters('protocol_connection') unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};
 Net::DRI::Util::load_module($t{pc},'transport/http');
 if ($t{pc}->can('transport_default'))
 {
  %opts=($t{pc}->transport_default('http'),%opts);
 }

 my $self=$class->SUPER::new($ctx,\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(1); ## some registries need login (like .PL) some not (like .ES) ; see end of method & call to open_connection()
 $self->is_sync(1);
 $self->name('http');
 $self->version('0.2');

 foreach my $k (qw/client_login client_password client_newpassword protocol_data/)
 {
  $t{$k}=$opts{$k} if exists($opts{$k});
 }

 my @need=qw/read_data write_message/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);
 $t{protocol_data}=$opts{protocol_data} if (exists($opts{protocol_data}) && $opts{protocol_data});
 Net::DRI::Exception::usererr_insufficient_parameters('remote_url must be defined') unless (exists $opts{'remote_url'} && defined $opts{'remote_url'});
 Net::DRI::Exception::usererr_invalid_parameters('remote_url must be an uri starting with http:// or https:// with a proper path') unless $opts{remote_url}=~m!^https?://\S+/\S*$!;
 $t{remote_url}=$opts{remote_url};
 $t{remote_uri}=$t{remote_url}; ## only used for error messages

 my $ua=LWP::UserAgent->new();
 $ua->agent(sprintf('Net::DRI/%s ',$Net::DRI::VERSION)); ## the final space triggers LWP::UserAgent to add its own string
 $ua->cookie_jar({}); ## Cookies needed by some registries, like .PL (how strange !)
 ## Now some security settings
 $ua->max_redirect(0);
 $ua->parse_head(0);
 $ua->protocols_allowed(['http','https']);
 $ua->timeout($self->timeout()) if $self->timeout(); ## problem with our own alarm ?
 $ua->local_address($opts{local_host}) if exists $opts{local_host} && defined $opts{local_host};

 if ($t{remote_url}=~m!^https://!)
 {
  my %ssl=%{$self->parse_ssl_options(\%opts)};
  while(my ($k,$v)=each %ssl)
  {
   $ua->ssl_opts($k,$v);
  }
 }

 $t{ua}=$ua;
 $t{verify_response}=$opts{verify_response} if (exists($opts{verify_response}) && defined($opts{verify_response}) && (ref($opts{verify_response}) eq 'CODE'));
 $self->{transport}=\%t;
 $t{pc}->init($self) if $t{pc}->can('init');

 $self->open_connection($ctx); ## noop for registries without login, will properly setup has_state()
 return $self;
}

sub send_login
{
 my ($self,$ctx)=@_;
 my $t=$self->transport_data();
 my $pc=$t->{pc};
 my ($cltrid,$dr);

 ## Get registry greeting, if available
 if ($pc->can('greeting') && $pc->can('parse_greeting'))
 {
  $cltrid=$self->generate_trid($self->{logging_ctx}->{registry}); ## not used for greeting (<hello> has no clTRID), but used in logging
  my $greeting=$pc->greeting($t->{message_factory});
  $self->log_output('notice','transport',$ctx,{trid=>$cltrid,phase=>'opening',direction=>'out',message=>$greeting});
  Net::DRI::Exception->die(0,'transport/http',4,'Unable to send greeting message to '.$t->{remote_uri}) unless $self->_http_send(1,$greeting,1);
  $dr=$self->_http_receive(1);
  $self->log_output('notice','transport',$ctx,{trid=>$cltrid,phase=>'opening',direction=>'in',message=>$dr});
  my $rc1=$pc->parse_greeting($dr); ## gives back a Net::DRI::Protocol::ResultStatus
  die($rc1) unless $rc1->is_success();
 }

 my $login=$pc->login($t->{message_factory},$t->{client_login},$t->{client_password},$cltrid,$dr,$t->{client_newpassword},$t->{protocol_data});
 $self->log_output('notice','transport',$ctx,{trid=>$cltrid,phase=>'opening',direction=>'out',message=>$login});
 Net::DRI::Exception->die(0,'transport/http',4,'Unable to send login message to '.$t->{remote_uri}) unless $self->_http_send(1,$login,1);
 $dr=$self->_http_receive(1);
 $self->log_output('notice','transport',$ctx,{trid=>$cltrid,phase=>'opening',direction=>'in',message=>$dr});
 my $rc2=$pc->parse_login($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc2) unless $rc2->is_success();
 return;
}

sub open_connection
{
 my ($self,$ctx)=@_;
 my $t=$self->transport_data();
 my $pc=$t->{pc};
 $self->has_state(0);

 if ($pc->can('login') && $pc->can('parse_login'))
 {
  $self->send_login($ctx);
  $self->has_state(1);
  $self->current_state(1);
 }

 $self->time_open(time());
 $self->time_used(time());
 $self->transport_data()->{exchanges_done}=0;
 return;
}

sub send_logout
{
 my ($self)=@_;
 my $t=$self->transport_data();
 my $pc=$t->{pc};

 return unless ($pc->can('logout') && $pc->can('parse_logout'));

 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my $logout=$pc->logout($t->{message_factory},$cltrid);
 $self->log_output('notice','transport',{otype=>'session',oaction=>'logout'},{trid=>$cltrid,phase=>'closing',direction=>'out',message=>$logout});
 Net::DRI::Exception->die(0,'transport/http',4,'Unable to send logout message to '.$t->{remote_uri}) unless $self->_http_send(1,$logout,3);
 my $dr=$self->_http_receive(1);
 $self->log_output('notice','transport',{otype=>'session',oaction=>'logout'},{trid=>$cltrid,phase=>'closing',direction=>'in',message=>$dr});
 my $rc1=$pc->parse_logout($dr);
 die($rc1) unless $rc1->is_success();
 return;
}

sub close_connection
{
 my ($self)=@_;
 $self->send_logout() if ($self->has_state() && $self->current_state());
 $self->transport_data()->{ua}->cookie_jar({});
 $self->current_state(0);
 return;
}

sub end
{
 my ($self)=@_;
 if ($self->current_state())
 {
  eval
  {
   local $SIG{ALRM}=sub { die 'timeout' };
   alarm(10);
   $self->close_connection();
  };
  alarm(0); ## since close_connection may die, this must be outside of eval to be executed in all cases
 }
 return;
}

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend)=@_;
 return $self->SUPER::send($ctx,$tosend,\&_http_send,sub {});
}

sub _http_send
{
 my ($self,$count,$tosend,$phase)=@_;
 $phase=2 unless defined($phase); ## Phase 2 = normal operations (1=greeting+login, 3=logout)
 my $t=$self->transport_data();

 ## Content-Length is automatically computed and added during the request() call, no need to do it before
 my $req=$t->{pc}->write_message($self,$tosend); ## gives back an HTTP::Request object
 Net::DRI::Util::check_isa($req,'HTTP::Request');
 my $ans=$t->{ua}->request($req);
 $t->{verify_response}->($self,$phase,$count,$req,$ans) if exists($t->{verify_response});
 $t->{last_reply}=$ans;
 return 1; ## very important
}

sub receive
{
 my ($self,$ctx,$count)=@_;
 return $self->SUPER::receive($ctx,\&_http_receive);
}

sub _http_receive
{
 my ($self,$count)=@_;
 my $t=$self->transport_data();

 ## Convert answer in a Net::DRI::Data::Raw object
 my $dr=$t->{pc}->read_data($self,$t->{last_reply});
 Net::DRI::Util::check_isa($dr,'Net::DRI::Data::Raw');
 $t->{last_reply}=undef;
 $t->{exchanges_done}++;
 return $dr;
}

#####################################################################################################
1;
