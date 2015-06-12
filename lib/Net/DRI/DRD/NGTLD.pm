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

alsace aquarelle aquitaine banque bzh corsica frogans leclerc ovh paris

=cut

 return {
     bep_type => 1, # dedicated regsitry
     tlds => ['alsace', 'aquarelle', 'aquitaine', 'banque', 'bzh', 'corsica', 'frogans', 'leclerc', 'ovh', 'paris'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1,'custom'=>['AFNIC_GTLD::RegistryMessage']}],
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

info xn--6frz82g black blue green kim lgbt lotto meet organic pink poker red shiksha vote voto

Contended TLD's not included

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['info','xn--6frz82g','black','blue','green','kim','lgbt','lotto','meet','organic','pink','poker','red','shiksha','vote','voto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.7'}],
     whois_server => 'whois.afilias.net',
   } if $bep eq 'afilias';

=pod

=head3 Afilias Client TLDs

Afilias SRS has extended the .XXX plaform to include these newGTLDs

 $dri->add_registry('NGTLD',{provider=>'afiliassrs'});

xxx xn--3ds443g xn--4gbrim xn--fiq228c5hs xn--kput3i adult bnpparibas creditunion ged global hiv indians irish ltda onl porn rich storage vegas

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xxx','xn--3ds443g','xn--4gbrim','xn--fiq228c5hs','xn--kput3i','adult','bnpparibas','creditunion','ged','global','hiv','indians','irish','ltda','onl','porn','rich','storage','vegas'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.7'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'afiliassrs';

=pod


=head2 ARI

 $dri->add_registry('NGTLD',{provider=>'ari'});

=head3 Status: Working

=head3 TLDs

xn--ngbc5azd xn--ngbrx abudhabi arab build dubai cancerresearch courses cuisinella krd luxury melbourne men menu monash one physio schmidt study sucks sydney wtc

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
     tlds => ['xn--ngbc5azd', 'xn--ngbrx', 'abudhabi', 'arab', 'build', 'dubai', 'cancerresearch', 'courses', 'cuisinella', 'krd', 'luxury', 'melbourne', 'men', 'menu', 'monash', 'one', 'physio', 'schmidt', 'study', 'sucks', 'sydney', 'wtc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}],
     whois_server => 'whois.aridnrs.net.au',
   } if $bep eq 'ari';


=pod


=head2 CentralNIC

 $dri->add_registry('NGTLD',{provider=>'centralnic'});

=head3 Status: Working

=head3 TLDs

bar college contact design fan fans feedback host ink online pid press reit rest site space website wiki wme xyz

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
    my @ngtlds = qw/bar college contact design fan fans feedback host ink love online pid press reit rest site space website wiki wme xyz/;
    my @ngtlds_contested = qw/reality/; # some of these might go to other registries, tbc later as these are expected in Q4 2014
    my @ngtlds_pipeline = qw/art auto now hotel forum gay group blog app mail llc/; # no expected dates given, probably contested strings
    my @tlds = (@coms,@nets,@orgs,@others,@ngtlds);

    return {
     bep_type => 2, # shared registry
     tlds => \@tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.5' }],
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

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['xn--80asehdb','xn--80aswg','xn--mgbab2bd','art','barcelona','eurovision','erni','eurovision','eus','gal','lacaixa','madrid','mango','museum','quebec','radio','scot','sport','swiss'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORENIC',{}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
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

xn--flw351e xn--q9jyb4c xn--qcka1pmc ads android boo cal car channel chrome dad day eat esq fly foo gbiz gle gmail google here how ing kid meme mov new nexus prod prof rsvp soy tour youtube zip

=head3 Notes

1. CRR does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

=cut

 return {
     bep_type => 1, # dedicated
     tlds => ['xn--flw351e','xn--q9jyb4c','xn--qcka1pmc','ads','android','boo','cal','car','channel','chrome','dad','day','eat','esq','fly','foo','gbiz','gle','gmail','google','here','how','ing','kid','meme','mov','new','nexus','prod','prof','rsvp','soy','tour','youtube','zip'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee'], 'disable_idn'=>1, 'brown_fee_version' => '0.6'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'crr';


=pod


=head2 Donuts

 $dri->add_registry('NGTLD',{provider=>'donuts'});

=head3 Status: Working

=head3 TLDs

academy accountants agency apartments architect associates bargains bike bingo boutique builders business cab cafe camera camp capital cards care careers cash casino catering center chat cheap church city claims cleaning clinic clothing coach codes coffee community company computer condos construction contractors cool credit creditcard cruises dating deals delivery dental diamonds digital direct directory discount dog domains education email energy engineering enterprises equipment estate events exchange expert exposed express fail farm finance financial fish fitness flights florist football foundation fund furniture gallery games gifts gold golf glass graphics gratis gripe guide guru healthcare holdings holiday hospital house immo industries institute insure international investments jewelry kitchen land lease legal life lighting limited limo loans maison management marketing media medical memorial money movie network partners parts pets photography photos pictures pizza place plumbing plus productions properties recipes reisen rentals repair report restaurant sarl school schule services shoes singles solar solutions sports style supplies supply support surgery systems tax technology tennis tienda tips tires today tools tours town toys training university vacations ventures viajes villas vin vision voyage watch world works wtf xn--czrs0t xn--unup4y xn--vhquv zone

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
     tlds => ['dpml.zone','academy','accountants','agency','apartments','architect','associates','bargains','bike','bingo','boutique','builders','business','cab','cafe','camera','camp','capital','cards','care','careers','cash','casino','catering','center','chat','cheap','church','city','claims','cleaning','clinic','clothing','coach','codes','coffee','community','company','computer','condos','construction','contractors','cool','credit','creditcard','cruises','dating','deals','delivery','dental','diamonds','digital','direct','directory','discount','dog','domains','education','email','energy','engineering','enterprises','equipment','estate','events','exchange','expert','exposed','express','fail','farm','finance','financial','fish','fitness','flights','florist','football','foundation','fund','furniture','gallery','games','gifts','gold','golf','glass','graphics','gratis','gripe','guide','guru','healthcare','holdings','holiday','hospital','house','immo','industries','institute','insure','international','investments','jewelry','kitchen','land','lease','legal','life','lighting','limited','limo','loans','maison','management','marketing','media','medical','memorial','money','movie','network','partners','parts','pets','photography','photos','pictures','pizza','place','plumbing','plus','productions','properties','recipes','reisen','rentals','repair','report','restaurant','sarl','school','schule','services','shoes','singles','solar','solutions','sports','style','supplies','supply','support','surgery','systems','tax','technology','tennis','tienda','tips','tires','today','tools','tours','town','toys','training','university','vacations','ventures','viajes','villas','vin','vision','voyage','watch','world','works','wtf','xn--czrs0t','xn--unup4y','xn--vhquv','zone'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
     whois_server => 'whois.donuts.co',
     check_limit => 5,
   } if $bep eq 'donuts';


=pod


=head2 Famous Four Media (Utilising Neustar)

 $dri->add_registry('NGTLD',{provider=>'ffm'});

=head3 Status: Untested

=head3 TLDs

accountant bid cricket date download faith loan men party racing review science trade webcam win

Contension: app baby bet cam charity forum game hockey hotel music rugby run search shop  soccer sport stream taxi

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::Fee> urn:ietf:params:xml:ns:neulevel-1.0

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['accountant', 'bid', 'cricket', 'date', 'download', 'faith', 'loan', 'men', 'party', 'racing', 'review', 'science', 'trade', 'webcam', 'win', # uncontended
              'app', 'baby', 'bet', 'cam', 'charity', 'forum', 'game', 'hockey', 'hotel', 'music', 'rugby', 'run', 'search', 'shop', 'soccer', 'sport', 'stream', 'taxi',# contended
             ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'ffm';



=pod


=head2 GMO Registry

GMO uses a shared enveronment (account) for its own TLDs (set provider to 'gmo') and a separate shared account for geoTLDs (set provider to 'gmogeo')

 $dri->add_registry('NGTLD',{provider=>'gmo'}); # Own: nagoya tokyo yokohama
 $dri->add_registry('NGTLD',{provider=>'gmogeo'}); # Geo: okinawa ryukyu

=head3 Status: Untested

=head3 TLDs

Own: nagoya tokyo yokohama
Geo: okinawa ryukyu

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.4

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['nagoya','tokyo','yokohama'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.4' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmo';

 return {
     bep_type => 2, # shared registry
     tlds => ['okinawa','ryukyu'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ('CentralNic::Fee'), 'brown_fee_version' => '0.4' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmogeo';
   
=pod


=head2 KNET

 $dri->add_registry('NGTLD',{provider=>'knet'});

=head3 Status: Working

=head3 TLDs

xn--45q11c xn--3bst00m xn--ses554g xn--efvy88h xn--czr694b xn--czru2d xn--6qq986b3xl xn--30rr7y xn--imr513n xn--otu796d xn--9et52u wang top

Contended TLD's not included

=head3 Notes

1. KNET does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

2. It looks as though KNET will run a shared EPP registry, but this is TBC

=cut

 return {
     bep_type => 2,
     tlds => ['xn--45q11c','xn--3bst00m','xn--ses554g','xn--efvy88h','xn--czr694b','xn--czru2d','xn--6qq986b3xl','xn--30rr7y','xn--imr513n','xn--otu796d','xn--9et52u','wang','top'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
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
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'ks';


=pod


=head2 Minds And Machines

M&M uses a shared enveronment for its own TLDs (set provider to 'mam' or 'mamown'), dedicted environments for partner TLDs ('mamsrs' or 'mampartner'), and a separate shared environment for their clients ('mamclient'). *However*, this might change somewhat, so please note that this M+M section might need adjusting and they release more info.

=head3 Status: Working

=head3 M+M Own TLDs

 $dri->add_registry('NGTLD',{provider=>'mam'}); # M+M Own TLDs, 'mam' or 'mamown'

Uncontested: abogado bayern beer budapest casa cooking country fashion fishing fit garden horse law luxe miami rodeo surf vip vodka wedding work yoga xn--g2xx48c


Contested: app art baby beauty blog book cloud coupon cpa data dds eco gay home hotel inc latino llc realestate soccer store tech

Collisions: cooking-collisions country-collisions fishing-collisions'horse-collisions rodeo-collisions vodka-collisions
=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['abogado', 'bayern', 'beer', 'budapest', 'casa', 'cooking', 'country', 'fashion', 'fishing', 'fit', 'garden', 'horse', 'law',  'luxe', 'miami', 'rodeo', 'surf',  'vip', 'vodka', 'wedding', 'work', 'yoga', 'xn--g2xx48c',
              'app', 'art', 'baby', 'beauty', 'blog', 'book', 'cloud', 'coupon', 'cpa', 'data', 'dds', 'eco', 'gay', 'home', 'hotel', 'inc', 'latino','llc', 'realestate', 'soccer', 'store', 'tech',
              'cooking-collisions', 'country-collisions', 'fishing-collisions', 'horse-collisions', 'rodeo-collisions', 'vodka-collisions',
             ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],
     whois_server => 'whois-dub.mm-registry.com',
   } if $bep eq 'mam' || $bep eq 'mamown';

=pod

=head3 M+M Partner TLDs

 $dri->add_registry('NGTLD',{provider=>'mamsrs'}); # M+M In Partnership 'mamsrs' or 'mampartner'

Uncontested: london review rugby

Contested: basketball group music

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['london', 'london-collisions', 'review', 'rugby',
              'basketball', 'group', 'music', 
             ],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],
   } if $bep eq 'mamsrs' || $bep eq 'mampartner';

=pod

=head3 M+M Client TLDs

 $dri->add_registry('NGTLD',{provider=>'mamclient'}); # M+M Clients 'mamclient'

Uncontested: bible gop kiwi

Contested: broadway radio tickets tube

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['bible', 'gop', 'kiwi',
              'broadway', 'radio', 'tickets', 'tube'
             ],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee']}],
   } if $bep eq 'mamclient';

=pod


=head2 Neustar

 $dri->add_registry('NGTLD',{provider=>'neustar'});

=head3 Status: Working

=head3 TLDs

xn--rhqv96g xn--g2xx48c xn--nyqy26a best uno safety pharmacy nyc jetzt taipei qpon moe buzz ceo htc club whoswho osaka

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
     bep_type => 1, # dedicated registy
     tlds => ['nyc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{custom=>'NeuLevel::EXTContact'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::NYC->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::NYC'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'neustar' && $tld eq 'nyc';

 return {
     bep_type => 1, # dedicated registy
     tlds => ['xn--rhqv96g','xn--g2xx48c','xn--nyqy26a','best','uno','safety','pharmacy','nyc','jetzt','taipei','qpon','moe','buzz','ceo','htc','club','whoswho','osaka'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEUSTAR',{}],
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
     bep_type => 2, # shared registy
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

cymru wales

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['cymru','wales'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1}],
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
     bep_type => 1, # dedicated registy
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
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::PIR',{}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'pir';


=pod


=head2 RegBox (Registry-in-a-Box from NicAT)

 $dri->add_registry('NGTLD',{provider=>'regbox'});

=head3 Status: Working

=head3 TLDs

bh berlin brussels gmbh hamburg reise tirol versicherung vlaanderen voting wien ikano

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::RegBox::ServiceMessage> http://tld-box.at/xmlns/resdata-1.1

=head3 Notes

1. RegBox does not use the IDN extension.

2. RegBox does not use billing contacts.

=cut

 return {
     bep_type => 1, # dedicated registy
     tlds => ['bh','berlin','brussels','gmbh','hamburg','reise','tirol','versicherung','vlaanderen','voting','wien','ikano'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RegBox',{}],
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

dpml.pub actor airforce army attorney auction band consulting dance degree democrat dentist engineer forsale futbol gives haus immobilien kaufen lawyer market moda mortgage navy ninja news pub rehab republican reviews rip rocks sale social software vet video

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
     tlds => ['dpml.pub','actor','airforce','army','attorney','auction','band','consulting','dance','degree','democrat','dentist','engineer','forsale','futbol','gives','haus','immobilien','kaufen','lawyer','market','moda','mortgage','navy','ninja','news','pub','rehab','republican','reviews','rip','rocks','sale','social','software','vet','video'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNITEDTLD',{}],
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


=head2 StartingDot (Provided by Key Sytems)

 $dri->add_registry('NGTLD',{provider=>'startingdot'});

=head3 Status: Working

=head3 TLDs

archi bio ski 

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['archi', 'bio', 'ski'],
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
     bep_type => 1, # dedicated registy
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
     bep_type => 1, # dedicated registy
     tlds => ['moscow', 'tatar', 'xn--d1acj3b', 'xn--1-7sbc5ceg', 'xn--2-7sbc5ceg', 'xn--80adxhks'],
     contact_i18n => 7, # and or ?
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::TCI_gTLD->new(@_); } } ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TCI_gTLD',{}],
   } if $bep eq 'tci';

=pod


=head2 UniRegistry (Internet Systems Consortium)

 $dri->add_registry('NGTLD',{provider=>'unireg'});

=head3 Status: Working

=head3 TLDs

art audio auto blackfriday cars christmas click deal diet family flowers free game garden gift guitars help hiphop home hosting inc juegos link lol mom photo pics property realestate save sexy shopping store tattoo team tech yoga

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::UNIREG::Centric> http://ns.uniregistry.net/centric-1.0

=head3 Other extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['art','audio','auto','blackfriday','cars','christmas','click','deal','diet','family','flowers','free','game','garden','gift','guitars','help','hiphop','home','hosting','inc','juegos','link','lol','mom','photo','pics','property','realestate','save','sexy','shopping','store','tattoo','team','tech','yoga'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UNIREG',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UNIREG->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UNIREG'],
     whois_server => 'whois.uniregistry.net',
   } if $bep eq 'unireg';

=pod


=head2 Verisign

 $dri->add_registry('NGTLD',{provider=>'verisign'});

=head3 Status: Not started

=head3 TLDs

xn--pssy2u xn--c1yn36f xn--11b4c3d xn--t60b56a xn--c2br7g xn--42c2d9a xn--j1aef xn--3pxu8k xn--hdb9cza1b xn--mk1bu44c xn--fhbei xn--tckwe azure bank bing career cfd crs hotmail java maif markets microsoft ooo oracle pictet realtor sca shell sky spreadbetting trading xbox windows

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
     tlds => ['com','net','cc','tv','bz','jobs','xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','azure','bank','bing','career','cfd','crs','hotmail','java','maif','markets','microsoft','ooo','oracle','pictet','realtor','sca','shell','sky','spreadbetting','trading','xbox','windows'],
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

=cut

sub domain_check_claims
{
 my ($self,$ndr,@names)=@_;
 my $bep = lc($self->{info}->{provider});
 my $rd = (@names && exists $names[-1] && ref $names[-1] eq 'HASH' ) ? pop @names : {};
 my $lp = { 'phase' => 'claims', 'type'=>'claims' };
 if (defined $rd && exists $rd->{phase} && lc($rd->{phase}) ne 'claims')
 {
  # By default, most registries do NOT use a sub_phase is claims lookups. Therefore if you specifiy a phase it will be ignored
  # Afilias/ARI/CentralNIC/CoreNic/CRR/Donuts/GMO/KS/PIR/RegBox/Rightside/StartingDot/Tango/UniRegistry

  # These registres use claims as phase + phase_name us sub_phase. domain_check_claims('test-validate.buzz',{phase=>'landrush'});
  # Neustar/MAM/FFM/KNet   (Knet seems to work either way - but rather put it here)
  $lp->{sub_phase} = $rd->{phase} if ($bep =~ m/^(?:neustar|mam|ffm|knet)/);
  # i think there is much more to do here
 }
 $rd->{lp} = $lp;
 return $ndr->domain_check(@names,$rd);
}

=pod 

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


#### FIXME: Neustar requires phase
sub domain_check_price
{
 my ($self,$ndr,@names)=@_;
 my $rd = (@names && exists $names[-1] && ref $names[-1] eq 'HASH' ) ? pop @names : {};
 $rd = $self->_build_price_query($ndr,$rd);
 return $ndr->domain_check(@names,$rd);
}

#### FIXME: Neustar requires phase
sub domain_info_price
{
 my ($self,$ndr,$domain,$rd)=@_;
 $rd = $self->_build_price_query($ndr,$rd);
 return $ndr->domain_info($ndr,$domain,$rd);
}

sub _build_price_query
{
 my ($self,$ndr,$rd)=@_;
 my $bep = lc($self->{info}->{provider});
 if ($bep =~ m/^(?:donuts|rightside|zacr)/)
 { 
  # they answer with fee anyway, so no action required on this one
 } elsif ($bep =~ m/^(?:neustar|ffm)/)
 {
   $rd->{fee} = 1;
 } elsif ($bep eq 'ari') {
   $rd->{price} = 1;
 } elsif ($bep eq 'verisign') {
   $rd->{premium_domain} = 1;
 } elsif (grep $_ eq 'Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee', @{$ndr->protocol()->{loaded_modules}}) {
   my ($fee,@fees);
   foreach my $k (qw/currency action duration/)
   {
     $fee->{$k} = $rd->{$k} if exists $rd->{$k};
   }
   $fee->{currency} = 'USD' unless exists $fee->{currency} || $bep !~ m/^gmo/; # fee-0.5+ should not set values for currency and duration as these will default
   $fee->{duration} = 1 unless exists $fee->{duration} || $bep !~ m/^gmo/;
   $fee->{duration} = $ndr->local_object('duration','years',$fee->{duration}) if exists $fee->{duration} && ref $fee->{duration} eq '' && $fee->{duration} =~ m/^\d$/;
   @{$rd->{fee}} = ();
   foreach (qw/create renew transfer restore/) {
     my $feetype = { %{$fee} };
     $feetype->{action} = $_;
     push @fees,$feetype;
   }
   $rd->{fee} = \@fees;
 }
 foreach (qw/currency action duration/)
 {
   delete $rd->{$_} if exists $rd->{$_};
 }
 return $rd;
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
