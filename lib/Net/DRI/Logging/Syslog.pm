## Domain Registry Interface, SYSLOG Logging operations for Net::DRI
##
## Copyright (c) 2009,2013 Jørgen Thomsen <netdri@jth.net>. All rights reserved
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

package Net::DRI::Logging::Syslog;

use utf8;
use strict;
use warnings;

use base qw/Net::DRI::Logging/;

use Sys::Syslog qw(:DEFAULT);

####################################################################################################

sub new
{
 my ($class,$data)=@_;
 my $self=$class->SUPER::new($data);
 if (! exists $self->{ident} || ! defined $self->{ident} ) { $self->{ident} = 'NetDRI'; }
 if (! exists $self->{priority} || ! defined $self->{priority} ) { $self->{priority} = 'info'; }
 if (! exists $self->{options} || ! defined $self->{options} ) { $self->{options} = 'pid,nofatal'; }
 if (! exists $self->{facility} || ! defined $self->{facility} ) { $self->{facility} = 'local3'; }
 if (! exists $self->{logopened} || ! defined $self->{logopened} ) { $self->{logopened} = 0; }
 return $self;
}

sub name { return 'syslog'; }

sub setup_channel {
my ($self,$source,$type,$data)=@_;
	$self->{format_header} ='[%ULEVEL] <%TYPE>';
	# either opened by caller: 1 or opened here: 2
	if (exists $self->{logopened} && defined($self->{logopened}) && $self->{logopened} > 0) { return; }

	openlog($self->{ident}, $self->{options}, $self->{facility});
	$self->{logopened} = 2;
	return;
}

sub output
{
 my ($self,$level,$type,$data)=@_;
 if ($self->should_log($level)) {
	my @lines = split( /\n/, $self->tostring($level,$type,$data) ); # log each indented line when xml_indent => 1
	foreach (@lines) {
               syslog($self->{priority}, ($self->{logopened} != 2 ? $self->{ident}.': ':'')."%s", $_);
	}
 }
 return;
}

sub DESTROY
{
 my ($self)=@_;
 closelog() if $self->{logopened} == 2; # we opened it
 return;
}
####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Logging::Syslog - SYSLOG Logging Operations for Net::DRI

=head1 SYNOPSIS

See L<Net::DRI::Logging>

=head1 DESCRIPTION

This class dumps all logging information to SYSLOG.

=head1 EXAMPLES

	$dri=Net::DRI->new({cache_ttl => 10,
		logging => ['syslog',
					{
					level => 'warning',
					xml_indent => 0,
					ident => 'NetDRI',
					priority => 'info',
					facility => 'local3',
					options => 'pid,nofatal',
					logopened => 0
					}
					]
	});

	The values above are the default

=over 2

=item - level, xml_ident

refer to L<Net::DRI::Logging>


=item - ident, priority, facility, options

refer to L<Sys::Syslog>


=item - logopened

Value 1: Sys::Syslog::openlog() already called, so do not call it in this
module, but still specify ident, priority, and facility, if the defaults
are not wanted

=back

=head1 SUBROUTINES/METHODS

All mandated by superclass L<Net::DRI::Logging>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This modules has to be used inside the Net::DRI framework and needs the
following components:

Sys::Syslog

=over

=item L<Net::DRI::Logging>

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT
system. Patches are welcome.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@jth.netE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Jørgen Thomsen, E<lt>netdri@jth.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Jørgen Thomsen <netdri@jth.net>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
