## Domain Registry Interface, Neulevel EPP EXT Contact Extension
##
## Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
## Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact - NeuLevel EPP EXTContact extension for Net::DRI

=head1 DESCRIPTION

Adds the EXTContact extension. Currently used for .NYC domains

  # Create EXTContact (see L<Net::DRI::Data::Contact::ARI>)
  $c = $dri->local_object('contact');
  $c->srid('abcde')->.....
  $c->nexus_category('ORG'); # ORG or INDIV
  $rc=$dri->contact_create($c);

  # Create domain
  $rc=$dri->domain_create('example.nyc',{..., {'ext_contact'=>$c->srid()});

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2013-2014 Michael Holloway <michael@thedarkwinter.com>.
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
 my %ctmp=(
           create => [ \&contact_create, undef ],
           update => [ \&contact_update, undef ],
           info   => [ undef , \&contact_parse ],
         );
 my %dtmp=(
           create => [ \&domain_create, undef ],
           update => [ \&domain_update, undef ],
           info   => [ undef , \&domain_parse ],
         );

 return { 'contact' => \%ctmp, 'domain' => \%dtmp };
}

sub setup
{
 my ($self,$po) = @_;
 $po->capabilities('domain_update','ext_contact',['set']);
}

####################################################################################################
#### Contact Functions

sub contact_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;
 my $s=$rinfo->{contact}->{$oname}->{self};

 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   next unless $k =~ m/^(?:AppPurpose|EXTContact|NexusCategory)$/;
   $s->nexus_category($v) if $k eq 'NexusCategory';
   $s->ext_contact($v)   if $k eq 'EXTContact';
   $s->application_purpose($v) if $k eq 'AppPurpose';
  }
 }

 return;
}

sub contact_create
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 return unless (grep $_ eq 'nexus_category', $c->attributes()) && defined $c->{nexus_category};

 # check if application_purpose exist - if exist return AppPurpose (for .US) otherwise EXTContact
 if ($c->{application_purpose}) {
   my $us_str=sprintf('AppPurpose=%s NexusCategory=%s',$c->application_purpose(),$c->nexus_category());
   $mes->command_extension($eid,['neulevel:unspec',$us_str]);
 } else {
   my $unspec = 'EXTContact=' . ($c->ext_contact() && $c->ext_contact() eq 'N' ? 'N':'Y') . ' NexusCategory=' . uc($c->nexus_category());
   $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 }

 return;
}

sub contact_update
{
 my ($epp,$oldc,$todo)=@_;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 my $c=$todo->set('info');
 return unless (grep $_ eq 'nexus_category', $c->attributes()) && defined $c->{nexus_category};

 # check if application_purpose exist - if exist return AppPurpose (for .US) otherwise EXTContact
 if ($c->{application_purpose}) {
   my $us_str=sprintf('AppPurpose=%s NexusCategory=%s',$c->application_purpose(),$c->nexus_category());
   $mes->command_extension($eid,['neulevel:unspec', $us_str]);
 } else {
   my $unspec = 'EXTContact=' . ($c->ext_contact() && $c->ext_contact() eq 'N' ? 'N':'Y') . ' NexusCategory=' . uc($c->nexus_category());
   $mes->command_extension($eid,['neulevel:unspec', $unspec]);
 }

 return;
}


####################################################################################################
#### Domain Functions

sub domain_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('neulevel','extension');
 return unless defined $infdata;

 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   $rinfo->{$otype}->{$oname}->{ext_contact} = $v if $k eq 'EXTContact';
  }
 }

 return;
}

sub domain_create
{
 my ($epp,$domain,$rd)=@_;
 return unless exists $rd->{ext_contact};
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', 'EXTContact=' . $rd->{ext_contact}]);
 return;
}

sub domain_update
{
 my ($epp,$domain,$todo)=@_;
 return unless my $ext_contact = $todo->set('ext_contact');
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('neulevel','extension');
 $mes->command_extension($eid,['neulevel:unspec', 'EXTContact=' . $ext_contact]);
 return;
}


1;
