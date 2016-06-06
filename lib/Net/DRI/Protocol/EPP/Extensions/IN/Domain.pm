## Domain Registry Interface, .IN Domain EPP extension commands [https://registry.in/system/files/IN_EPP_OTE_Criteria_v3.0.pdf]
##
## Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
## Copyright (c) 2013-2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::IN::Domain;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Format::ISO8601;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Data::Hosts;
use utf8;

use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IN::Domain - .IN EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

David Makuni <d.makuni@live.co.uk>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
Copyright (c) 2014-2016 David Makuni <d.makuni@live.co.uk>. All rights reserved.
Copyright (c) 2013-2016 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
	my ( $class, $version)=@_;
	my %tmp=(
		update => [ \&update, undef ],
	);

	return { 'domain' => \%tmp };
}

## .IN Trademark Options: name, country, number, date, ownerCountry

####################################################################################################

sub update {
  my ($epp,$domain,$rd)=@_;
  my (@t,@u,$rt);

  # Check trademark is present OR return
	return unless defined $rd->set('trademark') || $rd->del('trademark') ;
  if (defined $rd->set('trademark')) {
    $rt=$rd->set('trademark');
  } elsif (defined $rd->del('trademark')) {
    $rt=$rd->del('trademark');
  }

  # Build trademark name, country, number, ownerCountry
  foreach my $k (qw/name number country ownerCountry/) {
    next unless exists $rt->{$k} && length $rt->{$k};
    push @t,['trademark:'.$k,$rt->{$k}];
  }

  # Build trademark date
  if (exists $rt->{'date'}) {
    Net::DRI::Exception::usererr_invalid_parameters("Trademark date must be a 'DateTime' object")
      unless (Net::DRI::Util::check_isa($rt->{'date'},'DateTime'));
    push @t,['trademark:date',$rt->{'date'}->set_time_zone('UTC')->ymd()];
  }

  # Build domain trademark removal (if present)
  @t = ['trademark:rem',@t] if $rd->del('trademark');

  my $mes=$epp->message();
  my $eid=$mes->command_extension_register('trademark:update',sprintf('xmlns:trademark="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('trademark')));
  $mes->command_extension($eid,\@t);

  return;
}

####################################################################################################
1;
