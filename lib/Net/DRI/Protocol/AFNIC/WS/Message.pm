## Domain Registry Interface, AFNIC WS Message
##
## Copyright (c) 2005,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::AFNIC::WS::Message;

use utf8;
use strict;
use warnings;

use Net::DRI::Protocol::ResultStatus;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version service method params result errcode));

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::WS::Message - AFNIC Web Services Message for Net::DRI

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

Copyright (c) 2005,2008-2010,2013 Patrick Mevzek <netdri@dotandco.com>.
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
 my $self={errcode => undef};
 bless($self,$class);

 $self->params([]); ## default
 my $rh=shift;
 if (defined($rh) && (ref($rh) eq 'HASH'))
 {
  $self->service($rh->{service}) if exists($rh->{service});
  $self->method($rh->{method})   if exists($rh->{method});
  $self->params($rh->{params})   if exists($rh->{params});
 }
 return $self;
}

sub as_string
{
 my ($self)=@_;
 my @p=@{$self->params()};
 my @pr;
 foreach my $i (0..$#p)
 {
  push @pr,sprintf 'PARAM%d=%s',$i+1,$p[$i];
 }

 return sprintf "SERVICE=%s\nMETHOD=%s\n%s\n",$self->service(),$self->method(),join("\n",@pr);
}

sub parse
{
 my ($self,$r)=@_;

 $self->result($r);
 my $c;
 $c=$r->{reason} if (defined($r) && ref($r) && exists($r->{reason}));
 $self->errcode($c);

 ## Warning: when we handle multiple web services, we will need a way to retrieve the method name called,
 ## to find the correct errcode, as it will obviously not be done the same way accross all services.
 return;
}

## We handle all non free cases as errors, even if we should not
sub is_success
{
 my $self=shift;
 my $r=$self->result();
 my $code=$self->errcode();

 return 1 if ($r->{free});
 return 0;
}

sub result_status
{
 my $self=shift;
 my $r=$self->result();

 return Net::DRI::Protocol::ResultStatus->new_success($r->{message}) if $r->{free};

 my %codes=( 0   => 2400, # problème de connexion à la base de données => Command failed
             1   => 2302, # le nom de domaine est déjà enregistré => Object exists
             2   => 2308, # un nom de domaine est déjà enregistré à l'identique dans l'une des extensions du domaine public => Data management policy violation
             4   => 2304, # une opération est en cours pour ce nom de domaine => Object status prohibits operation
             5   => 2308, # nom de domaine interdit (termes fondamentaux) => Data management policy violation
             51  => 2308, # nom de domaine réservé pour les communes => Data management policy violation
             100 => 2005, # mauvaise syntaxe du nom de domaine => Parameter value syntax error
           );

 my $code=$self->errcode();
 my $eppcode=(defined $code && exists $codes{$code})? $codes{$code} : 'COMMAND_FAILED';
 return Net::DRI::Protocol::ResultStatus->new('afnic_ws_check_domain',$code,$eppcode,$self->is_success(),$r->{message});
 ## Warning: when we handle multiple web services, we will need a way to retrieve the method name called,
 ## to find the correct key of the hash (and special case of free <=> 2303)
}

####################################################################################################
1;
