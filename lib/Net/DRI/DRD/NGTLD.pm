## Domain Registry Interface, NGTLD Super DRD
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::NGTLD;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

####################################################################################################

=pod

=head1 NAME

Net::DRI::DRD::NGTLD - Generic New gTLD Driver for Net::DRI - Aka, the SuperDRD

=head1 DESCRIPTION

Additional domain extension for [most?] New Generic TLDs. This extension distinguishes between back end providers to select extensions, tld lists and some other config for the DRD. The providers listed her are loosely referred to as back end providers. Some registries may have multiple providers, and most providers have multiple registries. For example, Demand Media provides the backed for Donuts and Rightside Registry, but as both of these hold multiple TLDs in a shared registry distinct fro each other, each is their own provider in this driver.

=cut


=pod

=head1 SYNOPSYS

=head3 Usage

Load up Net::DRI as normal

 use Net::DRI;
 my $dri=Net::DRI->new(...);

=head3 Basic

Simply add NGTLD with defaults - not this is not really tested... at all. Rather specify a backend provider as below

 $dri->add_registry('NGTLD',{clid => 'ClientX'});
 $dri->target('NGTLD')->add_current_profile(....);

=head3 Options

There are a number of options that can be defined in the hash send to this unit

=over

=item provider  : select backend provider, this is case-insensitive

=item name : optionally set the 'target' name (default = provider) in the case of backends that have multiple distinct platforms

=item tlds : optionally send a specified list of TLDs. And empty array ref will result in any tlds being allowed

=back

 $dri->add_registry('NGTLD',{clid => '...',provider=>'...',name=>'...', tlds=>[]});

=head3 Selecting a back end provider

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'Neustar'});
 $dri->target('Neustar')->add_current_profile(....);

=head3 Backend providers with shared environments

Donuts is an example of a backend that provides a single platform for all their TLDs. Normally only specifying the provider will suite your needs

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'donuts'});
 $dri->target('donuts')->add_current_profile(....);

=head3 Backend providers with dedicated environments

Neustar is an example of a backend provider that provides a dedicated environment per TLD, so you may like to use the TLD as the target name.
e.g: add a custom target name, by default this is the back end provider name, but in this instance we select buzz
Note, if the name you specified matches one of the TLD's and you have not manually specified the tld list, if will use only this TLD. If the name doesn't match a TLD, it will make all TLD's by the prover available in the DRD

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'buzz'});
 $dri->target('buzz')->add_current_profile(....);

=cut

sub new
{
 my $class=shift;
 my $beprd = { %{$_[0]} } if (ref($_[0]) eq 'HASH' && defined $_[0]->{provider});
 undef $beprd->{name} unless exists $beprd->{name};
 my $self=$class->SUPER::new(@_);
 ($self->{info}->{provider},$self->{bep}) = undef;
 if (defined $beprd)
 {
  $self->{info}->{provider} = $beprd->{provider};
  $self->{bep} = $self->build_back_end_provider_info($beprd->{provider},$beprd->{name},(exists $beprd->{tlds} ? @{$beprd->{tlds}} : undef));
  if (my $req = $self->_get_bep_key('requires'))
  {
   foreach my $mod (@{$req}) { Net::DRI::Util::load_module($mod); }
  }
  $self->_set_bep_key('name',$beprd->{name}) if $beprd->{name};
  $self->_set_bep_key('name',$beprd->{provider}) unless $beprd->{name};
  if (exists $beprd->{tlds} && $beprd->{tlds} && ref($beprd->{tlds}) eq 'ARRAY') {
   $self->_set_bep_key('tlds',$beprd->{tlds});
  } elsif ($self->_get_bep_key('bep_type') && $self->_get_bep_key('bep_type')==1 && $beprd->{name}) { # select TLD for dedicated backends
   $self->_set_bep_key('tlds',[$beprd->{name}]) if (grep /$beprd->{name}/i,@{$self->_get_bep_key('tlds')});
  }
 }
 $self->{info}->{host_as_attr} = $self->_has_bep_key('host_as_attr') ? $self->_get_bep_key('host_as_attr') : 0;
 $self->{info}->{contact_i18n} = $self->_has_bep_key('contact_i18n') ? $self->_get_bep_key('contact_i18n') : 4; ## LOC+INT is default
 $self->{info}->{check_limit} = $self->_has_bep_key('check_limit') ? $self->_get_bep_key('check_limit') : 13; # DRD defaults to 10, but its probably 13 ?
 $self->{info}->{contact_check_limit} = $self->_has_bep_key('contact_check_limit') ? $self->_get_bep_key('contact_check_limit') : $self->{info}->{check_limit}; #  default to check_limit if no host_check_limit
 $self->{info}->{host_check_limit} = $self->_has_bep_key('host_check_limit') ? $self->_get_bep_key('host_check_limit') : $self->{info}->{check_limit}; #  default to check_limit if no hostn_check_limit
 $self->{info}->{domain_check_limit} = $self->_has_bep_key('domain_check_limit') ? $self->_get_bep_key('domain_check_limit') : $self->{info}->{check_limit}; #  default to check_limit if no domain_check_limit
 return $self;
}

sub periods       { return $_[0]->_has_bep_key('periods') ? @{$_[0]->_get_bep_key('periods')} : return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return $_[0]->_has_bep_key('name') ? $_[0]->_get_bep_key('name') : 'NGTLD'; }
sub tlds          { return $_[0]->_has_bep_key('tlds') ? @{$_[0]->_get_bep_key('tlds')} : (); }
sub object_types  { return $_[0]->_has_bep_key('object_types') ? @{$_[0]->_get_bep_key('object_types')} : ('domain','contact','ns'); }
sub profile_types { return $_[0]->_has_bep_key('whois_server') ? ('epp','whois') : ('epp'); }
#sub profile_types { return $_[0]->_has_bep_key('profile_types') ? @{$_[0]->_get_bep_key('profile_types')} : ('epp'); }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ($self->_has_bep_key('transport_protocol_default') ? @{$self->_get_bep_key('transport_protocol_default')} : ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{})) if $type eq 'epp';
 if ($type =~ m/^whois/)
 {
  return unless $self->_has_bep_key('whois_server') || $self->_has_bep_key('registrar_whois_server');
  return ('Net::DRI::Transport::Socket',{remote_host=>$self->_get_bep_key('registrar_whois_server')},'Net::DRI::Protocol::Whois',{'NGTLD'=>1} ) if $type eq 'whois-registrar' && $self->_has_bep_key('registrar_whois_server');
  return ('Net::DRI::Transport::Socket',{remote_host=>$self->_get_bep_key('whois_server')},'Net::DRI::Protocol::Whois',{'NGTLD'=>1} );
 }
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 return unless my $f = $self->_get_bep_key('factories');
 foreach my $factory (@{$f}) {
   $po->factories($factory->{object},$factory->{factory});
 }
 return;
}

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{
     check_name => $self->_has_bep_key('verify_check_name')?$self->_get_bep_key('verify_check_name'):1, # default on, checks dots etc ?
     icann_reserved => $self->_has_bep_key('verify_icann_reserved')?$self->_get_bep_key('verify_icann_reserved'):0, # TODO - disabled for now, this process needs reviewing with new gTLDs NXD/collisions releases etc.
     my_tld => ($self->_get_bep_key('tlds')), # by default it will verify TLD if there is a TLD list
   });
}

sub _set_bep_key
{
 my ($self,$key,$value) = @_;
 return unless defined $self->{info}->{provider};
 my $bep = lc($self->{info}->{provider});
 $self->{bep} = {} unless exists $self->{bep};
 $self->{bep}->{$key} = $value;
 return;
}

sub _get_bep_key
{
 my ($self,$key) = @_;
 return unless defined $self->{info}->{provider};
 my $bep = lc($self->{info}->{provider});
 return (exists $self->{bep} && exists $self->{bep}->{$key}) ? $self->{bep}->{$key} : undef;
}

sub _has_bep_key
{
 my ($self,$key) = @_;
 return unless defined $self->{info}->{provider};
 my $bep = lc($self->{info}->{provider});
 return exists $self->{bep} && exists $self->{bep}->{$key};
}

####################################################################################################
## Backend Provider Info

=head1 PROVIDERS

=head2 Standard extensions:

The following standard extensions are used for most gTLDs and will be utilised unless otherwise configured.

L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=cut

sub build_back_end_provider_info
{
 my ($self,$bep,$name,$tld) = @_;
 $bep = lc($bep);
 $tld = (defined $name ? $name : '') unless $tld;
 $tld = lc($tld);


=pod

=head2 AFNIC

 $dri->add_registry('NGTLD',{provider=>'afnic'});

=head3 Status: Working

=head3 TLDs

alsace aquarelle aquitaine banque bzh corsica frogans lancaster leclerc mma ovh paris sncf

=cut

 return {
     bep_type => 1, # dedicated regsitry
     tlds => ['alsace', 'aquarelle', 'aquitaine', 'banque', 'bzh', 'corsica', 'frogans', 'lancaster', 'leclerc', 'mma', 'ovh', 'paris', 'sncf'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1,'custom'=>['AFNIC_GTLD::RegistryMessage', 'AFNIC_GTLD::PremiumDomain']}],
     contact_i18n => 1, # can only use the "loc" type
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'afnic';

=pod


=head2 Afilias

Afilias operates a shared enveronment for its own TLDs (set provider to 'afilias'), and a separate shared environment for their clients ('afiliassrs').

=head3 Status: Working

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Price> urn:ietf:params:xml:ns:price-1.0

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=head3 Afilias Own TLDs

Afilias has extended the .INFO plaform to include these newGTLDs

 $dri->add_registry('NGTLD',{provider=>'afilias'}); # own tlds

info mobi pro xn--6frz82g bet black blue green kim lgbt lotto meet organic pet pink poker promo red shiksha vote voto

Contended TLD's not included

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['info','mobi','pro','law.pro','jur.pro','bar.pro','med.pro','cpa.pro','aca.pro','eng.pro',
              'xn--6frz82g','bet','black','blue','green','kim','lgbt','lotto','meet','organic','pet','pink','poker','promo','red','shiksha','vote','voto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.8'}],
     whois_server => 'whois.afilias.net',
   } if $bep eq 'afilias';

=pod

=head3 Afilias Client TLDs

Afilias SRS has extended the .XXX plaform to include these newGTLDs

 $dri->add_registry('NGTLD',{provider=>'afiliassrs'});

xxx xn--4gbrim xn--kput3i adult bnpparibas creditunion ged global indians irish ist istanbul ltda onl porn rich sex srl storage vegas

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xxx','me','mobi','xn--4gbrim','xn--kput3i','adult','bnpparibas','creditunion','ged','global','indians','irish','ist','istanbul','ltda','onl','porn','rich','sex','srl','storage','vegas'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.8'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'afiliassrs';


=pod

=head2 Amazon Registry Services, Inc. (provider: Neustar)

 $dri->add_registry('NGTLD',{provider=>'amazon'});

=head3 Status: Untested

=head3 TLDs

author aws book bot buy call circle fast got jot joy like moi pin read room safe smile song spot talk tunes tushu wanggou xn--1ck2e1b xn--bck1b9a5dre4c xn--cck2b3b xn--eckvdtc9d xn--fct429k xn--gckr3f0f yamaxun you zero

=head3 Custom extensions

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.6

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['author','aws','book','bot','buy','call','circle','fast','got','jot','joy','like','moi','pin','read','room','safe','smile','song','spot','talk','tunes','tushu','wanggou','xn--1ck2e1b','xn--bck1b9a5dre4c','xn--cck2b3b','xn--eckvdtc9d','xn--fct429k','xn--gckr3f0f','yamaxun','you','zero'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.6' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'amazon';



=pod

=head2 ARI

 $dri->add_registry('NGTLD',{provider=>'ari'});

=head3 Status: Working

=head3 TLDs

xn--kcrx77d1x4a xn--mgba7c0bbn0a xn--ngbc5azd afl anz barclaycard barclays bond boots bridgestone build cancerresearch cba cloud commbank compare courses cuisinella doha film firestone giving ibm icu iinet iselect krd latrobe luxury melbourne men menu monash mtn netbank olayan olayangroup one philips physio playstation quest sandvik sandvikcoromant saxo schmidt scor seek select seven sony starhub study sucks sydney tab trust virgin vista vistaprint walter woodside wtc

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::ARI::Application> urn:ar:params:xml:ns:application-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::Trademark> urn:ar:params:xml:ns:tmch-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::IDN> urn:ar:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::Variant> urn:ar:params:xml:ns:variant-1.1

L<Net::DRI::Protocol::EPP::Extensions::ARI::Price> urn:ar:params:xml:ns:price-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail> urn:ar:params:xml:ns:exAvail-1.0

=head3 Notes

1. ARI's implementation of LaunchPhase (TMCH) differers from the standard, however the units are built to mimic the standard extension's usage

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xn--kcrx77d1x4a', 'xn--mgba7c0bbn0a', 'xn--ngbc5azd', 'afl', 'anz', 'barclaycard', 'barclays', 'bond', 'boots', 'bridgestone', 'build', 'cancerresearch', 'cba', 'cloud', 'commbank', 'compare', 'courses', 'cuisinella', 'doha', 'film', 'firestone', 'giving', 'ibm', 'icu', 'iinet', 'iselect', 'krd', 'latrobe', 'luxury', 'melbourne', 'men', 'menu', 'monash', 'mtn', 'netbank', 'olayan', 'olayangroup', 'one', 'philips', 'physio', 'playstation', 'quest', 'sandvik', 'sandvikcoromant', 'saxo', 'schmidt', 'scor', 'seek', 'select', 'seven', 'sony', 'starhub', 'study', 'sucks', 'sydney', 'tab', 'trust', 'virgin', 'vista', 'vistaprint', 'walter', 'woodside', 'wtc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}],
     whois_server => 'whois.aridnrs.net.au',
   } if $bep eq 'ari';


=pod


=head2 CentralNIC

 $dri->add_registry('NGTLD',{provider=>'centralnic'});

=head3 Status: Working

=head3 TLDs

bar college contact design fan fans feedback host ink love online pid press protection reit rent rest security site space tech theatre tickets website wiki wme xyz

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.4

=head3 Notes

1. CentralNIC also provides some ccTLDs and sLDs. These are not included here yet as some testing is required.

=cut

 if ($bep eq 'centralnic') {
    my @coms = (map { $_.'.com' } qw/africa ar br cn de eu gb gr hu jpn kr mex no qc ru sa se uk us uy za/);
    my @nets = (map { $_.'.net' } qw/uk se gb jp hu in/);
    my @orgs = (map { $_.'.org' } qw/us ae/);
    my @others = qw/pw com.de/;
    my @ngtlds = qw/bar college contact design fan fans feedback host ink love online pid press protection reit rent rest security site space store tech theatre tickets website wiki wme xyz/;
    my @ngtlds_contested = qw/reality/; # some of these might go to other registries, tbc later as these are expected in Q4 2014
    my @ngtlds_pipeline = qw/art now hotel forum gay app mail llc/; # no expected dates given, probably contested strings
    my @tlds = (@coms,@nets,@orgs,@others,@ngtlds);

    return {
     bep_type => 2, # shared registry
     tlds => \@tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','CentralNic::RegType','CentralNic::AuxContact'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
     verify_icann_reserved => 0,
     verify_check_name => 0,
    };
 }

=pod


=head2 CoreNIC

 $dri->add_registry('NGTLD',{provider=>'corenic'});

=head3 Status: Working

=head3 TLDs

xn--80asehdb xn--80aswg xn--mgbab2bd art barcelona eurovision erni eurovision eus gal lacaixa madrid mango museum quebec radio scot sport swiss

=head3 Custom extensions: (From Tango-RS but with CoreNIC namespaces)

L<Net::DRI::Protocol::EPP::Extensions::TANGO::IDN> : http://xmlns.corenic.net/epp/idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Auction> : http://xmlns.corenic.net/epp/auction-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::LaunchPhase> : http://xmlns.corenic.net/epp/mark-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::ContactEligibility> : http://xmlns.corenic.net/epp/contact-eligibility-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Promotion> : http://xmlns.corenic.net/epp/promotion-1.0

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['xn--80asehdb','xn--80aswg','xn--mgbab2bd','art','barcelona','eurovision','erni','eurovision','eus','gal','lacaixa','madrid','mango','museum','quebec','radio','scot','sport','swiss'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORENIC',{}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'corenic';

=pod


=head2 CNNIC (China Internet Network Information Center)

 $dri->add_registry('NGTLD',{provider=>'cnnic'});

=head3 Status: Working

=head3 TLDs

xn--io0a7i xn--1qqw23a xn--xhq521b xn--55qx5d

Contended TLD's not included

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xn--io0a7i','xn--1qqw23a','xn--xhq521b','xn--55qx5d'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CNNIC',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::CNNIC->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::CNNIC'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef), ## FIXME check this and test whois?
   } if $bep eq 'cnnic';

=pod

=head2 CoCCA

 $dri->add_registry('NGTLD',{provider=>'cocca'});

=head3 Status: Working

=head3 TLDs

xn--p1acf xn--mgbt3dhd pars islam wed nowruz persiangulf tci shia halal

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['xn--p1acf','xn--mgbt3dhd','pars','islam','wed','nowruz','persiangulf','tci','shia','halal'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CoCCA::Notifications', 'CentralNic::Fee'], 'brown_fee_version' => '0.8'}],
   } if $bep eq 'cocca';

=pod


=head2 CRR (Charleston Road Registry)

 $dri->add_registry('NGTLD',{provider=>'crr'});

=head3 Status: Working

=head3 TLDs

xn--flw351e xn--q9jyb4c xn--qcka1pmc ads android boo cal channel chrome dad day eat esq fly foo gbiz gle gmail google here how ing kid meme mov new nexus prod prof rsvp soy tour youtube zip

=head3 Notes

1. CRR does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

=cut

 return {
     bep_type => 2, # shared
     tlds => ['xn--flw351e','xn--q9jyb4c','xn--qcka1pmc','ads','android','boo','cal','channel','chrome','dad','day','eat','esq','fly','foo','gbiz','gle','gmail','google','here','how','ing','kid','meme','mov','new','nexus','prod','prof','rsvp','soy','tour','youtube','zip'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee'], 'disable_idn'=>1, 'brown_fee_version' => '0.6'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'crr';


=pod


=head2 Donuts

 $dri->add_registry('NGTLD',{provider=>'donuts'});

=head3 Status: Working

=head3 TLDs

academy accountants agency apartments architect associates bargains bike bingo boutique builders business cab cafe camera camp capital cards care careers cash casino catering center chat cheap church city claims cleaning clinic clothing coach codes coffee community company computer condos construction contractors cool coupons credit creditcard cruises dating deals delivery dental diamonds digital direct directory discount doctor dog domains education email energy engineering enterprises equipment estate events exchange expert exposed express fail farm finance financial fish fitness flights florist football foundation fund furniture fyi gallery gifts gold golf glass gmbh graphics gratis gripe group guide guru healthcare hockey holdings holiday hospital house immo industries institute insure international investments jetzt jewelry kitchen land lease legal life lighting limited limo loans ltd maison management mba marketing media medical memorial money movie network partners parts pets photography photos pictures pizza place plumbing plus productions properties recipes reise reisen rentals repair report restaurant run salon sarl school schule services shoes shopping show singles soccer solar solutions sports style supplies supply support surgery systems tax taxi team technology tennis theater tienda tips tires today tools tours town toys training university vacations ventures viajes villas vin vision voyage watch wine world works wtf xn--czrs0t xn--unup4y xn--vhquv zone

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

=head3 DPML Blocks / Overrides:

In order to submit DPML blocks OR DMPL Overrides, submit a domain_create with the correct TLD (.dpml.zone for block) and the LaunchPhase extensions should contain the [Encoded] Signed Mark, along with the phase name 'dpml'

  $dri->domain_create('mylabel.dpml.zone',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   });# DPML Block
  $dri->domain_create('mylabel.energy',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   }); # DPML Override

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['dpml.zone','academy','accountants','agency','apartments','architect','associates','bargains','bike','bingo','boutique','builders','business','cab','cafe','camera','camp','capital','cards','care','careers','cash','casino','catering','center','chat','cheap','church','city','claims','cleaning','clinic','clothing','coach','codes','coffee','community','company','computer','condos','construction','contractors','cool','coupons','credit','creditcard','cruises','dating','deals','delivery','dental','diamonds','digital','direct','directory','discount','doctor','dog','domains','education','email','energy','engineering','enterprises','equipment','estate','events','exchange','expert','exposed','express','fail','farm','finance','financial','fish','fitness','flights','florist','football','foundation','fund','furniture','fyi','gallery','gifts','gold','golf','glass','gmbh','graphics','gratis','gripe','group','guide','guru','healthcare','hockey','holdings','holiday','hospital','house','immo','industries','institute','insure','international','investments','jetzt','jewelry','kitchen','land','lease','legal','life','lighting','limited','limo','loans','ltd','maison','management','mba','marketing','media','medical','memorial','money','movie','network','partners','parts','pets','photography','photos','pictures','pizza','place','plumbing','plus','productions','properties','recipes','reise','reisen','rentals','repair','report','restaurant','run','salon','sarl','school','schule','services','shoes','shopping','show','singles','soccer','solar','solutions','sports','style','supplies','supply','support','surgery','systems','tax','taxi','team','technology','tennis','theater','tienda','tips','tires','today','tools','tours','town','toys','training','university','vacations','ventures','viajes','villas','vin','vision','voyage','watch','wine','world','works','wtf','xn--czrs0t','xn--unup4y','xn--vhquv','zone'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{'ssl_version'=>'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
     whois_server => 'whois.donuts.co',
     check_limit => 5,
   } if $bep eq 'donuts';


=pod


=head2 Famous Four Media (Utilising Neustar)

 $dri->add_registry('NGTLD',{provider=>'ffm'});

=head3 Status: Untested

=head3 TLDs

accountant bid cricket date download faith loan party racing review science stream trade webcam win

Contension: app baby cam charity forum hotel music rugby search sport

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::Fee> urn:ietf:params:xml:ns:neulevel-1.0

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['accountant', 'bid', 'cricket', 'date', 'download', 'faith', 'loan', 'party', 'racing', 'review', 'science', 'stream', 'trade', 'webcam', 'win', # uncontended
              'app', 'baby', 'cam', 'charity', 'forum', 'hotel', 'music', 'rugby', 'search', 'sport',# contended
             ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.6' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'ffm';



=pod


=head2 GMO Registry

GMO uses a shared enveronment (account) for its own TLDs (set provider to 'gmo') and a separate shared account for geoTLDs (set provider to 'gmogeo'), and possibly more.

 $dri->add_registry('NGTLD',{provider=>'gmo'}); # Own: nagoya tokyo yokohama
 $dri->add_registry('NGTLD',{provider=>'gmogeo'}); # Geo: okinawa ryukyu
 $dri->add_registry('NGTLD',{provider=>'gmokyoto'}); # kyoto
 $dri->add_registry('NGTLD',{provider=>'gmoshop'}); # shop

=head3 Status: Working

=head3 TLDs

Own: nagoya tokyo yokohama
Geo: okinawa ryukyu
Kyoto: kyoto
Shop: shop

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.5

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['nagoya','tokyo','yokohama'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmo';

 return {
     bep_type => 2, # shared registry
     tlds => ['okinawa','ryukyu'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmogeo';

 return {
     bep_type => 2, # shared registry
     tlds => ['kyoto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmokyoto';

 return {
     bep_type => 2, # shared registry
     tlds => ['shop'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmoshop';

=pod


=head2 KNET

 $dri->add_registry('NGTLD',{provider=>'knet'});

=head3 Status: Working

=head3 Custom extensions

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.8

=head3 TLDs

xn--45q11c xn--3bst00m xn--ses554g xn--efvy88h xn--czr694b xn--czru2d xn--6qq986b3xl xn--30rr7y xn--imr513n xn--otu796d xn--9et52u xn--hxt814e wang top

Contended TLD's not included

=head3 Notes

1. KNET does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

2. It looks as though KNET will run a shared EPP registry, but this is TBC

=cut

 return {
     bep_type => 2,
     tlds => ['xn--45q11c','xn--3bst00m','xn--ses554g','xn--efvy88h','xn--czr694b','xn--czru2d','xn--6qq986b3xl','xn--30rr7y','xn--imr513n','xn--otu796d','xn--9et52u','xn--hxt814e','wang','top'],
     # tlds => ['open'], # use this if using their OT&E. We can only test with this TLD!
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.8' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'knet';

=pod


=head2 KS Registry (Key Sytems)

 $dri->add_registry('NGTLD',{provider=>'ks'});

=head3 Status: Working

=head3 Custom extensions

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=head3 TLDs

desi saarland

=cut

 return {
     bep_type => 1, # dedicated
     tlds => ['desi', 'saarland'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.7' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'ks';


=pod


=head2 Minds And Machines

M&M uses a shared enveronment for its own TLDs (set provider to 'mam' or 'mamown'), dedicted environments for partner TLDs ('mamsrs' or 'mampartner'), and a separate shared environment for their clients ('mamclient'). *However*, this might change somewhat, so please note that this M+M section might need adjusting and they release more info.

=head3 Status: Working

=head3 M+M Own TLDs

 $dri->add_registry('NGTLD',{provider=>'mam'}); # M+M Own TLDs, 'mam' or 'mamown'

Uncontested: abogado bayern beer budapest casa cooking country fashion fishing fit garden horse law luxe miami rodeo surf vip vodka wedding work yoga xn--g2xx48c


Contested: app art baby beauty coupon cpa data dds eco gay home hotel inc latino llc realestate

Collisions: cooking-collisions country-collisions fishing-collisions'horse-collisions rodeo-collisions vodka-collisions
=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['abogado', 'bayern', 'beer', 'budapest', 'casa', 'cooking', 'country', 'fashion', 'fishing', 'fit', 'garden', 'horse', 'law',  'luxe', 'miami', 'rodeo', 'surf',  'vip', 'vodka', 'wedding', 'work', 'yoga', 'xn--g2xx48c',
              'app', 'art', 'baby', 'beauty', 'coupon', 'cpa', 'data', 'dds', 'eco', 'gay', 'home', 'hotel', 'inc', 'latino','llc', 'realestate',
              'cooking-collisions', 'country-collisions', 'fishing-collisions', 'horse-collisions', 'rodeo-collisions', 'vodka-collisions',
             ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee','MAM::QualifiedLawyer']}],
     whois_server => 'whois-dub.mm-registry.com',
   } if $bep eq 'mam' || $bep eq 'mamown';

=pod

=head3 M+M Partner TLDs

 $dri->add_registry('NGTLD',{provider=>'mamsrs'}); # M+M In Partnership 'mamsrs' or 'mampartner'

Uncontested: london review rugby

Contested: basketball music

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['london', 'london-collisions', 'review', 'rugby',
              'basketball', 'music',
             ],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],
   } if $bep eq 'mamsrs' || $bep eq 'mampartner';

=pod

=head3 M+M Client TLDs

 $dri->add_registry('NGTLD',{provider=>'mamclient'}); # M+M Clients 'mamclient'

Uncontested: gop kiwi

Contested: broadway radio

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['gop', 'kiwi',
              'broadway', 'radio'
             ],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],
   } if $bep eq 'mamclient';

=pod


=head2 Neustar

 $dri->add_registry('NGTLD',{provider=>'neustar'});

=head3 Status: Working

=head3 TLDs

xn--g2xx48c xn--nyqy26a xn--rhqv96g best bible buzz ceo club earth ferrero hoteles hsbc htc kinder moe nyc osaka pharmacy qpon rocher safety taipei teva tube uno whoswho

Contended TLD's not included

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::Fee> urn:ietf:params:xml:ns:neulevel-1.0

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::NYCContact> urn:ietf:params:xml:ns:neulevel-1.0 (For .NYC Only)

=head3 Notes

Neustar operates dedicated connections per TLD, so it is recommended to use the name parameter to select the TLD.
In the case of NYC it is required to either set name or tlds parameter in order to load the Nexus extension for contacts and domains.
See: L<Net::DRI::Data::Contact::NYC> and L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact>

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'nyc'}); # using name
 $dri->target('nyc')->add_current_profile(....);
 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'whatever',tlds=['nyc']}); # using tld

=cut
 return {
     bep_type => 1, # dedicated registry
     tlds => ['nyc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom=>'NeuLevel::EXTContact'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::NYC->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::NYC'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'neustar' && $tld eq 'nyc';

 ## these use NeuLevel::Fee for "Tier 1 pricing model"
 return {
     bep_type => 1, # dedicated registry
     tlds => ['best', 'ceo', 'earth', 'pharmay'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom=>'NeuLevel::Fee'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'neustar' && $tld =~ m/(?:best|ceo|earth|pharmacy)/;

 ## these use CentralNic::Fee for "Tier 2 pricing model" or no premium extension (CentralNic::Fee is ignored by server)
 return {
     bep_type => 1, # dedicated registry
     tlds => ['xn--rhqv96g', 'xn--g2xx48c', 'xn--nyqy26a', 'bible', 'buzz', 'club', 'ferrero', 'hoteles', 'hsbc', 'htc', 'kinder', 'moe', 'osaka', 'qpon', 'rocher', 'safety', 'taipei', 'teva', 'tube', 'uno', 'whoswho'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.6' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'neustar';

=pod


=head2 NIC.br

 $dri->add_registry('NGTLD',{provider=>'nicbr'});

=head3 Status: Working

=head3 TLDs

bom final rio

=cut

 return {
     bep_type => 2, # shared registry
     host_as_attr => 1,
     contact_i18n => 1, # LOC only
     tlds => ['bom','final','rio'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
     whois_server => 'whois.gtlds.nic.br',
   } if $bep eq 'nicbr';


=pod


=head2 Nominet

 $dri->add_registry('NGTLD',{provider=>'nominet'});

=head3 Status: Working

=head3 TLDs

cymru wales bbc blog

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['blog'], ## TODO this will be all MMX Tlds
     transport_protocol_default => ['Net::DRI::Transport::Socket',{ssl_version => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','AllocationToken'], 'brown_fee_version' => '0.5' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nominet' && $tld eq 'blog';


 return {
     bep_type => 1, # dedicated registry
     tlds => ['cymru','wales','bbc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{ssl_version => 'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nominet';

=pod


=head2 OpenRegistry

 $dri->add_registry('NGTLD',{provider=>'openreg'}); # or provider = openregistry

=head3 Status: Working

=head3 TLDs

gent boston

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['gent','boston'],
     host_as_attr => 1,
     contact_i18n => 2,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1,custom=>['OpenRegistry::Domain']}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep =~ m/^openreg(istry)?$/;


=pod


=head2 PIR (Public Information Registry)

 $dri->add_registry('NGTLD',{provider=>'pir'});

=head3 Status: Untested

=head3 TLDs

org xn--c1avg xn--i1b6b1a6a2e xn--nqv7f xn--tqq33ed31aqia ngo ong

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Validation> urn:ietf:params:xml:ns:validation-1.0

=head3 Notes

1. PIR has extended the .ORG plaform to include these newGTLDs

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['org','xn--c1avg','xn--i1b6b1a6a2e','xn--nqv7f','xn--tqq33ed31aqia','ngo','ong'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::PIR',{'brown_fee_version' => '0.7'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'pir';


=pod


=head2 RegBox (Registry-in-a-Box from NicAT)

 $dri->add_registry('NGTLD',{provider=>'regbox'});

=head3 Status: Working

=head3 TLDs

bh berlin brussels hamburg tirol versicherung vlaanderen voting wien ikano

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::RegBox::ServiceMessage> http://tld-box.at/xmlns/resdata-1.1

=head3 Notes

1. RegBox does not use the IDN extension.

2. RegBox does not use billing contacts.

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['bh','berlin','brussels','hamburg','tirol','versicherung','vlaanderen','voting','wien','ikano'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RegBox',{'brown_fee_version' => '0.9'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::RegBox->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::RegBox'],
     contact_i18n => 2,
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'regbox';



=pod


=head2 Rightside (UnitedTLD)

 $dri->add_registry('NGTLD',{provider=>'rightside'});

=head3 Status: Working

=head3 TLDs

dpml.pub actor airforce army attorney auction band consulting dance degree democrat dentist engineer family forsale futbol games gives haus immobilien kaufen lawyer live market moda mortgage navy news ninja pub rehab republican reviews rip rocks sale social software studio vet video

Contended TLD's not included

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

=head3 DPML Blocks / Overrides:

In order to submit DPML blocks OR DMPL Overrides, submit a domain_create with the correct TLD (.dpml.pub for block) and the LaunchPhase extensions should contain the [Encoded] Signed Mark, along with the phase name 'dpml'

  $dri->domain_create('mylabel.dpml.pub',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   });# DPML Block
  $dri->domain_create('mylabel.energy',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   }); # DPML Override

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['dpml.pub','actor','airforce','army','attorney','auction','band','consulting','dance','degree','democrat','dentist','engineer','family','forsale','futbol','games','gives','haus','immobilien','kaufen','lawyer','live','market','moda','mortgage','navy','news','ninja','pub','rehab','republican','reviews','rip','rocks','sale','social','software','studio','vet','video'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{'ssl_version'=>'TLSv12'},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
     whois_server => 'whois.rightside.co',
     check_limit => 5,
   } if $bep eq 'rightside';


=pod


=head2 SIDN

 $dri->add_registry('NGTLD',{provider=>'sidn'});

=head3 Status: Working

=head3 TLDs

amsterdam


=cut

 return {
     bep_type => 1, # dedicated Registry
     tlds => ['amsterdam'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::SIDN_GTLD',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::SIDN->new(@_); } } ],
     contact_i18n => 1, ## LOC only
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'sidn';

=pod


=head2 NicMX

 $dri->add_registry('NGTLD',{provider=>'nicmx'});

=head3 Status: Working

=head3 TLDs

lat

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::MX::Domain>
L<NET::DRI::Protocol::EPP::Extensions::MX::Rar>
L<NET::DRI::Protocol::EPP::Extensions::MX::Message>
L<NET::DRI::Protocol::EPP::Extensions::MX::AdmStatus>
L<NET::DRI::Protocol::EPP::Extensions::MX::IDN>

=cut

 return {
     bep_type => 1, # dedicated Registry
     tlds => ['lat'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::MX_GTLD',{}],
     contact_i18n => 1,
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nicmx';

=pod


=head2 StartingDot (Provided by Key Sytems)

 $dri->add_registry('NGTLD',{provider=>'startingdot'});

=head3 Status: Working

=head3 TLDs

archi bio ski

=head3 Custom extensions

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['archi', 'bio', 'ski'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.7' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'startingdot';


=pod


=head2 Tango-RS

 $dri->add_registry('NGTLD',{provider=>'tango'});

=head3 Status: Working

=head3 TLDs

ruhr cologne gmx ifm koeln nrw

pay is in contention

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::TANGO::IDN> urn:ar:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Auction> urn:ar:params:xml:ns:auction-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::LaunchPhase> : http://xmlns.corenic.net/epp/mark-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.6

Fee extension is currently only used in .NRW and for domain_check command only.

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['ruhr','cologne','gmx','ifm','koeln','nrw'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TANGO',{enable_fee => ($tld eq 'nrw')}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'tango';

=pod


=head2 TCI (cctld.ru)

$dri->add_registry('NGTLD',{provider=>'tci'});

=head3 Status: Working

=head3 TLDs

moscow tatar xn--d1acj3b xn--1-7sbc5ceg xn--2-7sbc5ceg  xn--80adxhks

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Contact> http://www.tcinet.ru/epp/tci-contact-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Domain> http://www.tcinet.ru/epp/tci-domain-ext-1.0

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['moscow', 'tatar', 'xn--d1acj3b', 'xn--1-7sbc5ceg', 'xn--2-7sbc5ceg', 'xn--80adxhks'],
     contact_i18n => 7, # and or ?
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::TCI_gTLD->new(@_); } } ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TCI_gTLD',{}],
   } if $bep eq 'tci';

=pod


=head2 Teleinfo

$dri->add_registry('NGTLD',{provider=>'teleinfo'});

=head3 Status: Working

=head3 TLDs

xn--3ds443g xn--fiq228c5hs xn--vuq861b

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xn--3ds443g', 'xn--fiq228c5hs', 'xn--vuq861b'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
     whois_server => 'whois.teleinfo.cn',
   } if $bep eq 'teleinfo';

=pod


=head2 UniRegistry (Internet Systems Consortium)

 $dri->add_registry('NGTLD',{provider=>'unireg'});

=head3 Status: Working

=head3 TLDs

art audio auto blackfriday car cars christmas click deal diet flowers free game garden gift guitars help hiphop hiv home hosting inc juegos link lol mom photo pics property realestate save sexy tattoo yoga

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::UNIREG::Centric> http://ns.uniregistry.net/centric-1.0

=head3 Other extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=cut

 if ($bep eq 'unireg') {
  # These methods are in the DRD
  require Net::DRI::DRD::UNIREG;
  *market_check = sub { return Net::DRI::DRD::UNIREG::market_check(@_); };
  *market_info= sub { return Net::DRI::DRD::UNIREG::market_info(@_); };
  *market_create= sub { return Net::DRI::DRD::UNIREG::market_create(@_); };
  *market_update= sub { return Net::DRI::DRD::UNIREG::market_update(@_); };
 }

 return {
     bep_type => 2, # shared registry
     tlds => ['art','audio','auto','blackfriday','car','cars','christmas','click','deal','diet','flowers','free','game','garden','gift','guitars','help','hiphop','hiv','home','hosting','inc','juegos','link','lol','mom','photo','pics','property','realestate','save','sexy','tattoo','yoga'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNIREG',{'brown_fee_version' => '0.7'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UNIREG->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UNIREG'],
     whois_server => 'whois.uniregistry.net',
   } if $bep eq 'unireg';

=pod


=head2 Verisign

 $dri->add_registry('NGTLD',{provider=>'verisign'});

=head3 Status: Working

=head3 TLDs

xn--pssy2u xn--c1yn36f xn--11b4c3d xn--t60b56a xn--c2br7g xn--42c2d9a xn--j1aef xn--3pxu8k xn--hdb9cza1b xn--mk1bu44c xn--fhbei xn--tckwe azure bank bing broker career cfd crs forex hotmail insurance java maif markets microsoft ooo oracle pictet realtor sca shell sky spreadbetting trading xbox windows

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::PollLowBalance>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::PollRGP>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::IDNLanguage>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoWas>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Suggestion>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::ClientAttributes>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::TwoFactorAuth>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::ZoneManagement>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Balance>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::NameStore>
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::PremiumDomain>

=cut

 return {
     bep_type => 2,
     contact_i18n => 2, # FIXME: they appear to only accept one address, might be they either is valid?
     tlds => ['com','net','cc','tv','bz','jobs','xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','azure','bank','bing','broker','career','cfd','crs','forex','hotmail','insurance','java','maif','markets','microsoft','ooo','oracle','pictet','realtor','sca','shell','sky','spreadbetting','trading','xbox','windows'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1,custom=>['VeriSign::Sync', 'VeriSign::PollLowBalance', 'VeriSign::PollRGP', 'VeriSign::IDNLanguage', 'VeriSign::WhoWas', 'VeriSign::Suggestion', 'VeriSign::ClientAttributes', 'VeriSign::TwoFactorAuth', 'VeriSign::ZoneManagement', 'VeriSign::Balance', 'VeriSign::NameStore', 'VeriSign::PremiumDomain']}],
     whois_server => 'ccwhois.verisign-grs.com',
   } if $bep eq 'verisign';



=pod


=head2 ZACR (UniForum/ZA Central Registry)

 $dri->add_registry('NGTLD',{provider=>'zacr'});

=head3 Status: Working

=head3 TLDs

africa capetown durban joburg

=head3 Custom extensions:

L<NET::DRI::Protocol::EPP::Extensions::UNITEDTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

The extensions are optional, so no need to do anything out of the ordinary if you don't want to.

L<Net::DRI::Protocol::EPP::Extensions::COZA::Domain> http://co.za/epp/extensions/cozadomain-1-0
L<Net::DRI::Protocol::EPP::Extensions::COZA::Contact> http://co.za/epp/extensions/cozacontact-1-0

=cut

 return {
     bep_type => 1, # dedicated
     tlds => ['africa','durban','capetown','joburg'],
     host_as_attr => 1,
     object_types => ['domain','contact'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ZACR',{}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'zacr';


=pod


=head2 Other providers

Other gTLD providers may work fine using this module depending on their requirements.

TODO:

All registries in the todo list here...

=cut

 return;
}

####################################################################################################
## These methods have been moved to DRD.pm
=pod

=head1 ngTLD Domain Methods

=head2 domain_check_claims

This method wraps and normalises the claims check form. By default it will uses
'claims' as the phase. You can specify another phase (e.g.) landrush, and this
method will automatically fill in phase/sub_phase fields as required by the
backend operator. Its recommended you always use the current phase name in this
command.

 $rc = $dri->domain_check_claims('test.tld'); # standard claims lookup without phase name (use claims)
 $rc = $dri->domain_check_claims('test.tld',{'phase'=>'landrush','idn'=>{...}}); # claims lookup with phase name (recommended)

=head2 domain_check_price

Some ngTLD backend operators have extensions that support checking domain prices
(including premium prices). Unfortunately, there is a bit of a mix of how it
works, so this method attempts to standadise it somewhat. Where available,
currency, and duration (as interger for years or a DateTime::Duration
object) will be added to the lookup.

 $rc = $dri->domain_check_price('test.tld','test2.tld'); # defaults to USD / create / 1 year
 $rc = $dri->domain_check_price('test.tld','test2.tld',{'currency'=>'USD','duration'=>'1'}); # manually
 $rc = $dri->domain_check_price('test.tld','test2.tld',{'currency'=>'USD','idn'=>{...}}); # any other arguments can be specified alongside

=cut

####################################################################################################

=pod

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.

Copyright (c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


1;
