## Domain Registry Interface, Encapsulating raw data
##
## Copyright (c) 2005-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Raw;

use strict;
use warnings;

use Data::Dumper ();
use Net::DRI::Exception;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(type data hint));

=pod

=head1 NAME

Net::DRI::Data::Raw - Encapsulating raw data for Net::DRI

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

Copyright (c) 2005-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$type,$data,$hint)=@_;

## type=1, data=ref to array
## type=2, data=string
## type=3, data=ref to string NOTIMPL
## type=4, data=path to local file NOTIMPL
## type=5, data=object with a as_string method
## type=6, data=complex object in a ref array

 my $self={type => $type,
           data => $data,
           hint => $hint || '',
          };

 bless($self,$class);
 return $self;
}


sub new_from_array
{
 my ($class,@args)=@_;
 my @a=map { my $f=$_; $f=~s/[\r\n\s]+$//; $f; } (ref $args[0] ? @{$args[0]} : @args);
 return $class->new(1,\@a);
}

sub new_from_string    { return shift->new(2,@_); } ## no critic (Subroutines::RequireArgUnpacking)
sub new_from_xmlstring { return shift->new(2,$_[0],'xml'); } ## no critic (Subroutines::RequireArgUnpacking)
sub new_from_object    { return shift->new(5,@_); } ## no critic (Subroutines::RequireArgUnpacking)

####################################################################################################

sub as_string
{
 my $self=shift;
 my $data=$self->data();

 if ($self->type()==1)
 {
  return join("\n",@$data)."\n";
 }
 if ($self->type()==2)
 {
  $data=~s/\r\n/\n/g;
  return $data;
 }
 if ($self->type()==5)
 {
  Net::DRI::Exception::method_not_implemented('as_string',ref $data) unless $data->can('as_string');
  return $data->as_string();
 }
 if ($self->type()==6)
 {
  return Data::Dumper->new($data)->Indent(2)->Varname('')->Quotekeys(0)->Sortkeys(1)->Dump();
 }
}

sub last_line
{
 my $self=shift;

 if ($self->type()==1)
 {
  my $data=$self->data();
  return $data->[-1]; ## see above
 }
 if ($self->type()==2)
 {
  my @a=$self->as_array();
  return $a[-1];
 }
}

sub as_array
{
 my $self=shift;

 if ($self->type()==1)
 {
  return @{$self->data()};
 }

 if ($self->type()==2)
 {
  return split(/\r?\n/,$self->data());
 }
}

####################################################################################################
1;
