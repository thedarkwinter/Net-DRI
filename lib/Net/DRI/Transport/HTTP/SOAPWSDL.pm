## Domain Registry Interface, SOAP+WSDL Transport
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

package Net::DRI::Transport::HTTP::SOAPWSDL;

use strict;
use warnings;

use base qw(Net::DRI::Transport);

use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Util;
use SOAP::WSDL;

=pod

=head1 NAME

Net::DRI::Transport::HTTP::SOAPWSDL - SOAP+WSDL Transport for Net::DRI

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
 my $po=$ctx->{protocol};

 my %t=(message_factory => $po->factories()->{message});
 if (exists($opts{protocol_connection}) && $opts{protocol_connection})
 {
  $t{protocol_connection}=$opts{protocol_connection};
  Net::DRI::Util::load_module($t{protocol_connection},'transport/soapwsdl');
  if ($t{protocol_connection}->can('transport_default'))
  {
   %opts=($t{protocol_connection}->transport_default('soapwsdl'),%opts);
  }
 }

 my $self=$class->SUPER::new($ctx,\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->is_sync(1);
 $self->name('soapwsdl');
 $self->version('0.1');

 $t{has_login}=(exists($opts{has_login}) && defined($opts{has_login}))? $opts{has_login} : 0;
 $t{has_logout}=(exists($opts{has_logout}) && defined($opts{has_logout}))? $opts{has_logout} : 0;
 $self->has_state($t{has_login});
 if ($t{has_login})
 {
  foreach my $p (qw/client_login client_password/)
  {
   Net::DRI::Exception::usererr_insufficient_parameters($p.' must be provided') unless (exists($opts{$p}) && defined($opts{$p}));
   $t{$p}=$opts{$p};
  }
  $t{session_data}={};
 }

 foreach my $p (qw/protocol_connection wsdl_uri proxy_uri servicename portname/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be provided') unless (exists($opts{$p}) && defined($opts{$p}));
  $t{$p}=$opts{$p};
 }
 Net::DRI::Exception::usererr_invalid_parameters('proxy_uri must be http:// or https://') unless ($t{proxy_uri}=~m!^https?://!);

 my $pc=$t{protocol_connection};
 if ($t{has_login})
 {
  foreach my $m (qw/login parse_login extract_session/)
  {
   Net::DRI::Exception::usererr_invalid_parameters('Protocol connection class '.$pc.' must have a '.$m.'() method, since has_login=1') unless ($pc->can($m));
  }
 }
 if ($t{has_logout})
 {
  foreach my $m (qw/logout parse_logout/)
  {
   Net::DRI::Exception::usererr_invalid_parameters('Protocol connection class '.$pc.' must have a '.$m.'() method, since has_logout=1') unless ($pc->can($m));
  }
 }

 $self->{transport}=\%t;

 if ($self->has_state())
 {
  if ($self->defer()) ## we will open, but later
  {
   $self->current_state(0);
  } else ## we will open NOW 
  {
   $self->open_connection($ctx);
  }
 } else
 {
  $self->init();
  $self->time_open(time());
 }

 return $self;
}

sub soap { my ($self,$v)=@_; $self->{transport}->{soap}=$v if defined $v; return $self->{transport}->{soap}; }
sub session_data { my ($self,$v)=@_; $self->{transport}->{session_data}=$v if defined $v; return $self->{transport}->{session_data}; }

sub init
{
 my ($self)=@_;
 return if defined($self->soap());
 my $soap=SOAP::WSDL->new();
 $soap->wsdl($self->{transport}->{wsdl_uri});
 $soap->proxy($self->{transport}->{proxy_uri});
 $soap->wsdlinit();
 $soap->servicename($self->{transport}->{servicename});
 $soap->portname($self->{transport}->{portname});
 $soap->get_client()->get_transport()->agent(sprintf('Net::DRI/%s ',$Net::DRI::VERSION).$soap->get_client()->get_transport()->agent());
 $self->soap($soap);
 return;
}

sub send_login
{
 my ($self,$ctx)=@_;
 my $t=$self->{transport};
 return unless $t->{has_login};
 foreach my $p (qw/client_login client_password/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }

 my $pc=$t->{protocol_connection};
 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my $login=$pc->login($t->{message_factory},$t->{client_login},$t->{client_password},$cltrid);
 my $res=$self->_send_receive({otype=>'session',oaction=>'login',trid=>$cltrid,phase=>'opening'},$login);
 my $msg=$t->{message_factory}->();
 $msg->parse(Net::DRI::Data::Raw->new(1,[$res->result()]));
 my $rc=$pc->parse_login($msg);
 die($rc) unless $rc->is_success();

 $self->session_data($pc->extract_session($msg));
 return;
}

sub send_logout
{
 my ($self)=@_;
 my $t=$self->{transport};
 return unless $t->{has_logout};

 my $pc=$t->{protocol_connection};
 my $cltrid=$self->generate_trid($self->{logging_ctx}->{registry});
 my $logout=$pc->logout($t->{message_factory},$cltrid,$t->{session_data});
 my $res=$self->_send_receive({otype=>'session',oaction=>'logout',trid=>$cltrid,phase=>'closing'},$logout);
 my $msg=$t->{message_factory}->();
 $msg->parse(Net::DRI::Data::Raw->new(1,[$res->result()]));
 my $rc=$pc->parse_logout($msg);
 die($rc) unless $rc->is_success();

 $self->session_data({});
 return;
}

sub _send_receive ## no critic (Subroutines::RequireFinalReturn)
{
 my ($self,$ctx,$msg)=@_;
 my $soap=$self->soap();
 my $res=$soap->call($msg->method(),%{$msg->params()});
 if (my $httpres=$soap->get_client()->get_transport()->http_response())
 {
  $self->log_output('notice','transport',$ctx,{direction=>'out',message=>$httpres->request()});
  $self->log_output('notice','transport',$ctx,{direction=>'in', message=>$httpres});
 } else
 {
  $soap->no_dispatch(1);
  $self->log_output('error','transport',$ctx,{direction=>'out',message=>'No response for message '.$soap->call($msg->method(), %{$msg->params()})});
  $soap->no_dispatch(0);
 }
 return $res if $res; ## SOAP::WSDL::Client returns a fault object on errors, even on transport layer errors.

 Net::DRI::Exception->die(1,'transport/soapwsdl',4,'Unable to send message due to SOAP fault: '.$res->faultcode().' '.$res->faultstring());
}

sub open_connection
{
 my ($self,$ctx)=@_;
 $self->init();
 $self->send_login($ctx);
 $self->current_state(1);
 $self->time_open(time());
 $self->time_used(time());
 return;
}

sub close_connection
{
 my ($self)=@_;
 $self->send_logout();
 $self->soap(undef);
 $self->current_state(0);
 return;
}

sub end
{
 my ($self)=@_;
 if ($self->has_state() && $self->current_state())
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

####################################################################################################

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend)=@_;
 return $self->SUPER::send($ctx,$tosend,\&_soap_send,sub {});
}

sub _soap_send
{
 my ($self,$count,$tosend,$ctx)=@_;
 my $t=$self->{transport};
 $tosend->add_session($self->session_data());
 my $res=$self->_send_receive($ctx,$tosend);
 $t->{last_reply}=$res;
 return 1; ## very important
}

sub receive
{
 my ($self,$ctx,$count)=@_;
 return $self->SUPER::receive($ctx,\&_soap_receive);
}

sub _soap_receive
{
 my ($self,$count)=@_;
 my $t=$self->{transport};
 my $r=$t->{last_reply};
 $t->{last_reply}=undef;
 return Net::DRI::Data::Raw->new(6,[$r->result()]);
}

####################################################################################################
1;
