## Domain Registry Interface, IRIS Message
##
## Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::IRIS::Message;

use utf8;
use strict;
use warnings;

use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw/version tid authority options search results/);

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::Message - IRIS Message for Net::DRI

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

Copyright (c) 2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $trid=shift;

 my $self={ ns => {}, options => {} };
 bless($self,$class);

 $self->tid($trid) if defined $trid && length $trid;
 return $self;
}

sub ns
{
 my ($self,$what)=@_;
 return $self->{ns} unless defined $what;

 if (ref $what eq 'HASH')
 {
  $self->{ns}=$what;
  return $what;
 }
 return unless exists $self->{ns}->{$what};
 return $self->{ns}->{$what}->[0];
}

sub nsattrs
{
 my ($self,$what)=@_;
 return unless defined $what && exists $self->{ns}->{$what};
 my @n=@{$self->{ns}->{$what}};
 return ($n[0],$n[0],$n[1]);
}

sub is_success { return 1; } ## TODO

sub result_status { return Net::DRI::Protocol::ResultStatus->new_success(); }; ## There is no message-level result_status, only at resultSet level, hence global success

sub as_string
{
 my ($self)=@_;

 ## TODO : handle other top nodes, see RFC4991, + control node in <request>
 Net::DRI::Exception::err_assert('Net::DRI::Protocol::IRIS::Message can only handle <request> operations for now') unless defined $self->search();
 my @d;
 push @d,'<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
 push @d,sprintf('<request xmlns="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s">',$self->nsattrs('iris1'));

 foreach my $search (@{$self->search()}) ## $search is a refhash comme il faut
 {
  push @d,'<searchSet>';
  ## We do not handle bags for now
  ## Only lookupEntity is supported for now
  push @d,Net::DRI::Util::xml_write(['lookupEntity',$search]);
  push @d,'</searchSet>';
 }

 push @d,'</request>';
 return join('',@d);
}

# RFC3981 §4.2
sub parse
{
 my ($self,$dc,$rinfo)=@_;

 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dc->as_string());
 my $root=$doc->getDocumentElement();
 ## TODO: handle RFC4991 other types of responses
 Net::DRI::Exception->die(0,'protocol/IRIS',1,'Unsuccessfull parse, root element is not response') unless ($root->localname() eq 'response');

 ## We currently do not parse the <reaction> node (in reply to a <control> which we do never send for now, see §4.3.8) and <bags> (see §4.4)
 ## We take care only of the <resultSet> nodes
 $self->results(scalar($root->getChildrenByTagNameNS($self->ns('iris1'),'resultSet')));
 return;
}

####################################################################################################
1;
