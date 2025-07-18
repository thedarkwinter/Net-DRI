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

package Net::DRI::Protocol::EPP::Extensions::VeriSign::Platforms::NameStore;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign::Platforms::NameStore - VeriSign (.CC/.TV/.JOBS) EPP extensions for Net::DRI

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

Copyright (c) 2006,2008-2014,2016 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->default_parameters()->{subproductid}=$rp->{default_product} || '_auto_';
 $self->default_parameters()->{whois_info}=0;
 return;
}

## List of VeriSign extensions: http://www.verisigninc.com/en_US/channel-resources/domain-registry-products/epp-sdks/index.xhtml?loc=en_US
## But see http://www.verisign.com/assets/epp-sdk/Verisign-EPP-SDK-Prog-Guide.pdf §13 Mappings and Extensions

sub default_extensions
{
 my ($self,$rp)=@_;
 $self->{fee_version} = $rp->{fee_version} if exists $rp->{fee_version};
 # As VeriSign has started to use the RFC8748 Fee extension (fee-1.0), we are no longer supporting PremiumDomain and CentralNic::Fee to avoid conflicts
 # These can still be loaded manually in add_current_profile()
 my @c=qw/VeriSign::Sync VeriSign::PollLowBalance VeriSign::PollRGP VeriSign::IDNLanguage VeriSign::Balance GracePeriod SecDNS ChangePoll LaunchPhase VeriSign::DefReg VeriSign::EmailFwd Fee/;
 push @c,'VeriSign::NameStore'; ## this must come last
 return @c;
}

####################################################################################################
1;
