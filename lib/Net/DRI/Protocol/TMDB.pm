## Domain Registry Interface,  TMDB Protocol (Based TMDB System Registrar Manul 2.3 and http://tools.ietf.org/html/draft-lozano-tmch-func-spec-09)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
####################################################################################################

package Net::DRI::Protocol::TMDB;

use utf8;
use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::TMDB::Message;

=pod

=head1 NAME

Net::DRI::Protocol::TMDB - TMDB Protocol (Based TMDB System Registrar Manul 2.2 and http://tools.ietf.org/html/draft-lozano-tmch-func-spec-09) for Net::DRI

=head1 DESCRIPTION

TMDB Protocol for L<NET::DRI>. The module inplements the TMDB (Trademark Database) protocol using namespace: tmNotice-1.0 based on draft-lozano-tmch-func-spec-09. This currently only supports SMDRL and CNIS operations. DNL and LORDN are not supported (unless someone from a registry adds it)

=head1 SYNOPSIS

Currently used by L<Net::DRI::DRD::TMDB>

  $dri->add_registry('TMDB');

  # settings for CNIS and SMDRL servers are different, so they should be added to the protocol_params
  my $cnis_creds = { server=>'test.tmcnis.org', realm=>'tmcnis -OT&E service', username=>'cnisXXX', password=>'XYZ123' };
  my $smdrl_creds = { server=>'test.ry.marksdb.org', realm=>'marksdb -OT&E service', username=>'smdrlXXX', password=>'XYZ123' };

  # transport_paramters: remote_url is ignored but required
  $dri->target('TMDB')->add_current_profile('p1','tmdb',{clid=>123,remote_url=>'http://localhost/'}, {cnis => $cnis_creds, smdrl => $smdrl_creds });

  # methods
  $dri->smdrl_fetch(); # you could just use wget as this is a CSV file that you probably don't want to open with Net::DRI (?)
  $dri->smdrl_fetch_sig(); # get the signature - not internally verified, you can optionally do so using this
  $dri->cnis_looukp($lookup_key); # get the CNIS data. I would advise seeing the test file for info on the results.

=head1 METHODS:

=head2 smdrl_fetch

You can fetch the smdrl fil

 $rc = $dri->smdrl_fetch();
 my $smdrl = $dri->get_info('self');
 my $smdid = $smdrl->{smdlist}->[0]; #  a list of smd ids
 my $revoked_date = $smdrl->{$smdid}; # date revoked
 my $raw = $dri->get_info('raw'); # save it to file, if thats what you want

=head2 smdrl_fetch_sig

You can fetch the signature to to verify the smdrl file. Note, no internal validation is done

 $rc = $dri->smdrl_fetch_sig();
 my $sig = $dri->get_info('sig');

=head2 cnis_looukp($lookup_key);

See the test file for more details:

 $rc = $dri->cnis_lookup('abc123');
 $cnis_id = $dri->get_info('id');
 $not_after = $dri->get_info('not_after');
 my @claims = @{$dri->get_info('claim')};
  .. etc
  
=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. 
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 my ($c,$ctx,$rp)=@_;
 my $drd=$ctx->{registry}->driver();
 my $self=$c->SUPER::new($ctx);
 $self->name('TMDB');
 my $version=Net::DRI::Util::check_equal($rp->{version},['1.0'],'1.0');
 $self->version($version);

 $self->ns({ _main   => ['urn:ietf:params:xml:ns:tmNotice-1.0','tmNotice-1.0'],
                         mark => ['urn:ietf:params:xml:ns:mark-1.0','mark-1.0'],
                        });
 
 # set cnis / smd creds
 $self->factories('message',sub { 
        my $m=Net::DRI::Protocol::TMDB::Message->new(@_); 
        $m->ns($self->ns());
        $m->version($version); 
        $m->cnis_data($rp->{cnis_data}),
        $m->smdrl_data($rp->{smdrl_data}),
        return $m; 
  });
   
 $self->_load($rp);
 $self->setup($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 my $extramods=$rp->{extensions};
 my @class=$self->core_modules($rp);
 $self->SUPER::_load(@class);
}

sub setup {  } ## subclass as needed

sub core_modules { return ('Net::DRI::Protocol::TMDB::Commands'); }

sub ns
{
 my ($self,$add)=@_;
 $self->{ns}={ ref $self->{ns} ? %{$self->{ns}} : (), %$add } if defined $add && ref $add eq 'HASH';
 return $self->{ns};
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::TMDB::Connection', protocol_version => 1);
}

####################################################################################################
1;
