## Domain Registry Interface, .NO message extensions
##
## Copyright (c) 2008-2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::NO::Message;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Protocol::EPP::Extensions::NO::Contact;
use Net::DRI::Protocol::EPP::Extensions::NO::Host;
use Net::DRI::Protocol::EPP::Extensions::NO::Result;
use Net::DRI::Protocol::EPP::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Message - .NO Mesage Extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010,2013 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

################################################################################################

sub register_commands {
    my ( $class, $version ) = @_;

    my %tmp = (
        noretrieve => [ \&pollreq, \&parse_poll ],
        nodelete   => [ \&pollack, \&Net::DRI::Protocol::EPP::Extensions::NO::Result::condition_parse ],
    );

    return { 'message' => \%tmp };
}

sub facet {
    my ( $epp, $rd ) = @_;

    return Net::DRI::Protocol::EPP::Extensions::NO::Host::build_facets( $epp, $rd );
}

sub pollack {
    my ( $epp, $msgid, $rd ) = @_;

    my $mes = $epp->message();
    my $r = ( $mes->command( [ [ 'poll', { op => 'ack', msgID => $msgid } ] ] ) );

    if (defined($rd->{facets}) && $rd->{facets}) {
       $r = facet( $epp, $rd );
    }
    return $r;
}

sub pollreq {
    my ( $epp, $rd ) = @_;

    my $mes = $epp->message();

    my $r = ( $mes->command( [ [ 'poll', { op => 'req' } ] ] ) );

    if (defined($rd->{facets}) && $rd->{facets}) {
       $r = facet( $epp, $rd );
    }
    
    return $r;
}

sub parse_resp_result
{
 my ($node, $NS, $rinfo, $msgid)=@_;

 push @{$rinfo->{message}->{$msgid}->{results}},Net::DRI::Protocol::EPP::Util::parse_node_result($node,$NS,'no');
 return;
}

sub transfer_resp_parse {
 my ($po, $trndata, $oname, $rinfo, $msgid)=@_;

 return unless $trndata;

 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;

  if ($name eq 'name') {
   $oname=lc($c->textContent());
   $rinfo->{message}->{$msgid}->{domain}->{$oname}->{action}='transfer';

   $rinfo->{message}->{$msgid}->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/mx) {
   $rinfo->{message}->{$msgid}->{domain}->{$oname}->{$1}=$c->textContent() if ($c->getFirstChild());
  } elsif ($name=~m/^(reDate|acDate|exDate)$/mx) {
   $rinfo->{message}->{$msgid}->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

sub contact_resp_parse {
 my ($po, $credata, $oname, $rinfo, $msgid)=@_;

 return unless $credata;
 
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'id')
  {
   my $new=$c->getFirstChild()->getData();
   $rinfo->{message}->{$msgid}->{contact}->{$oname}->{id}=$new if (defined($oname) && ($oname ne $new)); ## registry may give another id than the one we requested or not take ours into account at all !
   $oname=$new;
   $rinfo->{message}->{$msgid}->{contact}->{$oname}->{id}=$oname;
   $rinfo->{message}->{$msgid}->{contact}->{$oname}->{action}='create';
   $rinfo->{message}->{$msgid}->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{message}->{$msgid}->{contact}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
 return;
}

## We take into account all parse functions, to be able to parse any result
sub parse_poll {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();

    my $eppNS = $mes->ns('_main');

    # both message and results are defined by the same no-ext-result schema
    my $NS = $mes->ns('no_result');

    return unless $mes->is_success();
    return if $mes->result_is('COMMAND_SUCCESSFUL_QUEUE_EMPTY');

    my $msgid = $mes->msg_id();
    $rinfo->{message}->{session}->{last_id} = $msgid;

    ## Parse any message
    my $mesdata = $mes->get_response('no_result','message');

    $rinfo->{$otype}->{$oname}->{message} = $mesdata;
    return unless $mesdata;

    my ( $epp, $rep, $ext, $ctag, @conds, @tags );
    my $command = $mesdata->getAttribute('type');

    @tags = $mesdata->getElementsByTagNameNS( $NS, 'desc' );

    # We supplement the standard top desc with our more detailed one
    if (@tags && $tags[0]->getFirstChild() && $tags[0]->getFirstChild()->getData()) {
       $rinfo->{message}->{$msgid}->{nocontent} = $tags[0]->getFirstChild()->getData();
    }

    #
    # Now the data tag
    @tags = $mesdata->getElementsByTagNameNS( $NS, 'data' );
    return unless @tags;

    my $data = $tags[0];

    ##
    # Inside a data we can have variants, 
    # a normal result block in the start, then an <entry ..>
    # which is a sequence, the other is a late response which will contain
    # a complete and ordinary EPP response, only delayed.

    #
    # Parse any ordinary result block(s)
    # 
    foreach my $result ($data->getElementsByTagNameNS($eppNS,'result')) {
	parse_resp_result($result, $eppNS, $rinfo, $msgid);
    }

    ###
    # Parse entry
    #
    @tags = $data->getElementsByTagNameNS( $NS, 'entry' );

    foreach my $entry (@tags) {
        next unless ( defined( $entry->getAttribute('name') ) );

        if ( $entry->getAttribute('name') eq 'objecttype' ) {
            $rinfo->{message}->{$msgid}->{object_type}
                = $entry->getFirstChild()->getData();
        } elsif ( $entry->getAttribute('name') eq 'command' ) {
            $rinfo->{message}->{$msgid}->{action}
                = $entry->getFirstChild()->getData();
        } elsif ( $entry->getAttribute('name') eq 'objectname' ) {
            $rinfo->{message}->{$msgid}->{object_id}
                = $entry->getFirstChild()->getData();
        } elsif (
            $entry->getAttribute('name') =~ /^(domain|contact|host)$/mx )
        {
            $rinfo->{message}->{$msgid}->{object_type} = $1;
            $rinfo->{message}->{$msgid}->{object_id}
                = $entry->getFirstChild()->getData();
        }
    }

    $rinfo->{message}->{$msgid}->{action} ||= $command;

    ###
    # The various EPP late response messages can be encapsulated in the service message data.
    # There may in principle be any type of object response, so we try to parse all variants
    # We try to use our various parse methods, copy the data and copy the data from it
    # into our message structure. The delete the source data to hopefully not
    # contaminate anything.

    ##
    # inside a data and a late-responses, an inner TRID pair should exist.
    # No more than one inner TRID pair is expected and handled
    # In case more exist, the first one is used.
    # Find the values and stash them in an $rinfo->{message}->{$msgid}->{trid} hash

    if (my $trid=(($data->getElementsByTagNameNS($eppNS,'trID'))[0])) {
       my $tmp=Net::DRI::Util::xml_child_content($trid,$eppNS,'clTRID');
       $rinfo->{message}->{$msgid}->{trid}->{cltrid} = $tmp if defined($tmp);
       $tmp = Net::DRI::Util::xml_child_content($trid,$eppNS,'svTRID');
       $rinfo->{message}->{$msgid}->{trid}->{svtrid} = $tmp if defined($tmp);
    }

    # Parse any domain command late response data
    if (my $infdata=$mes->get_response('domain','infData')) {
       Net::DRI::Protocol::EPP::Core::Domain::info_parse($po,'domain','info',$oname,$rinfo);

       if (defined($rinfo->{domain}) && $rinfo->{domain}) {
           $rinfo->{message}->{$msgid}->{domain} = $rinfo->{domain};
           delete($rinfo->{domain});
       }
    }

    # Parse any domain transfer late response data
    if (my $trndata = (($data->getElementsByTagNameNS($mes->ns('domain'), 'trnData'))[0])) {
	transfer_resp_parse($po, $trndata, $oname, $rinfo, $msgid);
    }

    # Parse any any contact create late response data
    if (my $credata = (($data->getElementsByTagNameNS($mes->ns('contact'), 'creData'))[0])) {
       contact_resp_parse($po, $credata, $oname, $rinfo, $msgid);
    }

    # Parse any any contact info late response data
    if (my $condata = $mes->get_extension('no_contact','infData')) {
       Net::DRI::Protocol::EPP::Extensions::NO::Contact::parse_info($po,'contact', 'info',$oname,$rinfo);
       if (defined($rinfo->{contact}) && $rinfo->{contact}) {
           $rinfo->{message}->{$msgid}->{contact} = $rinfo->{contact};
           delete ($rinfo->{contact});
       }
    }

    # Parse any any host info late response data
    if (my $condata = $mes->get_extension('no_host','infData')) {
       Net::DRI::Protocol::EPP::Extensions::NO::Host::parse_info($po,'host','info',$oname,$rinfo);

       if (defined($rinfo->{host}) && $rinfo->{host}) {
           $rinfo->{message}->{$msgid}->{host} = $rinfo->{host};
           delete($rinfo->{host});
       }
    }

    # Parse any result extension conditions
    my $innerepp=$data->getElementsByTagNameNS($eppNS,'epp')->shift();
    my $condata;
    if (defined($innerepp) && ($condata = $innerepp->getElementsByTagNameNS($NS,'conditions'))) {
       Net::DRI::Protocol::EPP::Extensions::NO::Result::parse($mes,$otype,$oname,$rinfo,$condata->shift());

       if ((defined($rinfo->{$otype}->{$oname}->{conditions})) &&
           $rinfo->{$otype}->{$oname}->{conditions}) {
           $rinfo->{message}->{$msgid}->{conditions} = $rinfo->{$otype}->{$oname}->{conditions};
           #delete ($rinfo->{$otype}->{$oname}->{conditions});
       }
    }
    return 1;
}

####################################################################################################
1;
