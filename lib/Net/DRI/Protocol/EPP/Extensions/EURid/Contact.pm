## Domain Registry Interface, EURid Contact EPP extension commands
## (based on EURid registration_guidelines_v1_0E-epp.pdf)
##
## Copyright (c) 2005,2008,2012,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##               2014 Michael Kefeder <michael.kefeder@world4you.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Contact;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Contact - EURid EPP Contact extension commands for Net::DRI

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

Copyright (c) 2005,2008,2012,2013 Patrick Mevzek <netdri@dotandco.com>.
              2014 Michael Kefeder <michael.kefeder@world4you.com>.
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

sub setup
{
 my ($class,$po,$version)=@_;
 foreach my $ns (qw/contact-ext/)
 {
  $po->ns({ $ns => [ 'http://www.eurid.eu/xml/epp/'.$ns.'-1.1',$ns.'-1.1.xsd' ] });
 }
 return;
}

####################################################################################################

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## validate() has been called, we are sure that type & lang exists
 my @n;
 push @n,['contact-ext:type',$contact->type()];
 push @n,['contact-ext:vat',$contact->vat()] if $contact->vat();
 push @n,['contact-ext:lang',$contact->lang()];

 my $eid=$mes->command_extension_register('contact-ext','create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless ($newc && (defined($newc->vat()) || defined($newc->lang())));

 my @n;
 push @n,['contact-ext:vat',$newc->vat()]   if defined($newc->vat());
 push @n,['contact-ext:lang',$newc->lang()] if defined($newc->lang());

 my $eid=$mes->command_extension_register('contact-ext','update');
 $mes->command_extension($eid,['contact-ext:chg',@n]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('contact-ext','infData');
 return unless $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(type|vat|lang)$/)
  {
   $s->$1($c->textContent());
  }
 }
 return;
}

####################################################################################################
1;
