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
  my $mes = $po->message;
  my $ns = $mes->ns('it_secdns');
  my $infds = $mes->get_extension('it_secdns', 'infDsOrKeyToValidateData');
  return unless defined $infds;
  my @d;
  my $msl;

  foreach my $el (Net::DRI::Util::xml_list_children($infds)) {
    my ($name,$c)=@$el;
    if ($name eq 'dsOrKeysToValidate') {
      foreach my $el2 (Net::DRI::Util::xml_list_children($c)) {
        my ($name2,$c2)=@$el2;
        if ($name2 eq 'maxSigLife') {
          $msl=0+$c2->textContent();
        } elsif ($name2 eq 'dsData') {
          my $rn=Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_dsdata($c2);
          $rn->{maxSigLife}=$msl if defined $msl;
          push @d,$rn;
        } elsif ($name2 eq 'keyData') {
          my %n;
          Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_keydata($c2 ,\%n);
          $n{maxSigLife}=$msl if defined $msl;
          push @d,\%n;
        }
      }
      $rinfo->{'domain'}->{$oname}->{ds_or_keys_to_validate}=\@d;
    } elsif ($name eq 'remAll') {
      # lets get as well removal on all records on a domain info
      $rinfo->{'domain'}{$oname}{'ds_or_keys_to_validate'}{'remAll'} = 'remAll';
    }
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