package Net::DRI::DRD::HostmasterUA;
#===============================================================================
#
#         FILE:  HostmasterUA.pm
#
#  DESCRIPTION:
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  03/11/2013 04:20:36 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

#__PACKAGE__->make_exception_for_unavailable_operations(qw/host_check host_info host_update host_delete host_create contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_renew/);

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1 .. 10); }
sub name     { return 'HostmasterUA'; }
sub tlds     { return ('kiev.ua', 'com.ua', 'epp.ua', 'ua'); }
sub object_types { return ('domain','contact','host'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UA',{}) if $type eq 'epp';
 return;
}

####################################################################################################
1;
