## Domain Registry Interface, VeriSign Two Factor Auth EPP extension
##
## Copyright (c) 2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::TwoFactorAuth;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'authsession' => { create => [ \&auth_create_generate, \&auth_create_parse ] },
          'domain' => { update => [ \&domain_update_generate, undef ] }, ## other domain operations ?
        };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'authExt' => [ 'http://www.verisign.com/epp/authExt-1.0','authExt-1.0.xsd' ],
           'authSession' => [ 'http://www.verisign.com/epp/authSession-1.0','authSession-1.0.xsd' ],
         });
 return;
}

####################################################################################################

sub _check_credentials
{
 my ($ra)=@_;

 Net::DRI::Exception::usererr_invalid_parameters('Value for key "credentials" must be an array reference') unless ref $ra eq 'ARRAY';
 foreach my $c (@$ra)
 {
  Net::DRI::Exception::usererr_invalid_parameters('Credentials must each be an XML token from 1 to 255 characters long, not '.$c) unless Net::DRI::Util::xml_is_token($c,1,255);
 }
 return;
}

sub _generate_svcotpcreds
{
 my ($rp)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('Key "service_provider" is mandatory') unless Net::DRI::Util::has_key($rp,'service_provider');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "otp" is mandatory') unless Net::DRI::Util::has_key($rp,'otp');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "credentials" is mandatory') unless Net::DRI::Util::has_key($rp,'credentials');
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "service_provider" must be an XML token from 3 to 10 characters long') unless Net::DRI::Util::xml_is_token($rp->{service_provider},3,10);
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "otp" must be an XML token from 5 to 20 characters long') unless Net::DRI::Util::xml_is_token($rp->{otp},5,20);
 _check_credentials($rp->{credentials});

 my @n;
 push @n,['authSession:serviceProvider',$rp->{service_provider}];
 push @n,['authSession:otp',$rp->{otp}];
 push @n,['authSession:credentialList',map { ['authSession:credentialId',$_] } @{$rp->{credentials}}];
 return @n;
}

sub _generate_token
{
 my ($rp)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('Key "service_provider" is mandatory') unless Net::DRI::Util::has_key($rp,'service_provider');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "credential" is mandatory') unless Net::DRI::Util::has_key($rp,'credential');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "crDate" is mandatory') unless Net::DRI::Util::has_key($rp,'crDate');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "exDate" is mandatory') unless Net::DRI::Util::has_key($rp,'exDate');
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "service_provider" must be an XML token from 3 to 10 characters long') unless Net::DRI::Util::xml_is_token($rp->{service_provider},3,10);
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "credential" must be an XML token from 1 to 255 characters long') unless Net::DRI::Util::xml_is_token($rp->{credential},1,255);
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "crDate" must be a DateTime object') unless Net::DRI::Util::check_isa($rp->{crDate},'DateTime');
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "exDate" must be a DateTime object') unless Net::DRI::Util::check_isa($rp->{exDate},'DateTime');

 my @n;
 push @n,['authSession:serviceProvider',$rp->{service_provider}];
 push @n,['authSession:credentialId',$rp->{credential}];
 push @n,['authSession:crDate',Net::DRI::Util::dto2zstring($rp->{crDate})];
 push @n,['authSession:exDate',Net::DRI::Util::dto2zstring($rp->{exDate})];
 return @n;
}

sub auth_create_generate
{
 my ($epp,$rp)=@_;
 my $mes=$epp->message();

 my @n;
 push @n,_generate_svcotpcreds($rp);

 $mes->command('create','authSession:create',sprintf('xmlns:authSession="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('authSession')));
 $mes->command_body(\@n);
 return;
}

sub auth_create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('authSession','creData');
 return unless defined $data;

 my %d;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;
  if ($name eq 'token')
  {
   foreach my $subel (Net::DRI::Util::xml_list_children($c))
   {
    my ($subname,$subc)=@$subel;
    if ($subname=~m/^(serviceProvider|credentialId)$/)
    {
     $d{Net::DRI::Util::remcam($1)}=$subc->textContent();
    } elsif ($subname=~m/^(crDate|exDate)$/)
    {
     $d{$1}=$po->parse_iso8601($subc->textContent());
    }
   }
  } elsif ($name eq 'signature')
  {
   $d{signature}=$c->textContent();
  }
 }

 $rinfo->{auth}->{$d{credential_id}}=\%d;
 return;
}

sub _generate_tokendata
{
 my ($rp)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('Key "token_provider" is mandatory') unless Net::DRI::Util::has_key($rp,'token_provider');
 Net::DRI::Exception::usererr_insufficient_parameters('Either key "token" or "generic_token" is mandatory') unless Net::DRI::Util::has_key($rp,'token') xor Net::DRI::Util::has_key($rp,'generic_token');
 Net::DRI::Exception::usererr_insufficient_parameters('Key "signature" is mandatory') unless Net::DRI::Util::has_key($rp,'signature');
 Net::DRI::Exception::usererr_invalid_parameters('Value for key "token_provider" must be an XML token from 3 to 10 characters long') unless Net::DRI::Util::xml_is_token($rp->{token_provider},3,10);

 my @n;
 push @n,['authExt:tokenProvider',$rp->{token_provider}];
 if (Net::DRI::Util::has_key($rp,'generic_token'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('Value for key "generic_token" must be an XML string') unless Net::DRI::Util::is_string($rp->{generic_token});
  push @n,['authExt:genericToken',$rp->{generic_token}];
 }
 if (Net::DRI::Util::has_key($rp,'token'))
 {
  push @n,['authExt:token',_generate_token($rp->{token})];
 }

 Net::DRI::Exception::usererr_invalid_parameters('Value for key "signature" must be an XML base64binary content') unless Net::DRI::Util::verify_base64($rp->{signature});
 push @n,['authExt:signature',$rp->{signature}];

 return ['authExt:tokenData',@n];
}

sub _generate_otpdata
{
 my ($rp)=@_;
 return ['authSession:otpData',_generate_svcotpcreds($rp)];
}

sub domain_update_generate
{
 my ($epp,$dom,$toc,$rp)=@_;

 return unless Net::DRI::Util::has_key($rp,'auth') && ref $rp->{auth} eq 'HASH' && grep { Net::DRI::Util::has_key($rp->{auth},$_); } qw/validate bind unbind/;

 my $mes=$epp->message();
 my @n;

 if (Net::DRI::Util::has_key($rp->{auth},'validate'))
 {
  my @d;

  if (Net::DRI::Util::has_key($rp->{auth}->{validate},'token_provider'))
  {
   push @d,_generate_tokendata($rp->{auth}->{validate});
  } elsif (Net::DRI::Util::has_key($rp->{auth}->{validate},'service_provider'))
  {
   push @d,_generate_otpdata($rp->{auth}->{validate});
  } else
  {
   Net::DRI::Exception::usererr_insufficient_parameters('Key "validate" needs either a "service_provider" or a "token_provider" key');
  }
  push @n,['authExt:validate',@d];
 }

 if (Net::DRI::Util::has_key($rp->{auth},'bind'))
 {
  my @data=ref $rp->{auth}->{bind} eq 'ARRAY' ? @{$rp->{auth}->{bind}} : ($rp->{auth}->{bind});
  Net::DRI::Exception::usererr_invalid_parameters('Value for key "bind" must be a refhash or a refarray of refhashes') if grep { ref $_ ne 'HASH' } @data;
  my $istoken=scalar grep { exists $_->{token_provider} } @data;
  my $isotp=scalar grep { exists $_->{service_provider} } @data;
  Net::DRI::Exception::usererr_invalid_parameters('For key "bind" values must be refarray of refhashes with key "token_provider" or "service_provider", not both') if ($istoken && $isotp);

  my @d;
  if ($istoken)
  {
   push @d,['authExt:tokenDataList',map { _generate_tokendata($_) } @data ];
  } elsif ($isotp)
  {
   push @d,['authExt:otpDataList',map { _generate_otpdata($_) } @data ];
  } else
  {
   Net::DRI::Exception::usererr_insufficient_parameters('For key "bind" values must be refarray of refhashes with either key "token_provider" or "service_provider"');
  }
  push @n,['authExt:bind',@d];
 }

 if (Net::DRI::Util::has_key($rp->{auth},'unbind'))
 {
  my @d;
  _check_credentials($rp->{auth}->{unbind});
  push @d,map { ['authSession:credentialId',$_] } @{$rp->{auth}->{unbind}};
  push @n,['authExt:unbind',@d];
 }

 my $eid=$mes->command_extension_register(['authExt','authSession'],'authActions');
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::TwoFactorAuth - VeriSign Two Factor Auth EPP for Net::DRI

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

Copyright (c) 2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
