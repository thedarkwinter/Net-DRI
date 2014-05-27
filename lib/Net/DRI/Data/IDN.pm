## Domain Registry Interface, Handling of IDN data
##
## Copyright (c) 2005-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Data::IDN;

use utf8;
use strict;
use warnings;
use base qw(Class::Accessor::Chained); ## provides a new() method

our @ATTRS=qw(uname aname script language variants extlang iso639_1 iso639_2 iso15924);
__PACKAGE__->mk_accessors(@ATTRS);

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::IDN::Encode;
use Locale::Language;
use Locale::Script;


####################################################################################################

# autodetect asci / unicode
sub autodetect
{
  my  ($self,$n,$c) = @_;
  if ($n =~ m/^[A-Za-z0-9-.]*$/) 
  {
    $self->aname($n);
    $self->uname(Net::IDN::Encode::domain_to_unicode($n));
  } else {
    $self->aname(Net::IDN::Encode::domain_to_ascii($n));
    $self->uname($n);
  }
  return $self unless $c; ## or work out codes

  $self->_from_iso639_1($c) if $c =~ m/^\w{2}$/;
  $self->_from_iso639_1_extlang($c) if $c =~ m/^\w{2}-[a-z]{2,}$/;
  $self->_from_iso639_2($c) if $c =~ m/^\w{3}$/;
  $self->_from_iso15924($c) if $c =~ m/^\w{4}$/;
  $self->_from_iso639_2_15924($c) if $c =~ m/^\w{3}-[A-Z][a-z]{3}$/;
  $self->_from_language($c) if $c =~ m/^\w{4,}/;
  return $self;
}

sub _from_iso639_1
{
  my ($self,$c) = @_;
  $self->iso639_1($c);
  $self->iso639_2(language_code2code($c,LOCALE_LANG_ALPHA_2,LOCALE_LANG_ALPHA_3));
  $self->language(code2language($c),LOCALE_LANG_ALPHA_2);
  return;
}

sub _from_iso639_1_extlang
{
  my ($self,$c) = @_;
  return unless $c =~ m/^(\w{2})-([a-z]{2,})$/;
  $self->extlang($2);
  return $self->_from_iso639_1($1);
}

sub _from_iso639_2
{
  my ($self,$c) = @_;
  $self->iso639_2($c);
  $self->iso639_1(language_code2code($c,LOCALE_LANG_ALPHA_3,LOCALE_LANG_ALPHA_2));
  $self->language(code2language($c),LOCALE_LANG_ALPHA_3);
  return;
}

sub _from_iso15924
{
  my ($self,$c) = @_;
  $self->script($c);
  $self->iso15924($c);
  return;
}

sub _from_iso639_2_15924
{
  my ($self,$c) = @_;
  my ($c1,$c2) = split '-',$c;
  $self->_from_iso639_2($c1);
  $self->_from_iso15924($c2);
  return;
}

sub _from_language
{
  my ($self,$c) = @_;
  $self->language($c);
  $self->iso639_1(language2code($c));
  $self->iso639_2(language_code2code($c,LOCALE_LANG_ALPHA_2,LOCALE_LANG_ALPHA_3));
  return;
}

sub clone
{
 my ($self)=@_;
 my $new=Net::DRI::Util::deepcopy($self);
 return $new;
}

####################################################################################################
1;
