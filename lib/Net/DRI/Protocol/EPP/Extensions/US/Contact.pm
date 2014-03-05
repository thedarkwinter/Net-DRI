## Domain Registry Interface, EPP .US Contact NEXUS Extensions
##
## Copyright (c) 2005,2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::US::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::US::Contact - .US EPP Contact NEXUS Extensions for Net::DRI

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

Copyright (c) 2005,2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

###################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
           update => [ \&update, undef ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $contact=$rinfo->{contact}->{$oname}->{self};
 my $ext=$mes->node_extension();

 return unless (defined($ext) && $ext && $ext->getFirstChild());
 my %tmp=map { split(/=/,$_) } split(/\s+/,$ext->getFirstChild()->getData());

 $contact->application_purpose($tmp{AppPurpose}) if exists($tmp{AppPurpose});
 $contact->nexus_category($tmp{NexusCategory})   if exists($tmp{NexusCategory});
 return;
}

############ Transform commands

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::isa_contact($contact,'Net::DRI::Data::Contact::US');

 my $str=sprintf('AppPurpose=%s NexusCategory=%s',$contact->application_purpose(),$contact->nexus_category());
 my $eid=$mes->command_extension_register('neulevel:extension','xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"');
 $mes->command_extension($eid,['neulevel:unspec',$str]);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless Net::DRI::Util::isa_contact($newc,'Net::DRI::Data::Contact::US');

 my @tmp;
 push @tmp,'AppPurpose='.$newc->application_purpose() if (defined($newc->application_purpose()));
 push @tmp,'NexusCategory='.$newc->nexus_category()   if (defined($newc->nexus_category()));

 return unless @tmp;
 
 my $eid=$mes->command_extension_register('neulevel:extension','xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"');
 $mes->command_extension($eid,['neulevel:unspec',join(' ',@tmp)]);
 return;
}

####################################################################################################
1;
