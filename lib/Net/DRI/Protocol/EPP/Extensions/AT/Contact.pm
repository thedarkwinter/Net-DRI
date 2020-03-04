## Domain Registry Interface, NIC.AT Contact extension
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006-2008,2010,2013,2016,2018,2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Contact;

use strict;
use warnings;
use feature 'state';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Contact - NIC.AT Contact Extensions for Net::DRI

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

Copyright (c) 2006-2008,2010,2013,2016,2018,2019 Patrick Mevzek <netdri@dotandco.com>.
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
 state $contact = {
                   info   => [ undef, \&parse_info ],
                   update => [ \&update, undef ],
                   create => [ \&create, undef ],
                  };
 state $commands = { 'contact' => $contact };

 return $commands;
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'at-ext-contact' => 'http://www.nic.at/xsd/at-ext-contact-1.0' });
 return;
}

sub parse_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 return unless $mes->is_success();

 my $c=$rinfo->{contact}->{$oname}->{self};
 $c->email(undef) if ($c->email() eq 'n/a');

 my $condata=$mes->get_extension('at-ext-contact', 'infData');
 return unless $condata;

 my @options;

 my $el=$condata->getElementsByTagNameNS($mes->ns('at-ext-contact'), 'type');
 my $type=$el? $el->get_node(1)->getFirstChild()->getData() : undef;

 $c->type($type) if (defined($type) && $type);
# $rinfo->{contact}->{$oname}->{type}=$type if $type;
 return;
}

sub create
{
 my ($epp,$contact,$rd)=@_;

 my $type=$contact->type();
 return unless defined $type;

 $epp->message()->command_extension('at-ext-contact', ['create', ['type', $type]]);
 return;
}

sub update
{
 my ($epp,$contact,$todo)=@_;

 my $type=$todo->set('info')->type();
 return unless defined $type;

 $epp->message()->command_extension('at-ext-contact', ['update', ['chg', ['type', $type]]]);
 return;
}

####################################################################################################
1;