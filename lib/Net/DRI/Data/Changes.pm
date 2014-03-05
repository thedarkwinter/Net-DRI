## Domain Registry Interface, Handle bundle of changes
##
## Copyright (c) 2005,2008,2011,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Changes;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Data::Changes - Bundle of changes in Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2008,2011,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

##############################################################################################################################

sub new
{
 my ($class,$type,$op,$el)=@_;

 my $self={}; ## { 'type' => [ toadd, todel, toset ] }   type=host,ip,status,contact,etc...
 bless($self,$class);

 if (defined($type) && defined($op) && defined($el))
 {
  $self->{$type}=[];
  $self->{$type}->[0]=$el if ($op=~m/^(?:0|add)$/);
  $self->{$type}->[1]=$el if ($op=~m/^(?:1|del)$/);
  $self->{$type}->[2]=$el if ($op=~m/^(?:2|set)$/);
 }

 return $self;
}

sub new_add { return shift->new(shift,'add',shift); }
sub new_del { return shift->new(shift,'del',shift); }
sub new_set { return shift->new(shift,'set',shift); }

sub types
{
 my ($self,$type)=@_;
 if (! defined $type)
 {
  my @r=sort { $a cmp $b } keys %$self;
  return @r;
 }
 my @r;
 return @r unless (exists($self->{$type}) && defined($self->{$type}));
 push @r,'add' if (defined($self->{$type}->[0]));
 push @r,'del' if (defined($self->{$type}->[1]));
 push @r,'set' if (defined($self->{$type}->[2]));
 return @r;
}

sub _el
{
 my ($self,$pos,$type,$new)=@_;
 unless (defined($new))
 {
  return unless (exists($self->{$type}) && defined($self->{$type}));
  return $self->{$type}->[$pos];
 }
 $self->{$type}=[] unless (exists($self->{$type}));
 $self->{$type}->[$pos]=$new;

 return $self;
}

sub add { return shift->_el(0,shift,shift); }
sub del { return shift->_el(1,shift,shift); }
sub set { return shift->_el(2,shift,shift); }

sub all_defined
{
 my ($self,$type)=@_;
 return () unless (defined($type) && $type && exists($self->{$type}) && defined($self->{$type}));
 return (grep { defined } @{$self->{$type}});
}

sub is_empty
{
 my $self=shift;
 my @o=map { $self->all_defined($_) } $self->types();
 return @o? 0 : 1;
}

##############################################################################################################################
1;
