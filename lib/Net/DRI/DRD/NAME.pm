## Domain Registry Interface, .NAME policies
##
## Copyright (c) 2007-2009,2011 HEXONET Support GmbH, www.hexonet.com,
##                    Alexander Biehl <info@hexonet.com>
##			and Patrick Mevzek <netdri@dotandco.com>.
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

package Net::DRI::DRD::NAME;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use Net::DRI::Util;
use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::NAME - .NAME policies for Net::DRI

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

Copyright (c) 2007-2009,2011 HEXONET Support GmbH, E<lt>http://www.hexonet.comE<gt>,
Alexander Biehl <info@hexonet.com>
and Patrick Mevzek <netdri@dotandco.com>.
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
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=2;	## INT only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'NAME'; }
sub tlds     { return ('name'); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NAME',{})              if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.nic.name'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1, check_name_dots => [1,2],
                                               my_tld_not_strict => 1, ## we need less strict checks because in X.Y.name domain names both X and Y are variables
                                               icann_reserved => 1,
                                              });                                              
}

sub emailfwd_check
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->try_restore_from_cache('emailfwd',$email,'check');
 if (! defined $rc) { $rc=$ndr->process('emailfwd','check',[$email]); }
 return $rc;
}

sub emailfwd_exist ## 1/0/undef
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->emailfwd_check($email);
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub emailfwd_info
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->try_restore_from_cache('emailfwd',$email,'info');
 if (! defined $rc) { $rc=$ndr->process('emailfwd','info',[$email]); }
 return $rc;
}

sub emailfwd_create
{
 my ($self,$ndr,$email,$rd)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->process('emailfwd','create',[$email,$rd]);
 return $rc;
}

sub emailfwd_delete
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->process('emailfwd','delete',[$email]);
 return $rc;
}

sub emailfwd_update
{
 my ($self,$ndr,$email,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 ## Technical syntax check of email object needed here
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  next if $ndr->protocol_capable('emailfwd_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of emailfwd_update/'.$t);
 }

 my $rc=$ndr->process('emailfwd','update',[$email,$tochange]);
 return $rc;
}

sub emailfwd_renew
{
 my ($self,$ndr,$email,$rd)=@_;
 ## Technical syntax check of email object needed here
 Net::DRI::Util::check_isa($rd->{duration},'DateTime::Duration') if defined($rd->{duration});
 Net::DRI::Util::check_isa($rd->{current_expiration},'DateTime') if defined($rd->{current_expiration});
 return $ndr->process('emailfwd','renew',[$email,$rd->{duration},$rd->{current_expiration}]);
}

####################################################################################################
1;
