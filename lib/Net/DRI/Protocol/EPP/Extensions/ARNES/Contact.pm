## Domain Registry Interface, ARNES (.SI) Contact EPP extension commands
##
## Copyright (c) 2008,2013,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ARNES::Contact;

use strict;
use warnings;
use feature 'state';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ARNES::Contact - ARNES (.SI) EPP Contact extensions for Net::DRI

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

Copyright (c) 2008,2013,2016 Patrick Mevzek <netdri@dotandco.com>.
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
 state $rcmds = { 'contact' => { 'create' => [ \&create, undef ],
                                 'info'   => [ undef, \&info_parse ],
                               },
                };
 return $rcmds;
}

####################################################################################################

sub create
{
 my ($epp,$contact)=@_;

# validate() has been called
 return unless $contact->ctype();

 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('dnssi','ext');
 $mes->command_extension($eid,[['dnssi:create', ['dnssi:contact',{type=>$contact->ctype()}]]]);
 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('dnssi','ext');
 return unless $infdata;

 $infdata=$infdata->getChildrenByTagNameNS($mes->ns('dnssi'),'info');
 return unless ($infdata && $infdata->size()==1);
 $infdata=$infdata->get_node(1)->getChildrenByTagNameNS($mes->ns('dnssi'),'contact');
 return unless ($infdata && $infdata->size()==1);

 $rinfo->{contact}->{$oname}->{self}->ctype($1) if $infdata->get_node(1)->getAttribute('type')=~m/^(org|person)$/;

 return;
}

####################################################################################################
1;
