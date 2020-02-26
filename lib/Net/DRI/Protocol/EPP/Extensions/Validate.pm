## Validate Mapping for the Extensible Provisioning Protocol (draft-ietf-regext-validate-04)
##
## Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Validate;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $cmds = { 'contact' => { 'validate' => [ \&check, \&check_parse ] } };
 return $cmds;
}

sub setup
{
 my ($class,$po,$version)=@_;

 state $ns = { 'validate' => 'urn:ietf:params:xml:ns:validate-0.2' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-ietf-regext-validate-04'; }

####################################################################################################

sub check
{
 my ($epp, $contact) = @_;
 my $mes = $epp->message();

 my @contacts;
 foreach my $cd (ref $contact eq 'ARRAY' ? @$contact : ($contact))
 {
  Net::DRI::Exception::usererr_invalid_parameters('"type" key must exist and its content be an XML token from 1 to 255 characters') unless Net::DRI::Util::has_key($cd, 'type') && Net::DRI::Util::xml_is_token($cd->{type}, 1, 255);
  Net::DRI::Exception::usererr_invalid_parameters('"zone" key must exist and its content be an XML token from 1 to 255 characters') unless Net::DRI::Util::has_key($cd, 'zone')    && Net::DRI::Util::xml_is_token($cd->{zone}, 1, 255);
  Net::DRI::Exception::usererr_invalid_parameters('"contact" key must exist and its content be a Net::DRI contact object') unless Net::DRI::Util::has_key($cd, 'contact') && Net::DRI::Util::isa_contact($cd->{contact});

  my $co = $cd->{'contact'};
  my @c;
  my $id = $co->srid() // '';
  Net::DRI::Exception::usererr_invalid_parameters('Contact ID must be defined and be a token from 3 to 16 characters') unless Net::DRI::Util::xml_is_token($id, 3, 16);
  push @c, ['validate:id', $id];

  if (grep { defined } map { $co->$_() } qw/name org street city sp pc cc/)
  {
   # We allow only one postalInfo
   my ($pi, @pi) = Net::DRI::Protocol::EPP::Util::build_postalinfo($co, $epp->{contacti18n});
   $pi->[0] = 'validate:postalInfo';
   push @c, $pi;
  }
  push @c, Net::DRI::Protocol::EPP::Util::build_tel('validate:voice', $co->voice()) if defined $co->voice();
  push @c, Net::DRI::Protocol::EPP::Util::build_tel('validate:fax', $co->fax()) if defined $co->fax();
  push @c, ['validate:email', $co->email()] if defined $co->email();
  my $az = $co->auth();
  push @c, ['validate:authInfo', ['contact:pw', $az->{pw}]] if defined $az && ref $az eq 'HASH' && exists $az->{pw};

  if (Net::DRI::Util::has_key($cd, 'kv'))
  {
   # contactType probably not needed here?
   Net::DRI::Exception::usererr_invalid_parameters('"kv" data element must be a ref hash') unless ref $cd->{kv} eq 'HASH';
   my @kvs;
   foreach my $key (sort { $a cmp $b } keys %{$cd->{kv}})
   {
    Net::DRI::Exception::usererr_invalid_parameters('KV key content must be an XML token of at least 1 character') unless Net::DRI::Util::xml_is_token($key, 1);
    my $value = $cd->{kv}->{$key};
    Net::DRI::Exception::usererr_invalid_parameters('KV value content must be an XML token') unless Net::DRI::Util::xml_is_token($value);
    push @kvs, ['validate:kv', { key => $key, value => $value }];
   }
   push @c, @kvs if @kvs;
  }
  push @contacts, ['validate:contact', { contactType => $cd->{type}, tld => $cd->{zone}}, @c];
 }

 $mes->command(['check', 'validate:check', $mes->nsattrs('validate')]);
 $mes->command_body(\@contacts);
 return;
}

sub check_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $chkdata = $mes->get_response('validate', 'chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('validate'), 'cd'))
 {
  my $contact;
  my %kvs;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($name, $node) = @$el;
   if ($name eq 'id')
   {
    $contact = $node->textContent();
    $rinfo->{contact}->{$contact}->{action} = 'validate';
   } elsif ($name eq 'response')
   {
    $rinfo->{contact}->{$contact}->{validate} = { response => $node->textContent() };
   } elsif ($name eq 'kv')
   {
    my $key = $node->getAttribute('key');
    my $value = $node->getAttribute('value');
    my $type = $node->getAttribute('contactType'); # optional
    $rinfo->{contact}->{$contact}->{validate}->{$key} //= {};
    $rinfo->{contact}->{$contact}->{validate}->{$key}->{defined $type ? lc $type : '*'} = $value;
   }
  }
 }

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNAME - EPP Mapping for validation of contact data (draft-ietf-regext-validate-04) for Net::DRI

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

Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut