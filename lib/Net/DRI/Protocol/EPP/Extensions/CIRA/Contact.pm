## Domain Registry Interface, CIRA EPP Contact commands
##
## Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CIRA::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info   => [ undef, \&info_parse ],
           create => [ \&create, undef ],
	   update => [ \&update ],
         );

 return { 'contact' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:cira="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('cira')));
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('cira','ciraInfo');
 return unless defined $infdata;

 my %ag;
 my $contact=$rinfo->{contact}->{$oname}->{self};
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'language')
  {
   $contact->lang($c->textContent());
  } elsif ($name eq 'cprCategory')
  {
   $contact->legal_form($c->textContent());
  } elsif ($name eq 'individual')
  {
   $contact->is_individual($c->textContent() eq 'Y' ? 1 : 0);
  } elsif ($name eq 'ciraAgreementVersion')
  {
   $ag{version}=$c->textContent();
   $ag{signed}=1;
  } elsif ($name eq 'agreementTimestamp')
  {
   $ag{timestamp}=$po->parse_iso8601($c->textContent());
   $ag{signed}=1;
  } elsif ($name eq 'originatingIpAddress')
  {
   $contact->ip_address($c->textContent());
  } elsif ($name eq 'whoisDisplaySetting')
  {
   $contact->whois_display($c->textContent());
  }
 }
 $contact->agreement(\%ag) if keys %ag;
 return;
}

####################################################################################################
########### Transform commands

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## $contact->validate() has been called
 my @n;
 push @n,['cira:language',$contact->lang()];
 push @n,['cira:originatingIpAddress',$contact->ip_address()] if defined $contact->ip_address();
 push @n,['cira:cprCategory',$contact->legal_form()] if defined $contact->legal_form();
 my $ra=$contact->agreement();
 if (defined $ra)
 {
  push @n,['cira:ciraAgreementVersion',$ra->{version}];
  push @n,['cira:agreementValue',$ra->{signed} ? 'Y' : 'N'];
 }
 push @n,['cira:createdByResellerId',$contact->reseller_id()] if defined $contact->reseller_id();
 push @n,['cira:whoisDisplaySetting',$contact->whois_display()] if defined $contact->whois_display();

 my $eid=build_command_extension($mes,$epp,'cira:ciraCreate');
 $mes->command_extension($eid,[@n]);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless defined $newc;

 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless Net::DRI::Util::isa_contact($newc,'Net::DRI::Data::Contact::CIRA');
 $newc->validate(1); ## will trigger an Exception if needed

 my @n;
 push @n,['cira:cprCategory',$newc->legal_form()] if defined $newc->legal_form();
 push @n,['cira:language',$newc->lang()] if defined $newc->lang();
 push @n,['cira:whoisDisplaySetting',$newc->whois_display()] if defined $newc->whois_display();

 return unless @n;

 my $eid=build_command_extension($mes,$epp,'cira:ciraUpdate');
 $mes->command_extension($eid,['cira:ciraChg',@n]);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::Contact - CIRA EPP Contact commands for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
