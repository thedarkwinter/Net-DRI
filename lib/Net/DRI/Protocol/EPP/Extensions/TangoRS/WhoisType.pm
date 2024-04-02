## Domain Registry Interface, Neulevel EPP WhoisType (for .TEL and possibly others)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013,2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::TangoRS::WhoisType;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::WhoisType - TangoRS EPP WhoisType Extension for .TEL

=head1 DESCRIPTION

TangoRS EPP WhoisType Extension for .TEL

Additional domain extension Neulevel unpsec for WhoisType/Publish

$dri->domain_create('domain.tel', { ....  whoisType => {  type=>'Legal', publish=>'N' } });

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
          (c) 2013,2017 Michael Holloway <michael@thedarkwinter.com>.
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

sub capabilities_add { return ('domain_update','whois_type',['set']); }

####################################################################################################

sub add_whoistype
{
 my $rd = shift;
 Net::DRI::Exception::usererr_insufficient_parameters('whois_type type value must be defined') unless Net::DRI::Util::has_key($rd,'type');
 my $wt = lc($rd->{'type'}) =~ m/legal/ ? 'Legal' : 'Natural';
 Net::DRI::Exception::usererr_invalid_parameters('whois_type type value must be either Legal or Natural') unless $wt =~ m/^(?:Legal|Natural)$/;
 my $pub = (defined $rd->{'publish'} && (lc($rd->{'publish'}) =~ m/(true|yes|1|y)/ ))?'Y':'N';
 return  "WhoisType=$wt" . (($wt eq 'LEGAL')?'': " Publish=$pub");
}

sub domain_create
{
 my ($epp,$domain,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'whois_type');
 my $unspec = add_whoistype($rd->{'whois_type'});
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 $mes->command_extension($eid,['unspec', $unspec]);
 return;
}

sub domain_update
{
 my ($epp,$domain,$todo)=@_;
 my $tochg=$todo->set('whois_type');
 return unless defined $tochg;
 my $unspec = add_whoistype($tochg);
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 $mes->command_extension($eid,['unspec', $unspec]);
 return;
}

sub domain_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 return unless defined $infdata;

 my %t;
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   $rinfo->{$otype}->{$oname}->{whois_type}->{type}=$v    if $k eq 'WhoisType';
   $rinfo->{$otype}->{$oname}->{whois_type}->{publish}=$v if $k eq 'Publish';
  }
 }

 return;
}

sub contact_create
{
 my ($epp,$contact,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'whois_type');
 my $unspec = add_whoistype($rd->{'whois_type'});
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 $mes->command_extension($eid,['unspec', $unspec]);
 return;
}

sub contact_update
{
 my ($epp,$contact,$todo)=@_;
 my $tochg=$todo->set('whois_type');
 return unless defined $tochg;
 my $unspec = add_whoistype($tochg);
 return unless defined $unspec;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 $mes->command_extension($eid,['unspec', $unspec]);
 return;
}

sub contact_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_extension('extension', 'xmlns="http://xmlns.tango-rs.net/epp/unspec-1.0"');
 return unless defined $infdata;

 my %t;
 my $unspec;
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($n,$c)=@$el;
  next unless $n eq 'unspec';
  foreach my $kv (split(/ /,$c->textContent()))
  {
   my ($k,$v) = split(/=/,$kv);
   $rinfo->{$otype}->{$oname}->{whois_type}->{type}=$v    if $k eq 'WhoisType';
   $rinfo->{$otype}->{$oname}->{whois_type}->{publish}=$v if $k eq 'Publish';
  }
 }

 return;
}

####################################################################################################
1;
