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
        'info'          => [ undef, \&parse_extdomain ]
  };
  my $ops_notification = {
        'notification'  => [ undef, \&parse_extnotification ]
  };

  return {
        'domain'     => $ops_domain,
        'message'    => $ops_notification
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

sub parse_extnotification
{
  my ($po, $otype, $oaction, $oname, $rinfo) = @_;
  my $mes=$po->message();
  return unless $mes->is_success();
  my $msgid=$oname=$mes->msg_id();
  return unless (defined($msgid) && $msgid);

  my $infds = $mes->get_extension('it_secdns', 'secDnsErrorMsgData');
  return unless defined $infds;

  foreach my $el (Net::DRI::Util::xml_list_children($infds)) {
    my ($name,$content)=@$el;
    if ($name eq 'dsOrKeys') {
      $rinfo->{$otype}->{$oname}->{extsecdns}->{dsorkeys} = _parse_dsorkeys($po, $content);
    } elsif ($name eq 'tests') {
      $rinfo->{$otype}->{$oname}->{extsecdns}->{tests} = _parse_tests($po, $content);
    } elsif ($name eq 'queries') {
      $rinfo->{$otype}->{$oname}->{extsecdns}->{queries} = _parse_queries($po, $content);
    }
  }

  return;
}

####################################################################################################
####################################################################################################
####################################################################################################

sub _parse_dsorkeys
{
  my ( $po, $node_dsorkeys ) = @_;
  return unless $node_dsorkeys;

  my $set_dsorkeys = {};
  my @d;
  my $msl;

  foreach my $el_dsorkeys (Net::DRI::Util::xml_list_children($node_dsorkeys)) {
    my ( $name_dsorkeys, $content_dsorkeys ) = @$el_dsorkeys;
    if ($name_dsorkeys eq 'maxSigLife') {
      $msl=0+$content_dsorkeys->textContent();
    } elsif ($name_dsorkeys eq 'dsData') {
      my $rn=Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_dsdata($content_dsorkeys);
      $rn->{maxSigLife}=$msl if defined $msl;
      push @d,$rn;
    } elsif ($name_dsorkeys eq 'keyData') {
      my %n;
      Net::DRI::Protocol::EPP::Extensions::SecDNS::parse_keydata($content_dsorkeys ,\%n);
      $n{maxSigLife}=$msl if defined $msl;
      push @d,\%n;
    }
    $set_dsorkeys = \@d;
  }

  return $set_dsorkeys;
}


sub _parse_tests
{
  my ( $po, $node_tests) = @_;
  return unless $node_tests;

  my $set_tests = {};

  foreach my $el_tests (Net::DRI::Util::xml_list_children($node_tests)) {
    my ( $name_tests, $content_tests ) = @$el_tests;
    my $tname = $content_tests->getAttribute('name');
    $set_tests->{$tname}->{status} = $content_tests->getAttribute('status');
    foreach my $el_tests2 (Net::DRI::Util::xml_list_children($content_tests)) {
      my ( $name_tests2, $content_tests2 ) = @$el_tests2;
      $set_tests->{$tname}->{dns}->{$content_tests2->getAttribute('name')} = $content_tests2->getAttribute('status') if $content_tests2->getAttribute('status') eq 'SUCCEEDED';
      $set_tests->{$tname}->{dns}->{$content_tests2->getAttribute('name')} = { $content_tests2->getAttribute('status'), $content_tests2->textContent } unless $content_tests2->getAttribute('status') eq 'SUCCEEDED';
    }
  }

  return $set_tests;
}


sub _parse_queries
{
  my ( $po, $node_queries ) = @_;
  return unless $node_queries;

  my $set_queries = {};

  foreach my $el_queries (Net::DRI::Util::xml_list_children($node_queries)) {
    my ( $name_queries, $content_queries ) = @$el_queries;
    my $qid = $content_queries->getAttribute('id');
    foreach my $el_queries2 (Net::DRI::Util::xml_list_children($content_queries)) {
      my ( $name_queries2, $content_queries2 ) = @$el_queries2;
      $set_queries->{$qid}->{$name_queries2} = $content_queries2->textContent;
    }
  }

  return $set_queries;
}

1;