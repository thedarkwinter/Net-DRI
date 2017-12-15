## CentralNic SK EPP Contact Ident extension
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::SkContactIdent;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::SkContactIdent- CentralNic SK EPP Contact Ident extension

=head1 DESCRIPTION

In case of a natural person ("PERS" constant): date of birth (not mandatory - format: YYYY-MM-DD).

In case entrepreneur ("CORP" constant): identification number.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

(c) 2017 Patrick Mevzek <netdri@dotandco.com>,

(c) 2017 Michael Holloway <michael@thedarkwinter.com>,

(c) 2017 Paulo Jorge <paullojorgge@gmail.com>.

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
 my %ops=(
  create  =>  [ \&create, undef ],
  # update  =>  [ \&update, undef ], # README: not supported? please read function comment!
  info    =>  [ undef, \&info_parse ],
 );
 return { 'contact' => \%ops };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'skContactIdent' => [ 'http://www.sk-nic.sk/xml/epp/sk-contact-ident-0.2','sk-contact-ident-0.2.xsd' ] });
 return;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @n;

 push @n,['skContactIdent:legalForm', $contact->legal_form()];
 if ( $contact->ident_value() ) {
  push @n,['skContactIdent:identValue', [ 'skContactIdent:corpIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'corp';
  push @n,['skContactIdent:identValue', [ 'skContactIdent:persIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'pers';
 }

 return unless @n;
 my $eid=$mes->command_extension_register('skContactIdent','create');
 $mes->command_extension($eid,\@n);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $cont_info = $rinfo->{contact}->{$oname}->{self};
 my $ext_data = $mes->get_extension( 'skContactIdent', 'infData' );
 return unless $ext_data;

 foreach my $el ( Net::DRI::Util::xml_list_children($ext_data) ) {
  my ( $name, $content ) = @$el;
  if ( lc($name) eq 'legalform' ) {
   $cont_info->legal_form( $content->textContent() );
  } elsif ( lc($name) eq 'identvalue' ) {
   $cont_info->ident_value( $content->textContent() );
  }
 }

 return;
}

# # didn't work on their OT&E - commenting in case they release documentation or XSD with <contact:update> example!
# sub update
# {
#  my ( $epp, $contact, $todo ) = @_;
#  my $mes  = $epp->message();
#  my $newc = $todo->set('info');
#  my @n;
#
#  return unless defined $contact->legal_form() && $contact->ident_value();
#  push @n,['skContactIdent:legalForm', $contact->legal_form()] if $contact->legal_form();
#  if ( $contact->ident_value() ) {
#   push @n,['skContactIdent:identValue', [ 'skContactIdent:corpIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'corp';
#   push @n,['skContactIdent:identValue', [ 'skContactIdent:persIdent', $contact->ident_value()] ] if lc($contact->legal_form()) eq 'pers';
#  }
#
#  return unless @n;
#  my $eid=$mes->command_extension_register('skContactIdent','update');
#  $mes->command_extension($eid,\@n);
#
#  return;
# }

####################################################################################################
1;
