## Domain Registry Interface, Price Extension Mapping for EPP
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AusRegistry::Price;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $rops = { 'domain' => { check            => [ \&check_build,    \&check_parse ],
                               check_multi      => [ \&check_build,    \&check_parse ],
                               create           => [ \&create_build,   undef ],
                               renew            => [ \&renew_build,    undef ],
                               transfer_request => [ \&transfer_build, undef ],
                               update           => [ \&update_build,   undef ],
                             }
               };

 return $rops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns = { 'price' => [ 'urn:ar:params:xml:ns:price-1.2','price-1.2.xsd' ] };
 $po->ns($ns);
 return;
}

sub implements { return 'https://ausregistry.github.io/doc/price-1.2/price-1.2.html'; }

####################################################################################################

sub check_build
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rp,'price');
 return unless $rp->{price};

 my $eid=$mes->command_extension_register('price','check');
 $mes->command_extension($eid,Net::DRI::Protocol::EPP::Util::build_period($rp->{price},'price')) if Net::DRI::Util::is_class($rp->{price},'DateTime::Duration');

 return;
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('price','chkData');
 return unless defined $data;

 foreach my $cd (grep { $_->[0] eq 'cd' } Net::DRI::Util::xml_list_children($data))
 {
  my ($domain,%p);
  foreach my $el (Net::DRI::Util::xml_list_children($cd->[1]))
  {
   my ($name,$node)=@$el;
   if ($name eq 'name')
   {
    $domain=$node->textContent();
   } elsif ($name=~m/^(category|reason)$/)
   {
    $p{$name}=$node->textContent();
   } elsif ($name eq 'period')
   {
    state $rperiods={qw/y years m months/};
    $p{duration}=$po->create_local_object('duration',$rperiods->{$node->getAttribute('unit')},$node->textContent());
   } elsif ($name=~m/^(create|renew|transfer|restore)Price$/)
   {
    $p{$1}=0+$node->textContent();
   }
  }
  $rinfo->{$otype}->{$domain}->{price}=\%p;
 }

 return;
}

sub _build
{
 my ($epp,$domain,$rp,$topname)=@_;
 my $mes=$epp->message();

 return unless Net::DRI::Util::has_key($rp,'price');
 return unless $rp->{price};
 Net::DRI::Exception::usererr_invalid_parameters('if provided, price element must be "ack" or a decimal number') unless $rp->{price}=~m/^(?:ack|\d+(?:\.\d+)?)$/;

 my $eid=$mes->command_extension_register('price',$topname);
 $mes->command_extension($eid,['price:ack',$rp->{price} ne 'ack' ? ['price:price', 0+$rp->{price}] : ()]);
 return;
}

sub create_build   { return _build(@_,'create');   } ## no critic (Subroutines::RequireArgUnpacking)
sub renew_build    { return _build(@_,'renew');    } ## no critic (Subroutines::RequireArgUnpacking)
sub transfer_build { return _build(@_,'transfer'); } ## no critic (Subroutines::RequireArgUnpacking)

sub update_build
{
 my ($epp,$domain,$todo,$rp)=@_;
 my $rgp=$todo->set('rgp');
 return unless Net::DRI::Util::has_key($rgp,'op') && $rgp->{op} eq 'request';
 return _build($epp,$domain,$rp,'update');
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AusRegistry::Price - EPP Price Extension mapping (https://ausregistry.github.io/doc/price-1.2/price-1.2.html) for Net::DRI

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

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
