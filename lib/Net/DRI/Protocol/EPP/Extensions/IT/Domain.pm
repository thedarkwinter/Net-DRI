## Domain Registry Interface, .IT Domain extension
##
## Copyright (C) 2009-2010 Tower Technologies. All rights reserved.
##
## This program free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License v2.
##

package Net::DRI::Protocol::EPP::Extensions::IT::Domain;

use strict;
use warnings;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::IT::Domain - .IT EPP Domain extension for Net::DRI

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>noc@towertech.itE<gt>

Please also see the SUPPORT file in the distribution.

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT

Copyright (C) 2009-2010 Tower Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 as published by
the Free Software Foundation.

See the LICENSE file that comes with this distribution for more details.

=cut

sub register_commands {

       my ($class, $version) = @_;

       my $ops = {
               'info'          => [ \&info, \&parse ],
               'create'        => [ undef, \&parse  ],
               'transfer_request'   => [\&transfer, \&parse],
       };

       return {
               'domain'        => $ops,
       };
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 return unless defined $rd->{inf_contacts};
 Net::DRI::Exception::usererr_invalid_parameters('inf_contacts must be one of registrant|admin|tech|all') unless $rd->{inf_contacts} =~ m/^registrant|admin|tech|all$/;
 my $mes=$epp->message();
 my $eid =$mes->command_extension_register('extdom:infContacts', sprintf('op="'.$rd->{inf_contacts}.'" xmlns:extdom="%s" xsi:schemaLocation="%s %s"', $mes->nsattrs('it_domain')));
 $mes->command_extension($eid);
}

sub transfer
{
 my ($epp,$domain,$rd)=@_;
 return unless defined $rd->{new_registrant } && defined $rd->{new_authinfo};
 my $mes=$epp->message();
 my $eid =$mes->command_extension_register('extdom:trade', sprintf('xmlns:extdom="%s" xsi:schemaLocation="%s %s"', $mes->nsattrs('it_domain')));
 my @d;
 push @d, ['extdom:newRegistrant', $rd->{new_registrant} ];
 push @d, ['extdom:newAuthInfo', ['extdom:pw',$rd->{new_authinfo}] ];
 $mes->command_extension($eid,['extdom:transferTrade',@d]);
}

sub parse
{
       use Data::Dumper;
       my ($po, $otype, $oaction, $oname, $rinfo) = @_;

       my $msg = $po->message;
       my $ns = $msg->ns('it_domain');

       my $infdata = $msg->get_extension('it_domain', 'infData');
       my $infns = $msg->get_extension('it_domain', 'infNsToValidateData');
       my $infconts = $msg->get_extension('it_domain','infContactsData');
       my $remapped_idn = $msg->get_extension('it_domain','remappedIdnData');

       if (defined $remapped_idn) {
                my ($idn_requested,$idn_created);
                foreach my $el (Net::DRI::Util::xml_list_children($remapped_idn))
                {
                        my ($name,$c) = @$el;
                        $idn_requested = $c->textContent() if $name eq 'idnRequested';
                        $idn_created = $c->textContent() if $name eq 'idnCreated';
                }
                unless (defined $oname)
                {
                        $oname = $idn_requested;
                        $rinfo->{'domain'}{$oname}{name} = $idn_requested;
                        $rinfo->{'domain'}{$oname}{action} = $oaction = 'idn_remapped';
                }
                $rinfo->{'domain'}{$oname}{idn_requested} = $idn_requested;
                $rinfo->{'domain'}{$oname}{idn_created} = $idn_created;
       }
       #use Data::Dumper; print Dumper $rinfo->{'domain'} if $oname;
       
       if (defined $infdata) {

               $rinfo->{'domain'}{$oname}{'own_status'} =
                       $infdata->getChildrenByTagNameNS($ns, 'ownStatus')
                       ->shift
                       ->getAttribute('s');
       }

       if (defined $infns) {

               # cannot match ./extdom:nsToValidate/domain:hostAttr/domain:hostName
               # due to mixed namespace
               foreach ($infns->findnodes('./extdom:nsToValidate/*/*')) {

                       push(@{$rinfo->{'domain'}{$oname}{'ns_to_validate'}},
                               $_->textContent)
                               if $_->getName eq 'domain:hostName';
               }
       }

      # The main contact parser wont parse this without some sersious work, so ive just added a basic parser for now
       if (defined $infconts) {
               #my $cs = Dumper $rinfo->{$otype}->{$oname}->{contact};
               my $cs = $po->create_local_object('contactset');
                foreach my $el (Net::DRI::Util::xml_list_children($infconts))
                {
                        my ($name,$c) = @$el;
                        my $ctype = ($name eq 'registrant')?'registrant':$c->getAttribute('type');
                        my $cont = $po->create_local_object('contact');
                        my %pi=map { $_ => [] } qw/city sp pc cc/;
                        foreach my $el2 (Net::DRI::Util::xml_list_children(Net::DRI::Util::xml_traverse($c,$msg->ns('it_domain'),'infContact')))
                        {
                                my ($name2,$c2) = @$el2;
                                $cont->srid($c2->textContent) if $name2 eq 'id';
                                $cont->{$name2} = $c2->textContent() if $name2 =~ m/^roid|name|org|email|clID|crID|upID$/;
                                $cont->{$name2} = $po->parse_iso8601($c2->textContent()) if $name2 =~ /Date$/;
                                $cont->{$name2} = Net::DRI::Protocol::EPP::Util::parse_tel($c2) if $name2 =~ /^voice|fax$/;
                                $cont->{status} = $po->create_local_object('status')->add(Net::DRI::Protocol::EPP::Util::parse_node_status($c2)) if $name2 eq 'status';
                                Net::DRI::Protocol::EPP::Core::Contact::parse_postalinfo($po,$c2,\%pi) if $name2 eq 'postalInfo';
                        } 
                        foreach my $key (keys %pi) { $cont->{$key} = $pi{$key}; }

                        # even the extra contact details are under a different namespace from a contact_info!
                        foreach my $el2 (Net::DRI::Util::xml_list_children(Net::DRI::Util::xml_traverse($c,$msg->ns('it_domain'),'extInfo')))
                        {
                                my ($name2,$c2) = @$el2;
                                $cont->consent_for_publishing( ($c->textContent()eq'true')?1:0 ) if $name eq 'consentForPublishing';
                                foreach my $el3 (Net::DRI::Util::xml_list_children($c2))
                                {
                                        my ($name3,$c3) = @$el3;
                                        $cont->nationality_code($c3->textContent()) if $name3 eq 'nationalityCode';
                                        $cont->entity_type($c3->textContent()) if $name3 eq 'entityType';
                                        $cont->reg_code($c3->textContent()) if $name3 eq 'regCode';
                                }
                        }
                        $cs->set($cont,$ctype);
                        $rinfo->{contact}->{$cont->srid()}->{self} = $cont;
                }
                $rinfo->{$otype}->{$oname}->{contact} = $cs;
        }
       return 1;
}

1;
