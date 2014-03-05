## Domain Registry Interface, Encapsulatng errors (fatal or not) as exceptions in an OO way
##
## Copyright (c) 2005,2007-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Exception;

use strict;
use warnings;

use Carp;

=pod

=head1 NAME

Net::DRI::Exception - Class to store all exceptions inside Net::DRI

=head1 SYNOPSIS

 my $s=Net::DRI::Exception->new(0,'area',500,'message');
 die($s);
 ## OR
 Net::DRI::Exception->die(0,'area',500,'message');

 $s->is_error(); ## gives 0 or 1, first argument of new/die
 ## (internal error that should not happen are 1, others are 0)

 $s->area(); ## gives back the area (second argument of new/die)

 $s->code(); ## gives back the code (third argument of new/die)

 $s->msg(); ## gives back the message (fourth argument of new/die)

 $s->as_string(); ## gives back a nicely formatted full backtrace

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2007-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($class,$error,$area,$code,$msg)=@_;
 my $self={ is_error => (defined $error ? $error : 1 ),
            area     => $area || '?',
            code     => $code || 0,
            msg      => $msg || '',
          };

 $self->{bt}=Carp::longmess();

 bless $self,$class;
 return $self;
}

sub die { die(new(@_)); } ## no critic (Subroutines::ProhibitBuiltinHomonyms Subroutines::RequireArgUnpacking)

sub is_error { return shift->{is_error}; }
sub area     { return shift->{area};     }
sub code     { return shift->{code};     }
sub msg      { return shift->{msg};      }

sub backtrace
{
 my $self=shift;
 my $m=$self->{bt};
 my (@bt1,@bt2);
 foreach (split(/\n/,$m)) { if (/^\s*Net::DRI::(?:BaseClass|Exception)::/) { push @bt1,$_; } else { push @bt2,$_; } }
 shift(@bt2) if ($bt2[0]=~m!Net/DRI/BaseClass!);
 shift(@bt2) if ($bt2[0]=~m!Net/DRI/Exception!);
 my ($f,$l);
 if (@bt1)
 {
  ($f,$l)=(pop(@bt1)=~m/ called at (\S+) line (\d+)\.?\s*$/);
 } else
 {
  ($f,$l)=(shift(@bt2)=~m/ at (\S+) line (\d+)\.?\s*$/);
 }
 my @b;
 push @b,sprintf('EXCEPTION %d@%s from line %d of file %s:',$self->code(),$self->area(),$l,$f);
 push @b,$self->msg();
 return (@b,@bt2);
}

## Do not parse result of this call. If needed, use accessors above (is_error(), area(), code(), msg())
sub as_string { return join("\n",shift->backtrace())."\n"; }
sub print     { print shift->as_string(); } ## no critic (Subroutines::ProhibitBuiltinHomonyms Subroutines::RequireFinalReturn)

####################################################################################################

sub err_failed_load_module { my ($w,$m,$e)=@_; Net::DRI::Exception->die(1,$w,8,'Failed to load Perl module '.$m.' : '.(ref($e)? $e->as_string() : $e)); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub err_insufficient_parameters { Net::DRI::Exception->die(1,'internal',2,'Insufficient parameters'.($_[0]? ': '.$_[0] : '')); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub err_invalid_parameters      { Net::DRI::Exception->die(1,'internal',3,'Invalid parameters'.($_[0]? ': '.$_[0] : '')); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)

sub usererr_insufficient_parameters { Net::DRI::Exception->die(0,'internal',2,'Insufficient parameters'.($_[0]? ': '.$_[0] : '')); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub usererr_invalid_parameters      { Net::DRI::Exception->die(0,'internal',3,'Invalid parameters'.($_[0]? ': '.$_[0] : '')); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)

sub err_assert { Net::DRI::Exception->die(1,'internal',4,'Assert failed'.($_[0]? ': '.$_[0] : '')); } ## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)

sub method_not_implemented ## no critic (Subroutines::RequireFinalReturn)
{
 my ($m,$w)=@_;
 ($w)=split(/=/,$w);
 Net::DRI::Exception->die(1,'internal',1,sprintf('Method "%s" not implemented in "%s"',$m,$w));
}

####################################################################################################
1;
