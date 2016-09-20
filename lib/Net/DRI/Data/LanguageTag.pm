## Domain Registry Interface, Language Tag parsing (RFC5646)
##
## Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::LanguageTag;

use strict;
use warnings;
use feature 'state';

use Sub::Name;

use overload '""'  => sub { my ($self, @rest) = @_; return $self->as_string(); },
             '@{}' => sub { my ($self, @rest) = @_; return [ $self->subtags() ]; },
             '.'   => sub { my ($self, $toadd, $swap) = @_; mydie('Left adding subtags is not implemented') if $swap; return $self->add_subtag($toadd); },
             'cmp' => sub { my ($self, $other, $swap) = @_; my $r = "${self}" cmp "${other}"; return $swap ? -$r : $r; }, ## should we compare subtags one by one?
             'fallback' => undef;

my $digit=qr/[0-9]/;
my $alpha=qr/[A-Za-z]/;
my $alphanum=qr/${digit}|${alpha}/;

my $irregular=qr/en-GB-oed|i-ami|i-bnn|i-default|i-enochian|i-hak|i-klingon|i-lux|i-mingo|i-navajo|i-pwn|i-tao|i-tay|i-tsu|sgn-BE-FR|sgn-BE-NL|sgn-CH-DE/i;
my $regular=qr/art-lojban|cel-gaulish|no-bok|no-nyn|zh-guoyu|zh-hakka|zh-min|zh-min-nan|zh-xiang/i;
my $grandfathered=qr/${irregular}|${regular}/;

my $privateuse=qr/x(?:-${alphanum}{1,8})+/i; ## TODO check if lower bound is indeed 1 ! is this like an extension, and hence need to be checked

my $extlang=qr/${alpha}{3}(?:-${alpha}{3}){0,2}/;
my $language=qr/(?:${alpha}{2,3}(-${extlang})?)|${alpha}{4}|${alpha}{5,8}/;

my $script=qr/${alpha}{4}/;
my $region=qr/${alpha}{2}|${digit}{3}/;
my $variant=qr/${alphanum}{5,8}|${digit}${alphanum}{3}/;

my $singleton=qr/${digit}|[A-W]|[Y-Z]|[a-w]|[y-z]/;
my $extension=qr/${singleton}(?:-${alphanum}{2,8})+/;

my $langtag=qr/(?<language>${language})(?<script>(-${script})?)(?<region>(-${region})?)(?<variant>(-${variant})*)(?<extension>(-${extension})*)(?<privateuse>(-${privateuse})?)/;

## §2.1.1 : At all times, language tags and their subtags, including private use and extensions, are to be treated as case insensitive
my $TAG=qr/(?<langtag>${langtag})|(?<privateuse>${privateuse})|(?<grandfathered>${grandfathered})/i;

my $mydie;
if (exists $INC{'Net/DRI.pm'})
{
 require Net::DRI::Exception;
 $mydie=sub { Net::DRI::Exception->usererr_invalid_parameters(@_); };
} else
{
 require Carp;
 $mydie=\&Carp::croak;
}
*mydie=$mydie;
subname 'mydie', $mydie;

sub new
{
 my ($class,$tag)=@_;
 my $self={};
 bless $self,$class;
 mydie('No tag to parse') unless defined $tag && length $tag;
 $self->_parse($tag);
 return $self;
}

my @okeys=qw/type language script region variant extension privateuse/;

## This also checks syntax and canonicalize (for parts that can be done without access to the langtag registry)
sub _parse
{
 my ($self,$tag)=@_;

 mydie(qq{Tag "$tag" does not validate as a "Language Tag" per RFC5646 rules}) unless $tag=~/^${TAG}$/;

 my %build;
 ## regular grandfathered tags will fall into the 'langtag' case as the re is parsed left to right
 $build{type}=exists $+{langtag} ? 'langtag': ( exists $+{privateuse} ? 'privateuse' : 'grandfathered');
 if ($build{type} eq 'langtag')
 {
  $build{language}=[ _format_subtags(0,grep { length } split(/-/,$+{language})) ];
  $build{script}=[ _format_subtags(1,grep { length } split(/-/,$+{script})) ];
  $build{region}=[ _format_subtags(1,grep { length } split(/-/,$+{region})) ];

  $build{variant}=[ _format_subtags(1,grep { length } split(/-/,$+{variant})) ];
  # §2.2.5 point 5
  {
   my %seen;
   foreach my $variant (@{$build{variant}})
   {
    if (exists $seen{$variant})
    {
     mydie(qq{Variant element "${variant}" can not appear more than once in language tag});
    }
    $seen{$variant}=1;
   }
  }

  my @exts=_format_subtags(1,grep { length } split(/-/,$+{extension}));
  # §2.2.6 point 3
  {
   my %seen;
   foreach my $extension (grep { length == 1 } @exts)
   {
    if (exists $seen{$extension})
    {
     mydie(qq{Extension singleton "${extension}" can not appear more than once in language tag});
    }
    $seen{$extension}=1;
   }
  }
  # §2.2.6 point 6
  mydie(q{In extension subtag, singletons can not follow one another}) if join('',map { length == 1 ? 1 : 0 } @exts)=~m/11/; ## TODO: check if this is possible (not with above regex anyway!)
  # §4.5 canonicalization (only part that can be done without the registry)
  # "Extension sequences are ordered into case-insensitive ASCII order by singleton subtag."
  {
   @exts=(join('-',@exts)=~m/(${singleton}(?:-${alphanum}{2,8})+)+/g);
   # uncoverable branch true (lc $a->[0] cmp lc $b->[0] can never be false (Devel::Cover sees it as unless …) because that would mean $a->[0] eq $b->[0] which means twice the same singleton which is something checked above already anyway)
   $build{extension}=[ map { ($_->[0],split(/-/,$_->[1])) } sort { lc $a->[0] cmp lc $b->[0] || lc $a->[1] cmp lc $b->[1] } map { [ split(/-/,$_,2) ] } @exts ];
  }

  $build{privateuse}=[ _format_subtags(1,grep { length } split(/-/,$+{privateuse})) ];

  $build{tags}=[ map { @{$build{$_}} } qw/language script region variant extension privateuse/ ];
 } else
 {
  $build{tags}=[ _format_subtags(0,split(/-/,$tag)) ];
 }

 ## Everything went through nicely, time to update the structure;
 ## ('tags' key will be always populated, no need to clean it first)
 delete @$self{@okeys};
 @$self{keys %build}=values %build;
 return;
}

# §2.1.1 Formatting of Language Tags
sub _format_subtags
{
 my ($notfirst,@tags)=@_;

 ## inline static list in order not to depend on locale subsystem where we run
 state $lc={ qw/A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z/ };
 state $up={ reverse %$lc };

 my @t;
 foreach my $ti (0..$#tags)
 {
  my $t=$tags[$ti];
  mydie(qq{Subtag "$t" is too long}) if length $t > 8; ## 2.1 Syntax: All subtags have a maximum length of eight characters.
  ## lowercase everything, except:
  ## two-letter and four-letter subtags that neither appear at the start of the tag nor occur after singletons.
  ## (upercase everything for two-letter, and titlecase for four-letter)
  if (($notfirst || $ti != 0) && length $tags[$ti-1] > 1)
  {
   if (length $t == 2)
   {
    push @t,join('',map { defined $up->{$_} ? $up-> {$_} : $_ } split(//,$t)); ## Devel::Cover does not handle // correctly, hence using the longer form
    next;
   } elsif (length $t == 4)
   {
    my ($first,$rest)=($t=~m/^(.)(...)$/);
    push @t,(defined $up->{$first} ? $up->{$first} : $first).(join('',map { defined $lc->{$_} ? $lc->{$_} : $_ } split(//, $rest))); ## See above comment on Devel::Cover
    next;
   }
  }
  push @t,join('',map { defined $lc->{$_} ? $lc->{$_} : $_ } split(//, $t)); ## See above comment on Devel::Cover
 }

 return @t;
}

sub type { return $_[0]->{type}; } ## no critic (Subroutines::RequireArgUnpacking)

sub _subtag
{
 my ($self,$item)=@_;
 my $ra=$self->{$item};
 return unless defined $ra;
 return wantarray ? @$ra : join('-',@$ra);
}

sub language   { return _subtag($_[0],'language');   } ## no critic (Subroutines::RequireArgUnpacking)
sub script     { return _subtag($_[0],'script');     } ## no critic (Subroutines::RequireArgUnpacking)
sub region     { return _subtag($_[0],'region');     } ## no critic (Subroutines::RequireArgUnpacking)
sub variant    { return _subtag($_[0],'variant');    } ## no critic (Subroutines::RequireArgUnpacking)
sub extension  { return _subtag($_[0],'extension');  } ## no critic (Subroutines::RequireArgUnpacking)
sub privateuse { return _subtag($_[0],'privateuse'); } ## no critic (Subroutines::RequireArgUnpacking)


sub subtags
{
 my ($self)=@_;
 return @{$self->{tags}} if wantarray;
 my %r;
 @r{@okeys}=@$self{@okeys};
 return \%r; ## in hashref context, all values are refarrays (or undef if not parsed at all), even for single valued items, such as script & region
}

sub as_string
{
 my ($self)=@_;
 return join('-',@{$self->{tags}});
}

sub add_subtag
{
 my ($self,$tag)=@_;
 mydie('Undefined subtag to add') unless defined $tag;
 return $self unless length $tag;
 my $try=$self->as_string().'-'.$tag;
 $self->_parse($try);
 return $self;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Data::LanguageTag - Language Tags (RFC5646) parsing for Net::DRI

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

Copyright (c) 2015,2016 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
