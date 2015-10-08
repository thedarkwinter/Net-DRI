## Qualified Lawyer, Minds + Machines Qualified Lawyer Extension
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2015 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::MAM::QualifiedLawyer;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Contact::MAM;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::MAM::QualifiedLawyer - Qualified Lawyer Extension for MAM.

=head1 DESCRIPTION

Adds the Qualified Lawyer Extension (http://www.mindsandmachines.com/epp/qualifiedLawyer-1.0) to contact commands.
.abogado and .law require additional details necessary to verify the registrant's status as a qualified lawyer.
This extension adds the necessary additionial elements to the contact mapping.

=item accreditation_id: is character string issued by the accreditation body to the qualified lawyer. Accreditation IDs uniquely
identify the qualified lawyer within the context of the accredtation body. An accreditation ID is required.

=item accreditation_body: is the entity that issued the accreditation ID to the qualified lawyer. Within the Qualified Lawyer
extension, a character string is used to represent an accreditation body. The accreditation body is required.

=item accreditation_year: is the year he/she was initially certified by the accreditation body. It is represented by a
four-digit year including the century.

=item jurisdiction_cc: the accreditation jurisdiction country is the country in which the accreditation body certifies the
qualified lawyer. ISO two-letter country codes are used to represent the accreditation jurisdiction country. The accreditation
jurisdiction country is required.

=item jurisdiction_sp: the accreditation jurisdiction state/province is the specific region, within the accreditation jurisdiction
country, in which the accreditation body certifies the qualified lawyer. A character string represents the region. The accreditation
jurisdiction is required when the accrediting body limits the qualified lawyers's certification to this area.


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
(c) 2015 Michael Holloway <michael@thedarkwinter.com>.
(c) 2015 Paulo Jorge <paullojorgge@gmail.com>.
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
           info   => [ undef, \&info_parse],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
        );

 return { 'contact' => \%tmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->ns({'qualifiedLawyer' => ['http://www.mindsandmachines.com/epp/qualifiedLawyer-1.0', 'qualifiedLawyer-1.0.xsd']});
 $po->factories('contact',sub { return Net::DRI::Data::Contact::MAM->new(); });
 
 return;
}

####################################################################################################

sub build_qualified_lawyer
{
 my ($rd) = shift;
 my @n;
 
 push @n, ['qualifiedLawyer:accreditationId',$rd->{'accreditation_id'}];
 push @n, ['qualifiedLawyer:accreditationBody',$rd->{'accreditation_body'}];
 push @n, ['qualifiedLawyer:accreditationYear',$rd->{'accreditation_year'}];
 push @n, ['qualifiedLawyer:jurisdictionCC',$rd->{'jurisdiction_cc'}];
 push @n, ['qualifiedLawyer:jurisdictionSP',$rd->{'jurisdiction_sp'}] if $rd->{'jurisdiction_sp'};
 
 return @n;
}

####################################################################################################

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 return unless $contact->{'accreditation_id'}; # only checking this param. Other mandatory params protection under Data::Contact::MAM :)
 
 my @n = build_qualified_lawyer($contact);
 return unless @n;
 
 my $eid=$mes->command_extension_register('qualifiedLawyer','create');
 $mes->command_extension($eid,\@n);
 
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();
 my $extc=$todo->set('info');
 return unless $extc->{'accreditation_id'}; # only checking this param. Other mandatory params protection under Data::Contact::MAM :)

 my @n = build_qualified_lawyer($extc);
 return unless @n;
 
 my $eid=$mes->command_extension_register('qualifiedLawyer','update');
 $mes->command_extension($eid,\@n);
 
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message(); 
 return unless $mes->is_success();
 my $infdata=$mes->get_extension($mes->ns('qualifiedLawyer'),'info');
 return unless defined $infdata;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   $rinfo->{contact}->{$oname}->{accreditation_id} = $c->textContent() if $n eq 'accreditationId';
   $rinfo->{contact}->{$oname}->{accreditation_body} = $c->textContent() if $n eq 'accreditationBody';
   $rinfo->{contact}->{$oname}->{accreditation_year} = $c->textContent() if $n eq 'accreditationYear';
   $rinfo->{contact}->{$oname}->{jurisdiction_cc} = $c->textContent() if $n eq 'jurisdictionCC';
   $rinfo->{contact}->{$oname}->{jurisdiction_sp} = $c->textContent() if $n eq 'jurisdictionSP';
 }

 return;
}

####################################################################################################


1;
