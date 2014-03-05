## Domain Registry Interface, Handling of contact data
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

package Net::DRI::Data::Contact;

use utf8;
use strict;
use warnings;

use base qw(Class::Accessor::Chained); ## provides a new() method

our @ATTRS=qw(name org street city sp pc cc email voice fax loid roid srid auth disclose);
__PACKAGE__->register_attributes(@ATTRS);

use Net::DRI::Exception;
use Net::DRI::Util;

use Email::Valid;
use Encode (); ## we need here direct use of Encode, not through Net::DRI::Util::encode_* as we need the default substitution for unknown data

=pod

=head1 NAME

Net::DRI::Data::Contact - Handle contact data, modeled from EPP for Net::DRI

=head1 DESCRIPTION

This base class encapsulates all data for a contact as defined in EPP (RFC4933).
It can (and should) be subclassed for TLDs needing to store other data for a contact.
All subclasses must have a validate() method that takes care of verifying contact data,
and an id() method returning an opaque value, unique per contact (in a given registry).

The following methods are both accessors and mutators :
as mutators, they can be called in chain, as they all return the object itself.

Postal information through name() org() street() city() sp() pc() cc() can be provided twice.
EPP allows a localized form (content is in unrestricted UTF-8) and internationalized form
(content MUST be represented in a subset of UTF-8 that can be represented 
in the 7-bit US-ASCII character set). Not all registries support both forms.

When setting values, you pass wo elements as a list (first the localized form, 
then the internationalized one), or only one element that will be taken as the localized form.
When getting values, in list context you get back both values, in scalar context you get
back the first one, that is the localized form.

You can also use methods int2loc() and loc2int() to create one version from the other.
These 2 methods may be used automatically inside Net::DRI as needed, depending on what
the registry expects and the operation conducted (like a contact create).

=head1 METHODS

=head2 loid()

local object ID for this contact, never sent to registry (can be used to track the local db id of this object)

=head2 srid()

server ID, ID of the object as known by the registry in which it was created

=head2 id()

an alias (needed for Net::DRI::Data::ContactSet) of the previous method

=head2 roid()

registry/remote object id (internal to a registry)

=head2 name()

name of the contact

=head2 org()

organization of the contact

=head2 street()

street address of the contact (ref array of up to 3 elements)

=head2 city() 

city of the contact

=head2 sp()

state/province of the contact

=head2 pc()

postal code of the contact

=head2 cc()

alpha2 country code of the contact (will be verified against list of valid country codes)

=head2 email()

email address of the contact

=head2 voice()

voice number of the contact (in the form +CC.NNNNNNNNxEEE)

=head2 fax()

fax number of the contact (same form as above)

=head2 auth()

authentication for this contact (hash ref with a key 'pw' and a value being the password)

=head2 disclose()

privacy settings related to this contact (see RFC)

=head2 int2loc()

create the localized part from the internationalized part ; existing internationalized data is overwritten

=head2 loc2int()

create the internationalized part from the localized part ; existing localized data is overwritten ;
as the internationalized part must be a subset of UTF-8 when the localized one can be the full UTF-8,
this operation may creates undefined characters (?) as result

=head2 as_string()

return a string formed with all data contained in this contact object ; this is mostly useful for debugging and logging, this
string should not be parsed as its format is not guaranteed to remain stable, you should use the above accessors

=head2 attributes()

return an array of attributes name available in this contact object (taking into account any subclass specific attribute)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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
## Needed for ContactSet
sub id { my ($self,@args)=@_; return $self->srid(@args); }

sub register_attributes
{
 my ($class,@a)=@_;
 __PACKAGE__->mk_accessors(@a);
 no strict 'refs'; ## no critic (ProhibitNoStrict)
 ${$class.'::ATTRS'}=($class eq 'Net::DRI::Data::Contact')? \@a : [ @ATTRS,@a ];
 return ${$class.'::ATTRS'};
}

sub attributes
{
 my $class=shift;
 $class=ref($class) || $class;
 no strict 'refs'; ## no critic (ProhibitNoStrict)
 return @{${$class.'::ATTRS'}};
}

## Overrides method in Class::Accessor, needed for int/loc data
sub get
{
 my ($self,$what)=@_;
 return unless defined $what && $what && exists $self->{$what};
 my $d=$self->{$what};
 return $d unless ($what=~m/^(name|org|street|city|sp|pc|cc)$/);

 ## Special case for street because it is always a ref array, but a complicate one, we have either
 ## [ X, Y, Z ] (with Y and/or Z optional)
 ## [ undef, [ X, Y, Z ] ]
 ## [ [ X, Y, Z ] , undef ]
 ## [ [ X, Y, Z ], [ XX, YY, ZZ ] ]
 ## [ undef, undef ]
 if ($what eq 'street')
 {
  Net::DRI::Exception::usererr_invalid_parameters('Invalid street information, should be one or two ref arrays of up to 3 elements each') unless ref $d eq 'ARRAY';
  return wantarray ? ($d, undef) : $d unless 2==grep { ! defined $_ || ref $_ eq 'ARRAY' } @$d;
 } else
 {
  return $d unless ref $d eq 'ARRAY';
 }
 return wantarray ? @$d : $d->[0];
}

sub loc2int
{
 my $self=shift;
 foreach my $f (qw/name org city sp pc cc/)
 {
  my @c=$self->$f();
  $c[1]=defined $c[0] ? Encode::encode('ascii',$c[0],0) : undef;
  $self->$f(@c);
 }
 my @c=$self->street();
 if (defined $c[0])
 {
  $c[1]=[ map { defined $_ ? Encode::encode('ascii',$_,0) : undef } @{$c[0]} ];
 } else
 {
  $c[1]=$c[0]=[];
 }
 $self->street(@c);
 return $self;
}

sub int2loc
{
 my $self=shift;
 foreach my $f (qw/name org street city sp pc cc/)
 {
  my @c=$self->$f();
  $c[0]=$c[1]; ## internationalized form is a subset of UTF-8 and localized form is full UTF-8
  $self->$f(@c);
 }
 return $self;
}

sub has_loc { return shift->_has(0); }
sub has_int { return shift->_has(1); }
sub _has
{
 my ($self,$pos)=@_;
 my @d=map { ($self->$_())[$pos] } qw/name org city sp pc cc/;
 my $s=($self->street())[$pos];
 push @d,@$s if defined $s && ref $s eq 'ARRAY';
 return (grep { defined } @d)? 1 : 0;
}

sub validate ## See RFC4933,§4
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 if (!$change)
 {
  my @missing=grep { my $r=scalar $self->$_(); (defined $r && length $r)? 0 : 1 } qw/name city cc email auth srid/;
  Net::DRI::Exception::usererr_insufficient_parameters('Mandatory contact information missing: '.join('/',@missing)) if @missing;
  push @errs,'srid' unless Net::DRI::Util::xml_is_token($self->srid(),3,16);
 }

 push @errs,'srid' if ($self->srid() && ! Net::DRI::Util::xml_is_token($self->srid(),3,16));
 push @errs,'name' if ($self->name() && grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) }     ($self->name()));
 push @errs,'org'  if ($self->org()  && grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } ($self->org()));

 my @rs=($self->street());
 foreach my $i (0,1)
 {
  next unless defined $rs[$i];
  push @errs,'street' if ((ref($rs[$i]) ne 'ARRAY') || (@{$rs[$i]} > 3) || (grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } @{$rs[$i]}));
 }

 push @errs,'city' if ($self->city() && grep { !Net::DRI::Util::xml_is_normalizedstring($_,1,255) }     ($self->city()));
 push @errs,'sp'   if ($self->sp()   && grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } ($self->sp()));
 push @errs,'pc'   if ($self->pc()   && grep { !Net::DRI::Util::xml_is_token($_,undef,16) }             ($self->pc()));
 push @errs,'cc'   if ($self->cc()   && grep { !Net::DRI::Util::xml_is_token($_,2,2) }                  ($self->cc()));
 push @errs,'cc'   if ($self->cc()   && grep { !exists($Net::DRI::Util::CCA2{uc($_)}) }                 ($self->cc()));

 push @errs,'voice' if ($self->voice() && ! ($self->voice()=~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/));
 push @errs,'fax'   if ($self->fax()   && ! ($self->fax()=~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/));
 push @errs,'email' if ($self->email() && ! (Net::DRI::Util::xml_is_token($self->email(),1,undef)  && Email::Valid->rfc822($self->email())));

 my $ra=$self->auth();
 push @errs,'auth' if ($ra && (ref($ra) eq 'HASH') && exists($ra->{pw}) && !Net::DRI::Util::xml_is_normalizedstring($ra->{pw}));

 ## Nothing checked for disclose

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub as_string
{
 my ($self,$sep)=@_;
 $sep='|' unless (defined($sep) && $sep);
 my $st=$self->street();
 my @v=grep { defined } ($self->srid(),$self->name(),$self->org(),defined($st)? join(' // ',@$st) : undef,$self->city(),$self->sp(),$self->pc(),$self->cc(),$self->voice(),$self->fax(),$self->email());
 my @ot=grep { ! /^(?:name|org|street|city|sp|pc|cc|email|voice|fax|loid|roid|srid|auth|disclose)$/ } sort(keys(%$self));
 foreach my $ot (@ot) ## extra attributes defined in subclasses
 {
  my $v=$self->$ot();
  next unless defined($v);
  if (ref($v) eq 'HASH')
  {
   my @iv=sort(keys(%$v));
   my @r;
   foreach my $k (@iv)
   {
    push @r,sprintf('%s.%s=%s',$ot,$k,defined($v->{$k})? $v->{$k} : '<undef>');
   }
   push @v,join(' ',@r);
  } else
  {
   push @v,$ot.'='.$v;
  }
 }

 my $c=ref($self);
 $c=~s/^Net::DRI::Data:://;
 return '('.$c.') '.join($sep,@v);
}

sub clone
{
 my ($self)=@_;
 my $new=Net::DRI::Util::deepcopy($self);
 return $new;
}

####################################################################################################
1;
