## Domain Registry Interface, Change Poll Extension Mapping for EPP
##
## Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ChangePoll;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rops = { 'session' => { change_poll => [ undef, \&parse ] } };

 return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'changepoll' => [ 'urn:ietf:params:xml:ns:changePoll-1.0','changePoll-1.0.xsd' ] };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-gould-change-poll-04'; }

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('changepoll','changeData');
 return unless defined $data;

 my %r=('state' => $data->hasAttribute('state') ? $data->getAttribute('state') : 'after');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$node)=@$el;
  if ($name eq 'operation')
  {
   my $value=$node->textContent();
   $r{$name}=$node->hasAttribute('op') ? [ $value, $node->getAttribute('op') ] : $value;
  } elsif ($name=~m/^(who|svTRID)$/)
  {
   $r{$name}=$node->textContent();
  } elsif ($name eq 'date')
  {
   $r{$name}=$po->parse_iso8601($node->textContent());
  } elsif ($name eq 'caseId')
  {
   my $type=$node->getAttribute('type');
   $type=$node->getAttribute('name') if $type eq 'custom';
   $r{case}={ type => $type, id => $node->textContent() };
  } elsif ($name eq 'reason')
  {
   $r{reason} = $node->hasAttribute('lang') ? { lang => $node->getAttribute('lang') // 'en', msg => $node->textContent() } : $node->textContent();
  }
 }

 my $msgid=$mes->msg_id();
 $rinfo->{message}->{$msgid}->{change}=\%r;
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ChangePoll - EPP Change Poll Extension mapping (draft-gould-change-poll-03) for Net::DRI

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

Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
