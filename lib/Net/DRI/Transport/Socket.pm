## Domain Registry Interface, TCP/SSL Socket Transport
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

package Net::DRI::Transport::Socket;

use base qw(Net::DRI::Transport);

use strict;
use warnings;

use Time::HiRes ();
use IO::Socket::INET;
## At least this version is needed, to have getline()
use IO::Socket::SSL 0.90;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Raw;


=pod

=head1 NAME

Net::DRI::Transport::Socket - TCP/TLS Socket connection for Net::DRI

=head1 DESCRIPTION

This module implements a socket (tcp or tls) for establishing connections in Net::DRI

=head1 METHODS

At creation (see Net::DRI C<new_profile>) you pass a reference to an hash, with the following available keys:

=head2 socktype

ssl, tcp or udp

=head2 ssl_key_file ssl_cert_file ssl_ca_file ssl_ca_path ssl_cipher_list ssl_version ssl_passwd_cb ssl_hostname

if C<socktype> is 'ssl', all key materials, see IO::Socket::SSL documentation for corresponding options

=head2 ssl_verify

see IO::Socket::SSL documentation about verify_mode (by default 0x00 here)

=head2 ssl_verify_callback

see IO::Socket::SSL documentation about verify_callback, it gets here as first parameter the transport object
then all parameter given by IO::Socket::SSL; it is explicitly verified that the subroutine returns a true value,
and if not the connection is aborted.

=head2 remote_host remote_port

hostname (or IP address) & port number of endpoint

=head2 client_login client_password

protocol login & password

=head2 client_newpassword

(optional) new password if you want to change password on login for registries handling that at connection

=head2 protocol_connection

Net::DRI class handling protocol connection details. (Ex: C<Net::DRI::Protocol::RRP::Connection> or C<Net::DRI::Protocol::EPP::Connection>)

=head2 protocol_data

(optional) opaque data given to protocol_connection class.
For EPP, a key login_service_filter may exist, whose value is a code ref. It will be given an array of services, and should give back a
similar array; it can be used to filter out some services from those given by the registry.

=head2 close_after

number of protocol commands to send to server (we will automatically close and re-open connection if needed)

=head2 local_host

(optional) the local address (hostname or IP) you want to use to connect

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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

sub new
{
 my ($class,$ctx,$rp)=@_;
 my %opts=%$rp;
 my $po=$ctx->{protocol};

 my %t=(message_factory => $po->factories()->{message});
 Net::DRI::Exception::usererr_insufficient_parameters('protocol_connection') unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};
 Net::DRI::Util::load_module($t{pc},'transport/socket');
 if ($t{pc}->can('transport_default'))
 {
  %opts=($t{pc}->transport_default('socket_inet'),%opts);
 }

 my $self=$class->SUPER::new($ctx,\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(exists $opts{has_state}? $opts{has_state} : 1);
 $self->is_sync(1);
 $self->name('socket_inet');
 $self->version('0.8');
 ##delete($ctx->{protocol}); ## TODO : double check it is ok
 delete($ctx->{registry});
 delete($ctx->{profile});

 Net::DRI::Exception::usererr_insufficient_parameters('socktype must be defined') unless (exists($opts{socktype}));
 Net::DRI::Exception::usererr_invalid_parameters('socktype must be ssl, tcp or udp') unless ($opts{socktype}=~m/^(ssl|tcp|udp)$/);
 $t{socktype}=$opts{socktype};
 $t{client_login}=$opts{client_login};
 $t{client_password}=$opts{client_password};
 $t{client_newpassword}=$opts{client_newpassword} if (exists($opts{client_newpassword}) && $opts{client_newpassword});

 $t{protocol_data}=$opts{protocol_data} if (exists($opts{protocol_data}) && $opts{protocol_data});
 my @need=qw/read_data write_message/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class ('.$t{pc}.') must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);

 if (exists($opts{find_remote_server}) && defined($opts{find_remote_server}) && $t{pc}->can('find_remote_server'))
 {
  ($opts{remote_host},$opts{remote_port})=$t{pc}->find_remote_server($self,$opts{find_remote_server});
  $self->log_output('notice','transport',$ctx,{phase=>'opening',message=>'Found the following remote_host:remote_port = '.$opts{remote_host}.':'.$opts{remote_port}});
 }
 foreach my $p ('remote_host','remote_port','protocol_version')
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($opts{$p}) && $opts{$p});
  $t{$p}=$opts{$p};
 }

 Net::DRI::Exception::usererr_invalid_parameters('close_after must be an integer') if ($opts{close_after} && !Net::DRI::Util::isint($opts{close_after}));
 $t{close_after}=$opts{close_after} || 0;

 if ($t{socktype} eq 'ssl')
 {
  $t{ssl_context}=$self->parse_ssl_options(\%opts);
 }

 $t{local_host}=$opts{local_host} if (exists($opts{local_host}) && $opts{local_host});
 $t{remote_uri}=sprintf('%s://%s:%d',$t{socktype},$t{remote_host},$t{remote_port}); ## handy shortcut only used for error messages
 $self->{transport}=\%t;

 my $rc;
 if ($self->defer()) ## we will open, but later
 {
  $self->current_state(0);
 } else ## we will open NOW
 {
  $rc=$self->open_connection($ctx);
  $self->current_state(1);
 }

 return ($self,$rc);
}

sub sock { my ($self,$v)=@_; $self->transport_data()->{sock}=$v if defined($v); return $self->transport_data()->{sock}; }

## TODO (for IRIS DCHK1 + NAPTR/SRV)
## Wrap in an eval to handle timeout (see if outer eval already for that ?)
## Handle remote_host/port being ref array of ordered strings to try (in which case defer should be 0 probably as the list of things to try have been determined now, not later)
## Or specify a callback to call when doing socket open to find the correct host+ports to use at that time
sub open_socket
{
 my ($self,$ctx)=@_;
 my $t=$self->transport_data();
 my $type=$t->{socktype};
 my $sock;

 my %n=( PeerAddr   => $t->{remote_host},
         PeerPort   => $t->{remote_port},
         Proto      => $t->{socktype} eq 'udp'? 'udp' : 'tcp',
         Blocking   => 1,
         MultiHomed => 1,
       );
 $n{LocalAddr}=$t->{local_host} if exists($t->{local_host});

 if ($type eq 'ssl')
 {
  $sock=IO::Socket::SSL->new(%{$t->{ssl_context}},
                             %n,
                            );
 } elsif ($type eq 'tcp' || $type eq 'udp')
 {
  $sock=IO::Socket::INET->new(%n);
 }

 Net::DRI::Exception->die(1,'transport/socket',6,'Unable to setup the socket for '.$t->{remote_uri}.' with error: "'.$!.($type eq 'ssl'? '" and SSL error: "'.IO::Socket::SSL::errstr().'"' : '"')) unless defined $sock;
 $sock->autoflush(1);
 $self->sock($sock);
 $self->log_output('notice','transport',$ctx,{phase=>'opening',message=>'Successfully opened socket to '.$t->{remote_uri}});
 return;
}

sub send_login
{
 my ($self,$ctx)=@_;
 my $t=$self->transport_data();
 my $sock=$self->sock();
 my $pc=$t->{pc};
 my $dr;
 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my @rs;

 ## Get server greeting, if needed
 if ($ctx->{protocol}->has_action('session','connect'))
 {
  my $t1=Time::HiRes::time();
  $dr=$pc->read_data($self,$sock);
  my $t2=Time::HiRes::time();
  $self->log_output('notice','transport',$ctx,{trid=>$cltrid,phase=>'opening',direction=>'in',message=>$dr});
  push @rs,$self->protocol_parse($ctx->{protocol},'session','connect',$dr,$cltrid,$t2-$t1);
  return Net::DRI::Util::link_rs(@rs) unless $rs[-1]->is_success();
 }

 return unless $ctx->{protocol}->has_action('session','login');

 foreach my $p (qw/client_login client_password/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }

 $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});

 my $login=$ctx->{protocol}->action('session','login',$cltrid,$t->{client_login},$t->{client_password},{ client_newpassword => $t->{client_newpassword}, %{$t->{protocol_data} || {}}}); ## TODO: fix last hash ref
 $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'login',trid=>$cltrid,phase=>'opening',direction=>'out',message=>$login});
 my $t1=Time::HiRes::time();
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send login message to '.$t->{remote_uri}) unless ($sock->connected() && $sock->print($pc->write_message($self,$login)));

 ## Verify login successful
 $dr=$pc->read_data($self,$sock);
 my $t2=Time::HiRes::time();
 $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'login',trid=>$cltrid,phase=>'opening',direction=>'in',message=>$dr});
 push @rs,$self->protocol_parse($ctx->{protocol},'session','login',$dr,$cltrid,$t2-$t1,$login);

 return Net::DRI::Util::link_rs(@rs);
}

sub send_logout
{
 my ($self,$ctx)=@_;
 my $t=$self->transport_data();
 my $sock=$self->sock();
 my $pc=$t->{pc};

 return unless $ctx->{protocol}->has_action('session','logout');

 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my $logout=$ctx->{protocol}->action('session','logout',$cltrid);
 $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'logout',trid=>$cltrid,phase=>'closing',direction=>'out',message=>$logout});
 my $t1=Time::HiRes::time();
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send logout message to '.$t->{remote_uri}) unless ($sock->connected() && $sock->print($pc->write_message($self,$logout)));
 my $dr=$pc->read_data($self,$sock); ## We expect this to throw an exception, since the server will probably cut the connection
 my $t2=Time::HiRes::time();
 $self->time_used(time());
 $t->{exchanges_done}++;
 $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'logout',trid=>$cltrid,phase=>'closing',direction=>'in',message=>$dr});
 my $rc1=$self->protocol_parse($ctx->{protocol},'session','logout',$dr,$cltrid,$t2-$t1,$logout);
 die $rc1 unless $rc1->is_success();
 return $rc1;
}

sub open_connection
{
 my ($self,$ctx)=@_;
 $self->open_socket($ctx);
 my $rc=$self->send_login($ctx);
 $self->current_state(1);
 $self->time_open(time());
 $self->time_used(time());
 $self->transport_data()->{exchanges_done}=0;
 return $rc;
}

sub ping
{
 my ($self,$ctx,$autorecon)=@_;
 $autorecon=0 unless defined $autorecon;
 my $t=$self->transport_data();
 my $pc=$t->{pc};
 my $sock=$self->sock();

 return 0 unless $self->has_state();
 return 0 unless $ctx->{protocol}->has_action('session','noop');

 my $rc1;
 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my $ok=eval
 {
  local $SIG{ALRM}=sub { die 'timeout' };
  alarm 10;
  my $noop=$ctx->{protocol}->action('session','noop',$cltrid);
  $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'keepalive',trid=>$cltrid,phase=>'keepalive',direction=>'out',message=>$noop});
  my $t1=Time::HiRes::time();
  Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send keepalive message to '.$t->{remote_uri}) unless ($sock->connected() && $sock->print($pc->write_message($self,$noop)));
  my $dr=$pc->read_data($self,$sock);
  my $t2=Time::HiRes::time();
  $self->time_used(time());
  $t->{exchanges_done}++;
  $self->log_output('notice','transport',$ctx,{otype=>'session',oaction=>'keepalive',trid=>$cltrid,phase=>'keepalive',direction=>'in',message=>$dr});
  $rc1=$self->protocol_parse($ctx->{protocol},'session','noop',$dr,$cltrid,$t2-$t1,$noop);
  die $rc1 unless $rc1->is_success();
  1;
 };
 my $err=$@;

 alarm 0;
 if (defined $ok && $ok==1)
 {
  $self->current_state(1);
 } else
 {
  $self->current_state(0);
  $rc1=$err if defined $err && Net::DRI::Util::is_class($err,'Net::DRI::Protocol::ResultStatus');
  if ($autorecon)
  {
   $self->log_output('notice','transport',{},{phase=>'keepalive',message=>'Reopening connection to '.$t->{remote_uri}.' because ping failed and asked to auto-reconnect'});
   my $rc2=$self->open_connection($ctx);
   $rc1=defined $rc1 ? Net::DRI::Util::link_rs($rc1,$rc2) : $rc2;
  }
 }

 return defined $rc1 ? $rc1 : Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','ping failed, no auto-reconnect');
}

sub close_socket
{
 my ($self)=@_;
 my $t=$self->transport_data();
 $self->sock()->close();
 $self->log_output('notice','transport',{},{phase=>'closing',message=>'Successfully closed socket for '.$t->{remote_uri}});
 $self->sock(undef);
 return;
}

sub close_connection
{
 my ($self,$ctx)=@_;
 $self->send_logout($ctx);
 $self->close_socket();
 $self->current_state(0);
 return;
}

sub end
{
 my ($self,$ctx)=@_;
 if ($self->current_state())
 {
  eval
  {
   local $SIG{ALRM}=sub { die 'timeout' };
   alarm 10;
   $self->close_connection($ctx);
  };
  alarm 0; ## since close_connection may die, this must be outside of eval to be executed in all cases
 }
 return;
}

####################################################################################################

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend,$count)=@_;
 ## We do a very crude error handling : if first send fails, we reset connection.
 ## Thus if you put retry=>2 when creating this object, the connection will be re-established and the message resent
 return $self->SUPER::send($ctx,$tosend,\&_print,sub { shift->current_state(0) },$count);
}

sub _print ## here we are sure open_connection() was called before
{
 my ($self,$count,$tosend,$ctx)=@_;
 my $pc=$self->transport_data('pc');
 my $sock=$self->sock();
 my $m=($self->transport_data('socktype') eq 'udp')? 'send' : 'print';
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send message to '.$self->transport_data('remote_uri').' because of error: '.$!) unless (($m ne 'print' || $sock->connected()) && $sock->$m($pc->write_message($self,$tosend)));
 return 1; ## very important
}

sub receive
{
 my ($self,$ctx,$count)=@_;
 return $self->SUPER::receive($ctx,\&_get,undef,$count);
}

sub _get
{
 my ($self,$count,$ctx)=@_;
 my $t=$self->transport_data();
 my $sock=$self->sock();
 my $pc=$t->{pc};

 ## Answer
 my $dr=$pc->read_data($self,$sock);
 $t->{exchanges_done}++;
 if ($t->{exchanges_done}==$t->{close_after} && $self->has_state() && $self->current_state())
 {
  $self->log_output('notice','transport',$ctx,{phase=>'closing',message=>'Due to maximum number of exchanges reached, closing connection to '.$t->{remote_uri}});
  $self->close_connection($ctx);
 }
 return $dr;
}

sub try_again
{
 my ($self,$ctx,$po,$err,$count,$istimeout,$step,$rpause,$rtimeout)=@_;
 if ($step==0) ## sending not already done, hence error during send
 {
  $self->current_state(0);
  return 1;
 }

 ## We do a more agressive retry procedure in case of udp (that is IRIS basically)
 ## See RFC4993 section 4
 if ($step==1 && $istimeout==1 && $self->transport_data()->{socktype} eq 'udp')
 {
  $self->log_output('debug','transport',$ctx,{phase=>'active',message=>sprintf('In try_again, currently: pause=%f timeout=%f',$$rpause,$$rtimeout)});
  $$rtimeout=2*$$rtimeout;
  $$rpause+=rand(1+int($$rpause/2));
  $self->log_output('debug','transport',$ctx,{phase=>'active',message=>sprintf('In try_again, new values: pause=%f timeout=%f',$$rpause,$$rtimeout)});
  return 1; ## we will retry
 }

 return 0; ## we do not handle other cases, hence no retry and fatal error
}


####################################################################################################
1;
