## Domain Registry Interface, ICANN policy on reserved names
##
## Copyright (c) 2005-2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::ICANN;

use utf8;
use strict;
use warnings;

use Net::DRI::Util;

## See http://www.icann.org/en/resources/registries/rsep for changes (done until 2012004)
our %ALLOW1=map { $_ => 1 } qw/mobi coop biz pro cat info travel tel asia org/; ## Pending ICANN review: (none)
our %ALLOW2=map { $_ => 1 } qw/mobi coop name jobs biz pro cat info travel tel asia org/; ## Pending ICANN review: (none)

## See http://www.icann.org/en/about/agreements/registries
sub is_reserved_name
{
 my ($domain,$op)=@_;

 return '' if (defined $op && $op ne 'create');

 my @d=split(/\./,lc($domain));

 ## Tests at all levels
 foreach my $d (@d)
 {
  ## §A (ICANN+IANA reserved)
  return 'NAME_RESERVED_PER_ICANN_RULE_A' if ($d=~m/^(?:aso|gnso|icann|internic|ccnso|afrinic|apnic|arin|example|gtld-servers|iab|iana|iana-servers|iesg|ietf|irtf|istf|lacnic|latnic|rfc-editor|ripe|root-servers)$/o);

  ## §C (tagged domain names)
  return 'NAME_RESERVED_PER_ICANN_RULE_C' if (length($d)>3 && (substr($d,2,2) eq '--') && ($d!~/^xn--/));
 }

 ## .TEL specific rules
 ## per RSEP #2010012
 ## and http://telnic.org/downloads/GAShortNumericDomains.pdf (2011-06-13)
 ## (the latter being quite contradictory with RSEP #201008, hence this block must be here not later)
 if ($d[-1] eq 'tel')
 {
  return 'NAME_RESERVED_PER_ICANN_RULE_TEL_1CHAR'          if length $d[-2]==1;
  return 'NAME_RESERVED_PER_ICANN_RULE_TEL_2CHARS_CC'      if length $d[-2]==2 && exists $Net::DRI::Util::CCA2{$d[-2]};
  return 'NAME_RESERVED_PER_ICANN_RULE_TEL_DIGITS_HYPHENS' if $d[-2]=~m/^[\d-]+$/ && length $d[-2] > 7;
 }

 ## §B.1 (additional second level)
 return 'NAME_RESERVED_PER_ICANN_RULE_B1' if (length($d[-2])==1 && ! exists($ALLOW1{$d[-1]}));

 ## §B.2
 return 'NAME_RESERVED_PER_ICANN_RULE_B2' if (length($d[-2])==2 && ! exists($ALLOW2{$d[-1]}));

 ## §D (reserved for Registry operations)
 return 'NAME_RESERVED_PER_ICANN_RULE_D' if ($d[-2]=~m/^(?:nic|whois|www)$/o);

 ## .NAME specific rules
 if ($d[-1] eq 'name')
 {
  return 'NAME_RESERVED_PER_ICANN_RULE_NAME_J'  if (@d==2 && $d[-2]=~m/-(?:familie|family|perhe|famille|parivaar|keluarga|famiglia|angkan|rodzina|familia|mischpoche|umdeni)$/);
 }

 return '';
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::DRD::ICANN - ICANN policies for Net::DRI

=head1 SYNOPSIS

This module is never used directly, it is used by other DRD modules
for registries that follow ICANN policies on syntax of domain names.

More precisely, it is called from subroutine _verify_name_rules in
L<Net::DRI::DRD>.

=head1 DESCRIPTION

This module implements ICANN rules on domain names such as minimum and maximum length,
allowed characters, etc...

=head1 EXAMPLES

None.

=head1 SUBROUTINES/METHODS

=over

=item is_reserved_name()

returns a string if the name passed violates some ICANN policy on domain name
(the string being the ICANN rule name that was violated), 
and an empty string otherwise (meaning success).

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

This module has to be used inside the Net::DRI framework and does not have any dependency.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

No known bugs. Please report problems to author (see below) or use CPAN RT system. Patches are welcome.

xn--something domain names are currently allowed as a temporary passthrough until L<Net::DRI> gets
full IDN support.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005-2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

