## Domain Registry Interface, Nomulus Allocate Extension Mapping for EPP
##
## Copyright (c) 2017-2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nomulus::Allocate;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $cmds = { 'domain' => { create => [ \&build, undef ] } };
 return $cmds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'allocate' => 'urn:google:params:xml:ns:allocate-1.0' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://github.com/google/nomulus/blob/5012893c1d761d60591f165a1c5640624b28df9d/java/google/registry/xml/xsd/allocate.xsd'; }

####################################################################################################

sub build
{
 my ($epp,$domain,$rd)=@_;

 return unless Net::DRI::Util::has_key($rd, 'allocate') && ref $rd->{'allocate'} eq 'HASH';

 my $rh=$rd->{'allocate'};
 my @data;
 Net::DRI::Exception::usererr_insufficient_parameters('allocate.roid must be defined') unless Net::DRI::Util::has_key($rh, 'roid') && Net::DRI::Util::is_roid($rh->{'roid'});
 push @data, ['allocate:applicationRoid', $rh->{'roid'}];
 Net::DRI::Exception::usererr_invalid_parameters('allocate.application_time must be a DateTime object') unless Net::DRI::Util::has_key($rh, 'application_time') && Net::DRI::Util::check_isa($rh->{application_time}, 'DateTime');
 push @data, ['allocate:applicationTime', $rh->{application_time}->clone()->set_time_zone('UTC')->strftime('%Y-%m-%dT%H:%M:%SZ')];
 if (Net::DRI::Util::has_key($rh, 'smd'))
 {
  Net::DRI::Exception::usererr_invalid_parameters('allocate.smd must be of type mark:idType') unless $rh->{smd}=~m/^\d+-\d+$/;
  push @data, ['allocate:smdId', $rh->{smd}];
 }
 if (Net::DRI::Util::has_key($rh, 'notice'))
 {
  my $rn = $rh->{'notice'};
  foreach my $param (qw/id expiration_date accepted_date/)
  {
   Net::DRI::Exception::usererr_insufficient_parameters("allocate.notice.$param must be defined") unless Net::DRI::Util::has_key($rn, $param);
  }
  my @notice;
  my %attr;
  if (Net::DRI::Util::has_key($rn, 'validator_id'))
  {
   Net::DRI::Exception::usererr_invalid_parameters('allocate.notice.validator_id must be an XML token with at least 1 character') unless Net::DRI::Util::xml_is_token($rn->{validator_id}, 1);
   $attr{validatorID} = $rn->{validator_id};
  }
  Net::DRI::Exception::usererr_invalid_parameters('allocate.notice.id must be an XML token with at least 1 character') unless Net::DRI::Util::xml_is_token($rn->{id}, 1);
  push @notice, ['launch:noticeID', $rn->{id}, %attr];
  Net::DRI::Exception::usererr_invalid_parameters('allocate.notice.expiration_date must be a DateTime object') unless Net::DRI::Util::check_isa($rn->{expiration_date}, 'DateTime');
  push @notice, ['launch:notAfter', $rn->{expiration_date}->clone()->set_time_zone('UTC')->strftime('%Y-%m-%dT%H:%M:%SZ')];
  Net::DRI::Exception::usererr_invalid_parameters('allocate.notice.accepted_date must be a DateTime object') unless Net::DRI::Util::check_isa($rn->{accepted_date}, 'DateTime');
  push @notice, ['launch:acceptedDate', $rn->{accepted_date}->clone()->set_time_zone('UTC')->strftime('%Y-%m-%dT%H:%M:%SZ')];
  push @data, ['allocate:notice', @notice];
 }

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('allocate', 'create');
 $mes->command_extension($eid, \@data);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nomulus::Allocate - EPP Allocate Nomulus Extension mapping for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

From Google documentation:
Domain name extension schema for allocating domains from applications.
This is a proprietary, internal-only, non-public extension only for use
inside the Google registry.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017-2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
