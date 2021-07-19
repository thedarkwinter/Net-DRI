## EPP Mapping for Art Record Extension (draft-brown-epp-artRecord-00)
##
## Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ArtRecord;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rd={ 'domain' => {
                           info    => [ undef, \&info_parse ],
                           create  => [ \&command, undef ],
                           update  => [ \&command, undef ],
                         },
           };

 return $rd;
}

sub capabilities_add { return ['domain_update','art_record',['set']]; }

sub setup
{
 my ($class,$po,$version)=@_;

 state $ns = { 'artRecord' => 'urn:ietf:params:xml:ns:artRecord-0.1' };
 $po->ns($ns);
 return;
}

sub implements { return 'https://gitlab.centralnic.com/centralnic/epp-artrecord-extension/raw/fd935a927252f4420e233adce877830782a22ba4/draft-brown-artRecord.txt'; }

####################################################################################################

sub command
{
 my ($epp,$domain,$data)=@_;
 my $mes=$epp->message();
 my $operation=$mes->operation()->[1];
 my $art;
 if ($operation eq 'update')
 {
  $art=$data->set('art_record');
  return unless defined $art;
 } else
 {
  return unless Net::DRI::Util::has_key($data, 'art_record');
  $art=$data->{art_record};
 }

 my @art;
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "object_type"') unless exists $art->{object_type};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "object_type": '.$art->{object_type}) unless Net::DRI::Util::xml_is_token($art->{object_type}, 0, 255);
 push @art, ['artRecord:objectType',$art->{object_type}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "materials_and_techniques"') unless exists $art->{materials_and_techniques};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "materials_and_techniques": '.$art->{materials_and_techniques}) unless Net::DRI::Util::xml_is_token($art->{materials_and_techniques}, 0, 255);
 push @art, ['artRecord:materialsAndTechniques',$art->{materials_and_techniques}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "dimensions"') unless exists $art->{dimensions};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "dimensions": '.$art->{dimensions}) unless Net::DRI::Util::xml_is_token($art->{dimensions}, 0, 255);
 push @art, ['artRecord:dimensions',$art->{dimensions}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "title"') unless exists $art->{title};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "title": '.$art->{title}) unless Net::DRI::Util::xml_is_token($art->{title}, 0, 255);
 push @art, ['artRecord:title',$art->{title}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "date_or_period"') unless exists $art->{date_or_period};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "date_or_period": '.$art->{date_or_period}) unless Net::DRI::Util::xml_is_token($art->{date_or_period}, 0, 255);
 push @art, ['artRecord:dateOrPeriod',$art->{date_or_period}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "maker"') unless exists $art->{maker};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "maker": '.$art->{maker}) unless Net::DRI::Util::xml_is_token($art->{maker}, 0, 255);
 push @art, ['artRecord:maker',$art->{maker}];
 Net::DRI::Exception::usererr_insufficient_parameters('Missing art record "reference"') unless exists $art->{reference};
 Net::DRI::Exception::usererr_invalid_parameters('Invalid syntax for art record "reference": '.$art->{reference}) unless Net::DRI::Util::xml_is_token($art->{reference}, 0, 255);
 push @art, ['artRecord:reference',$art->{reference}];

 my $eid=$mes->command_extension_register('artRecord',$operation);
 $mes->command_extension($eid,\@art);

 return;
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('artRecord','infData');
 return unless defined $data;

 my %art;
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;

  if ($name=~m/^(objectType|materialsAndTechniques|dimensions|title|dateOrPeriod|maker|reference)$/) {
   $art{Net::DRI::Util::remcam($name)}=$c->textContent();
  }
 }

 $rinfo->{domain}->{$oname}->{art_record}=\%art;

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ArtRecord - EPP Mapping for Art Record Extension (draft-brown-epp-artRecord-00) for Net::DRI

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

Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
