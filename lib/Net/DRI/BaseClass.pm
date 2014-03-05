## Domain Registry Interface, Superclass of various classes for Net::DRI
##
## Copyright (c) 2009-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::BaseClass;

use strict;
use warnings;

use Net::DRI::Exception;

####################################################################################################
## CLASS METHODS

sub make_exception_if_not_implemented
{
 my ($self,@methods)=@_;
 my $class=ref $self || $self;
 foreach my $name (@methods)
 {
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  *{"${class}::${name}"}=sub { my $self=shift; Net::DRI::Exception->die(1,'internal',1,sprintf('Method %s not implemented in %s, please report.',$name,$class)); };
 }
 return;
}

sub make_exception_for_unavailable_operations
{
 my ($self,@methods)=@_;
 my $class=ref $self || $self;
 foreach my $name (@methods)
 {
  my @op=split(/_/,$name,2);
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  *{"${class}::${name}"}=sub { my $self=shift; Net::DRI::Exception->die(0,'DRD',4,sprintf('No operation %s %s available for registry %s',@op,$self->name())); };
 }
 no strict 'refs'; ## no critic (ProhibitNoStrict)
 *{"${class}::unavailable_operations"}=sub { return @methods; };
 return;
}

####################################################################################################
## OBJECT METHODS

sub generate_trid
{
 my ($self,$name)=@_;
 if (! defined $name) { $name=$self->name(); }
 return $self->trid_factory()->($name);
}

sub log_setup_channel { my ($self,@r)=@_; $self->logging()->setup_channel(@r); return; }
sub log_output        { my ($self,@r)=@_; $self->logging()->output(@r) if $self->logging(); return; }

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::BaseClass - Superclass of various classes inside Net::DRI

=head1 SYNOPSIS

Not directly used by users, this is a purely internal class, never visible to the outside of Net::DRI.

=head1 DESCRIPTION

This is the superclass of some Net::DRI classes, providing various useful functions.

=head1 EXAMPLES

No user examples.

=head1 SUBROUTINES/METHODS

This is mostly a pure virtual superclass.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This modules has to be used inside the Net::DRI framework and needs the following composants:

=over

=item L<Net::DRI::Exception>

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

This should probably be better done with Moose and roles. It would however require a major overhaul
to everything inside Net::DRI, so this would probably not happen very soon, maybe with a Perl6 port.

This class was introduced very late in Net::DRI, multiple parts of this framework should be
modified to take advantage of this class.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
