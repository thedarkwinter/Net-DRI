## Domain Registry Interface, Afilias ccTLD policies for .AG
##
## Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##           (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>.
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

package Net::DRI::DRD::AG;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::AG - .AG policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2010,2011 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{contact_i18n}=2;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Afilias AG'; }
sub tlds     { return qw/ag com.ag net.ag org.ag nom.ag co.ag/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Afilias',{}) if $type eq 'epp';
 return;
}

####################################################################################################
## http://www.afilias-grs.info/public/policies/ag
## http://www.nic.ag/rules.htm
## http://www.nic.ag/reserved-names-policy.htm
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{ check_name => 1,
                                                my_tld => 1,
                                                no_double_hyphen => 1, ## http://www.nic.ag/reserved-names-policy.htm §1
                                                no_country_code => 1,## http://www.nic.ag/reserved-names-policy.htm §6
                                                no_digits_only => 1, ## http://www.nic.ag/reserved-names-policy.htm §4
                                                excluded_labels => [qw/enum example localhost ns com edu ftp net whois wpad brand org tm co nom ac bd/], ## §7,8,9,10
                                                ## Other names are banned in http://www.nic.ag/reserved-names-policy.htm §11,12 we do not implement all checks
                                              });
}

####################################################################################################
1;
