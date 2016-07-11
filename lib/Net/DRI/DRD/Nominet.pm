## Domain Registry Interface, .UK (Nominet) policies for Net::DRI
##
## Copyright (c) 2007-2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::Nominet;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;

use DateTime::Duration;

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_update_status_add domain_update_status_del domain_update_status_set domain_update_status domain_status_allows_delete domain_status_allows_update domain_status_allows_transfer domain_status_allows_renew domain_status_allows domain_current_status host_update_status_add host_update_status_del host_update_status_set host_update_status host_current_status contact_update_status_add contact_update_status_del contact_update_status_set contact_update_status contact_current_status contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query  domain_transfer_stop domain_transfer_query host_delete contact_delete/);

=pod

=head1 NAME

Net::DRI::DRD::Nominet - .UK (Nominet) policies for Net::DRI

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

Copyright (c) 2007-2011 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{contact_i18n}=1; ## LOC only
 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Nominet'; }
sub tlds {
  my @uk = ('uk', map { $_.'.uk'} qw/co ltd me net org plc sch/);
  # from Schools_Domain_Name_Rules.pdf
  my @sch_england = (map { $_.'.sch.uk'} qw/
      barking-dagenham barnet barnsley bathnes beds bexley bham blackburn blackpool bolton bournemouth bracknell-forest bradford brent brighton-hove bristol bromley bucks bury
      calderdale cambs camden beds cheshire city-of-london cornwall coventry croydon cumbria darlington derby derbyshire devon doncaster dorset dudley durham
      ealing e-riding e-sussex enfield essex gateshead gloucs greenwich hackney halton lbhf hants haringey harrow hartlepool havering hereford herts hillingdon hounslow
      iow scilly islington kensington-chelsea kent hull kingston kirklees knowsley lambeth lancs leeds leicester leics lewisham lincs liverpool luton
      manchester medway merton middlesbrough milton-keynes newcastle newham norfolk ne-lincs n-lincs n-sommerset n-tyneside n-yorks northants northumberland notthingham notts
      oldham oxon peterborough plymouth poole portsmouth reading redbridge rac richmond rochdale rotherham rutland salford sandwell sefton sheffield shropshire slough solihull
      somerset s-gloucs s-tyneside southampton southend southwark st-helens staffs stockport stockton stoke suffolk sunderland surrey sutton swindon
      tameside wrekin thurrock torbay towerhamlets trafford
      wakefield walsall waltham wandsworth warringhton warwickshire w-berks w-sussex westminster wigan wilts windsor-maidenhead wirral wokingham wolverhampton worcs
      york
    /);
  my @sch_scotland = (map { $_.'.sch.uk'} qw /
      aberdeen aberdeenshire angus argyll-bute clacks dumgal dundeecity e-ayr e-dunbarton e-lothian e-renfrew edin falkirk fife glasgow highland inverclyde
      midlothian moray n-ayrshire n-lanark orkney pkc renfrewshire scotborders shetland sayr s-lanark stirling w-dunbarton westlothian eileanansiar
    /);
  my @sch_wales = (map { $_.'.sch.uk'} qw/
      anglesey ynysmon blaenau-gwent bridgend caerphilly cardiff carms  sirgar ceredigion conwy denbighshire sirddinbych flintshire
      siryfflint gwynedd merthyr monmouthshire neath-porttalbot newport casnewydd pembrokeshire sirbenfro powys rhondda-cynon-taff
      swansea valeofglamorgan torfaen wrexham
    /);
  return (@uk,@sch_england,@sch_scotland,@sch_wales);
}
sub object_types  { return qw/domain contact ns/; }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 Net::DRI::Exception->die(0,'DRD',6,"Nominet EPP no longer supported, please use Standard EPP interface") if $type eq 'epp_nominet';
 return ('Net::DRI::Transport::Socket',{remote_host => 'epp.nominet.org.uk', ssl_version => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::Nominet',{}) if $type eq 'epp';
 return;
}

####################################################################################################

sub domain_unrenew
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $ndr->process('domain','unrenew',[$domain,$rd]);
}

sub domain_list
{
 my ($self,$ndr,$rd)=@_;
 return $ndr->process('domain','list',[$rd]);
}

sub domain_lock
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $ndr->process('domain','lock',[$domain,$rd]);
}

sub domain_transfer_start # release
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $ndr->process('domain','transfer_start',[$domain,$rd]);
}

sub domain_transfer_accept # handshake
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $ndr->process('domain','transfer_accept',[$domain,$rd]);
}

sub domain_transfer_refuse # handshake
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $ndr->process('domain','transfer_refuse',[$domain,$rd]);
}

sub contact_fork
{
 my ($self,$ndr,$contact,$rd)=@_;
 return $ndr->process('contact','fork',[$contact,$rd]);
}

sub contact_lock
{
 my ($self,$ndr,$contact,$rd)=@_;
 return $ndr->process('contact','lock',[$contact,$rd]);
}

####################################################################################################
1;
