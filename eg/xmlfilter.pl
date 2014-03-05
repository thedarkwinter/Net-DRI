#!/usr/bin/perl -w
##

=pod

=head1 NAME

xmlfilter.pl - A command line client program using Net::DRI towards the
.NO EPP registry.

=head1 DESCRIPTION

This program is a small filter utility which acts an xml_pp (pretty-print)
function for the xml-dump output coming from Net::DRI Transport.pm log 
function.

The format in input is a long line like this:

 "2008-02-20 10:22:19.092865 C<=S [SOCKET_INET-92047-1203499339055994]\
  <?xml version="1.0" encoding="UTF-8" standalone="no" ?><epp xmlns=" .\
  .....</epp>"

This filter separates the date/time part and the xml-part and prints 
a pretty-print of the xml.

if the -s (skip) option is set, it suppresses the greeting, login and 
logout sequences.

=head1 COPYRIGHT

Copyright (c) 2008 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=cut

use strict;
use vars qw($opt_s);
use Getopt::Std;

# There are \0 chars in input, set binmode on stdin
binmode STDIN;
binmode STDOUT;
use XML::Twig;

&getopts('s');

my $tw = new XML::Twig(
    pretty_print    => 'indented',
    output_encoding => 'UTF-8',
);
my $fh = \*STDOUT;

my $skipnext;

while (<>) {

    #chomp;
    my $tp = $_;

    # .NO: changed the log output to a pretty-printed one

    if ( $tp =~ m|(^20\d\d.+C.+)(\<\?xml .+$)|msx ) {
        my $t = $1;
        my $s = $2;

        #print "t: $t\n";
        #print "s: $s\n\n\n";

        if ($opt_s) {
            if ($skipnext) {
                $skipnext = undef;
                next;
            }

            # skip dump of greeting, login, logout
            if ( $s =~ m/<greeting>/gmx ) {
                next;
            }
            if ( $s =~ m|<command><login>|gmx ) {
                ++$skipnext;
                next;
            }
            if ( $s =~ m|<command><logout/>|gmx ) {
                ++$skipnext;
                next;
            }

        }
        $tw->parse($s);

        $t = "";    # if ($opt_s);   # No timestamps either if skip is on

        my $tpp = $t . $tw->sprint;
        print {$fh} $tpp . "\n---\n\n";
    }
    else {
        print {$fh} $tp;
    }
}
