## Domain Registry Interface, Cloud Registry LaunchPhase EPP Extension for managing Sunrise and Landrush
##
## Copyright (c) 2009-2011,2013 Cloud Registry Pty Ltd <http://www.cloudregistry.net>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CloudRegistry::LaunchPhase;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CloudRegistry::LaunchPhase - Cloud Registry LaunchPhase (Sunrise and Land Rush) EPP Extension for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

Please use the issue tracker

E<lt>https://github.com/cloudregistry/net-dri/issuesE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.cloudregistry.net/E<gt> and
E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Wil Tan E<lt>wil@cloudregistry.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2009-2011,2013 Cloud Registry Pty Ltd <http://www.cloudregistry.net>.
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
           create => [ \&create, \&create_parse ],
           info   => [ \&info, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'lp');

 my @lpdata;
 push @lpdata, ['lp:trademark_name', $rd->{lp}->{trademark_name}]               if exists $rd->{lp}->{trademark_name};
 push @lpdata, ['lp:trademark_number', $rd->{lp}->{trademark_number}]           if exists $rd->{lp}->{trademark_number};
 push @lpdata, ['lp:trademark_locality', $rd->{lp}->{trademark_locality}]       if exists $rd->{lp}->{trademark_locality};
 push @lpdata, ['lp:trademark_entitlement', $rd->{lp}->{trademark_entitlement}] if exists $rd->{lp}->{trademark_entitlement};
 push @lpdata, ['lp:pvrc', $rd->{lp}->{pvrc}]                                   if exists $rd->{lp}->{pvrc};
 push @lpdata, ['lp:phase', $rd->{lp}->{phase}]                                 if exists $rd->{lp}->{phase};

 my $eid=$mes->command_extension_register('lp:create',sprintf('xmlns:lp="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('lp')));
 $mes->command_extension($eid,[@lpdata]);
 return;
}

sub create_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 my $creData = $mes->get_extension('lp','creData');

 return unless defined $creData;

 my $c = $creData->getElementsByTagNameNS($mes->ns('lp'), 'application_id');
 $rinfo->{$otype}->{$oname}->{lp} = {application_id=>$c->get_node(1)->textContent()} if defined $c && $c->size();
 return;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rd,'lp');

 my @lpdata;
 push @lpdata, ['lp:application_id', $rd->{lp}->{application_id}] if exists $rd->{lp}->{application_id};
 push @lpdata, ['lp:phase', $rd->{lp}->{phase}]                   if exists $rd->{lp}->{phase};

 my $eid=$mes->command_extension_register('lp:info',sprintf('xmlns:lp="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('lp')));
 $mes->command_extension($eid,[@lpdata]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('lp','infData');

 return unless defined $infdata;

 my %lpdata;
 my $ns=$mes->ns('lp');
 foreach my $el (qw/trademark_name trademark_number trademark_locality trademark_entitlement pvrc phase/)
 {
  my $v=Net::DRI::Util::xml_child_content($infdata,$ns,$el);
  $lpdata{$el}=$v if defined $v;
 }
 $rinfo->{$otype}->{$oname}->{lp} = \%lpdata;
 return;
}

####################################################################################################
1;
