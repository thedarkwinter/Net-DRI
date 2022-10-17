## Domain Registry Interface, NameAction Status
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::NameAction::Status;

use base qw!Net::DRI::Data::StatusList!;

use strict;
use warnings;

use Net::DRI::Exception;

=pod

=head1 NAME

Net::DRI::Protocol::NameAction::Status - NameAction Status for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#######################################################################################

sub new
{
 my ($class,$msg)=@_;
 my $self=$class->SUPER::new('nameaction','1.0.4');
 return $self unless defined $msg;
 Net::DRI::Exception::err_invalid_parameters('new() expects a ref array') unless ref $msg eq 'ARRAY';
 $self->add(@$msg);
 return $self;

}

sub is_active    { return shift->has_any('Registered'); }
sub is_pending   { return shift->has_any('In Process'); }
sub can_update   { return !shift->is_pending(); }
sub can_transfer { return !shift->is_pending(); }
sub can_delete   { return !shift->is_pending(); }
sub can_renew    { return !shift->is_pending(); }

#######################################################################################
1;
