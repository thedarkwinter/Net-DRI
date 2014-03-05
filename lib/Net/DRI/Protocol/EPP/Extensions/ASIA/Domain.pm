## Domain Registry Interface, ASIA domain extension
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

package Net::DRI::Protocol::EPP::Extensions::ASIA::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           create =>	[ \&create, \&create_parse ],
	   update => 	[ \&update, undef ],
	   info =>	[ undef, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @d;
 push @d,Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::create('asia',$rd);

 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  foreach my $type (grep { ! /^(?:registrant|admin|tech|billing|regAgent)$/ } $cs->types())
  {
   push @d,map { ['asia:contact',{type => $type},$_->srid()] } ($cs->get($type));
  }
 }

 return unless @d;
 my $eid=$mes->command_extension_register('asia:create',sprintf('xmlns:asia="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('asia')));
 $mes->command_extension($eid,\@d);
 return;
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('asia','creData');

 return unless defined $infdata;

 my $c=Net::DRI::Util::xml_child_content($infdata,$mes->ns('asia'),'domainRoid');
 $rinfo->{$otype}->{$oname}->{roid}=$c if defined $c;
 return;
}

## TODO: from liberty-rtk-addon-0.5.1 it seems domainRoid can be in info and update commands, in the asia extension ?

sub update
{
 my ($epp,$domain,$todo) = @_;
 my $mes=$epp->message();

 my @d;
 push @d,Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::update('asia',$todo);

 my $cs=$todo->set('contact');
 if (Net::DRI::Util::isa_contactset($cs))
 {
  foreach my $type (grep { ! /^(?:registrant|admin|tech|billing)$/ } $cs->types())
  {
   push @d,map { ['asia:contact',{type => $type},$_->srid()] } ($cs->get($type));
  }
 }

 return unless @d;
 my $eid=$mes->command_extension_register('asia:update',sprintf('xmlns:asia="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('asia')));
 $mes->command_extension($eid,['asia:chg',@d]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('asia','infData');

 return unless defined $infdata;

 my $c=Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl::info_parse($mes->ns('asia'),$infdata);
 $rinfo->{$otype}->{$oname}->{maintainer_url}=$c if defined $c;

 my $cs=$rinfo->{$otype}->{$oname}->{contact};
 foreach my $ct ($infdata->getElementsByTagNameNS($mes->ns('asia'),'contact'))
 {
  $cs->add($po->create_local_object('contact')->srid($ct->textContent()),$ct->getAttribute('type'));
 }
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA::Domain - ASIA domain EPP Extension for Net::DRI

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

Copyright (c) 2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
