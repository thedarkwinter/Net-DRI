## Domain Registry Interface, Domain Verification Extension Mapping for EPP
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

package Net::DRI::Protocol::EPP::Extensions::DomainVerification;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $rcmds = { 'domain' => { 'check'       => [ undef, \&check_parse ],
                                'check_multi' => [ undef, \&check_parse ],
                                'info'        => [ undef, \&info_parse ],
                              },
                };
 return $rcmds;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $rns = { 'veridomain' => [ 'urn:ietf:params:xml:ns:veridomain-1.0','veridomain-1.0.xsd' ] };
 $po->ns($rns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-wang-eppext-domain-verification-01'; }

####################################################################################################

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension($mes->ns('veridomain'),'chkData');
 return unless defined $data;

 my %r;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'distinction')
  {
   $rinfo->{'domain'}->{lc $node->getAttribute('name')}->{restriction}->{type}=$node->getAttribute('type');
  }
 }

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $ns=$mes->ns('veridomain');
 my $data=$mes->get_extension($ns,'infData');
 return unless defined $data;

 my %r;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'status')
  {
   $r{status}=$node->textContent();
  } elsif ($name eq 'history')
  {
   foreach my $record (Net::DRI::Util::xml_list_children($node, 'record'))
   {
    push @{$r{history}}, { date => $po->parse_iso8601(Net::DRI::Util::xml_child_content($record, $ns, 'date')),
                           op   => Net::DRI::Util::xml_child_content($record, $ns, 'op'),
                           clID => Net::DRI::Util::xml_child_content($record, $ns, 'clID'),
                         };
   }
  }
 }

 $rinfo->{$otype}->{$oname}->{restriction}=\%r;

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DomainVerification - EPP Domain Verification Extension mapping (draft-wang-eppext-domain-verification-01) for Net::DRI

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
