## Domain Registry Interface, .COOP Contact EPP extension commands
## (based on document: EPP Extensions for the .coop TLD Registrant Verification version 1.6)
##
## Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::COOP::Contact;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::COOP::Contact - .COOP EPP Contact extension commands for Net::DRI

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

Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp1=( 
           create => [ \&create, undef ],
           update => [ \&update, undef ],
           info   => [ undef, \&info_parse ],
          );
 my %tmp2=(
           create => [ \&domain_create, \&domain_parse ],
           update => [ undef,           \&domain_parse ],
          );

 return { 'contact' => \%tmp1, 'domain' => \%tmp2 };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:coop="%s"',$mes->nsattrs('coop')));
}

sub build_sponsors
{
 my $s=shift;
 return map { ['coop:sponsor',$_] } (ref($s)? @$s : $s);
}

sub build_prefs
{
 my $contact=shift;
 my @n;
 push @n,['coop:langPref',$contact->lang()]                if $contact->lang();
 push @n,['coop:mailingListPref',$contact->mailing_list()] if $contact->mailing_list();
 return @n;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## validate() has been called
 my @n;
 push @n,build_prefs($contact);
 push @n,build_sponsors($contact->sponsors()) if $contact->sponsors();

 return unless @n;

 my $eid=build_command_extension($mes,$epp,'coop:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my @n;
 push @n,['coop:add',build_sponsors($todo->add('sponsor'))] if $todo->add('sponsor');
 push @n,['coop:rem',build_sponsors($todo->del('sponsor'))] if $todo->del('sponsor');
 my @nn=build_prefs($todo->set('info'));
 push @n,['coop:chg',\@nn] if @nn;
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'coop:update');
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('coop','infData');
 return unless $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};

 my $ns=$mes->ns('coop');
 my $el=$infdata->getChildrenByTagNameNS($ns,'state');
 $s->state($el->get_node(1)->getAttribute('code')) if defined($el->get_node(1));

 my @s=map { $_->getFirstChild()->getData() } $infdata->getChildrenByTagNameNS($ns,'sponsor');
 $s->sponsors(\@s) if @s;

 $el=$infdata->getChildrenByTagNameNS($ns,'langPref');
 $s->lang($el->get_node(1)->getFirstChild()->getData()) if defined($el->get_node(1));
 $el=$infdata->getChildrenByTagNameNS($ns,'mailingListPref');
 $s->mailing_list($el->get_node(1)->getFirstChild()->getData()) if defined($el->get_node(1));
 return;
}

####################################################################################################

sub domain_create
{
 my ($epp,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('registrant is mandatory') unless (Net::DRI::Util::has_contact($rd) && $rd->{contact}->get('registrant'));
 Net::DRI::Exception::usererr_insufficient_parameters('registrant org is mandatory') unless $rd->{contact}->get('registrant')->org();
 return;
}

sub domain_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('coop','stateChange');
 return unless $data;

 my $id=$data->getChildrenByTagNameNS($mes->ns('coop'),'id')->get_node(1)->getFirstChild()->getData();
 $rinfo->{contact}->{$id}->{state}=$data->getChildrenByTagNameNS($mes->ns('coop'),'state')->get_node(1)->getAttribute('code');
 $rinfo->{contact}->{$id}->{action}='verification_review';

 if (defined($otype) && ($otype eq 'domain') && defined($oaction) && ($oaction eq 'create' || $oaction eq 'update'))
 {
  $rinfo->{domain}->{$oname}->{registrant_id}=$id;
  $rinfo->{domain}->{$oname}->{registrant_state}=$rinfo->{contact}->{$id}->{state};
 }
 return;
}

####################################################################################################
1;
