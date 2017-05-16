## Domain Registry Interface, .PRO policies
##
## Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
##           (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::PRO;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::PRO - .PRO policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>,
Alexander Biehl, E<lt>info@hexonet.netE<gt>, HEXONET Support GmbH,
E<lt>http://www.hexonet.net/E<gt>.

=head1 COPYRIGHT

Copyright (c) 2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
          (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
 my $class = shift;
 my $self = $class->SUPER::new(@_);
 $self->{info}->{host_as_attr} = 0;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'RegistryPro'; }
sub tlds     { return qw/pro law.pro jur.pro bar.pro med.pro cpa.pro aca.pro eng.pro/; }
sub object_types { return ('domain','contact','ns','av'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::PRO',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self, $ndr, $domain, $op) = @_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1,
                                              });
}

####################################################################################################
## TODO : $av should be checked here to be syntaxically correct before doing process()

sub av_create { my ($self,$ndr,$av,$ep)=@_; return $ndr->process('av','create',[$av,$ep]); }
sub av_check  { my ($self,$ndr,$av,$ep)=@_; return $ndr->process('av','check',[$av,$ep]); }
sub av_info   { my ($self,$ndr,$av,$ep)=@_; return $ndr->process('av','info',[$av,$ep]); }

####################################################################################################
1;
