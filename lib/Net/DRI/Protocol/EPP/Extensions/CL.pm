## Domain Registry Interface, .CL policies from 'NIC_Chile_EPP_Documentation_1.0.4.pdf'
##
## Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CL;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CL - .CL EPP extensions 'NIC_Chile_EPP_Documentation_1.0.4.pdf' for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge <paullojorgge@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2017 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2017 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

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
  $self->ns({
      clcontact   => 'urn:ietf:params:xml:ns:clcontact-1.0',
      cldomain    => 'urn:ietf:params:xml:ns:cldomain-1.0',
      clnic       => 'urn:ietf:params:xml:ns:clnic-1.0',
      pollryrr    => 'urn:ietf:params:xml:ns:pollryrr-1.0'
    });

  return;
}

sub default_extensions { return qw/GracePeriod CL::Message/; }

####################################################################################################
1;
