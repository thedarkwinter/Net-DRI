## Domain Registry Interface, .IT SecDNS extension
##
## Copyright (C) 2019 Paulo Jorge. All rights reserved.
##
## This program free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License v2.
##

package Net::DRI::Protocol::EPP::Extensions::IT::SecDNS;

use strict;
use warnings;

use Data::Dumper; # TODO: remove me later!

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IT::SecDNS - .IT EPP SecDNS extension for Net::DRI

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2019 Paulo Jorge.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.

=cut

sub register_commands {
  my ($class, $version) = @_;
  my $ops_domain = {
        'info'       => [ undef, \&parse_extdomain ]
  };
  my $ops_message = {
        'result'     => [ undef, \&parse_extmessage ]
  };

  return {
        'domain'     => $ops_domain,
        'message'    => $ops_message
  };
}

####################################################################################################

sub parse_extdomain
{
  my ($po, $otype, $oaction, $oname, $rinfo) = @_;
  my $msg = $po->message;
  my $ns = $msg->ns('it_secdns');
  my $infds = $msg->get_extension('it_secdns', 'infDsOrKeyToValidateData');

  if (defined($infds)) {
    foreach ($infds->findnodes('./extsecDNS:dsOrKeysToValidate/*/*')) {
      push (@{$rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'keyTag'}}, $_->textContent) if  $_->getName eq 'secDNS:keyTag';
      push (@{$rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'alg'}}, $_->textContent) if $_->getName eq 'secDNS:alg';
      push (@{$rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'digest'}}, $_->textContent) if $_->getName eq 'secDNS:digest';
      push (@{$rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'digestType'}}, $_->textContent) if $_->getName eq 'secDNS:digestType';
      

    }
    # lets get as well removal on all records on a domain info
    $rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'remAll'} = 'remAll' if ($infds->findnodes('//extsecDNS:remAll'));
  }

  return;
}

sub parse_extmessage
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  my @r=$mes->results_extra_info();
  return unless @r;

 foreach my $r (@r)
 {
  foreach my $rinfo (@$r)
  {
   if ($rinfo->{from} eq 'eppcom:value' && $rinfo->{type} eq 'rawxml' && $rinfo->{message}=~m!<extepp:wrongValue><extepp:element>(.+?)</extepp:element><extepp:namespace>(.+?)</extepp:namespace><extepp:value>(.+?)</extepp:value></extepp:wrongValue>!)
   {
    $rinfo->{message}="wrongValue $3 for $1";
    $rinfo->{from}='extepp';
    $rinfo->{type}='text';
   }

   if ($rinfo->{from} eq 'eppcom:extValue' && $rinfo->{type} eq 'rawxml' && $rinfo->{message}=~m!<extepp:reasonCode>(.+?)</extepp:reasonCode>!)
   {
    $rinfo->{message}="Reasoncode $1";
    $rinfo->{from}='extepp';
    $rinfo->{type}='text';
   }
  }
 }
 return;
}

1;