## Domain Registry Interface, EPP AusRegistry IDN Extension
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AusRegistry::IDN;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef         , \&info_parse ],
           create => [ \&create_build, \&create_parse ],
         );

 return { 'domain' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'idn' => [ 'urn:X-ar:params:xml:ns:idnadomain-1.0','idnadomain-1.0.xsd' ],
         });
 return;
}

####################################################################################################

sub parse_idn
{
 my ($rh,$data)=@_;

 my %idn;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'userForm')
  {
   $idn{user_form}=$node->textContent();
   $idn{language}=$node->getAttribute('language');
  } elsif ($name eq 'canonicalForm')
  {
   $idn{canonical_form}=$node->textContent();
  }
 }

 $rh->{idn}=\%idn;
 $rh->{language}=$idn{language}; ## compatibility mode with other IDN extensions
 return;
}

## <extension>
##  <infData xmlns="urn:X-ar:params:xml:ns:idnadomain-1.0">
##   <userForm language="gr">&#x03C9;&#x03C2;.example</userForm>
##   <canonicalForm>&#x03C9;&#x03C2;.example</canonicalForm>
##  </infData>
## </extension>

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('idn','infData');
 return unless defined $data;

 parse_idn($rinfo->{domain}->{$oname},$data);
 return;
}

## (In documentation, XML exemple is wrong, text is OK)
##
## <extension>
##  <create xmlns="urn:X-ar:params:xml:ns:idnadomain-1.0">
##   <userForm language="gr">&#x03C9;&#x03C2;.example</userForm>
##  </create>
## </extension>

sub create_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'idn');

 Net::DRI::Exception::usererr_invalid_parameters(q{Value for "idn" key must be a ref hash, not: }.$rd->{idn}) unless $rd->{idn} eq 'HASH';
 Net::DRI::Exception::usererr_insufficient_parameters(q{IDN ref hash must have a language key}) unless exists $rd->{idn}->{language} && defined $rd->{idn}->{language};
 Net::DRI::Exception::usererr_invalid_parameters(q{IDN language tag value must be of type XML schema language}) unless Net::DRI::Util::xml_is_language($rd->{idn}->{language});
 Net::DRI::Exception::usererr_insufficient_parameters(q{IDN ref hash must have a user_form key}) unless exists $rd->{idn}->{user_form} && defined $rd->{idn}->{user_form};
 Net::DRI::Exception::usererr_invalid_parameters(q{IDN user_form value must be of type XML token from 1 to 255 characters}) unless Net::DRI::Util::xml_is_token($rd->{idn}->{user_form},1,255);

 my $eid=$mes->command_extension_register('idn','create');
 $mes->command_extension($eid,['userForm',{language => $rd->{idn}->{language}},$rd->{idn}->{user_form}]);

 return;
}

## <extension>
##  <creData xmlns="urn:X-ar:params:xml:ns:idnadomain-1.0">
##   <userForm language="gr">&#x03C9;&#x03C2;.example</userForm>
##   <canonicalForm>&#x03C9;&#x03C2;.example</canonicalForm>
##  </creData>
## </extension>

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('idn','creData');
 return unless defined $data;

 parse_idn($rinfo->{domain}->{$oname},$data);
 return;
}


####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AusRegistry::IDN - EPP AusRegistry IDN commands for Net::DRI

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

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

