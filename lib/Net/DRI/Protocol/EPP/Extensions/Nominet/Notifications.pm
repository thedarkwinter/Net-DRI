## Domain Registry Interface, .UK EPP Notifications
##
## Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Notifications;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Account;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Notifications - .UK EPP Notifications for Net::DRI

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

Copyright (c) 2008,2009,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmpn=(
		registrar_change => [ undef, \&registrar_change ],
		registrant_change => [ undef, \&registrant_change ],
		domain_cancelled => [ undef, \&domain_cancelled ],
		poor_quality => [ undef, \&poor_quality ],
		domains_released => [ undef, \&domains_released ],
	);
 my %tmpd=map { $_ => [ undef, \&domain_failwarning ] } qw/info update create/; ## the documentation is not clear about when this happen => we take some cases as others below + create since it is in example
 my %tmpa=map { $_ => [ undef, \&account_failwarning ] } qw/info update/;
 my %tmpc=map { $_ => [ undef, \&contact_failwarning ] } qw/info update/;
 my %tmph=map { $_ => [ undef, \&host_failwarning ] } qw/info update/;

 return { 'notifications' => \%tmpn, 'domain' => \%tmpd, 'account' => \%tmpa, 'contact' => \%tmpc, 'host' => \%tmph,  };
}

####################################################################################################

## http://www.nominet.org.uk/registrars/systems/epp/registrarchange/
## http://www.nominet.org.uk/registrars/systems/epp/handshakerequest/
sub registrar_change
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $rcdata=$mes->get_response('notifications','rcData');
 return unless defined $rcdata;

 my $msgid=$mes->msg_id();
 my $ns=$mes->ns('notifications');
 $rinfo->{message}->{$msgid}->{action}='registrar_change';
 $rinfo->{message}->{$msgid}->{orig}=Net::DRI::Util::xml_child_content($rcdata,$ns,'orig');
 $rinfo->{message}->{$msgid}->{registrar_to}=Net::DRI::Util::xml_child_content($rcdata,$ns,'registrar-tag');

 if ($rcdata->getChildrenByTagNameNS($ns,'case-id')->size())
 {
  $rinfo->{message}->{$msgid}->{action}='handshake_request';
  $rinfo->{message}->{$msgid}->{case_id}=Net::DRI::Util::xml_child_content($rcdata,$ns,'case-id');
 }

 my $list=$mes->get_response('domain','listData'); ## attribute no-domains is not used, as there should be as many simpleInfData as domain names
 my @d=parse_listdata($mes,$list,$rinfo);
 $rinfo->{message}->{$msgid}->{domains}=\@d;

 my $ainfo=$mes->get_response('account','infData');
 ## TODO : parse account info, see Account::parse_infdata
 return;
}

sub parse_listdata
{
 my ($mes,$list,$rinfo)=@_;
 my $nsd=$mes->ns('domain');
 my @d;
 foreach my $d ($list->getChildrenByTagNameNS($nsd,'simpleInfData'))
 {
  push @d,Net::DRI::Util::xml_child_content($d,$nsd,'name');
  ## TODO : parse other keys, using Domain::info_parse stuff extracted into some sort of parse_infdata
 }
 return @d;
}

## http://www.nominet.org.uk/registrars/systems/epp/registrantchange/
sub registrant_change
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $rcdata=$mes->get_response('notifications','trnData');
 return unless defined $rcdata;

 my $msgid=$mes->msg_id();
 my $ns=$mes->ns('notifications');
 $rinfo->{message}->{$msgid}->{action}='registrant_change';
 $rinfo->{message}->{$msgid}->{account_from}=Net::DRI::Util::xml_child_content($rcdata,$ns,'old-account-id');
 $rinfo->{message}->{$msgid}->{account_to}=Net::DRI::Util::xml_child_content($rcdata,$ns,'account-id');

 ## domainList or listData ??? The documentation is very unclear on details like that !
 my $list=$mes->get_response('domain','domainList'); ## attribute no-domains is not used, as there should be as many simpleInfData as domain names
 my @d=parse_listdata($mes,$list,$rinfo);
 $rinfo->{message}->{$msgid}->{domains}=\@d;

 my $ainfo=$mes->get_response('account','infData');
 ## TODO : parse account info, see Account::parse_infdata
 return;
}

## http://www.nominet.org.uk/registrars/systems/epp/accountdetails/
## TODO : we do not parse the changed="Y" attribute

## http://www.nominet.org.uk/registrars/systems/epp/domaincancelled/
sub domain_cancelled
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $cancdata=$mes->get_response('notifications','cancData');
 return unless defined $cancdata;

 my $ns=$mes->ns('notifications');
 my $name=Net::DRI::Util::xml_child_content($cancdata,$ns,'domain-name');
 $rinfo->{domain}->{$name}->{exist}=0;
 $rinfo->{domain}->{$name}->{action}='cancelled';
 $rinfo->{domain}->{$name}->{cancelled_orig}=Net::DRI::Util::xml_child_content($cancdata,$ns,'orig');
 return;
}

## http://www.nominet.org.uk/registrars/systems/epp/handshakerejected/
## seem totally bogus and conflicts with http://www.nominet.org.uk/registrars/systems/epp/domainsreleased/

## http://www.nominet.org.uk/registrars/systems/epp/poorqualitydata/
sub poor_quality
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $pqdata=$mes->get_response('notifications','pqData');
 return unless defined $pqdata;

 my $msgid=$mes->msg_id();
 my $ns=$mes->ns('notifications');
 $rinfo->{message}->{$msgid}->{action}='poor_quality';
 $rinfo->{message}->{$msgid}->{poor_quality_stage}=$pqdata->getAttribute('stage');

 my $d=$pqdata->getChildrenByTagNameNS($ns,'suspend-date');
 $rinfo->{message}->{$msgid}->{poor_quality_suspend}=$po->parse_iso8601($d->get_node(1)->textContent()) if $d->size();
 $d=$pqdata->getChildrenByTagNameNS($ns,'cancel-date');
 $rinfo->{message}->{$msgid}->{poor_quality_cancel}=$po->parse_iso8601($d->get_node(1)->textContent()) if $d->size();

 ## No account:infData, what a great idea (not) !
 my $nsa=$mes->ns('account');
 my $a=$po->create_local_object('contact');
 ## Text & XML do not agree !
 $a->roid(Net::DRI::Util::xml_child_content($pqdata,$nsa,'roid'));
 $a->name(Net::DRI::Util::xml_child_content($pqdata,$nsa,'name'));
 $d=$pqdata->getChildrenByTagNameNS($nsa,'addr');
 if ($d->size())
 {
  Net::DRI::Protocol::EPP::Extensions::Nominet::Account::parse_addr($d->get_node(1),$a);
 }
 $rinfo->{message}->{$msgid}->{poor_quality_account}=$a;

 my $list=$mes->get_response('domain','listData'); ## attribute no-domains is not used, as there should be as many simpleInfData as domain names
 ## here we do not use the same listData as everywhere else ! What a great idea (not) !
 my $nsd=$mes->ns('domain');
 my @d;
 foreach my $d ($list->getChildrenByTagNameNS($nsd,'name'))
 {
  push @d,$d->textContent();
 }
 $rinfo->{message}->{$msgid}->{domains}=\@d;
 return;
}

## http://www.nominet.org.uk/registrars/systems/epp/domainsreleased/
sub domains_released
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $reldata=$mes->get_response('notifications','relData');
 return unless defined $reldata;

 my $msgid=$mes->msg_id();
 my $ns=$mes->ns('notifications');
 $rinfo->{message}->{$msgid}->{action}='domains_released';
 my $n=$reldata->getChildrenByTagNameNS($ns,'account-id')->get_node(1);
 $rinfo->{message}->{$msgid}->{account_id}=$n->textContent();
 $rinfo->{message}->{$msgid}->{account_moved}=$n->getAttribute('moved') eq 'Y'? 1 : 0;
 $rinfo->{message}->{$msgid}->{registrar_from}=Net::DRI::Util::xml_child_content($reldata,$ns,'from');
 $rinfo->{message}->{$msgid}->{registrar_to}=Net::DRI::Util::xml_child_content($reldata,$ns,'registrar-tag');

 my $list=$mes->get_response('domain','listData'); ## attribute no-domains is not used, as there should be as many simpleInfData as domain names
 ## here we do not use the same listData as everywhere else ! What a great idea (not) !
 my $nsd=$mes->ns('domain');
 my @d;
 foreach my $d ($list->getChildrenByTagNameNS($nsd,'name'))
 {
  push @d,$d->textContent();
 }
 $rinfo->{message}->{$msgid}->{domains}=\@d;
 return;
}

####################################################################################################

# http://www.nominet.org.uk/registrars/systems/epp/error/
sub faildata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 ## no test on success, as this obviously can happen when no success !
 my $faildata=$mes->get_response($otype,'failData');
 return unless defined $faildata;

 my $ns=$mes->ns($otype);
 my $name=Net::DRI::Util::xml_child_content($faildata,$ns,$otype eq 'domain'? 'name' : 'roid');
 $rinfo->{$otype}->{$name}->{fail_reason}=Net::DRI::Util::xml_child_content($faildata,$ns,'reason');
 $rinfo->{$otype}->{$name}->{action}='fail' unless exists $rinfo->{$otype}->{$name}->{action};
 $rinfo->{$otype}->{$name}->{exist}=0 unless exists $rinfo->{$otype}->{$name}->{exist};
 return;
}

sub warning_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success(); ## the documentation seems to imply it is only during success, but not very clear
 my $warning=$mes->get_extension($otype,'warning');
 return unless defined $warning;

 ## No clear specification of the content
 $rinfo->{$otype}->{$oname}->{warning}=$warning->textContent();
 return;
}

# http://www.nominet.org.uk/registrars/systems/epp/error/ (does not explain when this case can occur for domain operations)
# http://www.nominet.org.uk/registrars/systems/epp/referralreject/
sub domain_failwarning  { my ($po,$otype,$oaction,$oname,$rinfo)=@_; faildata_parse($po,'domain',$oaction,$oname,$rinfo); warning_parse($po,'domain',$oaction,$oname,$rinfo); return; }
sub account_failwarning { my ($po,$otype,$oaction,$oname,$rinfo)=@_; faildata_parse($po,'account',$oaction,$oname,$rinfo); warning_parse($po,'account',$oaction,$oname,$rinfo); return; }
sub contact_failwarning { my ($po,$otype,$oaction,$oname,$rinfo)=@_; faildata_parse($po,'contact',$oaction,$oname,$rinfo); warning_parse($po,'contact',$oaction,$oname,$rinfo); return; }
sub host_failwarning    { my ($po,$otype,$oaction,$oname,$rinfo)=@_; faildata_parse($po,'ns',$oaction,$oname,$rinfo); warning_parse($po,'ns',$oaction,$oname,$rinfo); return; }

####################################################################################################
1;
