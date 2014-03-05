## Domain Registry Interface, Afilias maintainerUrl EPP extension
##
## Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub create
{
 my ($ns,$rd)=@_;
 return unless Net::DRI::Util::has_key($rd,'maintainer_url');
 return [$ns.':maintainerUrl',$rd->{maintainer_url}];
}

sub update
{
 my ($ns,$todo)=@_;

 Net::DRI::Exception->die(0,'protocol/EPP',11,'Only maintainer_url set available for domain') if (grep { ! /^(?:set)$/ } $todo->types('maintainer_url'));
 return unless $todo->set('maintainer_url');
 return [$ns.':maintainerUrl',$todo->set('maintainer_url')];
}

sub info_parse
{
 my ($ns,$infdata)=@_;
 my $c=$infdata->getChildrenByTagNameNS($ns,'maintainerUrl');
 return unless (defined $c && $c->size()==1);
 return $c->get_node(1)->textContent();
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Afilias::MaintainerUrl - Afilias maintainerUrl extension for Net::DRI

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

Copyright (c) 2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
