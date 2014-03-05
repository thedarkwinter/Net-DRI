## Domain Registry Interface, ASIA CED extension
##
## Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ASIA::CED;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA::CED - .ASIA EPP CED extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>
          (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>
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
 my %contacttmp=(
	   create =>	[ \&user_create, undef ],
	   update =>	[ \&user_update, undef ],
	   info =>	[ undef, \&user_info ]
	 );

 return { 'contact' => \%contacttmp };
}

####################################################################################################

# automatically put type/form in other fields if not in the list of allowed
sub auto_cedother
{
  my $contact = shift;
  return $contact unless $contact->cedinum();
  my $etype = lc($contact->cedetype());
  unless ($etype =~ m/^(naturalperson|corporation|cooperative|partnership|government|politicalparty|society|institution|other)$/)
  {
     $contact->cedothertype($contact->cedetype());
     $contact->cedetype('other');
  }
  my $iform = $contact->cediform();
  unless ($iform =~ m/^(passport|certificate|legislation|societyregistry|politicalpartyregistry|other)$/)
  {
     $contact->cedoiform($contact->cediform());
     $contact->cediform('other');
  }
  return $contact;
}

sub user_create
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();
 my @ceddata;

 return unless Net::DRI::Util::isa_contact($contact, 'Net::DRI::Data::Contact::ASIA');

 $contact = auto_cedother($contact);
 push(@ceddata, ['asia:ccLocality', $contact->cedcc()])         if defined $contact->cedcc()        && length $contact->cedcc();
 push(@ceddata, ['asia:localitySp', $contact->cedsp()])         if defined $contact->cedsp()        && length $contact->cedsp();
 push(@ceddata, ['asia:localityCity', $contact->cedcity()])     if defined $contact->cedcity()      && length $contact->cedcity();
 push(@ceddata, ['asia:legalEntityType', $contact->cedetype()]) if defined $contact->cedetype()     && length $contact->cedetype();
 push(@ceddata, ['asia:identForm', $contact->cediform()])       if defined $contact->cediform()     && length $contact->cediform();
 push(@ceddata, ['asia:identNumber', $contact->cedinum()])      if defined $contact->cedinum()      && length $contact->cedinum();
 push(@ceddata, ['asia:otherLEType', $contact->cedothertype()]) if defined $contact->cedothertype() && length $contact->cedothertype();
 push(@ceddata, ['asia:otherIdentForm', $contact->cedoiform()]) if defined $contact->cedoiform()    && length $contact->cedoiform();

 return unless (@ceddata);

 my $eid=$mes->command_extension_register('asia:create',sprintf('xmlns:asia="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('asia')));
 $mes->command_extension($eid,['asia:cedData', @ceddata]);
 return;
}

sub user_update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();
 my $newc=$todo->set('info');
 my @ceddata;

 $contact = auto_cedother($contact);
 push(@ceddata, ['asia:ccLocality', $contact->cedcc()])         if defined $contact->cedcc();
 push(@ceddata, ['asia:localitySp', $contact->cedsp()])         if defined $contact->cedsp();
 push(@ceddata, ['asia:localityCity', $contact->cedcity()])     if defined $contact->cedcity();
 push(@ceddata, ['asia:legalEntityType', $contact->cedetype()]) if defined $contact->cedetype();
 push(@ceddata, ['asia:identForm', $contact->cediform()])       if defined $contact->cediform();
 push(@ceddata, ['asia:identNumber', $contact->cedinum()])      if defined $contact->cedinum();
 push(@ceddata, ['asia:otherLEType', $contact->cedothertype()]) if defined $contact->cedothertype();
 push(@ceddata, ['asia:otherIdentForm', $contact->cedoiform()]) if defined $contact->cedoiform();

 return unless (@ceddata);

 my $eid=$mes->command_extension_register('asia:update',sprintf('xmlns:asia="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('asia')));
 $mes->command_extension($eid,['asia:chg', ['asia:cedData', @ceddata]]);
 return;
}

sub user_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('asia','infData');
 my $ceddata;
 my $contact = $rinfo->{$otype}->{$oname}->{self};
 my $c;

 my $ns=$mes->ns('asia');
 $ceddata = $infdata->getElementsByTagNameNS($ns, 'cedData')->shift() if (defined($infdata));
 return unless ($ceddata);

 $c = $ceddata->getElementsByTagNameNS($ns,'ccLocality');
 $contact->cedcc($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'localitySp');
 $contact->cedsp($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'localityCity');
 $contact->cedcity($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'legalEntityType');
 $contact->cedetype($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'identForm');
 $contact->cediform($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'identNumber');
 $contact->cedinum($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'otherLEType');
 $contact->cedothertype($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS($ns,'otherIdentForm');
 $contact->cedoiform($c->shift()->getFirstChild()->getData()) if ($c);

 return;
}

####################################################################################################
1;
