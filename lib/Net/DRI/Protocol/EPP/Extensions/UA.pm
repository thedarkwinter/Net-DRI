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

sub default_extensions { return qw(GracePeriod UA::Domain UA::HostDelete); }

1;