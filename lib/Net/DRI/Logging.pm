## Domain Registry Interface, Logging operations for Net::DRI
##
## Copyright (c) 2009-2010,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Logging;

use strict;
use warnings;

use base qw/Net::DRI::BaseClass/;
use Net::DRI::Util;
use Net::DRI::Exception;

__PACKAGE__->make_exception_if_not_implemented(qw/name setup_channel output/);

## Taken from Log::Log4Perl
our %LEVELS=qw/debug 0 info 1 notice 2 warning 3 error 4 critical 5 alert 6 emergency 7/;

####################################################################################################
## Public API

sub new
{
 my $c=shift;
 my $self=shift || {};
 if (! exists $self->{level}            || ! defined $self->{level} )            { $self->{level}           =3; }
 if (! exists $self->{xml_indent}       || ! defined $self->{xml_indent} )       { $self->{xml_indent}      =0; }
 if (! exists $self->{encoding}         || ! defined $self->{encoding} )         { $self->{encoding}        ='UTF-8'; }
 if (! exists $self->{format_header}    || ! defined $self->{format_header} )    { $self->{format_header}   ='%FULLTIME [%ULEVEL] <%TYPE>'; }
 if (! exists $self->{format_transport} || ! defined $self->{format_transport} ) { $self->{format_transport}='%TRID %UDIRECTION %MESSAGE'; }
 if (! exists $self->{format_protocol}  || ! defined $self->{format_protocol} )  { $self->{format_protocol} ='%TRID %UDIRECTION %MESSAGE'; }
 if (! exists $self->{sanitize_data}    || ! defined $self->{sanitize_data} )    { $self->{sanitize_data}   = {}; }
 bless $self,$c;
 $self->level($self->{level}); ## convert the level token to a numerical value
 return $self;
}

sub level
{
 my ($self,$level)=@_;
 if (defined $level)
 {
  if (exists $LEVELS{$level}) { $level=$LEVELS{$level}; }
  if ($level!~/^\d+$/ || $level > 7) { $self->output('error','logging','Invalid level value "'.$level.'", switching to default'); $level=3; }
  $self->{level}=$level;
 }
 return $self->{level};
}

####################################################################################################
## Internal API

sub string_header
{
 my ($self,$level,$type,$data)=@_;
 my $f=$self->{format_header};
 $f=~s/%FULLTIME/Net::DRI::Util::fulltime()/eg;
 $f=~s/%ULEVEL/uc($level)/eg;
 $f=~s/%TYPE/$type/g;
 return $f;
}

sub string_data
{
 my ($self,$hdr,$type,$data)=@_;
 if (! ref $data || ! exists $self->{'format_'.$type}) { return $hdr.q{ }.$data; }
 my $msg=$data->{message};
 my $ct=q{};
 my $ref=ref $msg;
 if ($ref)
 {
  if ($ref eq 'Net::DRI::Data::Raw')
  {
   $ct=$msg->hint();
  } else
  {
   if (! $msg->can('as_string')) { Net::DRI::Exception::method_not_implemented('as_string',ref $msg); }
  }
  $msg=$msg->as_string($self->{sanitize_data});
 }

 ## If this is deemed to be too brittle, a type() method could be added to Protocol/Message and correctly set to "xml" by Message classes in RRI,EPP,OpenSRS/XCP,IRIS/{XCP,LWZ}
 if (! length($ct) && substr($msg,0,5) eq '<?xml') { $ct='xml'; }

 if ($ct eq 'xml')
 {
  if ($self->{xml_indent})
  {
   $msg=Net::DRI::Util::xml_indent($msg);
  } else
  {
   $msg=~s/^\s+//mg;
   $msg=~s/\s+$//mg;
   $msg=~s/\n/ /g;
   $msg=~s/> </></g;
  }
 }

 $data->{all}=join q{ },map { $_.q{=}.(defined $data->{$_} ? $data->{$_} : '') } sort { $a cmp $b } keys %{$data}; ## this should be handy during debugging
 if (exists $data->{direction}) { $data->{udirection}=uc $data->{direction}; $data->{adirection}=$data->{direction} eq 'in'? 'C<=S' : 'C=>S';}
 my @r;
 foreach my $l (split /\n/,$msg)
 {
  my $f=$hdr.q{ }.$self->{'format_'.$type};
  $data->{message}=$l;
  $f=~s/%([A-Z]+)/$data->{lc $1} || ''/eg;
  push @r,$f;
 }
 return join qq{\n}, @r;
}

sub tostring
{
 my ($self,$level,$type,$data)=@_;
 my $hdr=$self->string_header($level,$type);
 my $r=$self->string_data($hdr,$type,$data);
 return Net::DRI::Util::encode($self->{encoding},$r);
}

sub should_log
{
 my ($self,$level)=@_;
 return ($LEVELS{$level} >= $self->{level})? 1 : 0;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Logging - Logging Operations for Net::DRI

=head1 SYNOPSIS

This module is never used directly, only its subclasses are used. See the subclasses
documentation: L<Net::DRI::Logging::Files>, L<Net::DRI::Logging::Null> and L<Net::DRI::Logging::Stderr>.
See also L<Net::DRI> documentation and its C<logging()> method.

=head1 DESCRIPTION

This is the superclass of all logging modules (under the L<Net::DRI::Logging::*> namespace).

=head1 EXAMPLES

See L<Net::DRI> documentation.

=head1 SUBROUTINES/METHODS

This is mostly a pure virtual superclass. All subclasses should have the following methods:

=over

=item new()

a ref hash is passed with some keys ; besides keys specifically related to the logging
class used, some keys are (or should be) understood by all clases.

They are:

=over

=item level

current level of logging (no messages below this level would be dumped), between:
debug info notice warning error critical alert emergency ; default: warning

It can be changed anytime later by using the level() method

=item xml_indent

0 or 1 depending if you want your XML strings to be dumped as a long line (0) or indented for humans (1) ; default: 0

=item encoding

if needed, name of encoding to use to convert data stream ; default: UTF-8

=item sanitize_data

an optional ref hash to know which part of logged data should be replaced to ensure confidentiality;
for now it works only for EPP, with the hash key "session_password" and a true value, then content
of <pw> and <newPW> are replaced by a string of * in logging data

=back

=item name()

returns the name as string of the logging modules

=item setup_channel(SOURCE,TYPE,DATA)

prepare for a new channel of data comming from SOURCE (package name), of TYPE ;
DATA is a ref hash of additional parameter, such as filenames, etc.

=item output(LEVEL,TYPE,DATA1,DATA2,...)

add data to channel type TYPE at level LEVEL ('debug', 'info', 'notice', etc.) ;
DATA is a ref hash with all data to log or a simple string (the message) ; the logging module should know what
to do with it and how to format it (which may depend on the TYPE attribute, which itself
is tied to the SOURCE attribute of C<setup_channel()>).

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

See the C<new()> method.

=head1 DEPENDENCIES

This module has to be used inside the Net::DRI framework and needs the following components:

=over

=item L<Net::DRI::BaseClass>

=item L<Net::DRI::Util>

=item L<Net::DRI::Exception>

=back

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

The interface could be later changed to suit Log::Log4Perl or other Perl standard logging modules, if needed.

Other subclasses should be created to cater for other logging destinations (such as a RDBMS).

L<Net::DRI> expects these logging modules to be non-blocking and returning immediately.

This logging framework is currently only used by L<Net::DRI::Transport::Socket>, it should
get applied to other transports and other internal parts of L<Net::DRI>.

When LocalStorage do appear inside Net::DRI, logging should probably use it (TODO).

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2010,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
