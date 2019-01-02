## Domain Registry Interface, Charleston Road Registry Driver
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014,2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::CRR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::CRR - Charleston Road Registry Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension Charleston Road Registry New Generic TLDs

Charleston Road Registry utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

Note: CRR does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2014,2017 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'CRR'; }
sub tlds     { return qw/xn--flw351e xn--q9jyb4c xn--qcka1pmc ads android app boo cal channel chrome dad day dclk dev docs drive eat esq fly foo gbiz gle gmail goog google guge hangout here how ing kid map meet meme mov new nexus page phd play prod prof rsvp search soy tour youtube zip/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 # Do we (the people) prefer to use Extensions::CRR instead of NEWGTLD with custom options?
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee'],'disable_idn'=>1,'brown_fee_version'=>'0.6'}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.charlestonroadregistry.com'},'Net::DRI::Protocol::Whois',{'NGTLD'=>1}) if $type eq 'whois';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1,
                                              });
}

####################################################################################################

1;
