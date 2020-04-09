## Domain Registry Interface, ES Tray (Bandeja) EPP extension commands 
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ES::Tray;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Format::ISO8601;
use Data::Dumper;
=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ES::Bandeja - ES EPP Tray (Bandeja) extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SYNOPSIS

 # to search to task tray, we use the tray_info commands
 # the following arguments are all optional, but probably at least one should be specified: fromDate, toDate, category, type, domain
 my $rc = $dri->tray_info({fromDate => '2013-01-01', toDate => '2013-01-21', category => 10, type=>3,domain => 'test1.es'});
 
 # since no unique identifieds are returned, the last_id is set to time()
 my $last_id = $dri->get_info('last_id','message','session');
 my $total = $dri->get_info('total','tray',$last_id);# the total matched (NOT retrieved)
 my $retrieved = $dri->get_info('retrieved','tray',$last_id); # total retrieved
 
 # you can either get a hash containing all messages, index 0..x
 my $items = $dri->get_info('items','tray',$last_id); 
 
 # or use the next dummy  sub to loop through all messages retrieved
 while (my $item = $dri->get_info('next','tray',$last_id)->()) {
  ...
 }


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

sub register_commands
{
 my ($class,$version)=@_;
 return { 'tray' => { info=> [ \&info, \&info_parse ] } };
}

sub info {
 my ($epp,$rd)=@_;
 
  # validate
 my @errs;
 push @errs,'tray category must be between 1 and 10 if defined' if (defined($rd->{category}) && $rd->{category} >10);
 push @errs,'tray type must be between 1 and 38' if (defined($rd->{type}) && $rd->{type} > 38);
 push @errs,'invalid domain name' if (defined($rd->{domain}) && !Net::DRI::Util::is_hostname($rd->{domain}));
 push @errs,'either both dates or no dates should be specified' if defined($rd->{fromDate}) xor defined($rd->{toDate});
 
 # validate and covert dates if possible
 foreach my $f ('fromDate','toDate')
 {
   next if !defined($rd->{$f}) || UNIVERSAL::isa('DateTime',$rd->{$f});
   push @errs,'invalid date for $f' unless $rd->{$f} = new DateTime::Format::ISO8601->new()->parse_datetime($rd->{$f});
 }
 Net::DRI::Exception::usererr_invalid_parameters('Invalid tray parameters: '.join('/',@errs)) if @errs;

 #create message 
 my $mes=$epp->message();
 $mes->command(['info','es_bandeja:info',$mes->nsattrs('es_bandeja')]);
 my @d;
 push @d, ['es_bandeja:fechaDesde',$rd->{fromDate}->iso8601()] if defined $rd->{fromDate};
 push @d, ['es_bandeja:fechaHasta',$rd->{toDate}->iso8601()] if defined $rd->{toDate};
 push @d, ['es_bandeja:nombreDominio',$rd->{domain}] if defined $rd->{domain};
 push @d, ['es_bandeja:tipoCategoria',$rd->{category}] if defined $rd->{category};
 push @d, ['es_bandeja:tipoMensaje',$rd->{type}] if defined $rd->{type};
 $mes->command_body(\@d);
}

sub info_parse {
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('es_bandeja','infoData');
 return unless defined $infdata;

 $otype = 'tray';
 $oaction = 'info';
 $oname = time;
 $rinfo->{message}->{session}->{last_id} = $oname;

 # resdata contains total and retrieved
 my $resdata = $mes->node_resdata();
 foreach my $elem (Net::DRI::Util::xml_list_children($resdata))
 {
   my ($name,$el)=@$elem;
   $rinfo->{$otype}->{$oname}->{index} = -1;
   $rinfo->{$otype}->{$oname}->{retrieved} = $el->textContent() if $name eq 'mostrando';
   $rinfo->{$otype}->{$oname}->{total} = $el->textContent() if $name eq 'total';
   $rinfo->{$otype}->{$oname}->{next} = sub {
     $rinfo->{$otype}->{$oname}->{index}++;
     return ( $rinfo->{$otype}->{$oname}->{index} < $rinfo->{$otype}->{$oname}->{retrieved} ) ? $rinfo->{$otype}->{$oname}->{items}->{$rinfo->{$otype}->{$oname}->{index}} : undef;
   } 
 }

 # all these rows are different messages
 my $rd;
 my $elnum=0;
 my @rows = Net::DRI::Util::xml_list_children($infdata);
 foreach my $row (@rows)
 {
   my ($obj,$dom);
   foreach my $elem (Net::DRI::Util::xml_list_children(@$row[1]))
   {
     my ($name,$el)=@$elem;
     $obj->{qDate} = new DateTime::Format::ISO8601->new()->parse_datetime($el->textContent()) if $name eq "fecha";
     $dom = $obj->{domain} = $el->textContent() if $name eq "nombreDominio";
     if ($name eq "tipoCategoria")
     {
      my @nodes = $el->attributes();
      $obj->{category} = $nodes[0]->value;
      $obj->{category_text} = $el->textContent()
     }

     if ($name eq "tipoMensaje") {
      my @nodes = $el->attributes();
      $obj->{type} = $nodes[0]->value;
      $obj->{type_text} = $el->textContent();
     }
   }
   $rd->{$elnum++} = $obj;
  }
 $rinfo->{$otype}->{$oname}->{items} = $rd;
}

return 1;