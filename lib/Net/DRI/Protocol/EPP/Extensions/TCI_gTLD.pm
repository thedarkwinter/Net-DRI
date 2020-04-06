package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD;

use strict;

use base qw(Net::DRI::Protocol::EPP);
use Net::DRI::Data::Contact::TCI_gTLD;
use Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Message;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub setup
{
 my ($self,$rp)=@_;
 $self->ns({
                'secdns'          => 'urn:ietf:params:xml:ns:secDNS-1.1',
                'rgp'             => 'urn:ietf:params:xml:ns:rgp-1.0',
                'tci-contact-ext' => 'http://www.tcinet.ru/epp/tci-contact-ext-1.0',
                'tci-domain-ext'  => 'http://www.tcinet.ru/epp/tci-domain-ext-1.0',
                'launch'          => 'urn:ietf:params:xml:ns:launch-1.0'
          });


 $self->factories('contact',sub { return Net::DRI::Data::Contact::TCI_gTLD->new(); });
 $self->factories('message',sub { my $m= Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Message->new(@_); $m->ns($self->ns()); $m->version($self->version() ); return $m; });

 foreach my $o (qw/contact/) { $self->capabilities('contact_update',$o,['set']); }
 foreach my $o (qw/description/) { $self->capabilities('domain_update',$o,['set']); }
 foreach my $o (qw/contact/) { $self->capabilities('domain_update',$o,['set', 'add', 'del']); }
 foreach my $o (qw/ns/) { $self->capabilities('domain_update',$o,['add', 'del']); }
 return;
}

sub default_extensions {
 my ($self,$pp) = @_;
 $self->{brown_fee_version} = '0.11';
 return qw(TCI_gTLD::Contact TCI_gTLD::Domain GracePeriod SecDNS LaunchPhase IDN CentralNic::Fee);
}

####################################################################################################
1;
