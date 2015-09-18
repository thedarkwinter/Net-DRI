## Contact Registry Interface, Tango-RS EPP Contact Eligibility Extension
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

package Net::DRI::Protocol::EPP::Extensions::TANGO::ContactEligibility;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::TANGO::ContactEligibility - Contact Eligibility Extension for Tango-RS (?) and Corenic.
At the moment only been used for .swiss. Since CORENIC use a similar EPP implementation continue add the extension under TANGO :)

=head1 DESCRIPTION

Adds the Contact Eligibility Extension (http://xmlns.corenic.net/epp/contact-eligibility-1.0) to contact commands.
Depending on the policy of a registry supporting this extension, it may be optional or mandatory to provide eligibility
information with a contact object. If eligibility information is optional, the registry policy may prevent registrars
from using contacts lacking eligibility information from being used in certain roles within a domain.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>
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

####################################################################################################

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 return unless $contact->{'enterprise_id'};

 my @n;
 push @n, ['el:enterpriseID',$contact->{'enterprise_id'}];
 return unless @n;

 my $eid=$mes->command_extension_register('el','create');
 $mes->command_extension($eid,\@n);

 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_; 
 my $mes=$epp->message();
 my $extc=$todo->set('info');

 my $enterprise_id=$extc->{'enterprise_id'};
 return unless (defined($enterprise_id));

 my $eid=$mes->command_extension_register('el','update');
 $mes->command_extension($eid,['el:chg',['el:enterpriseID',$enterprise_id]]);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_extension($mes->ns('el'),'infData');
 return unless defined $infdata;
  
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
   my ($n,$c)=@$el;
   $rinfo->{contact}->{$oname}->{enterprise_id} = $c->textContent() if $n eq 'enterpriseID';
   $rinfo->{contact}->{$oname}->{validation_status} = $c->textContent() if $n eq 'validationStatus';
 }

 return;
}

####################################################################################################


1;
