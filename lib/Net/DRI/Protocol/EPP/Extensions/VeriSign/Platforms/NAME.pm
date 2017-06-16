## Domain Registry Interface, VeriSign EPP extensions
##
## Copyright (c) 2006,2008-2014,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::Platforms::NAME;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Protocol::EPP::Extensions::VeriSign::EmailFwd;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::Platforms::NAME - VeriSign dotName (.NAME) EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

Note that the PremiumDomain extension is not loaded by default.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008-2014,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

## List of VeriSign extensions: http://www.verisigninc.com/en_US/channel-resources/domain-registry-products/epp-sdks/index.xhtml?loc=en_US
## But see http://www.verisign.com/assets/epp-sdk/Verisign-EPP-SDK-Prog-Guide.pdf §13 Mappings and Extensions
## TODO for .NAME: namewatch, persreg
## NOTE namestore is [currently] announced by the server, but it returns an error when used!

sub default_extensions
{
 my ($self,$rp)=@_;
 my @c=qw/VeriSign::PollRGP VeriSign::PollLowBalance VeriSign::IDNLanguage VeriSign::DefReg VeriSign::EmailFwd GracePeriod SecDNS/; # Not implmented:
 return @c;
}

####################################################################################################
1;
