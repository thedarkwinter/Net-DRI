## Domain Registry Interface, .NAME EPP extensions
##
## Copyright (c) 2007-2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2010,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NAME;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NAME - .NAME EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> or
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2012 Patrick Mevzek <netdri@dotandco.com>
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
 $self->ns({ emailFwd => ['http://www.nic.name/epp/emailFwd-1.0','emailFwd-1.0.xsd'] });
 $self->ns({ defReg => ['http://www.nic.name/epp/defReg-1.0','defReg-1.0.xsd'] });
 $self->capabilities('emailfwd_update','info',['set']);
 return;
}

sub default_extensions { return qw/NAME::EmailFwd NAME::DefReg VeriSign::IDNLanguage GracePeriod SecDNS/; }

####################################################################################################
1;
