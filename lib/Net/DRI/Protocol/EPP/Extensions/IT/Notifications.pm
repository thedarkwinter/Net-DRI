## Domain Registry Interface, .IT message extensions
##
## Copyright (C) 2009-2010,2013,2016 Tower Technologies. All rights reserved.
##                        (C) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##
## This program free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License v2.
##

package Net::DRI::Protocol::EPP::Extensions::IT::Notifications;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IT::Notifications - .IT EPP Notifications Parsing for Net::DRI

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>noc@towertech.itE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT

Copyright (C) 2009-2010,2013,2016 Tower Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.


=cut

sub register_commands
{
       my ($class, $version) = @_;
       return { 'message' => { 'notication' => [undef, \&parse] } };
}

####################################################################################################

sub parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $msgid=$oname=$mes->msg_id();
 return unless (defined($msgid) && $msgid);

 # namespace => node , action
 my %namespaces=(
               'it_epp' => {
                                'passwdReminder' => 'password_expiring',
                                'wrongNamespaceReminder' => 'wrong_namespace',
                                'creditMsgData' => 'low_balance',

                        },
                'extdom' => {
                                'chgStatusMsgData' => 'update', # FIXME is this right?
                                'dnsErrorMsgData' => 'dns_error',
                                'dnsWarningMsgData' => 'update', #FIXME is this right?
                                'simpleMsgData' => 'delete', #FIXME
                                'dlgMsgData' => 'lost_delegation', #FIXME ??
                                'trade' => 'transfer', # FIXME or trade?
                                'delayedDebitAndRefundMsgData' => 'refund',
                        },
#       this is processed fine by main parser
#                'domain' => (
#                                'trnData' => 'transfer',
#                        ),
        );
        
        my ($data,$ns,$nodeac,$node,$ac,$tmp);
        while ( ($ns, $nodeac) = each(%namespaces))
        {
                while ( ($node,$ac) = each (%{$nodeac}))
                {
                        next unless $data= $mes->get_extension($ns,$node);
                        $otype = ($ns eq 'it_epp') ? 'message' : 'domain';
                        if ($otype eq 'domain') {
                                my $tn = Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'domain');
                                $tn = Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'name');
                                $rinfo->{$otype}->{$oname}->{object_id} = $oname = $tn->textContent() if $tn;
                         }
                        $oaction = $rinfo->{$otype}->{$oname}->{action} = $ac;
                        parse_recurse($po, $otype, $oaction, $oname, $rinfo,$data);
                }
        }
        return;
}

sub parse_recurse
{
        my ($po, $otype, $oaction, $oname, $rinfo,$data) = @_;
        return unless $data;
        my $mes=$po->message();

        parse_namespace($po,$otype,$oaction,$oname,$rinfo,Net::DRI::Util::xml_traverse($data,$mes->ns('it_epp'),'wrongNamespaceInfo'));
        parse_status($po,$otype,$oaction,$oname,$rinfo,Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'targetStatus'));
        parse_nameservers($po,$otype,$oaction,$oname,$rinfo,Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'nameservers'));
        parse_tests($po,$otype,$oaction,$oname,$rinfo,Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'tests'));
        parse_queries($po,$otype,$oaction,$oname,$rinfo,Net::DRI::Util::xml_traverse($data,$mes->ns('extdom'),'queries'));

        foreach my $el (Net::DRI::Util::xml_list_children($data))
        {
                my ($name,$c) = @$el;
                next if $name =~ m/nameservers|tests|queries|targetStatus|wrongNamespaceInfo/; # already parsed in the other subs
                $rinfo->{$otype}->{$oname}->{$name} = $po->parse_iso8601($c->textContent) if ($name =~ m/Date$/); # date nodes
                $rinfo->{$otype}->{$oname}->{Net::DRI::Util::xml2perl($name)} = $c->textContent if ($c->nodeType == 1); # all other text nodes
                parse_recurse($po, $otype, $oaction, $oname, $rinfo,$c) if ($name =~ m/Data$/); # recursive parse 
        }
        return;
}

sub parse_namespace
{
        my ($po, $otype, $oaction, $oname, $rinfo,@data) = @_;
        return unless @data;
        foreach my $data (@data) {
                foreach my $el (Net::DRI::Util::xml_list_children($data))
                {
                        my ($name,$c) = @$el;
                        push @{$rinfo->{$otype}->{$oname}->{Net::DRI::Util::xml2perl($name)}},$c->textContent();
                }
        }
        return;
}

sub parse_nameservers
{
        my ($po, $otype, $oaction, $oname, $rinfo,$data) = @_;
        return unless $data;
        foreach my $el (Net::DRI::Util::xml_list_children($data))
        {
                my ($name,$c) = @$el;
                push @{$rinfo->{$otype}->{$oname}->{nameservers}},$c->getAttribute('name');
         }
        return;
}

sub parse_tests
{
        my ($po, $otype, $oaction, $oname, $rinfo,$data) = @_;
        return unless $data;
        foreach my $el (Net::DRI::Util::xml_list_children($data))
        {
                my ($name,$c) = @$el;
                my $tname = $c->getAttribute('name');
                $rinfo->{$otype}->{$oname}->{test}->{$tname}->{status} = $c->getAttribute('status');
                foreach my $el2 (Net::DRI::Util::xml_list_children($c))
                {
                        my ($name2,$c2) = @$el2;
                        $rinfo->{$otype}->{$oname}->{test}->{$tname}->{dns}->{$c2->getAttribute('name')} = $c2->getAttribute('status') if $c2->getAttribute('status') eq 'SUCCEEDED';
                        $rinfo->{$otype}->{$oname}->{test}->{$tname}->{dns}->{$c2->getAttribute('name')} = {$c2->getAttribute('status'),$c2->textContent} unless $c2->getAttribute('status') eq 'SUCCEEDED';
                }
        }
        return;
}

sub parse_queries
{
        my ($po, $otype, $oaction, $oname, $rinfo,$data) = @_;
        return unless $data;
        foreach my $el (Net::DRI::Util::xml_list_children($data))
        {
                my ($name,$c) = @$el;
                my $qid = $c->getAttribute('id');
                foreach my $el2 (Net::DRI::Util::xml_list_children($c))
                {
                        my ($name2,$c2) = @$el2;
                        $rinfo->{$otype}->{$oname}->{'queries'}->{$qid}->{$name2} = $c2->textContent;
                }
        }
        return;
}

sub parse_status
{
        my ($po, $otype, $oaction, $oname, $rinfo,$data) = @_;
        return unless $data;
        foreach my $el (Net::DRI::Util::xml_list_children($data))
        {
                my ($name,$c) = @$el;
                $rinfo->{$otype}->{$oname}->{target_status} = $c->getAttribute('s') if $name eq 'status';
                $rinfo->{$otype}->{$oname}->{rgp_status} = $c->getAttribute('s') if $name eq 'rgpStatus';
        }
        return;
}

       
1;
