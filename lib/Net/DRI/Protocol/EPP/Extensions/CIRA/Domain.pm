## Domain Registry Interface, CIRA EPP Domain extensions
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

package Net::DRI::Protocol::EPP::Extensions::CIRA::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           info  => [ undef, \&info_parse],
           create => [ \&create, undef ],
           transfer_request => [ \&transfer_request, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:cira="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('cira')));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('cira','ciraInfo');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'domainStageOfLife')
  {
   $rinfo->{domain}->{$oname}->{stage_of_life}=$c->textContent();
  } elsif ($name eq 'domainStageOfLifeEnd')
  {
   $rinfo->{domain}->{$oname}->{stage_of_life_end}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('contacts are mandatory in .CA for domain_create') unless Net::DRI::Util::has_contact($rd);
 my $cs=$rd->{contact};
 my @c=$cs->get('registrant');
 Net::DRI::Exception::usererr_insufficient_parameters('one registrant is mandatory in .CA for domain_create') unless (@c==1 && Net::DRI::Util::isa_contact($c[0],'Net::DRI::Data::Contact::CIRA') && length $c[0]->srid() && $c[0]->validate(1));
 @c=$cs->get('admin');
 Net::DRI::Exception::usererr_insufficient_parameters('one admin contact is mandatory in .CA for domain_create') unless (@c==1 && Net::DRI::Util::isa_contact($c[0],'Net::DRI::Data::Contact::CIRA') && length $c[0]->srid() && $c[0]->validate(1));
 @c=$cs->get('tech');
 return unless @c;
 Net::DRI::Exception::usererr_insufficient_parameters('only up to 3 tech contacts are possible in .CA for domain_create') if (scalar(@c)!=scalar(grep { Net::DRI::Util::isa_contact($_,'Net::DRI::Data::Contact::CIRA') && length $_->srid() && $_->validate(1) } @c) || @c>3);
 return;
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 return unless Net::DRI::Util::has_contact($rd);

 my @n;
 my $cs=$rd->{contact};
 Net::DRI::Exception::usererr_insufficient_parameters('Both registrant and admin contacts are required for .CA domain name transfer if contacts are provided') unless ($cs->has_type('registrant') && $cs->has_type('admin'));
 my @c=$cs->get('registrant');
 Net::DRI::Exception::usererr_insufficient_parameters('only one registrant is mandatory in .CA for domain_transfer_start if contacts are provided') unless (@c==1 && Net::DRI::Util::isa_contact($c[0],'Net::DRI::Data::Contact::CIRA') && length $c[0]->srid() && $c[0]->validate(1));
 push @n,['cira:registrant',$c[0]->srid()];
 @c=$cs->get('admin');
 Net::DRI::Exception::usererr_insufficient_parameters('only one admin contact is mandatory in .CA for domain_transfer_start if contacts are provided') unless (@c==1 && Net::DRI::Util::isa_contact($c[0],'Net::DRI::Data::Contact::CIRA') && length $c[0]->srid() && $c[0]->validate(1));
 push @n,['cira:contact',{type=>'admin'},$c[0]->srid()];
 @c=$cs->get('tech');
 if (@c)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('only up to 3 tech contacts are possible in .CA for domain_transfer_start') if (scalar(@c)!=scalar(grep { Net::DRI::Util::isa_contact($_,'Net::DRI::Data::Contact::CIRA') && length $_->srid() && $_->validate(1) } @c) || @c>3);
  push @n,map { ['cira:contact',{type=>'tech'},$_->srid()] } @c;
 }

 my $eid=build_command_extension($mes,$epp,'cira:ciraTransfer');
 $mes->command_extension($eid,['cira:ciraChg',@n]);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::Domain - CIRA (.CA) EPP Domain extensions for Net::DRI

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

