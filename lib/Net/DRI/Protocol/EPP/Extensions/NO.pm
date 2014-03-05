## Domain Registry Interface, NORID (.NO) EPP extensions
##
## Copyright (c) 2008-2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NO;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::NO;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO - .NO EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup {
    my ($self,$rp)=@_;
    $self->ns({ no_contact => [ 'http://www.norid.no/xsd/no-ext-contact-1.0','no-ext-contact-1.0.xsd' ],
                no_domain  => [ 'http://www.norid.no/xsd/no-ext-domain-1.0','no-ext-domain-1.0.xsd' ],
                no_domain_1_1 => [ 'http://www.norid.no/xsd/no-ext-domain-1.1','no-ext-domain-1.1.xsd' ],
                no_host    => [ 'http://www.norid.no/xsd/no-ext-host-1.0','no-ext-host-1.0.xsd' ],
                no_result  => [ 'http://www.norid.no/xsd/no-ext-result-1.0','no-ext-result-1.0.xsd' ],
                no_epp     => [ 'http://www.norid.no/xsd/no-ext-epp-1.0','no-ext-epp-1.0.xsd' ],
             });


    foreach my $o (qw/mobilephone identity xdisclose facets/)  { $self->capabilities('contact_update',$o,['set']); }
    foreach my $o (qw/organization rolecontact xemail/)        { $self->capabilities('contact_update',$o,['add','del']); }
    $self->capabilities('host_update','contact',['set']);
    $self->capabilities('host_update','facets',['set']);
    $self->capabilities('domain_update','facets',['set']);
    $self->capabilities('domain_update','applicantdataset',['set']);
    $self->factories('contact',sub { return Net::DRI::Data::Contact::NO->new(); });

    return;
}

sub default_extensions { return qw/NO::Domain NO::Contact NO::Host NO::Result NO::Message/; }

####################################################################################################
1;
