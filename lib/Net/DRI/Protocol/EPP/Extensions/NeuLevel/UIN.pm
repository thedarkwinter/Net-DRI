## Domain Registry Interface, EPP Extension for .travel UIN
## (ICANN Sponsored TLD Registry Agreement, Part IV)
##
## Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
## Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NeuLevel::UIN;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NeuLevel::UIN - EPP Extension for .TRAVEL UIN for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008,2013 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
Copyright (c) 2016,2018-2019 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


####################################################################################################

sub register_commands
{
 my ($class, $version) = @_;
 state $domain = {
                  create           => [ \&add_uin, undef ],
                  transfer_request => [ \&add_uin, undef ],
                  renew            => [ \&renew,   undef ],
                 };
 state $commands = { domain => $domain };
 return $commands;
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'neulevel' => 'urn:ietf:params:xml:ns:neulevel-1.0' });
 return;
}

####################################################################################################

############ Transform commands

sub add_uin
{
 my ($epp, $domain, $rd) = @_;

 return unless Net::DRI::Util::has_key($rd,'uin');

 $epp->message()->command_extension('neulevel', ['extension', ['unspec', 'UIN=' . $rd->{uin}]]);
 return;
}

sub renew
{
 my ($epp, $domain, $rd) = @_;
 my @vals = qw(RestoreReasonCode RestoreComment TrueData ValidUse UIN);
 my %info;
 my $comment;

 if (defined($rd->{rgp}) && ref($rd->{rgp}) eq 'HASH')
 {
  $info{TrueData} = 'Y';
  $info{ValidUse} = 'Y';
  $info{RestoreReasonCode} = $rd->{rgp}->{code};
  $comment = $rd->{rgp}->{comment};
  $comment = join('', map { ucfirst($_) } split(/\s+/, $comment));
  $info{RestoreComment} = $comment;
 }

 if (Net::DRI::Util::has_key($rd,'uin'))
 {
  $info{UIN} = $rd->{uin};
 }

 $epp->message()->command_extension('neulevel', ['extension', ['unspec', join(' ', map { $_ . '=' . $info{$_} } grep { defined($info{$_}) } @vals)]]);
 return;
}

####################################################################################################
1;