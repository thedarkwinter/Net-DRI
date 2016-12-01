## Domain Registry Interface, .PL Message EPP extension commands
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
## Copyright (c) 2008 Thorsten Glaser for Sygroup GmbH
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>
## Copyright (c) 2015 Paulo Jorge <paullojorgge@gmail.com>
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Message;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Message - .PL EPP Message extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/project/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>
Thorsten Glaser

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2008 Thorsten Glaser for Sygroup GmbH
Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          notification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

# parse additional notifications not handled elsewhere, at the mo this is just doing extdom
sub parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
  my $mes=$po->message();
  return unless $mes->is_success();
  return unless my $msgid=$mes->msg_id();
  my @tmp; # used to parse at the end of this function the dom names if extdom-2.0

  # pl_domain => extdom-2.0
  foreach my $tmp_pl_domain (qw/pollAuthInfo pollDomainAutoRenewed pollDomainAutoRenewFailed dlgData expData pollDomainBlocked pollDomainUnblocked pollFutureRemoved pollTasteRemoved pollDomainJudicialRemoved trnData/)
  {
    if (my $data=$mes->get_response('pl_domain',$tmp_pl_domain))
    {
      $oaction = Net::DRI::Util::xml2perl($tmp_pl_domain);
      $oaction =~ s/^poll_//;
      $otype = 'domain';
      foreach my $el (Net::DRI::Util::xml_list_children($data))
      {
        my ($n,$c) = @$el;
        # for multiple domain names. @tmp is passed at the end of the function. we also pass the correspondent action
        if ($n eq 'name' && $oaction =~ m/^(dlg_data|exp_data)$/ )
        {
          $oname = $c->textContent();
          push @tmp, $oname;
        } elsif ($n eq 'name') { # use normal action. check next condition :)
          $oname = $c->textContent();
          $rinfo->{$otype}->{$oname}->{name}=$oname;
          $rinfo->{$otype}->{$oname}->{exist}=1;
          $rinfo->{$otype}->{$oname}->{action}=$oaction;
        }
        $rinfo->{$otype}->{$oname}->{date}= DateTime::Format::ISO8601->new()->parse_datetime($c->textContent()) if $n eq 'date';
        $rinfo->{$otype}->{$oname}->{exDate} = DateTime::Format::ISO8601->new()->parse_datetime($c->textContent()) if $n eq 'exDate';
        $rinfo->{$otype}->{$oname}->{ns} = $c->textContent() if $n eq 'ns';
        foreach my $el2 (Net::DRI::Util::xml_list_children($c))
        {
          my ($n2,$c2) = @$el2;
          if ($n =~ m/^(domain|registrant|future|taste)$/) # add unless domainstandard auth
          {
            if ($n2 eq 'name')
            {
              $oname = $c2->textContent();
              $rinfo->{$otype}->{$oname}->{name}=$oname;
              $rinfo->{$otype}->{$oname}->{exist}=1;
              $rinfo->{$otype}->{$oname}->{action}=$oaction;
            } elsif ($n2 eq 'authInfo')
            {
              foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
              {
                my ($n3,$c3)=@$el3;
                if ($n eq 'domain' && $n3 eq 'pw')
                {
                  $rinfo->{$otype}->{$oname}->{'auth'} = {pw=>$c3->textContent()};
                } else {
                  $rinfo->{$otype}->{$oname}->{'auth_'.$n} = {pw=>$c3->textContent()};
                }

              }
            }
            $rinfo->{$otype}->{$oname}->{'id_'.$n} = $c2->textContent() if $n2 eq 'id';
            $rinfo->{$otype}->{$oname}->{date}= DateTime::Format::ISO8601->new()->parse_datetime($c2->textContent()) if $n2 eq 'date';
          }
        }
      }
     }
  }

  # extepp => extepp-2.0
  foreach my $tmp_extepp (qw/accountBalanceCrossed accountBalanceInsufficient passwdReminder/)
  {
    if (my $data=$mes->get_response('extepp',$tmp_extepp))
    {
      $oaction = Net::DRI::Util::xml2perl($tmp_extepp);
      $otype = 'extepp';
      $oname = 'domain';
      #my $domain=$data->getFirstChild();
      foreach my $el4 (Net::DRI::Util::xml_list_children($data))
      {
        my ($n4,$c4)=@$el4;
        $rinfo->{$otype}->{$oname}->{notification_level} = $c4->textContent() if $n4 eq 'notificationLevel';
        $rinfo->{$otype}->{$oname}->{account_type} = $c4->textContent() if $n4 eq 'accountType';
        $rinfo->{$otype}->{$oname}->{account_level} = $c4->textContent() if $n4 eq 'accountLevel';
        $rinfo->{$otype}->{$oname}->{service_name} = $c4->textContent() if $n4 eq 'serviceName';
        $rinfo->{$otype}->{$oname}->{domain_name} = $c4->textContent() if $n4 eq 'name'; # contains domain or future name
        $rinfo->{$otype}->{$oname}->{exDate} = DateTime::Format::ISO8601->new()->parse_datetime($c4->textContent()) if $n4 eq 'exDate';
        $rinfo->{$otype}->{$oname}->{action}=$oaction;
      }
    }
  }

  # Multiple domain names for the extdom...
  foreach (qw/dlgData expData/)
  {
    if (my $data=$mes->get_response('pl_domain',$_))
    {
      $rinfo->{$otype}->{$oname}->{extdom_names}= \@tmp;
      $rinfo->{$otype}->{$oname}->{action}= $_;
    }
  }

  # 4.7 extreportData
  if (my $data=$mes->get_response('extreport','extreportData'))
  {
    my $report;
    foreach my $el (Net::DRI::Util::xml_list_children($data))
    {
      my ($n,$c)=@$el;
      $oname = $report->{object_id} = $report->{report_id} = $c->textContent() if $n eq 'extreportId';
      $report->{processing_state} = $c->textContent() if $n eq 'reportProcessingState';
    }
    $otype = 'extreport';
    $oaction = $report->{action}= 'poll_report';
    $rinfo->{$otype}->{$oname} = $report;
  }


 return;
}

####################################################################################################
1;
