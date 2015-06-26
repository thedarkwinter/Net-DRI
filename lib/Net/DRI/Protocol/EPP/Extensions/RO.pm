## Domain Registry Interface, .RO EPP extensions [https://epp2-test.rotld.ro/epp/index.html]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI.
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::RO;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::RO - .RO EPP Contact extension commands for Net::DRI

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

sub setup {
	my ( $self, $rp ) = @_;
	$self->ns(
		{
			ro_idn_ext =>       ['http://www.rotld.ro/xml/epp/idn-1.0','idn-1.0.xsd'],
			ro_contact_ext =>   ['http://www.rotld.ro/xml/epp/rotld-1.0','rotld-1.0.xsd'],
			ro_domain_ext =>    ['http://www.rotld.ro/xml/epp/rotld-1.0','rotld-1.0.xsd'],
			ro_domain =>        ['http://www.rotld.ro/xml/epp/domain-1.0','domain-1.0.xsd'],
		}
	);
	$self->capabilities( 'domain_update', 'activate_domain', ['set'] );
	return;
}

sub default_extensions { return qw/RO::Domain RO::Contact/; }

####################################################################################################
1;
