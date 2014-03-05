## Domain Registry Interface, EPP Grace Period commands (RFC3915)
##
## Copyright (c) 2005,2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::GracePeriod;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::GracePeriod - EPP Grace Period commands (RFC3915) for Net::DRI

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

Copyright (c) 2005,2006,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           info   => [ undef, \&info_parse ],
           update => [ \&update, \&update_parse ],
         );

 return { 'domain' => \%tmp };
}

sub capabilities_add { return ('domain_update','rgp',['set']); }

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'rgp' => [ 'urn:ietf:params:xml:ns:rgp-1.0','rgp-1.0.xsd' ] });
 return;
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=$mes->ns('rgp');
 my $infdata=$mes->get_extension($ns,'infData');
 return unless defined $infdata;

 my $cs=$rinfo->{domain}->{$oname}->{status}; ## a Net::DRI::Protocol::EPP::Core::Status object

 foreach my $el ($infdata->getChildrenByTagNameNS($ns,'rgpStatus'))
 {
  $cs->add($el->getAttribute('s'));
 }
 return;
}

############ Transform commands

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $rgp=$todo->set('rgp');
 return unless (defined $rgp && $rgp && ref $rgp eq 'HASH');

 my $op=$rgp->{op} || '';
 Net::DRI::Exception::usererr_invalid_parameters('RGP op must be request or report') unless ($op=~m/^(?:request|report)$/);
 Net::DRI::Exception::usererr_invalid_parameters('Report data must be included if the operation is a report') unless (($op eq 'request') xor exists $rgp->{report});

 my $eid=$mes->command_extension_register('rgp:update',sprintf('xmlns:rgp="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('rgp')));

 if ($op eq 'request')
 {
  $mes->command_extension($eid,['rgp:restore',{ op => $op }]);
 } else
 {
  my %r=%{$rgp->{report}};
  my $def=$epp->default_parameters();
  my @d;
  push @d,['rgp:preData',$r{predata}]; ## XML data is possible in the RFC, but not here ?!
  push @d,['rgp:postData',$r{postdata}]; ## ditto

  Net::DRI::Util::check_isa($r{deltime},'DateTime');
  push @d,['rgp:delTime',$r{deltime}->strftime('%Y-%m-%dT%T.%1NZ')];
  Net::DRI::Util::check_isa($r{restime},'DateTime');
  push @d,['rgp:resTime',$r{restime}->strftime('%Y-%m-%dT%T.%1NZ')];
  push @d,['rgp:resReason',$r{reason}];
  push @d,['rgp:statement',$r{statement1},exists $r{statement1_lang} ? {lang => $r{statement1_lang}} : ()];
  push @d,['rgp:statement',$r{statement2},exists $r{statement2_lang} ? {lang => $r{statement2_lang}} : ()];
  push @d,['rgp:other',$r{other}] if exists $r{other};
  $mes->command_extension($eid,['rgp:restore',['rgp:report',@d],{ op => $op }]);
 }
 return;
}

sub update_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $updata=$mes->get_extension($mes->ns('rgp'),'upData');
 return unless defined $updata;

 ## We do nothing, since the rgpStatus alone is useless
 ## (we do not have the other status)
 return;
}

####################################################################################################
1;
