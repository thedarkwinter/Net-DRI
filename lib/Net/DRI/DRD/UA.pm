package Net::DRI::DRD::UA;
#===============================================================================
#
#         FILE:  UA.pm
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
sub name     { return 'UA'; }
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

package Net::DRI::Protocol::EPP::Extensions::UA;

use strict;

use base qw(Net::DRI::Protocol::EPP);

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({ domain    => ['http://hostmaster.ua/epp/domain-1.1', 'domain-1.1.xsd'],
             contact   => ['http://hostmaster.ua/epp/contact-1.1','contact-1.1.xsd'],
						 host      => ['http://hostmaster.ua/epp/host-1.1',   'host-1.1.xsd'],
						 graceperiod => ['http://hostmaster.ua/epp/rgp-1.1', 'rgp-1.1.xsd'],
						 uaepp       => ['http://hostmaster.ua/epp/uaepp-1.1', 'uaepp-1.1.xsd'],
          });
 $Net::DRI::Protocol::EPP::Extensions::GracePeriod::NS = 'http://hostmaster.ua/epp/rgp-1.1';
 foreach my $o (qw/contact/) { $self->capabilities('contact_update',$o,['set']); }

 foreach my $o (qw/contact license/) { $self->capabilities('domain_update',$o,['set']); }
 foreach my $o (qw/ns/) { $self->capabilities('domain_update',$o,['add', 'del']); }
 return;
}

sub core_modules
{
 my ($self,$rp)=@_;
 my @c;
 push @c, map { 'Net::DRI::Protocol::EPP::Core::'.$_ } qw/Session RegistryMessage Domain Host Contact/;
 return @c;
}

sub default_extensions { return qw(GracePeriod UA::Domain); }

####################################################################################################
1;
