## Domain Registry Interface, SOAP Transport (HTTP/HTTPS)
##
## Copyright (c) 2005,2009-2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Transport::SOAP;

use strict;
use warnings;

use base qw(Net::DRI::Transport);

use Net::DRI::Exception;

use SOAP::Lite;

=pod

=head1 NAME

Net::DRI::Transport::SOAP - SOAP (HTTP/HTTPS) Transport for Net::DRI

=head1 DESCRIPTION

When calling new_current_profile with this transport, in ref array of parameters
for transport, pass an hash ref with the following keys, as needed:

=over

=item *

C<proxy_url> is a string giving the url to use
(mostly worthless since using services, but needed to setup credentials)

=item *

C<credentials> is an array ref with four items in this order:
sitename:port,realm,username,password
 ex: C<< credentials=>['soap-adh.nic.fr:443','Webservices Adherents AFNIC','USERNAME','PASSWORD'] >>

=item *

C<service_wsdl> is an hash ref : the key is a string used in Protocol classes,
value is an url to the corresponding WSDL file
 ex: C<< service_wsdl=>{Domain=>'file:./Domain-perl.wsdl'} >>

=item *

C<ssl_ca_file> is a string giving the local path to the CA certificate file, if using https

=back

=head2 CURRENT LIMITATIONS

=over

=item * only for SOAP over HTTP/HTTPS

=item * only one CA certificate can be used in each given instance of Net::DRI 
(because it is given through %ENV)

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2009-2011,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->has_state(0);
 $self->is_sync(1);
 $self->name('soap');
 $self->version('0.1');

 my %t;

 Net::DRI::Exception::usererr_insufficient_parameters('proxy_url must be defined') unless (exists($opts{proxy_url}));
 Net::DRI::Exception::usererr_invalid_parameters('proxy_url must be http:// or https://') unless ($opts{proxy_url}=~m!^https?://!);
 Net::DRI::Exception::usererr_insufficient_parameters('service_wsdl') unless (exists($opts{service_wsdl}));
 Net::DRI::Exception::usererr_invalid_parameters('service_wsdl must be a ref hash') unless (ref($opts{service_wsdl}) eq 'HASH'); ## Name (without .wsdl),ex: Domain => Path to corresponding wsdl file

 my $service=SOAP::Lite->on_fault(\&soap_fault);
 my %st;

 while(my ($k,$v)=each(%{$opts{service_wsdl}}))
 {
  my $go=$service->service($v);
  my $t=$go->transport();
  $t->agent(sprintf('Net::DRI/%s',$Net::DRI::VERSION).$t->agent());
  if ($self->timeout())
  {
   $t->proxy($opts{proxy_url},timeout => $self->timeout());
  } else
  {
   $t->proxy($opts{proxy_url});
  }

  # name:port,realm,user,login
  $t->credentials(@{$opts{credentials}}) if ($opts{credentials} && (ref($opts{credentials}) eq 'ARRAY'));

  $st{$k}=$go;
 }

 $t{service_wsdl}=\%st;

 if (exists($opts{ssl_ca_file}) && (-s $opts{ssl_ca_file}))
 {
  ## How to handle multiple SOAP instances in the same process ??
  $ENV{HTTPS_CA_FILE}=$opts{ssl_ca_file}; ## no critic (Variables::RequireLocalizedPunctuationVars)
 }

 $t{soap}=$service;
 $self->{transport}=\%t;
 return $self;
}

sub soap_fault ## no critic (Subroutines::RequireFinalReturn)
{
 my($soap,$res)=@_; 
 my $msg=ref $res ? $res->faultstring() : $soap->transport()->status();
 Net::DRI::Exception->die(1,'transport/soap',7,'SOAP fault: '.$msg);
}

sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
 my ($self,$ctx,$tosend)=@_;
 return $self->SUPER::send($ctx,$tosend,\&_soap_send,sub {});
}

sub _soap_send
{
 my ($self,$count,$tosend)=@_;
 my $t=$self->{transport};
 my $so=$t->{soap};
 my $sw=$t->{service_wsdl}; ## a ref hash
 my $service=$tosend->service();

 Net::DRI::Exception::usererr_insufficient_parameters("No wsdl file specified for service $service") unless (exists($sw->{$service}));

 my $m=$tosend->method();
 my $r=$sw->{$service}->$m(@{$tosend->params()});
 $t->{last_reply}=$r;
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
 my $so=$t->{service};
 my $r=$t->{last_reply};
 $t->{last_reply}=undef;

 return $r; ## will we need one day access to $so ?
}

####################################################################################################
1;
