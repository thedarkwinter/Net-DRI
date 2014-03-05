## Domain Registry Interface, .IT message extensions
##
## Copyright (C) 2009-2010,2013 Tower Technologies. All rights reserved.
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

Copyright (C) 2009-2010,2013 Tower Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.


=cut

sub register_commands
{
       my ($class, $version) = @_;

       my $ops = {
               'review_credit' => [ undef, \&parse_credit ],
               'review_passwd' => [ undef, \&parse_reminder ],
               'review_simple' => [ undef, \&parse_simple ],
               'review_change' => [ undef, \&parse_chgstatus ],
               'review_dnserror' => [ undef, \&parse_dnserror ],
       };

       return {
               'message' => $ops,
       };
}

sub retrieve_ext
{
 my ($po,$ns,$node)=@_;
 my $msg = $po->message;
 return unless $msg->is_success;
 my $ext = $msg->get_extension($ns,$node);
 return unless defined $ext;
 my $id = $msg->msg_id;
 return ($ext,$id);
}

sub parse_credit
{
 my ($po, $type, $action, $name, $rinfo) = @_;
 my ($ext,$id)=retrieve_ext($po,'it_epp','creditMsgData');
 return unless defined $ext;

 $rinfo->{'message'}->{$id}->{credit}=($ext->getElementsByTagName('extepp:credit'))[0]->textContent; ## TODO: use xml_child_content() instead
 return;
}

sub parse_reminder
{
 my ($po, $type, $action, $name, $rinfo) = @_;
 my ($ext,$id)=retrieve_ext($po,'it_epp','passwdReminder');
 return unless defined $ext;

 $rinfo->{'message'}->{$id}->{'passwd_expires_on'}= ($ext->getElementsByTagName('extepp:exDate'))[0]->textContent; ## TODO: use xml_child_content() instead + convert date to DateTime object ?
 return;
}

sub parse_simple
{
 my ($po, $type, $action, $name, $rinfo) = @_;
 my ($ext,$id)=retrieve_ext($po,'it_domain','simpleMsgData');
 return unless defined $ext;

 $rinfo->{'message'}->{$id}->{'domain'}=($ext->getElementsByTagName('extdom:name'))[0]->textContent; ## TODO: use xml_child_content() instead
 return;
}

sub parse_chgstatus
{      
 my ($po, $type, $action, $name, $rinfo) = @_;
 my ($ext,$id)=retrieve_ext($po,'it_domain','chgStatusMsgData');
 return unless defined $ext;

 $rinfo->{'message'}->{$id}->{'domain'}=($ext->getElementsByTagName('extdom:name'))[0]->textContent; ## TODO: use xml_child_content() instead
       
       foreach ($ext->findnodes('//extdom:targetStatus/*')) {
       
               $rinfo->{'message'}->{$id}->{'status'} = $_->getAttribute('s')
                       if $_->nodeName eq 'domain:status';
               
               $rinfo->{'message'}->{$id}->{'own_status'} = $_->getAttribute('s')
                       if $_->nodeName eq 'extdom:ownStatus'; ## TODO : what is the difference between the two statuses ? + create a true StatusList object
       }
       return;
}

sub parse_dnserror
{
 my ($po, $type, $action, $name, $rinfo) = @_;
 my ($ext,$id)=retrieve_ext($po,'it_domain','dnsErrorMsgData');
 return unless defined $ext;
 
       $rinfo->{'message'}->{$id}->{'domain'}
               = ($ext->getElementsByTagName('extdom:domain'))[0]
               ->getAttribute('name'); ## TODO: use xml_child_content() instead

       $rinfo->{'message'}->{$id}->{'status'}
               = ($ext->getElementsByTagName('extdom:domain'))[0]
               ->getAttribute('status'); ## TODO: use xml_child_content() instead

       $rinfo->{'message'}->{$id}->{'response_id'}
               = ($ext->getElementsByTagName('extdom:responseId'))[0]->textContent; ## TODO: use xml_child_content() instead

       $rinfo->{'message'}->{$id}->{'validation_date'}
               = ($ext->getElementsByTagName('extdom:validationDate'))[0]->textContent; ## TODO: use xml_child_content() instead

       foreach my $test ($ext->findnodes('//extdom:test')) {

               my $name = $test->getAttribute('name');

               $rinfo->{'message'}->{$id}->{'test'}{$name}{'status'} = $test->getAttribute('status');

               foreach my $dns ($test->findnodes('./extdom:dns')) {

                       $rinfo->{'message'}->{$id}->{'test'}{$name}{'dns'}{$dns->getAttribute('name')}
                               = $dns->getAttribute('status');
               }
       }
       return;
}
       
1;
