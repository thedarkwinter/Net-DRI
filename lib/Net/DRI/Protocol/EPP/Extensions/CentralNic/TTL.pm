## Domain Registry Interface, CentralNic DNS TTL EPP extension
## (http://labs.centralnic.com/epp/ext/ttl.php)
##
## Copyright (c) 2007,2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::TTL;

use strict;
use warnings;

use DateTime::Duration;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::TTL - EPP DNS TTL CentralNic extension commands for Net::DRI

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

Copyright (c) 2007,2008,2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=( create => [ \&create ],
            update => [ \&update ],
            info   => [ undef, \&info_parse ],
          );
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('ttl','infData');
 return unless $infdata;

 my @secs=$infdata->getChildrenByTagNameNS($mes->ns('ttl'),'secs');
 return unless @secs;

 $rinfo->{domain}->{$oname}->{ttl}=DateTime::Duration->new(seconds => $secs[0]->textContent());
 return;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists($rd->{ttl}) && ((ref($rd->{ttl}) && Net::DRI::Util::is_class($rd->{ttl},'DateTime::Duration')) || $rd->{ttl}=~m/^\d+$/));

 my $eid=$mes->command_extension_register('ttl:create',sprintf('xmlns:ttl="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ttl')));
 my @n=(['ttl:secs',ref($rd->{ttl})? $rd->{ttl}->in_units('seconds') : $rd->{ttl}]);
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toset=$todo->set('ttl');
 return unless (defined $toset && ((ref $toset && Net::DRI::Util::is_class($toset,'DateTime::Duration')) || $toset=~m/^\d+$/));

 my $eid=$mes->command_extension_register('ttl:update',sprintf('xmlns:ttl="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ttl')));
 my @n=(['ttl:secs',ref($toset)? $toset->in_units('seconds') : $toset]);
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
