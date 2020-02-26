## Domain Registry Interface, Verification Code Extension Mapping for EPP
##
## Copyright (c) 2016,2018,2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VerificationCode;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $ractions = { 'info'   => [ \&info_build, \&info_parse ],
                     'create' => [ \&create_build, undef ],
                     'delete' => [ \&create_build, undef ],
                     'renew'  => [ \&create_build, undef ],
                     'transfer_request' => [ \&create_build, undef ],
                     'update' => [ \&create_build, undef ],
                   };
 state $rcmds = { 'domain'  => $ractions,
                  'contact' => $ractions,
                  'host'    => $ractions,
                };
 return $rcmds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $rns = { 'verificationCode' => 'urn:ietf:params:xml:ns:verificationCode-1.0' };
 $po->ns($rns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-ietf-regext-verificationcode-06'; }

####################################################################################################

sub is_verification_code
{
 my ($code) = @_;
 return defined $code && $code =~m/^\d+-[0-9a-z]+$/i ? 1 : 0;
}

####################################################################################################

sub info_build
{
 my ($epp, $oname, $rd)=@_;

 return unless Net::DRI::Util::has_key($rd, 'verification_code') && $rd->{'verification_code'};

 my %attrs;
 if (Net::DRI::Util::has_key($rd, 'verification_code_profile'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('verification_code_profile must be an XML token') unless Net::DRI::Util::xml_is_token($rd->{verification_code_profile});
  $attrs{profile} = $rd->{verification_code_profile};
 }

 $epp->message()->command_extension('verificationCode', ['info', \%attrs]);

 return;
}

sub info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $data = $mes->get_extension('verificationCode', 'infData');
 return unless defined $data;

 my %v;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name, $node)=@$el;
  if ($name eq 'status')
  {
   $v{status} = $node->textContent();
  } elsif ($name eq 'profile')
  {
   my $pname = $node->getAttribute('name');
   my %p;
   foreach my $subel (Net::DRI::Util::xml_list_children($node))
   {
    my ($subname, $subnode) = @$subel;
    if ($subname eq 'status')
    {
     $p{status} = $subnode->textContent();
    } elsif ($subname eq 'missing')
    {
     foreach my $code (Net::DRI::Util::xml_list_children($subnode, 'code'))
     {
      my %a = ( type => $code->getAttribute('type'),
                due  => $po->parse_iso8601($code->getAttribute('due')),
              );
      push @{$p{missing}}, \%a;
     }
    } elsif ($subname eq 'set')
    {
     foreach my $code (Net::DRI::Util::xml_list_children($subnode, 'code'))
     {
       my %a = ( type => $code->getAttribute('type'),
                 date => $po->parse_iso8601($code->getAttribute('date')),
                 code => $code->textContent(),
               );
       push @{$p{set}}, \%a;
     }
    }
   }
   $v{profiles}->{$pname} = \%p;
  }
 }

 $rinfo->{$otype}->{$oname}->{verification}=\%v;

 return;
}

sub create_build
{
 my ($epp, $oname, $rd)=@_;

 return unless Net::DRI::Util::has_key($rd, 'verification_code') && $rd->{'verification_code'};

 my $vc = $rd->{verification_code};
 $vc = [ $vc ] unless ref $vc eq 'ARRAY';

 ## TODO: handle other encoding than base64
 foreach my $code (@$vc)
 {
  Net::DRI::Exception::usererr_invalid_parameters('verification code must be BASE64 formatted') unless Net::DRI::Util::verify_base64($code);
 }

 $epp->message()->command_extension('verificationCode', ['encodedSignedCode', map { ['verificationCode:code', $_] } @$vc]);

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VerificationCode - EPP Verification Code Extension mapping (draft-ietf-regext-verificationcode-06) for Net::DRI

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

Copyright (c) 2016,2018,2019 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut