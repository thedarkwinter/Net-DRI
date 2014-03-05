## Domain Registry Interface, ENUM.AT Result Condition
## Contributed by Michael Braunoeder from ENUM.AT <michael.braunoeder@enum.at>
##
## Copyright (c) 2006,2007,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Result;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $NS='http://www.enum.at/rxsd/ienum43-result-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Result - ENUM.AT Result Condition EPP Mapping for Net::DRI

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

Copyright (c) 2006,2007,2013 Patrick Mevzek <netdri@dotandco.com>.
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
           login => [ undef, \&condition_parse ],
           check  => [ undef, \&condition_parse ],
           info   => [ undef, \&condition_parse ],
           transfer_query  => [ undef, \&condition_parse ],
           create => [ undef, \&condition_parse ],
           delete => [ undef, \&condition_parse],
           transfer_request => [ undef, \&condition_parse ],
           transfer_cancel  => [ undef,\&condition_parse ],
           transfer_answer  => [ undef,\&condition_parse ],
           update => [ undef, \&condition_parse ],
         );

 return { 'domain' => \%tmp };
}


sub condition_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 my $condata=$mes->get_extension($NS,'conditions');
 return unless $condata;

 my @conditions;

 foreach my $el ($condata->getElementsByTagNameNS($NS,'condition'))
 {
  my %con;
  my $c=$el->getFirstChild();

  $con{code}=$el->getAttribute('code') if $el->getAttribute('code');
  $con{severity}=$el->getAttribute('severity') if $el->getAttribute('severity');

  while ($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $name=$c->localname() || $c->nodeName();
   next unless $name;
   if ($name=~m/^(msg|details)$/)
   {
    $con{$1}=$c->getFirstChild()->getData();
   }
  } continue { $c=$c->getNextSibling(); }
  push @conditions,\%con;
 }

 $rinfo->{domain}->{$oname}->{conditions}=\@conditions;
 return;
}

####################################################################################################
1;
