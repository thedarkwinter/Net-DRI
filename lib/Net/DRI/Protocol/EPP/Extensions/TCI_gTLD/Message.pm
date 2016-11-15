package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Message;

use strict;
use warnings;
use utf8;
use base qw(Net::DRI::Protocol::EPP::Message);
our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

sub parse_greeting
{
 my ($self,$g)=@_;

 my $tmp = $self->SUPER::parse_greeting($g);

 my @svcs = map {(split(/\s+/, $_))[0]} @{$tmp->{svcs}};
 $tmp->{svcs} = \@svcs;
 
 my @svcext = map {(split(/\s+/, $_))[0]} @{$tmp->{svcext}};
 $tmp->{svcext} = \@svcext;
 
 return $tmp; 
}

1;

