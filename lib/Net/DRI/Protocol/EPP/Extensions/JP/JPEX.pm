## Domain Registry Interface, JPEX EPP extension commands
##
## Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::JP::JPEX;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

use Data::Dumper; # TODO: delete me when all done :p

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::JP::JPEX - .JP EPP JPEX extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2021 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
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

 state $cmds = {
    'contact' => {
        'create' => [ \&contact_create_build, undef ],
        'info'   => [ undef, \&contact_info_parse ],
    },
    'domain' => {
        'create' => [ \&domain_create_build, undef ],
        'info'   => [ undef, \&domain_info_parse ],
        'update' => [ \&domain_update_build, undef ],
    },
 };

 return $cmds;
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:jpex="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('jpex')));
}

####################################################################################################

sub contact_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('jpex','info');
 return unless $infdata;
 my $ns=$mes->ns('jpex');
 return unless $ns;

 my $cont_info = $rinfo->{contact}->{$oname}->{self};
 foreach my $el ( Net::DRI::Util::xml_list_children($infdata) ) {
  my ( $name, $content ) = @$el;
  if ( lc($name) eq 'domain' ) {
   $cont_info->suffix( $content->getAttribute('suffix') ); # required
   $cont_info->transfer( $content->getAttribute('transfer') ); # optional
   $cont_info->domainCreatePreValidation( $content->getAttribute('domainCreatePreValidation') ); # optional
   foreach my $el_domain ( Net::DRI::Util::xml_list_children($content) ) {
    my ( $name_domain, $content_domain ) = @$el_domain;
    $cont_info->suspendDate( $content_domain->textContent() ) if ( $name_domain eq 'suspendDate' );
    $cont_info->lapsedNs( $content_domain->textContent() ) if ( $name_domain eq 'lapsedNs' );
    # for ojp domain names 
    $cont_info->suspiciousDomainName( $content_domain->textContent() ) if ( $name_domain eq 'suspiciousDomainName' );
    $cont_info->expirationMonth( $content_domain->textContent() ) if ( $name_domain eq 'expirationMonth' );
    $cont_info->deletionDate( $content_domain->textContent() ) if ( $name_domain eq 'deletionDate' );
   }
  } elsif ( lc($name) eq 'contact' ) {
   $cont_info->alloc( $content->getAttribute('alloc') ); # required
   foreach my $el_contact ( Net::DRI::Util::xml_list_children($content) ) {
    my ( $name_contact, $content_contact ) = @$el_contact;
    $cont_info->ryid( $content_contact->textContent() ) if ( lc($name_contact) eq 'ryid' );
    $cont_info->handle( $content_contact->textContent() ) if ( lc($name_contact) eq 'handle' );
   }
  }
 }

 return;
}

sub contact_create_build
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## validate() has been called, we are sure that type exists
 my @n;
 push @n,['jpex:domain suffix="'.$contact->suffix().'"'] if $contact->suffix();
 push @n,['jpex:contact alloc="'.$contact->alloc().'"'] if $contact->alloc();

 my $eid=build_command_extension($mes,$epp,'jpex:create');
 $mes->command_extension($eid,[@n]);

 return;
}

sub domain_create_build
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 # suffix is required
 Net::DRI::Exception->die(0,'protocol/EPP',11,'suffix is required in domain_create')
  unless ($rd && $rd->{'suffix'});
 Net::DRI::Exception->die(0,'protocol/EPP',11,'invalid suffix: jp or ojp')
  unless ($rd->{'suffix'} =~ m/^(jp|ojp)$/);

 my @jpex;
 push @jpex,['jpex:domain suffix="'.$rd->{'suffix'}.'"'];
 push @jpex,['jpex:contact', ['jpex:handle', $rd->{'handle'}], {'alloc'=>$rd->{'alloc'}}] if $rd->{'alloc'};

 my $eid=build_command_extension($mes,$epp,'jpex:create');
 $mes->command_extension($eid,[@jpex]);

 return;
}

sub domain_update_build
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my @jpex;
 push @jpex,['jpex:domain suffix="'.$todo->set('suffix').'"'] if $todo->{'suffix'};
 push @jpex,['jpex:contact', ['jpex:handle', $todo->set('handle')], {'alloc'=>$todo->set('alloc')}] if $todo->{'alloc'};

 my $eid=build_command_extension($mes,$epp,'jpex:update');
 $mes->command_extension($eid,[@jpex]);

 return;

}

sub domain_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('jpex','info');
 return unless $infdata;
 my $ns=$mes->ns('jpex');
 return unless $ns;

 my $dom_info = $rinfo->{domain}->{$oname};
 foreach my $el ( Net::DRI::Util::xml_list_children($infdata) ) {
  my ( $name, $content ) = @$el;
  if ( lc($name) eq 'domain' ) {
   $dom_info->{'suffix'} = $content->getAttribute('suffix') if $content->hasAttribute('suffix');
   $dom_info->{'transfer'} = $content->getAttribute('transfer') if $content->hasAttribute('transfer');
   $dom_info->{'domainCreatePreValidation'} = $content->getAttribute('domainCreatePreValidation') if $content->hasAttribute('domainCreatePreValidation');
   foreach my $el_domain ( Net::DRI::Util::xml_list_children($content) ) {
    my ( $name_domain, $content_domain ) = @$el_domain;
    $dom_info->{'suspendDate'} = $content_domain->textContent() if ( $name_domain eq 'suspendDate' );
    $dom_info->{'lapsedNs'} = $content_domain->textContent() if ( $name_domain eq 'lapsedNs' );
    # for ojp domain names
    $dom_info->{'suspiciousDomainName'} = $content_domain->textContent() if ( $name_domain eq 'suspiciousDomainName' );
    $dom_info->{'expirationMonth'} = $content_domain->textContent() if ( $name_domain eq 'expirationMonth' );
    $dom_info->{'deletionDate'} = $content_domain->textContent() if ( $name_domain eq 'deletionDate' );
   }
  } elsif ( lc($name) eq 'contact' ) {
   $dom_info->{'alloc'} = $content->getAttribute('alloc') if $content->hasAttribute('alloc');
   foreach my $el_contact ( Net::DRI::Util::xml_list_children($content) ) {
    my ( $name_contact, $content_contact ) = @$el_contact;
    $dom_info->{'ryid'} = $content_contact->textContent() if ( lc($name_contact) eq 'ryid' );
    $dom_info->{'handle'} = $content_contact->textContent() if ( lc($name_contact) eq 'handle' );
   }
  }
 }

 return;
}

####################################################################################################
1;
