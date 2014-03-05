## Domain Registry Interface, ENUM.AT Options extension
## Contributed by Michael Braunoeder from ENUM.AT <michael.braunoeder@enum.at>
##
## Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::IOptions;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $NS='http://www.enum.at/rxsd/ienum43-options-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::IOptions - ENUM.AT Options EPP Mapping for Net::DRI

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

Copyright (c) 2006,2008,2013 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
                  info   => [ undef, \&parse_options ],
                  update => [ \&set_options, undef ],
                  #create => [ \&set_options, undef ],
         );

 return { 'domain' => \%tmp };
}

sub capabilities_add { return ('domain_update','options',['set']); }

sub parse_options
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 my $condata=$mes->get_extension($NS,'options');
 return unless $condata;

 my @options;

 foreach my $el ($condata->getElementsByTagNameNS($NS,'naptr-application'))
 {
  my %opts;
  my $c=$el->getFirstChild();

  $opts{'naptr_application_origin'}  =$el->getAttribute('origin')   if (defined $el->getAttribute('origin'));
  $opts{'naptr_application_wildcard'}=$el->getAttribute('wildcard') if (defined $el->getAttribute('wildcard'));

  push @options,\%opts;
 }

 $rinfo->{domain}->{$oname}->{options}=\@options;
 return;
}

sub set_options
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $roptions=$rd->set('options');
 return unless (defined($roptions) && (ref($roptions) eq 'HASH') && keys(%$roptions));

 my %options;
 foreach my $d ('origin','wildcard')
 {
  next unless exists($roptions->{'naptr_application_'.$d});
  Net::DRI::Exception::usererr_invalid_paramaters("Option naptr_application_${d} must be of an XML boolean") unless Net::DRI::Utils::xml_is_boolean($roptions->{'naptr_application_'.$d});
  $options{$d}=$roptions->{'naptr_application_'.$d};
 }

 return unless keys(%options);

 my $eid=$mes->command_extension_register('ienum43:update','xmlns:ienum43="'.$NS.'" xsi:schemaLocation="'.$NS.' ienum43-options-1.0.xsd"');
 $mes->command_extension($eid,[['ienum43:options',['ienum43:naptr-application',\%options]]]);
 return;
}

####################################################################################################
1;
