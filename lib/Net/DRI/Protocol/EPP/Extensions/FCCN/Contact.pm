## Domain Registry Interface, FCCN (.PT) Contact EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::FCCN::Contact;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::FCCN::Contact - FCCN (.PT) EPP Contact extensions for Net::DRI

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
 my %tmp=( 
          create => [ \&create, undef ],
          update => [ \&update, undef ],
          info   => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:ptcontact="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ptcontact')));
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

# validate() has been called
 my @n;
 push @n,['ptcontact:type',$contact->type()];
 push @n,['ptcontact:identification',{type=>$contact->identification()->{type}},$contact->identification()->{value}];
 push @n,['ptcontact:mobile',$contact->mobile()] if $contact->mobile();

 my $eid=build_command_extension($mes,$epp,'ptcontact:create');
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 my @n;
 my $auth=$contact->auth();
 Net::DRI::Exception::usererr_insufficient_parameters('Contact password is mandatory for .PT contact update') unless (defined($auth) && (ref($auth) eq 'HASH') && exists($auth->{pw}) && Net::DRI::Util::xml_is_normalizedstring($auth->{pw}));
 push @n,['ptcontact:pw',$auth->{pw}];

 my $newc=$todo->set('info');
 if ($newc)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc,'Net::DRI::Data::Contact::FCCN');
  push @n,['ptcontact:mobile',$newc->mobile()] if $newc->mobile();
 }

 my $eid=build_command_extension($mes,$epp,'ptcontact:update');
 $mes->command_extension($eid,\@n);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('ptcontact','infData');
 return unless $infdata;
 my $ns=$mes->ns('ptcontact');

 my $co=$rinfo->{contact}->{$oname}->{self};
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'type')
  {
   $co->type($c->getFirstChild()->getData());
  } elsif ($name eq 'identification')
  {
   $co->identification({type=>$c->getAttribute('type'),value=>$c->getFirstChild()->getData()});
  } elsif ($name eq 'mobile')
  {
   $co->mobile($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }
 return;
}

####################################################################################################
1;
