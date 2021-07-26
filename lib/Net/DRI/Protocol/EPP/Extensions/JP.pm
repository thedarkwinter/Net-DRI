## Domain Registry Interface, JPRS EPP extensions
##
## Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::JP;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::JP;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::JP - JPRS EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2021 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({jpex => ['urn:ietf:params:xml:ns:jpex-1.0','jpex-1.0.xsd']});
 $self->factories('contact', sub { return Net::DRI::Data::Contact::JP->new(); });

 # domain
 foreach my $o (qw/alloc handle suffix/)  { $self->capabilities('domain_update',$o,['set']); }

 return;
}

sub core_contact_types { return ('admin','billing','tech'); }
sub default_extensions { return qw/CentralNic::Fee GracePeriod IDN JP::JPEX LaunchPhase SecDNS/; }

####################################################################################################
1;
