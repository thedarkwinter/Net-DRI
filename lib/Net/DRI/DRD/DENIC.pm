## Domain Registry Interface, DENIC policies
##
## Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2012-2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::DENIC;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::DENIC - DENIC (.DE) policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2012 Michael Holloway <michael@thedarkwinter.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'DENIC'; }
sub tlds     { return ('de','9.4.e164.arpa'); } ## *.9.4.e164.arpa can be queried over IRIS DCHK, do not know about RRI support
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/rri dchk/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{remote_host=>'rri.test.denic.de',remote_port=>51131,defer=>1,close_after=>1,socktype=>'tcp'},'Net::DRI::Protocol::RRI',{version=>'2.0'}) if $type eq 'rri';
 ## DENIC IRIS server does not support request deflation, see §3.1.7 "no-inflation-support-error", so we force no deflate
 return ('Net::DRI::Transport::Socket',{find_remote_server => ['de.','DCHK1:iris.lwz']},'Net::DRI::Protocol::IRIS',{version=>'1.0',authority=>'de',request_deflate=>0})          if $type eq 'dchk';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1, ## is that right ??
                                              });
}

sub contact_update
{
 my ($self, $reg, $c, $changes, $rd) = @_;
 my $oc = $reg->get_info('self', 'contact', $c->srid());

 if (!defined($oc))
 {
  my $res = $reg->process('contact', 'info',
	[$reg->local_object('contact')->srid($c->srid())]);
  $oc = $reg->get_info('self', 'contact', $c->srid())
	if ($res->is_success());
 }

 $c->type($oc->type()) if (defined($oc));

 return $self->SUPER::contact_update($reg, $c, $changes, $rd);
}

sub domain_update
{
 my ($self, $reg, $dom, $changes, $rd) = @_;
 $rd=Net::DRI::Util::create_params('domain_update',$rd);
 my $cs = $reg->get_info('contact', 'domain', $dom);
 my $ns = $reg->get_info('ns', 'domain', $dom);

 if (!defined($cs) || !defined($ns))
 {
  my $res = $reg->process('domain', 'info', [$dom]);
  $cs = $reg->get_info('contact', 'domain', $dom) if ($res->is_success());
  $ns = $reg->get_info('ns', 'domain', $dom) if ($res->is_success());
 }

 $rd->{contact} = $cs unless (defined($rd->{contact}));
 $rd->{ns} = $ns unless (defined($rd->{ns}));

 return $self->SUPER::domain_update($reg, $dom, $changes, $rd);
}

sub domain_trade
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'trade', [$dom, $rd]);
}

sub domain_transit
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'transit', [$dom, $rd]);
}

sub domain_migrate_descr
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'migrate_descr', [$dom, $rd]);
}

sub domain_create_authinfo
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'create_authinfo', [$dom, $rd]);
}

sub domain_delete_authinfo
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'delete_authinfo', [$dom, $rd]);
}

####################################################################################################
1;
