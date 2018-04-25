## Domain Registry Interface, FRED Poll EPP extension commands
##
## Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
################################################################################

package Net::DRI::Protocol::EPP::Extensions::FRED::Message;

use strict;
use warnings;
use POSIX qw(strftime);
use DateTime::Format::ISO8601;
use Data::Dumper; # TODO: remove me later

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FRED::Message - FRED Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

David Makuni, E<lt>d.makuni@live.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
  my ($class, $version) = @_;
  return { 'message' => { 'retrieve' => [ undef, \&parse_poll ] } };
}

####################################################################################################

sub parse_poll {
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;

  my $mes=$po->message();
  return unless $mes->is_success();

  my $msgid=$mes->msg_id();
  my $msg_content = $mes->node_msg();
  return unless ((defined($msgid) && $msgid) && (defined($msg_content) && $msg_content));

  $oname = $msgid;
  $otype = $otype ? $otype : 'message';

  my @res_children = Net::DRI::Util::xml_list_children($msg_content);
  # print Dumper(\@res_children);
  foreach my $el(@res_children) {
    my ($n,$c)=@$el;
    if ($n eq 'trnData') {
      my @trnData = Net::DRI::Util::xml_list_children($c);
      foreach my $el(@trnData) {
        my ($n,$c)=@$el;
        if ($n eq 'trDate') {
          $rinfo->{$otype}->{$oname}->{action} = 'transfer';
          $rinfo->{$otype}->{$oname}->{object_type} = 'domain';
          $rinfo->{$otype}->{$oname}->{object_id} = $rinfo->{$otype}->{$oname}->{name}
            if ($rinfo->{$otype}->{$oname}->{name});
        }
        if ($n eq 'clID') {
          $rinfo->{$otype}->{$oname}->{reID} = $c->textContent() ? $c->textContent() : '' if ($n);
        }
        $rinfo->{$otype}->{$oname}->{$n} = $c->textContent() ? $c->textContent() : '' if ($n);
      }
    } else {
      if ( $n && lc($n) =~ m/^(lowcreditdata|requestfeeinfodata|impendingexpdata|expdata|dnsoutagedata|deldata|impendingvalexpdata|valexpdata|updatedata|idledeldata|testdata)$/ ) {
        $rinfo->{$otype}->{$oname}->{$n} = message_types(@$el);
        $rinfo->{$otype}->{$oname}->{action} = 'fred_' . $n;
        # $rinfo->{$otype}->{$oname}->{object_type} = 'fred_' . $n;
      }
    }
  }

  return;

}

# fred poll message types
# more info here: https://fred.nic.cz/documentation/html/EPPReference/CommandStructure/Poll/MessageTypes.html
sub message_types {
  my ($name, $content)=@_;
  # print Dumper($name);
  # print Dumper($content->textContent());
  my $fred;
  my @fredData = Net::DRI::Util::xml_list_children($content);
  $fred = __low_credit(@fredData) if ($name eq 'lowCreditData');
  $fred = __request_usage(@fredData) if ($name eq 'requestFeeInfoData');
  $fred = __domain_life_cycle(@fredData) if ($name=~m/^(impendingExpData|expData|dnsOutageData|delData)$/);
  $fred = __enum_domain_validation(@fredData) if ($name=~m/^(impendingValExpData|valExpData)$/);
  # README: next one was already done under parse_poll() - leaving this in case we want to clean in the future!
  # $fred = __object_transfer(@fredData) if ($name=~m/^(trnData)$/);
  $fred = __object_update(@fredData) if ($name=~m/^(updateData)$/);
  $fred = __idle_object_deletion(@fredData) if ($name=~m/^(idleDelData)$/);
  $fred = __technical_check_results(@fredData) if ($name=~m/^(testData)$/);
  # print Dumper($fred);

  return $fred;
}


# Event: Client’s credit has dropped below the stated limit.
sub __low_credit {
  my $fred_low_credit;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    if ($n_fred eq 'zone') {
      $fred_low_credit->{$n_fred} = $c_fred->textContent();
    } elsif ($n_fred=~m/^(limit|credit)$/) {
      foreach my $el_limit(Net::DRI::Util::xml_list_children($c_fred)) {
        my ($n_limit, $c_limit)=@$el_limit;
        $fred_low_credit->{$n_fred}->{$n_limit} = $c_limit->textContent() if $n_limit=~m/^(zone|credit)$/;
      }
    }
  }

  return $fred_low_credit;
}


# Event: Daily report of how many free requests have been made this month so far, and how much the client will be charged for the requests that exceed the limit.
sub __request_usage {
  my $fred_request_usage;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    if ($n_fred=~m/^(periodFrom|periodTo)$/) {
      $fred_request_usage->{$n_fred} = new DateTime::Format::ISO8601->new()->parse_datetime($c_fred->textContent());
    } elsif ($n_fred=~m/^(totalFreeCount|usedCount|price)$/) {
      $fred_request_usage->{$n_fred} = $c_fred->textContent();
    }
  }

  return $fred_request_usage;
}


# There are several notifications concerning the life cycle of domains that have the same content but are issued on different events:
# * <domain:impendingExpData> – the domain is going to expire (by default 30 days before expiration),
# * <domain:expData> – the domain has expired (on the date of expiration),
# * <domain:dnsOutageData> – the domain has been excluded from the zone (by default 30 days after expiration),
# * <domain:delData> – the domain has been deleted (by default 61 days after expiration or deleted by the Registry for another reason).
sub __domain_life_cycle {
  my $fred_domain_life_cycle;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_domain_life_cycle->{name} = $c_fred->textContent() if $n_fred eq 'name';
    # <domain:exDate>: the expiration date of the domain name as xs:date
    $fred_domain_life_cycle->{exDate} = $c_fred->textContent() if $n_fred eq 'exDate';
  }

  return $fred_domain_life_cycle;
}


# Notifications concerning the validation of ENUM domains for events:
# * <enumval:impendingValExpData> – domain’s validation is going to expire (by default 30 days before validation expiration),
# * <enumval:valExpData> – domain’s validation has expired (on the day of validation expiration).
sub __enum_domain_validation {
  my $fred_enum_domain_validation;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_enum_domain_validation->{name} = $c_fred->textContent() if $n_fred eq 'name';
    # <enumval:valExDate>: the expiration date of domain validation as xs:date.
    $fred_enum_domain_validation->{valExDate} = $c_fred->textContent() if $n_fred eq 'valExDate';
  }

  return $fred_enum_domain_validation;
}


# Event: An object has been transferred to another registrar.
# TODO: they don't have more example but might need to improve this because:
# This message type appears in all 4 object namespaces: domain, contact, nsset, keyset.
sub __object_transfer {
  my $fred_object_transfer;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_object_transfer->{name} = $c_fred->textContent() if $n_fred eq 'name';
    $fred_object_transfer->{id} = $c_fred->textContent() if $n_fred eq 'id';
    $fred_object_transfer->{trDate} = $c_fred->textContent() if $n_fred eq 'trDate';
    $fred_object_transfer->{clID} = $c_fred->textContent() if $n_fred eq 'clID';
  }

  return $fred_object_transfer;
}


# Event: An object has been updated (in consequence of a server-side operation).
sub __object_update {
  my $fred_object_update;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_object_update->{opTRID} = $c_fred->textContent() if $n_fred eq 'opTRID';
    if ($n_fred=~m/^(oldData|newData)$/) {
      foreach my $el_infdata(Net::DRI::Util::xml_list_children($c_fred)) {
        my ($n_infdata, $c_infdata)=@$el_infdata;
        if ($n_infdata eq 'infData') {
          foreach my $el_data(Net::DRI::Util::xml_list_children($c_infdata)) {
            my ($n_data, $c_data)=@$el_data;
            $fred_object_update->{$n_fred}->{$n_data} = $c_data->textContent() if ($n_data=~m/^(name|roid|status|registrant|admin|nsset|keyset|clID|crID|crDate|upID|upDate|exDate|trDate|authInfo|tempcontact|id|ns|tech|reportlevel)$/);
          }
        }
      }
    }
  }

  return $fred_object_update;
}


# Event: An object has been deleted because it had not been used for a long time.
# This message type appears in the following object namespaces: contact, nsset, keyset.
sub __idle_object_deletion {
  my $fred_idle_object_deletion;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_idle_object_deletion->{id} = $c_fred->textContent() if $n_fred eq 'id';
  }

  return $fred_idle_object_deletion;
}


# Event: A technical check that the client had requested, has finished.
sub __technical_check_results {
  my $fred_technical_check_results;
  foreach my $el_fred(@_) {
    my ($n_fred, $c_fred)=@$el_fred;
    $fred_technical_check_results->{id} = $c_fred->textContent() if $n_fred eq 'id';
    if ($n_fred eq 'name') {
      # <nsset:name> (0..n)
      push @{$fred_technical_check_results->{$n_fred}}, $c_fred->textContent();
    } elsif ($n_fred eq 'result') {
      my $result = {};
      foreach my $el_result(Net::DRI::Util::xml_list_children($c_fred)) {
        my ($n_result, $c_result)=@$el_result;
        $result->{$n_result} = $c_result->textContent() if $n_result eq 'testname';
        $result->{$n_result} = $c_result->textContent() if $n_result eq 'status';
        $result->{$n_result} = $c_result->textContent() if $n_result eq 'note';
      }
      # <nsset:result> (0..n)
      push @{$fred_technical_check_results->{$n_fred}}, $result;
    }
  }

  return $fred_technical_check_results;
}


1;
