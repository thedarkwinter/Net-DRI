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
               'info'          => [ undef, \&parse ],
       };

       return {
               'domain'        => $ops,
       };
}

sub parse
{
       my ($po, $type, $action, $name, $info) = @_;

       my $msg = $po->message;
       my $ns = $msg->ns('it_domain');

       my $infdata = $msg->get_extension('it_domain', 'infData');
       my $infns = $msg->get_extension('it_domain', 'infNsToValidateData');

       if (defined $infdata) {

               $info->{'domain'}{$name}{'own_status'} =
                       $infdata->getChildrenByTagNameNS($ns, 'ownStatus')
                       ->shift
                       ->getAttribute('s');
       }

       if (defined $infns) {

               # cannot match ./extdom:nsToValidate/domain:hostAttr/domain:hostName
               # due to mixed namespace
               foreach ($infns->findnodes('./extdom:nsToValidate/*/*')) {

                       push(@{$info->{'domain'}{$name}{'ns_to_validate'}},
                               $_->textContent)
                               if $_->getName eq 'domain:hostName';
               }
       }

       return 1;
}

1;
