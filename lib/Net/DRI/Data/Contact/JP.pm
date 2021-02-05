## Domain Registry Interface, Handling of contact data for JP
##
## Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2021 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::Data::Contact::JP;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(suffix alloc ryid handle transfer domainCreatePreValidation suspendDate lapsedNs));

=pod

=head1 NAME

Net::DRI::Data::Contact::JP - Handle .JP contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.JP specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 suffix()

domain suffix attribute : jp or ojp

=head2 alloc()

contact alloc attribute : registrant, public or personnel

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2021 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2021 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2021 Paulo Jorge <paullojorgge@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

# list of Japonese prefecture codes - JISX0401
my %prefectures = (
  '01' => 'Hokkaido',
  '02' => 'Aomori',
  '03' => 'Iwate',
  '04' => 'Miyagi',
  '05' => 'Akita',
  '06' => 'Yamagata',
  '07' => 'Fukushima',
  '08' => 'Ibaraki',
  '09' => 'Tochigi',
  '10' => 'Gunma',
  '11' => 'Saitama',
  '12' => 'Chiba',
  '13' => 'Tokyo',
  '14' => 'Kanagawa',
  '15' => 'Niigatta',
  '16' => 'Toyama',
  '27' => 'Osaka',
  '28' => 'Hyogo',
  '29' => 'Nara',
  '30' => 'Wakayama',
  '31' => 'Tottori',
  '32' => 'Shimane',
  '33' => 'Okayama',
  '34' => 'Hiroshima',
  '35' => 'Yamaguchi',
  '36' => 'Tokushima',
  '37' => 'Kagawa',
  '38' => 'Ehime',
  '39' => 'Kochi',
  '40' => 'Fukuoka',
  '41' => 'Saga',
  '42' => 'Nagasaki',
  '43' => 'Kumamoto',
  '44' => 'Oita',
  '45' => 'Miyazaki',
  '46' => 'Kagoshima',
  '47' => 'Okinawa',
  '99' => 'outside of Japan'
);

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 push @errs,'suffix' if ($self->suffix() && $self->suffix()!~m/^(?:jp|ojp)/);
 push @errs,'alloc' if ($self->alloc() && $self->alloc()!~m/^(?:registrant|public|personnel)/);
 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 # sp is mandatory for alloc registrant AND only accepts 2 digit number allocated to Japan prefectures
 if ($self->alloc() && $self->alloc() eq 'registrant') {
  Net::DRI::Exception::usererr_insufficient_parameters('sp field is mandatory for registrant!') unless ($self->sp());
  Net::DRI::Exception::usererr_invalid_parameters('sp is not a 2 digits number!') unless ($self->sp() =~ m/^\d{1,2}$/);
  Net::DRI::Exception::usererr_invalid_parameters("sp is not a valid prefecture!") unless (exists $prefectures{$self->sp()});
 }

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;

 if ($what eq 'create')
 {
  my $a=$self->auth();
  $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw}));
 }
 return;
}
####################################################################################################
1;
