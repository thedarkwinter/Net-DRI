package Net::DRI::Protocol::EPP::Extensions::RF;

use strict;

use base qw(Net::DRI::Protocol::EPP::Extensions::TCI);
our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub default_extensions { return qw(TCI::Contact TCI::Domain TCI::Registrar TCI::Billing SecDNS); }

####################################################################################################
1;
