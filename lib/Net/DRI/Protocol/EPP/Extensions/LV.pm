## Domain Registry Interface, .LV EPP extensions [http://www.nic.lv/eppdoc/html/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LV;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LV - .LV EPP Contact extension commands for Net::DRI

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
Copyright (c) 2013-2020 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup {
    my ( $self, $rp ) = @_;
    $self->ns(
        {
            ext_domain => ['http://www.nic.lv/epp/schema/lvdomain-ext-1.0','lvdomain-ext-1.0.xsd'],
            ext_contact => ['http://www.nic.lv/epp/schema/lvcontact-ext-1.0','lvcontact-ext-1.0.xsd'],
        }
    );

    foreach my $o (qw/vat orgno/) {
        $self->capabilities( 'contact_create', $o, ['set'] );
    }
    $self->capabilities( 'domain_update', 'auto_renew',         ['set'] );
    $self->capabilities( 'domain_update', 'auto_renew_message', ['set'] );

    return;
}

sub default_extensions { return qw/LV::Domain LV::Contact/; }

####################################################################################################
1;
