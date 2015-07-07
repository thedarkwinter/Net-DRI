## Domain Registry Interface, Afilias GRS ccTLD Registry System [EPP - 1.0 Specification]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2015 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2015 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::AfiliasGRS;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;
use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::DRD::AfiliasGRS - Afilias GRS ccTLD Registry System for Net::DRI

=head1 DESCRIPTION

AfiliasGRS to allow the registration of the following ccTLDs:

AG - Antigua and Barbuda
BZ - Belize
LC - Saint Lucia
MN - Mongolia
SC - Seychelles
VC - Saint Vincent and the Grenadines

=head1 SUPPORT

For now, support questions should be sent to:

David Makuni <d.makuni@live.co.uk>

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

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
	$self->{info}->{host_as_attr}=0;
	$self->{info}->{contact_i18n}=4; ## LOC+INT 
	return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return 'AfiliasGRS'; }
sub tlds          { return ('ag','bz','lc','mn','sc','vc'); }
sub object_types  { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default {
	my ($self,$type)=@_;
	return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP',{}) if $type eq 'epp';
	return;
}

####################################################################################################

1;
