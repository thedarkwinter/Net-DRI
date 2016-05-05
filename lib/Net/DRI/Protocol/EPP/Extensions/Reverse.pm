## Domain Registry Interface, Command Reversal Extension for EPP
##
## Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Reverse;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $rmcds = { 'command' => { 'reverse'        => [ \&build, undef ],
                                 'review_reverse' => [ undef, \&parse ],
                               }
                };
 return $rmcds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $rns = { 'reverse' => [ 'urn:ietf:params:xml:ns:reverse-0.1', 'reverse-0.1.xsd' ]};
 $po->ns($rns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-brown-epp-reverse-00'; }

####################################################################################################

sub build
{
 my ($epp,$svtrid,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_insufficient_parameters('svtrid of command to reverse is mandatory') unless defined $svtrid;
 Net::DRI::Exception::usererr_invalid_parameters('svtrid must be of type epp:trIDStringType') unless Net::DRI::Util::xml_is_token($svtrid, 3, 64);

 my @d;
 push @d, ['reverse:reason', $rd->{reason}] if Net::DRI::Util::has_key($rd, 'reason');
 push @d, ['reverse:trID', Net::DRI::Util::has_key($rd, 'trid') ? ['reverse:clTRID', $rd->{trid}] : (), ['reverse:svTRID', $svtrid]];
 push @d, ['reverse:clTRID', $mes->cltrid()];

 my $eid=$mes->command_extension_register('reverse', 'reverse');
 $mes->command_extension($eid, \@d);

 return;
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_response('reverse','panData');
 return unless defined $data;

 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;
  if ($name eq 'paTRID')
  {
   my $ns=$mes->ns('reverse');
   $oname=Net::DRI::Util::xml_child_content($c,$ns,'svTRID');
   $rinfo->{command}->{$oname}->{action}='review_reverse';
   $rinfo->{command}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
   $rinfo->{command}->{$oname}->{svtrid}=$oname;
   my $tmp=Net::DRI::Util::xml_child_content($c,$ns,'clTRID');
   $rinfo->{command}->{$oname}->{trid}=$tmp if defined $tmp;
  } elsif ($name eq 'paDate')
  {
   $rinfo->{command}->{$oname}->{date}=$po->parse_iso8601($c->textContent());
  }
 }

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Reverse - Command Reversal EPP Extension (draft-brown-epp-reverse-00) for Net::DRI

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

Copyright (c) 2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
