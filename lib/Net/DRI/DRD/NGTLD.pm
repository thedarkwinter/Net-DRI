## Domain Registry Interface, NGTLD Super DRD
##
## Copyright (c) 2014 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

use Data::Dumper;

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

 return $self;
}

sub periods       { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name          { return $_[0]->_has_bep_key('name') ? $_[0]->_get_bep_key('name') : 'NGTLD'; }
sub tlds          {  return $_[0]->_has_bep_key('tlds') ? @{$_[0]->_get_bep_key('tlds')} : (); }
sub object_types  { return $_[0]->_has_bep_key('object_types') ? @{$_[0]->_get_bep_key('object_types')} : ('domain','contact','ns'); }
sub profile_types { return $_[0]->_has_bep_key('profile_types') ? @{$_[0]->_get_bep_key('profile_types')} : (); }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ($self->_has_bep_key('transport_protocol_default') ? @{$self->_get_bep_key('transport_protocol_default')} : ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{})) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois'; # todo, not customisable at the mo
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
     icann_reserved => $self->_has_bep_key('verify_icann_reserved')?$self->_get_bep_key('verify_icann_reserved'):1, # default verify ICANN reservered
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

=head3 Status: Untested

=head3 TLDs

alsace aquitaine banque bzh corsica ovh paris

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['alsace', 'aquitaine', 'banque', 'bzh', 'corsica', 'ovh', 'paris'],
   } if $bep eq 'afnic';

=pod


=head2 Afilias

 $dri->add_registry('NGTLD',{provider=>'afilias'});

=head3 Status: Working

=head3 TLDs

info xn--6frz82g black blue kim lgbt lotto meet organic pink red shiksha

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

=head3 Notes

1. Afilias has extended the .INFO plaform to include these newGTLDs

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['info','xn--6frz82g','black','blue','kim','lgbt','lotto','meet','organic','pink','red','shiksha'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{}],
   } if $bep eq 'afilias';


=pod


=head2 Afilias-SRS

 $dri->add_registry('NGTLD',{provider=>'afiliasrss'});

=head3 Status: Working

=head3 TLDs

xxx xn--3ds443g xn--4gbrim xn--fiq228c5hs xn--kput3i adult creditunion ged global hiv indians ltda onl porn rich storage vegas vote voto

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

=head3 Notes

1. Afilias SRS  has extended the .XXX plaform to include these newGTLDs

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xxx','xn--3ds443g','xn--4gbrim','xn--fiq228c5hs','xn--kput3i','adult','creditunion','ged','global','hiv','indians','ltda','onl','porn','rich','storage','vegas','vote','voto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{}],
   } if $bep eq 'afiliassrs';


=pod


=head2 ARI

 $dri->add_registry('NGTLD',{provider=>'ari'});

=head3 Status: Working

=head3 TLDs

xn--ngbc5azd xn--ngbrx abudhabi arab build dubai host krd luxury melbourne men menu physio press space sydney website

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
     tlds => ['xn--ngbc5azd', 'xn--ngbrx', 'abudhabi', 'arab', 'build', 'dubai', 'host', 'krd', 'luxury', 'melbourne', 'men', 'menu', 'physio', 'press', 'space', 'sydney', 'website'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}],
   } if $bep eq 'ari';


=pod


=head2 CentralNIC

 $dri->add_registry('NGTLD',{provider=>'centralnic'});

=head3 Status: Working

=head3 TLDs

bar cafe college contact fans feedback host ink pid place press rest space website wiki xyz

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
    my @others = qw/la pw com.de/;
    my @ngtlds = qw/bar cafe college contact fans feedback host ink pid place press rest space website wiki xyz/;
    my @ngtlds_contested = qw/cafe fans place reality/; # some of these might go to other registries, tbc later as these are expected in Q4 2014
    my @ngtlds_pipeline = qw/art auto design sucks pizza now hotel forum law golf school style chat gay group blog app mail love news llc/; # no expected dates given, probably contested strings
    my @tlds = (@coms,@nets,@orgs,@others,@ngtlds);

    return {
     bep_type => 2, # shared registry
     tlds => \@tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CentralNic',{}],
     verify_icann_reserved => 0,
     verify_check_name => 0,
    };
 }

=pod


=head2 CoreNIC

 $dri->add_registry('NGTLD',{provider=>'corenic'});

=head3 Status: Working

=head3 TLDs

xn--80asehdb xn--80aswg xn--mgbab2bd art barcelona eurovision eus gal madrid quebec radio scot sport swiss

=head3 Custom extensions: (From Tango-RS but with CoreNIC namespaces)

L<Net::DRI::Protocol::EPP::Extensions::TANGO::IDN> : http://xmlns.corenic.net/epp/idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Auction> : http://xmlns.corenic.net/epp/auction-1.0

=head3 Unimplemented extensions:

http://xmlns.corenic.net/epp/mark-ext-1.0 : This means thats we are not currently able submit "Custom Trademark"  and "Transliteration" applications.

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['xn--80asehdb','xn--80aswg','xn--mgbab2bd','art','barcelona','eurovision','eus','gal','madrid','quebec','radio','scot','sport','swiss'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORENIC',{}],
   } if $bep eq 'corenic';

=pod


=head2 CNNIC (China Internet Network Information Center)

 $dri->add_registry('NGTLD',{provider=>'cnnic'});

=head3 Status: Not started

=head3 TLDs

xn--io0a7i xn--1qqw23a xn--xhq521b xn--55qx5d

Contended TLD's not included

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['xn--io0a7i','xn--1qqw23a','xn--xhq521b','xn--55qx5d'],
   } if $bep eq 'cnnic';

=pod


=head2 CoCCA

 $dri->add_registry('NGTLD',{provider=>'cocca'});

=head3 Status: Not started

=head3 TLDs

xn--p1acf xn--mgbt3dhd pars islam wed nowruz persiangulf tci shia halal

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['xn--p1acf','xn--mgbt3dhd','pars','islam','wed','nowruz','persiangulf','tci','shia','halal'],
   } if $bep eq 'cocca';

=pod


=head2 CRR (Charleston Road Registry)

 $dri->add_registry('NGTLD',{provider=>'crr'});

=head3 Status: Working

=head3 TLDs

xn--q9jyb4c ads android boo car dad day eat esq fly foo here how ing kid meme mov new prof rsvp soy tour zip

=head3 Notes

1. CRR does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

=cut

 return {
     bep_type => 1, # TODO: check this
     tlds => ['xn--q9jyb4c','ads','android','boo','car','dad','day','eat','esq','fly','foo','here','how','ing','kid','meme','mov','new','prof','rsvp','soy','tour','zip'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
   } if $bep eq 'crr';


=pod


=head2 Donuts

 $dri->add_registry('NGTLD',{provider=>'donuts'});

=head3 Status: Working

=head3 TLDs

academy accountants agency architect associates attorney bargains bike boutique builders business cab camera camp capital cards care careers cash catering center cheap church claims cleaning clinic clothing codes coffee community company computer condos construction consulting contractors cool credit creditcard cruises dating degree dental dentist diamonds digital directory discount domains education email engineering enterprises equipment estate events exchange expert exposed fail fan farm finance financial fish fitness flights florist foundation fund gallery games glass graphics gripe guide guru haus healthcare holdings holiday hospital house industries institute insure international investments kitchen land lawyer lease life lighting limited limo loans maison management market marketing media medical mortgage network partners parts pets photography photos pictures plumbing productions properties recipes reisen rentals repair report reviews schule services shoes singles software solar solutions sports supplies supply support surgery systems tax technology tienda tips today tools tours town toys training university vacations ventures vet viajes villas vin vision voyage watch works wtf xn--czrs0t xn--unup4y xn--vhquv zone

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
     tlds => ['dpml.zone','academy','accountants','agency','architect','associates','attorney','bargains','bike','boutique','builders','business','cab','camera','camp','capital','cards','care','careers','cash','catering','center','cheap','church','claims','cleaning','clinic','clothing','codes','coffee','community','company','computer','condos','construction','consulting','contractors','cool','credit','creditcard','cruises','dating','degree','dental','dentist','diamonds','digital','directory','discount','domains','education','email','engineering','enterprises','equipment','estate','events','exchange','expert','exposed','fail','fan','farm','finance','financial','fish','fitness','flights','florist','foundation','fund','gallery','games','glass','graphics','gripe','guide','guru','haus','healthcare','holdings','holiday','hospital','house','industries','institute','insure','international','investments','kitchen','land','lawyer','lease','life','lighting','limited','limo','loans','maison','management','market','marketing','media','medical','mortgage','network','partners','parts','pets','photography','photos','pictures','plumbing','productions','properties','recipes','reisen','rentals','repair','report','reviews','schule','services','shoes','singles','software','solar','solutions','sports','supplies','supply','support','surgery','systems','tax','technology','tienda','tips','today','tools','tours','town','toys','training','university','vacations','ventures','vet','viajes','villas','vin','vision','voyage','watch','works','wtf','xn-czrs0t','xn--unup4y','xn--vhquv','zone'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
   } if $bep eq 'donuts';


=pod


=head2 Famous Four Media (Utilising Neustar)

 $dri->add_registry('NGTLD',{provider=>'ffm'});

=head3 Status: Untested

=head3 TLDs

accountant bid date download faith loan men review science trade webcam win

Contended TLD's not included

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['accountant', 'bid', 'date', 'download', 'faith', 'loan', 'men', 'review', 'science', 'trade', 'webcam', 'win'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}],
   } if $bep eq 'ffm';



=pod


=head2 GMO Registry

 $dri->add_registry('NGTLD',{provider=>'gmo'});

=head3 Status: Untested

=head3 TLDs

nagoya tokyo yokohama

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['nagoya','tokyo','yokohama'],
   } if $bep eq 'gmo';

=pod


=head2 KNET

 $dri->add_registry('NGTLD',{provider=>'knet'});

=head3 Status: Not started

=head3 TLDs

xn--45q11c xn--3bst00m xn--ses554g xn--efvy88h xn--czr694b xn--czru2d xn--6qq986b3xl xn--30rr7y xn--imr513n xn--otu796d xn--9et52u wang top

Contended TLD's not included

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['xn--45q11c','xn--3bst00m','xn--ses554g','xn--efvy88h','xn--czr694b','xn--czru2d','xn--6qq986b3xl','xn--30rr7y','xn--imr513n','xn--otu796d','xn--9et52u','wang','top'],
   } if $bep eq 'knet';

=pod


=head2 KS Registry (Key Sytems)

 $dri->add_registry('NGTLD',{provider=>'ks'});

=head3 Status: Working

=head3 TLDs

desi saarland

=cut

 return {
     bep_type => 1, # dedicated
     tlds => ['desi', 'saarland'],
   } if $bep eq 'ks';


=pod


=head2 Minds And Machines (MAM Own TLDs)

 $dri->add_registry('NGTLD',{provider=>'mam'});

=head3 Status: Working

=head3 TLDs

Uncontested: babogado bayern budapest casa cooking fishing fit horse luxe miami nrw rodeo surf vodka wedding work xn--g2xx48c

Contested: app art baby beauty blog book cloud coupon cpa cricket data dds deals design dog eco fashion garden gay home hotel immo inc latino law llc love pizza property realestate restaurant school site soccer store style tech video vip yoga

=head3 Notes

M&M uses a single enveronment for its own TLDs (set provider to 'mam'), while using separate unique environments for other TLDs (use provider 'mamsrs').

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['abogado', 'bayern', 'budapest', 'casa', 'cooking', 'fishing', 'fit', 'horse', 'luxe', 'miami', 'nrw', 'rodeo', 'surf', 'vodka', 'wedding', 'work', 'xn--g2xx48c',
              'app ', 'art ', 'baby ', 'beauty ', 'blog ', 'book ', 'cloud ', 'coupon ', 'cpa ', 'cricket ', 'data ', 'dds ', 'deals ', 'design ', 'dog ', 'eco ', 'fashion ', 'garden ', 'gay ', 'home ', 'hotel ', 'immo ', 'inc ', 'latino ', 'law ', 'llc ', 'love ', 'pizza ', 'property ', 'realestate ', 'restaurant ', 'school ', 'site ', 'soccer ', 'store ', 'style ', 'tech ', 'video ', 'vip ', 'yoga'
             ],
   } if $bep eq 'mam';


=pod


=head2 Minds And Machines SRS (Other TLDs)

 $dri->add_registry('NGTLD',{provider=>'mamsrs'});

=head3 Status: Working

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::Fee> urn:ietf:params:xml:ns:neulevel-1.0

=head3 TLDs

Uncontested: bible country gop kiwi london review rugby

Contested: basketball group music broadway casino poker radio tickets tube

=head3 Notes

M&M uses a single enveronment for its own TLDs (set provider to 'mam'), while using separate unique environments for other TLDs (use provider 'mamsrs').

=cut

 return {
     bep_type => 1, # single registry
     tlds => ['bible', 'country', 'gop', 'kiwi', 'london', 'review', 'rugby',
              'basketball ', 'group ', 'music ', 'broadway ', 'casino ', 'poker ', 'radio ', 'tickets ', 'tube'
             ],
   } if $bep eq 'mamsrs';

=pod


=head2 Neustar

 $dri->add_registry('NGTLD',{provider=>'neustar'});

=head3 Status: Working

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::Fee> urn:ietf:params:xml:ns:neulevel-1.0

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::NYCContact> urn:ietf:params:xml:ns:neulevel-1.0 (For .NYC Only)

=head3 TLDs

xn--rhqv96g xn--g2xx48c xn--nyqy26a best uno safety pharmacy nyc jetzt taipei qpon moe buzz ceo htc club kyoto

Contended TLD's not included

=head3 Notes

Neustar operates dedicated connections per TLD, so it is recommended to use the name parameter to select the TLD. 
In the case of NYC it is required to either set name or tlds parameter in order to load the Nexus extension for contacts and domains.
See: L<Net::DRI::Data::Contact::NYC> and L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact>

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'nyc'}); # using name
 $dri->target('nyc')->add_current_profile(....);
 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'whatever',tlds=['nyc']}); # using tld

=cut
 return {
     bep_type => 1, # dedicated registy
     tlds => ['nyc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::NYC->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::NYC'],
   } if $bep eq 'neustar' && $tld eq 'nyc';

 return {
     bep_type => 1, # dedicated registy
     tlds => ['xn--rhqv96g','xn--g2xx48c','xn--nyqy26a','best','uno','safety','pharmacy','nyc','jetzt','taipei','qpon','moe','buzz','ceo','htc','club','kyoto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}],
   } if $bep eq 'neustar';

=pod


=head2 NIC.br

 $dri->add_registry('NGTLD',{provider=>'nicbr'});

=head3 Status: Not started

=head3 TLDs

bom final

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['bom','final'],
   } if $bep eq 'nicbr';


=pod


=head2 Nominet

 $dri->add_registry('NGTLD',{provider=>'nominet'});

=head3 Status: Not started

=head3 TLDs

cymru wales

=head3 Notes

1. Not yet implemented - but it might work

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['cymru','wales'],
   } if $bep eq 'nominet';


=pod


=head2 OpenRegistry

 $dri->add_registry('NGTLD',{provider=>'openreg'});

=head3 Status: Not started

=head3 TLDs

gent boston

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['gent','boston'],
   } if $bep eq 'openreg';


=pod


=head2 PIR (Public Information Registry)

 $dri->add_registry('NGTLD',{provider=>'pir'});

=head3 Status: Untested

=head3 TLDs

org xn--i1b6b1a6a2e xn--nqv7f xn--tqq33ed31aqia ngo ong opr

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage> urn:afilias:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::Afilias::IPR> urn:afilias:params:xml:ns:ipr-1.1

L<Net::DRI::Protocol::EPP::Extensions::Afilias::Registrar> urn:ietf:params:xml:ns:registrar-1.0

=head3 Notes

1. PIR has extended the .ORG plaform to include these newGTLDs

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['org','xn--i1b6b1a6a2e','xn--nqv7f','xn--tqq33ed31aqia','ngo','ong','opr'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{}],
   } if $bep eq 'pir';


=pod


=head2 RegBox (Registry-in-a-Box from NicAT)

 $dri->add_registry('NGTLD',{provider=>'regbox'});

=head3 Status: Working

=head3 TLDs

bh berlin brussels gmbh hamburg immo reise tirol versicherung vlaanderen voting wien ikano

Contended TLD's not included

=head3 Notes

1. RegBox does not use the IDN extension.

2. RegBox does not use billing contacts.

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['bh','berlin','brussels','gmbh','hamburg','immo','reise','tirol','versicherung','vlaanderen','voting','wien','ikano'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RegBox',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::RegBox->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::RegBox'],
     contact_i18n => 2,
   } if $bep eq 'regbox';



=pod


=head2 Rightside (UnitedTLD)

 $dri->add_registry('NGTLD',{provider=>'rightside'});

=head3 Status: Working

=head3 TLDs

dpml.pub actor airforce army attorney consulting dance degree democrat dentist engineer futbol gives haus immobilien kaufen lawyer market moda mortgage navy ninja pub rehab republican reviews rocks social software vet

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
     tlds => ['dpml.pub','actor','airforce','army','attorney','consulting','dance','degree','democrat','dentist','engineer','futbol','gives','haus','immobilien','kaufen','lawyer','market','moda','mortgage','navy','ninja','pub','rehab','republican','reviews','rocks','social','software','vet'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
   } if $bep eq 'rightside';


=pod


=head2 SIDN

 $dri->add_registry('NGTLD',{provider=>'sidn'});

=head3 Status: Not started

=head3 TLDs

amsterdam


=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['amsterdam'],
   } if $bep eq 'sidn';

=pod


=head2 StartingDot (Provided by Key Sytems)

 $dri->add_registry('NGTLD',{provider=>'startingdot'});

=head3 Status: Working

=head3 TLDs

archi bio ski 

immo (contested)

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['archi', 'bio', 'ski', 'immo'],
   } if $bep eq 'startingdot';


=pod


=head2 Tango-RS

 $dri->add_registry('NGTLD',{provider=>'tango'});

=head3 Status: Working

=head3 TLDs

ruhr cologne koeln nrw

pay is in contention

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::TANGO::IDN> urn:ar:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TANGO::Auction> urn:ar:params:xml:ns:auction-1.0

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['ruhr','cologne','koeln','nrw'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TANGO',{}],
   } if $bep eq 'tango';

=pod


=head2 TCI (cctld.ru)

$dri->add_registry('NGTLD',{provider=>'tci'});

=head3 Status: Not started

=head3 TLDs

tatar xn--d1acj3b

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['tatar','xn--d1acj3b'],
     # TCI cctlds has Contact Object and Extensions Object, these may be required
   } if $bep eq 'tci';

=pod


=head2 UniRegistry (Internet Systems Consortium)

 $dri->add_registry('NGTLD',{provider=>'unireg'});

=head3 Status: Working

=head3 TLDs

art auction audio auto blackfriday cars christmas click country deal design diet family fashion flowers free furniture game garden gift gratis guitars help hiphop home hosting inc juegos link lol love mom news photo pics pizza property racing realestate restaurant sale save school sexy shopping store style tattoo team tech video yoga

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::UNIREG::Centric> http://ns.uniregistry.net/centric-1.0

=head3 Other extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['art','auction','audio','auto','blackfriday','cars','christmas','click','country','deal','design','diet','family','fashion','ﬂowers','free','furniture','game','garden','gift','gratis','guitars','help','hiphop','home','hosting','inc','juegos','link','lol','love','mom','news','photo','pics','pizza','property','racing','realestate','restaurant','sale','save','school','sexy','shopping','store','style','tattoo','team','tech','video','yoga'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNIREG',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UNIREG->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UNIREG'],
   } if $bep eq 'unireg';

=pod


=head2 Verisign

 $dri->add_registry('NGTLD',{provider=>'verisign'});

=head3 Status: Not started

=head3 TLDs

xn--pssy2u xn--c1yn36f xn--11b4c3d xn--t60b56a xn--c2br7g xn--42c2d9a xn--j1aef xn--3pxu8k xn--hdb9cza1b xn--mk1bu44c xn--fhbei xn--tckwe career ooo

Contended TLD's not included

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','career','ooo'],
   } if $bep eq 'verisign';



=pod


=head2 ZACR (UniForum/ZA Central Registry)

 $dri->add_registry('NGTLD',{provider=>'zacr'});

=head3 Status: In progress

=head3 TLDs

joburg durban capetown

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::COZA::Domain> http://co.za/epp/extensions/cozadomain-1-0

=cut

 return {
     bep_type => undef, # TODO: check this
     tlds => ['africa','durban','capetown','joburg'],
     ote_tlds => ['cities.dnservices.co.za'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ZACR',{}],
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

Copyright (c) 2014 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


1;