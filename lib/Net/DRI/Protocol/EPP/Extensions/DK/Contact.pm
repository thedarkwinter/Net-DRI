## Domain Registry Interface, .DK Contact EPP extension commands
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DK::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use DateTime::Format::ISO8601;
use utf8;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DK::Contact - .DK EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
    my ( $class, $version ) = @_;
    my %tmp = (
        create => [ \&create, undef ],
    );

    return { 'contact' => \%tmp };
}

####################################################################################################

sub create {
    my ( $epp, $c ) = @_;
    my $mes = $epp->message;
    
    return unless defined $c->vat() || $c->type() || $c->ean();
    
    if (defined $c->ean()) {
		my $eid1=$mes->command_extension_register('dkhm:EAN','xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2"');
		$mes->command_extension($eid1,$c->ean());
	} 
    
	if (defined $c->vat()) {
		my $eid1=$mes->command_extension_register('dkhm:CVR','xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2"');
		$mes->command_extension($eid1,$c->vat());
	} 
	
	if (defined $c->type()) {
		my $eid2=$mes->command_extension_register('dkhm:userType','xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-1.2"');
		$mes->command_extension($eid2,$c->type());
	}
		
    return;
}

####################################################################################################
1;
