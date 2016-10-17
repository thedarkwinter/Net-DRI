## Domain Registry Interface, .IN EPP Extension Commands [https://registry.in/system/files/IN_EPP_OTE_Criteria_v3.0.pdf - 09/06/2016]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::IN;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IN - IN (.ORG & various ccTLDs) EPP extensions for Net::DRI

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
Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub setup {
   my ( $self , $rp ) = @_;
   $self->ns(
      {
          trademark   => ['urn:afilias:params:xml:ns:trademark-1.0','trademark-1.0.xsd'], # Trademark
          idn         => ['urn:afilias:params:xml:ns:idn-1.0','idn-1.0.xsd'], # IDN
          secdns      => ['urn:ietf:params:xml:ns:secDNS-1.1','secDNS-1.1.xsd'], # SecDNS
          fee         => [ 'urn:ietf:params:xml:ns:fee-0.8','fee-0.8.xsd' ], # Fee
      }
   );

   $self->capabilities( 'domain_update', 'trademark', ['set','del']);

   return;
}

sub default_extensions { return qw/Afilias::Trademark Afilias::IDNLanguage IN::Domain SecDNS IDN CentralNic::Fee/; }

####################################################################################################
1;
