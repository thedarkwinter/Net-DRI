## Domain Registry Interface, CentralNic Web Forwarding EPP extension
## (http://labs.centralnic.com/epp/ext/wf.php)
##
## Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CentralNic::WebForwarding;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CentralNic::WebForwarding - EPP WebForwarding CentralNic extension commands for Net::DRI

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

Copyright (c) 2007,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
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

 my $infdata=$mes->get_extension('wf','infData');
 return unless $infdata;

 my @c=$infdata->getChildrenByTagNameNS($mes->ns('wf'),'url');
 return unless @c;

 $rinfo->{domain}->{$oname}->{web_forwarding}=$c[0]->getFirstChild()->getData();
 return;
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists($rd->{web_forwarding}) && defined($rd->{web_forwarding}));

 my $eid=$mes->command_extension_register('wf:create',sprintf('xmlns:wf="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('wf')));
 my @n=(['wf:url',$rd->{web_forwarding}]);
 $mes->command_extension($eid,\@n);
 return;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $toset=$todo->set('web_forwarding');
 return unless defined($toset);

 my $eid=$mes->command_extension_register('wf:update',sprintf('xmlns:wf="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('wf')));
 my @n=(['wf:url',$toset]);
 $mes->command_extension($eid,\@n);
 return;
}

####################################################################################################
1;
