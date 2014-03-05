## Domain Registry Interface, .CAT Contact EPP extension commands
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
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::CAT::Contact;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CAT::Contact - .CAT EPP Contact extension commands for Net::DRI

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
 my %tmp=( 
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:cx="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('puntcat_contact')));
}

sub add_puntcat_extension
{
 my ($contact)=@_;

 ## Everything is optional
 my @n;
 push @n,['cx:language',$contact->lang()]              if $contact->lang();
 push @n,['cx:maintainer',$contact->maintainer()]      if $contact->maintainer();
 push @n,['cx:sponsorEmail',$contact->email_sponsor()] if $contact->email_sponsor();

 return @n;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 
 my @n=add_puntcat_extension($contact);
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'cx:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless $newc; ## if there already verified in Core

 my @n=add_puntcat_extension($newc);
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'cx:update');
 $mes->command_extension($eid,['cx:chg',@n]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('puntcat_contact','infData');
 return unless $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};

 my $el=$infdata->getChildrenByTagNameNS($mes->ns('puntcat_contact'),'language');
 $s->lang($el->get_node(1)->getFirstChild()->getData()) if $el;
 $el=$infdata->getChildrenByTagNameNS($mes->ns('puntcat_contact'),'maintainer');
 $s->maintainer($el->get_node(1)->getFirstChild()->getData()) if $el;
 $el=$infdata->getChildrenByTagNameNS($mes->ns('puntcat_contact'),'sponsorEmail');
 $s->email_sponsor($el->get_node(1)->getFirstChild()->getData()) if $el;
 return;
}

####################################################################################################
1;
