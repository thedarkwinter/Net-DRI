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

Additional domain extension for [most?] New Generic TLDs. This extension distinguishes between back end providers to select extensions, tld lists and some other config for the DRD. The providers listed her are loosely referred to as back end providers. Some registries may have multiple providers, and most providers have multiple registries.

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
e.g: add a custom target name, by default this is the back end provider name, but in this instance we select tube
Note, if the name you specified matches one of the TLD's and you have not manually specified the tld list, if will use only this TLD. If the name doesn't match a TLD, it will make all TLD's by the prover available in the DRD

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'tube'});
 $dri->target('tube')->add_current_profile(....);

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
    tlds => ['alsace', 'corsica', 'paris'],
    transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{disable_idn=>1,custom=>['AFNIC::RegistryMessage', 'Fee'], 'fee_version' => '1.0'}],
    contact_i18n => 1, # can only use the "loc" type
    whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
  } if $bep eq 'afnic' && $tld =~ m/(?:alsace|corsica|paris)/;

 return {
     bep_type => 1, # dedicated regsitry
     tlds => ['aquarelle', 'aquitaine', 'banque', 'bzh', 'frogans', 'lancaster', 'leclerc', 'mma', 'ovh', 'sncf'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{disable_idn=>1,custom=>['AFNIC::RegistryMessage', 'AFNIC::PremiumDomain']}],
     contact_i18n => 1, # can only use the "loc" type
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'afnic';


=pod

=head3 Afilias Client TLDs

Afilias SRS has extended their plaform to include these newGTLDs

 $dri->add_registry('NGTLD',{provider=>'afiliassrs'});

ngtlds: xn--kput3i bnpparibas ged indians ist istanbul ltda onl rich spa srl vegas zara
cctlds: ag bz gi lc mn me sc vc

=cut

 if ($bep eq 'afiliassrs') {
   my @ngtlds = qw/xn--kput3i bnpparibas ged indians ist istanbul ltda onl rich spa srl vegas zara/;
   my @gtlds = qw/asia/;
   my @cctlds = (
       'ag',(map { $_.'.ag'} qw/co com net nom org/),
       'bz',(map { $_.'.bz'} qw/co com net org/),
       'gi',
       'lc',(map { $_.'.lc'} qw/co com l net org p/),
       'me',
       'mn',
       'pr',(map { $_.'.pr'} qw/biz com info isla name net org pro/),
       'sc',(map { $_.'.sc'} qw/com net org/),
       'vc',(map { $_.'.vc'} qw/com net org/));
   my @tlds = (@ngtlds,@gtlds,@cctlds);

   return {
     bep_type => 2, # shared registry
     tlds => \@tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::AfiliasSRS',{'brown_fee_version' => '0.8'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   };
 }


=pod


=head2 CentralNIC

 $dri->add_registry('NGTLD',{provider=>'centralnic'});

=head3 Status: Working

=head3 TLDs

art auto autos baby bar beauty best blog boats bond budapest build cam car cars ceo cfd college cyou dealer desi fans feedback forum fun gent hair homes host icu inc london luxury makeup monster motorcycles online ooo pid press protection qpon quest reit rent rest saarland sbs security site skin space spreadbetting storage store tech theatre tickets uno website wme xn--4gbrim xyz yachts

Contended TLD's not included

=head3 CCTLDs

bh .xn--mgbcpq6gpa1a biz.bh cc.bh com.bh edu.bh info.bh me.bh med.bh name.bh net.bh org.bh

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.5

=head3 Notes

1. CentralNIC also provides some ccTLDs and sLDs. These are not included here yet as some testing is required.

=cut

 if ($bep eq 'centralnic') {
    my @coms = (map { $_.'.com' } qw/africa ar br cn co de eu gb gr hu jpn kr mex no qc ru sa se uk us uy za/);
    my @nets = (map { $_.'.net' } qw/uk se gb jp hu in/);
    my @orgs = (map { $_.'.org' } qw/us ae/);
    my @others = qw/pw com.de com.se co.nl fm radio.fm radio.am gd vg/;
    my @ngtlds = qw/art auto autos baby bar beauty best blog boats bond budapest build cam car cars ceo cfd college cyou dealer desi fans feedback forum fun gent hair homes host icu inc london luxury makeup monster motorcycles online ooo pid press protection qpon quest reit rent rest saarland sbs security site skin space spreadbetting storage store tech theatre tickets uno website wme xn--4gbrim xyz yachts/;
    my @ngtlds_contested = qw/hotel mail/; # some of these might go to other registries
    my @cctlds = (qw/bh .xn--mgbcpq6gpa1a/, map {$_.'.bh'} qw/biz cc com edu info me med name net org/);
    my @tlds = (@coms,@nets,@orgs,@others,@ngtlds,@cctlds);

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


=head2 Zuerich

 $dri->add_registry('NGTLD',{provider=>'centralnic_zuerich'});

=head3 Status: Working

=head3 TLDs

zuerich

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.5

=cut

 if ($bep eq 'centralnic_zuerich') {
   return {
     bep_type => 1, # dedicated registry
     tlds => [ qw/zuerich/ ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','CentralNic::RegType','CentralNic::AuxContact'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.nic.zuerich',
     verify_icann_reserved => 0,
     verify_check_name => 0,
   };
 }

=pod


=head2 CoreNIC

 $dri->add_registry('NGTLD',{provider=>'corenic'});

=head3 Status: Working

=head3 TLDs

xn--80asehdb xn--80aswg xn--mgbab2bd barcelona eurovision erni eurovision eus gal lacaixa madrid mango museum quebec radio scot sport swiss

=head3 Custom extensions: (From Tango-RS but with CoreNIC namespaces)

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::IDN> : http://xmlns.corenic.net/epp/idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::Auction> : http://xmlns.corenic.net/epp/auction-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::LaunchPhase> : http://xmlns.corenic.net/epp/mark-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::ContactEligibility> : http://xmlns.corenic.net/epp/contact-eligibility-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::Promotion> : http://xmlns.corenic.net/epp/promotion-1.0

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['xn--80asehdb','xn--80aswg','xn--mgbab2bd','barcelona','eurovision','erni','eurovision','eus','gal','lacaixa','madrid','mango','museum','quebec','radio','scot','sport','swiss'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::CORE',{fee_version => ($tld eq 'radio' ? '0.21': undef)}],
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

xn--flw351e xn--q9jyb4c xn--qcka1pmc ads android app boo cal channel chrome dad day dclk dev docs drive eat esq fly foo gbiz gle gmail goog google guge hangout here how ing kid map meet meme mov new nexus page phd play prod prof rsvp search soy tour youtube zip

=head3 Notes

1. CRR does not use an IDN extension. IDNs are submitted as ASCII strings without specifying language/script.

=cut

 return {
     bep_type => 2, # shared
     tlds => ['xn--flw351e','xn--q9jyb4c','xn--qcka1pmc','ads','android','app','boo','cal','channel','chrome','dad','day','dclk','dev','docs','drive','eat','esq','fly','foo','gbiz','gle','gmail','goog','google','guge','hangout','here','how','ing','kid','map','meet','meme','mov','new','nexus','page','phd','play','prod','prof','rsvp','search','soy','tour','youtube','zip'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom=>['CentralNic::Fee','AllocationToken'], 'disable_idn'=>1, 'brown_fee_version' => '0.6'}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'crr';


=pod


=head2 DNSBelgium

 $dri->add_registry('NGTLD',{provider=>'dnsbelgium'});

=head3 Status: Working

=head3 TLDs

 brussels dnsbelgium vlaanderen

=cut

  return {
      bep_type => 1, # dedicated registry
      host_as_attr => 1,
      contact_i18n => 2, #  ## They accept LOC *or* INT, but only one of them. Forcing INT!
      tlds => ['brussels', 'dnsbelgium', 'vlaanderen'], # README: dnsbelgium used on their OT&E only!
      transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{}],
      whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
    } if $bep eq 'dnsbelgium';



=pod


=head2 Donuts

 $dri->add_registry('NGTLD',{provider=>'donuts'});

=head3 Status: Working

=head3 TLDs

ac academy accountants actor agency airforce apartments archi architect army associates attorney auction band bargains bet bike bingo bio black blue boutique broker builders business cab cafe camera camp capital cards care careers cash casino catering center charity chat cheap church city claims cleaning clinic clothing coach codes coffee community company computer condos construction consulting contact contractors cool coupons credit creditcard cruises dance dating deals degree delivery democrat dental dentist diamonds digital direct directory discount doctor dog domains dpml.pub dpml.zone education email energy engineer engineering enterprises equipment estate events exchange expert exposed express fail family fan farm finance financial fish fitness flights florist football forex forsale foundation fund furniture futbol fyi gallery games gifts gives glass global gmbh gold golf graphics gratis green gripe group guide guru haus healthcare hockey holdings holiday hospital house immo immobilien industries info institute insure international investments io irish jetzt jewelry kaufen kim kitchen land lawyer lease legal lgbt life lighting limited limo live llc loans lotto ltd maison management market marketing markets mba media medical memorial mobi moda money mortgage movie navy network news ninja observer organic partners parts pet pets photography photos pictures pink pizza place plumbing plus poker pro law.pro jur.pro bar.pro med.pro cpa.pro aca.pro eng.pro productions promo properties pub realty recipes red rehab reise reisen rentals repair report republican restaurant reviews rip rocks run sale salon sarl school schule services sh shiksha shoes shopping show singles ski soccer social software solar solutions sports studio style supplies supply support surgery systems tax taxi team technology tennis theater tienda tips tires today tools tours town toys trading training travel university vacations ventures vet viajes video villas vin vision vote voto voyage watch watches wine works world wtf xn--5tzm5g xn--6frz82g xn--czrs0t xn--fjq720a xn--unup4y xn--vhquv zone

=head3 Custom extensions

L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

=head3 DPML Blocks / Overrides:

In order to submit DPML blocks OR DMPL Overrides, submit a domain_create with the correct TLD (.dpml.zone for block) and the LaunchPhase extensions should contain the [Encoded] Signed Mark, along with the phase name 'dpml'

  $dri->domain_create('mylabel.dpml.zone',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   });# DPML Block
  $dri->domain_create('mylabel.energy',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   }); # DPML Override

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['ac','academy','accountants','actor','agency','airforce','apartments','archi','architect','army','associates','attorney','auction','band','bargains','bet','bike','bingo','bio','black','blue','boutique','broker','builders','business','cab','cafe','camera','camp','capital','cards','care','careers','cash','casino','catering','center','charity','chat','cheap','church','city','claims','cleaning','clinic','clothing','coach','codes','coffee','community','company','computer','condos','construction','consulting','contact','contractors','cool','coupons','credit','creditcard','cruises','dance','dating','deals','degree','delivery','democrat','dental','dentist','diamonds','digital','direct','directory','discount','doctor','dog','domains','dpml.pub','dpml.zone','education','email','energy','engineer','engineering','enterprises','equipment','estate','events','exchange','expert','exposed','express','fail','family','fan','farm','finance','financial','fish','fitness','flights','florist','football','forex','forsale','foundation','fund','furniture','futbol','fyi','gallery','games','gifts','gives','glass','global','gmbh','gold','golf','graphics','gratis','green','gripe','group','guide','guru','haus','healthcare','hockey','holdings','holiday','hospital','house','immo','immobilien','industries','info','institute','insure','international','investments','io','irish','jetzt','jewelry','kaufen','kim','kitchen','land','lawyer','lease','legal','lgbt','life','lighting','limited','limo','live','llc','loans','lotto','ltd','maison','management','market','marketing','markets','mba','media','medical','memorial','mobi','moda','money','mortgage','movie','navy','network','news','ninja','observer','organic','partners','parts','pet','pets','photography','photos','pictures','pink','pizza','place','plumbing','plus','poker','pro','law.pro','jur.pro','bar.pro','med.pro','cpa.pro','aca.pro','eng.pro','productions','promo','properties','pub','realty','recipes','red','rehab','reise','reisen','rentals','repair','report','republican','restaurant','reviews','rip','rocks','run','sale','salon','sarl','school','schule','services','sh','shiksha','shoes','shopping','show','singles','ski','soccer','social','software','solar','solutions','sports','studio','style','supplies','supply','support','surgery','systems','tax','taxi','team','technology','tennis','theater','tienda','tips','tires','today','tools','tours','town','toys','trading','training','travel','university','vacations','ventures','vet','viajes','video','villas','vin','vision','vote','voto','voyage','watch','watches','wine','works','world','wtf','xn--5tzm5g','xn--6frz82g','xn--czrs0t','xn--fjq720a','xn--unup4y','xn--vhquv','zone'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UnitedTLD',{}],
     whois_server => 'whois.donuts.co',
     check_limit => 5,
   } if $bep eq 'donuts';


=pod


=head2 Fury Regisrty (CIRA)

=head3 Fury Client TLDs

 $dri->add_registry('NGTLD',{provider=>'fury'});

=head3 Status: Untested

=head3 TLDs

kiwi sx

=head3 Custom extensions

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.11

=head3 Notes

They will be adding a fury.xsd extension

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['eco', 'kiwi', 'sx'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{ custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.11' }],
   } if $bep eq 'fury';

=pod


=head2 GMO Registry

GMO uses a shared enveronment (account) for its own TLDs (set provider to 'gmo') and a separate shared account for geoTLDs (set provider to 'gmogeo'), and possibly more.

 $dri->add_registry('NGTLD',{provider=>'gmo'}); # Own: nagoya tokyo yokohama
 $dri->add_registry('NGTLD',{provider=>'gmogeo'}); # Geo: okinawa ryukyu (BRRegistry)
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
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
   } if $bep eq 'gmo';

 return {
     bep_type => 2, # shared registry
     tlds => ['okinawa','ryukyu'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
 } if $bep eq 'gmogeo' || $bep eq 'brregistry';

 return {
     bep_type => 2, # shared registry
     tlds => ['kyoto'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
 } if $bep eq 'gmokyoto' || $bep eq 'kyoto';

 return {
     bep_type => 2, # shared registry
     tlds => ['shop'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee'], 'brown_fee_version' => '0.5' }],
     whois_server => 'whois.centralnic.com',
 } if $bep eq 'gmoshop' || $bep eq 'shop';

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

=head2 Neustar Narwhal / ex - ARI

 $dri->add_registry('NGTLD',{provider=>'ari'}); # To use ARI extensions

 $dri->add_registry('NGTLD',{provider=>'narwhal'}); # To use Standard/Nesutar extensions

 $dri->add_registry('NGTLD',{provider=>'neustar'}); # To use neustar legacy system (being phased out)

=head3 Status: Working

=head3 TLDs

Legacy (use 'neustar')
Neustar operates dedicated connections per TLD, so it is recommended to use the name parameter to select the TLD.

biz hotels htc ipiranga itau

Narwhal (use 'ari' or 'narwhal') or DRD::Narwhal

aaa able abogado accountant adult aetna afl aig americanexpress amex amica analytics anz aramco athleta auspost axa banamex bananarepublic bank barclaycard barclays baseball basketball beer bible bid biz booking boots boston box buzz calvinklein cancerresearch caravan cartier casa catholic cba cbn cbre chase chintai chloe cisco citadel citi cloud club co com.co commbank compare cooking coupon courses cricket cuisinella date dds dell design discover doha download duns dupont earth everbank faith farmers fashion ferrero film fishing fit flickr flir ford fox frontier ftr gap garden gay giving grainger hbo health homegoods homesense honeywell horse hoteles hotels hsbc htc hyatt ibm ieee ink insurance intel intuit ipiranga iselect itau iwc jlc jmp jnj jpmorgan kinder kpmg krd kred lanxess latrobe law lifeinsurance lilly lincoln link loan loft luxe luxury marshalls mattel mcd mcdonalds melbourne men menu miami mint mlb mobily moe monash montblanc moto mtn mutual nba net.co netbank netflix neustar nfl nike nom.co northwesternmutual nyc office olayan olayangroup oldnavy one open osaka pamperedchef panerai party passagens pfizer philips physio piaget ping porn pramerica praxi pru prudential qvc racing review rmit rocher rodeo rugby safety sandvik sandvikcoromant sas saxo schmidt science scor seek select seven sex skype song staples starhub statefarm stream study sucks surf swiftcover sydney tab taipei taobao target tdk tel teva tjmaxx tjx tkmaxx tmall trade tube us vip virgin vista vistaprint vivo vodka voting vu vuelos walter watches weather weatherchannel webcam wedding wiki williamhill win winners woodside work wtc xn--1ck2e1b xn--80aqecdr1a xn--bck1b9a5dre4c xn--cck2b3b xn--eckvdtc9d xn--fct429k xn--g2xx48c xn--gckr3f0f xn--gk3at1e xn--jvr189m xn--kcrx77d1x4a xn--kpu716f xn--mgba3a3ejt xn--mgba7c0bbn0a xn--mgbb9fbpob xn--mgbi4ecexp xn--ngbc5azd xn--pbt977c xn--rovu88b xn--tiq49xqyj xxx yahoo yandex yoga zero zippo

=head3 Standard extensions:

L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::AllocationToken> urn:ietf:params:xml:ns:allocationToken-1.0

=head3 Custom extensions (NeuLevel Narwhal)

L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::Message> urn:ietf:params:xml:ns:neulevel-1.0

L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact> urn:ietf:params:xml:ns:neulevel-1.0 (For .NYC Only)

L<NET::DRI::Protocol::EPP::Extensions::NeuLevel::WhoisType> urn:ietf:params:xml:ns:neulevel-1.0 (For .TEL Only)

=head3 Custom extensions (ARI)

L<Net::DRI::Protocol::EPP::Extensions::ARI::Application> urn:ar:params:xml:ns:application-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::Trademark> urn:ar:params:xml:ns:tmch-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::IDN> urn:ar:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::Variant> urn:ar:params:xml:ns:variant-1.1

L<Net::DRI::Protocol::EPP::Extensions::ARI::Price> urn:ar:params:xml:ns:price-1.2

L<Net::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::ExAvail> urn:ar:params:xml:ns:exAvail-1.0

L<Net::DRI::Protocol::EPP::Extensions::ARI::Block> urn:ar:params:xml:ns:block-1.0

=head3 Notes

1. You can select from "narwhal" or "ari" which use different extensions. "ari" uses custom ARI extensions, while "narwhal" uses the more standardizes extensions.
It is recommended that "neustar" legacy is not used, but rather use the DRD::Neustar::* Drivers.

2. ARI's implementation of LaunchPhase (TMCH) differers from the standard, however the units are built to mimic the standard extension's usage

3. In the case of NYC it is required to either set name or tlds parameter in order to load the Nexus extension for contacts and domains.
See: L<Net::DRI::Data::Contact::ARI> and L<Net::DRI::Protocol::EPP::Extensions::NeuLevel::EXTContact>

 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'ari',name=>'nyc'}); # using name
 $dri->target('nyc')->add_current_profile(....);
 $dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'ari',name=>'whatever',tlds=['nyc']}); # using tld

=cut

 my @neustar_tlds = qw/aaa able abogado accountant adult aetna afl aig americanexpress amex amica analytics anz aramco athleta auspost axa banamex bananarepublic bank barclaycard barclays baseball basketball beer bible bid biz booking boots boston box buzz calvinklein cancerresearch caravan cartier casa catholic cba cbn cbre chase chintai chloe cisco citadel citi cloud club co com.co net.co nom.co commbank compare cooking coupon courses cricket cuisinella date dds dell design discover doha download duns dupont earth everbank faith farmers fashion ferrero film fishing fit flickr flir ford fox frontier ftr gap garden gay giving grainger hbo health homegoods homesense honeywell horse hoteles hotels hsbc htc hyatt ibm ieee ink insurance intel intuit ipiranga iselect itau iwc jlc jmp jnj jpmorgan kinder kpmg krd kred lanxess latrobe law lifeinsurance lilly lincoln loan loft luxe luxury marshalls mattel mcd mcdonalds melbourne men menu miami mint mlb mobily moe monash montblanc moto mtn mutual nba netbank netflix neustar nfl nike northwesternmutual nyc office olayan olayangroup oldnavy one open osaka pamperedchef panerai party passagens pfizer philips physio piaget ping porn pramerica praxi pru prudential qvc racing review rmit rocher rodeo rugby safety sandvik sandvikcoromant sas saxo schmidt science scor seek select seven sex skype song staples starhub statefarm stream study sucks surf swiftcover sydney tab taipei taobao target tdk tel teva tjmaxx tjx tkmaxx tmall trade tube us vip virgin vista vistaprint vivo vodka voting vu vuelos walter watches weather weatherchannel webcam wedding wiki williamhill win winners woodside work wtc xn--1ck2e1b xn--80aqecdr1a xn--bck1b9a5dre4c xn--cck2b3b xn--eckvdtc9d xn--fct429k xn--g2xx48c xn--gckr3f0f xn--gk3at1e xn--jvr189m xn--kcrx77d1x4a xn--kpu716f xn--mgba3a3ejt xn--mgba7c0bbn0a xn--mgbb9fbpob xn--mgbi4ecexp xn--ngbc5azd xn--pbt977c xn--rovu88b xn--tiq49xqyj xxx yahoo yandex yoga zero zippo/;

 return {
     bep_type => 2, # shared registry
     tlds => \@neustar_tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ARI',{}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::Neustar->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::Neustar'],
     whois_server => 'whois.aridnrs.net.au',
 } if $bep eq 'ari';

 return {
     bep_type => 2, # shared registry
     tlds => \@neustar_tlds,
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Neustar',{ 'brown_fee_version' => '0.6' }],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::Neustar->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::Neustar'],
     whois_server => 'whois.aridnrs.net.au',
 } if $bep eq 'narwal' || $bep eq 'narwhal';

 return {
     bep_type => 1, # dedicated registry
     tlds => ['hotels htc ipiranga itau'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::Neustar',{extensions => ['-NeuLevel::WhoisType','-ARI::KeyValue','-NeuLevel::EXTContact'], 'brown_fee_version' => '0.6' }],
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

=head3 Nominet TLDs

cymru wales bbc

=head3 Nominet-MMX: TLDs migrated in 2016 from Mind + Machines into Nominet management

bentley bradesco broadway career gop gucci jobs med pharmacy realestate realtor
# README: .bentley/.career/.gucci/.jobs/.med/.pharmacy/.realestate/.realtor is not part of MMX but loading here because has a similar logic :p

=head3 Nominet-Amazon: TLDs migrated in 2019 from Neustar into Nominet management

amazon audible author aws book bot buy call circle deal fast fire free got hot imdb jot joy kindle like moi now pay pin prime read room safe save secure silk smile spot talk tunes tushu wanggou wow yamaxun you zappos

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['cymru','wales','bbc'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn'=>1, custom => ['CentralNic::Fee','AllocationToken']}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nominet';

 return {
     bep_type => 1, # dedicated registry
     tlds => ['bentley', 'bradesco', 'broadway', 'career', 'gop', 'gucci', 'jobs', 'med', 'pharmacy', 'realestate', 'realtor'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','AllocationToken'], 'brown_fee_version' => '0.5' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nominet-mmx';

  return {
     bep_type => 1, # dedicated registry
     tlds => ['amazon','audible','author','aws','book','bot','buy','call','circle','deal','fast','fire','free','got','hot','imdb','jot','joy','kindle','like','moi','now','pay','pin','prime','read','room','safe','save','secure','silk','smile','spot','talk','tunes','tushu','wanggou','wow','yamaxun','you','zappos'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{custom => ['CentralNic::Fee','AllocationToken'], 'brown_fee_version' => '0.23' }],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nominet-amazon';

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

berlin hamburg versicherung ikano

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::RegBox::ServiceMessage> http://tld-box.at/xmlns/resdata-1.1

=head3 Notes

1. RegBox does not use the IDN extension.

2. RegBox does not use billing contacts.

=cut

 return {
     bep_type => 1, # dedicated registry
     tlds => ['berlin','hamburg','versicherung','ikano'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::RegBox',{'brown_fee_version' => '0.9'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::RegBox->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::RegBox'],
     contact_i18n => 2,
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'regbox';


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
     transport_protocol_default => ['Net::DRI::Transport::Socket', {},'Net::DRI::Protocol::EPP::Extensions::SIDN_GTLD',{}],
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
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::ECOMLAC',{}],
     contact_i18n => 1,
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'nicmx';

=pod


=head2 Tango-RS

 $dri->add_registry('NGTLD',{provider=>'tango'});

=head3 Status: Working

=head3 TLDs

bayern ruhr gmx ifm nrw whoswho tel

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::IDN> urn:ar:params:xml:ns:idn-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::Auction> urn:ar:params:xml:ns:auction-1.0

L<Net::DRI::Protocol::EPP::Extensions::TangoRS::LaunchPhase> : http://xmlns.corenic.net/epp/mark-ext-1.0

=cut

 my $tangorsversion; # setting this variable because this profile use distinct fee extensions per TLD :(
 $tangorsversion = undef; # no fee - default
 $tangorsversion = '1.0' if $tld eq 'nrw'; # fee standard (rfc8748)
 $tangorsversion = '0.8' if $tld eq 'tel'; # fee standard (rfc8748)
 $tangorsversion = '0.21' if $tld eq 'whoswho'; # draft fee version 0.21
 # no idea about the other TLDs: gmx and ifm - simply add, and share please, if needed :)

 return {
     bep_type => 1, # dedicated registry
     tlds => ['bayern','ruhr','gmx','ifm','nrw','whoswho','tel'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TangoRS',{fee_version => $tangorsversion}],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'tango' || $bep eq 'tangors';

=pod


=head2 TCI (cctld.ru)

$dri->add_registry('NGTLD',{provider=>'tci'});

=head3 Status: Working

=head3 TLDs

moscow tatar xn--d1acj3b xn--1-7sbc5ceg xn--2-7sbc5ceg  xn--80adxhks

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Contact> http://www.tcinet.ru/epp/tci-contact-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Domain> http://www.tcinet.ru/epp/tci-domain-ext-1.0

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.11

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xn--80adxhks', 'xn--d1acj3b', 'tatar', 'moscow'], # testing : 'xn--1-7sbc5ceg', 'xn--2-7sbc5ceg',
     contact_i18n => 7, # and or ?
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::TCI_gTLD->new(@_); } } ],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::TCI_gTLD',{}],
   } if $bep eq 'tci';

=pod


=head2 Teleinfo

$dri->add_registry('NGTLD',{provider=>'teleinfo'});

=head3 Status: Working

=head3 TLDs

xn--3ds443g xn--fiq228c5hs xn--nyqy26a xn--rhqv96g xn--vuq861b

=cut

 return {
     bep_type => 2, # shared registry
     tlds => ['xn--3ds443g', 'xn--fiq228c5hs', 'xn--nyqy26a', 'xn--rhqv96g', 'xn--vuq861b'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'custom' => ['CentralNic::Fee'], 'disable_idn' => 1, 'brown_fee_version' => '0.9'}],
     whois_server => 'whois.teleinfo.cn',
   } if $bep eq 'teleinfo';

=pod


=head2 UniRegistry (Internet Systems Consortium)

 $dri->add_registry('NGTLD',{provider=>'unireg'});
 $dri->add_registry('NGTLD',{provider=>'tucows'});

=head3 Status: Working

=head3 TLDs

audio blackfriday christmas click country diet flowers game gift guitars help hiphop hiv hosting juegos link lol mom photo pics property sexy tattoo trust

Contended TLD's not included

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric> http://ns.uniregistry.net/centric-1.0

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market> http://ns.uniregistry.net/market-1.0

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::RegistryMessage> (poll parser suppliment)

=head3 Other extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=cut

 if ($bep eq 'unireg' or $bep eq 'tucows') {
  # These methods are in the DRD
  require Net::DRI::DRD::UniRegistry::UniRegistry;
  *market_check = sub { return Net::DRI::DRD::UniRegistry::UniRegistry::market_check(@_); };
  *market_info= sub { return Net::DRI::DRD::UniRegistry::UniRegistry::market_info(@_); };
  *market_create= sub { return Net::DRI::DRD::UniRegistry::UniRegistry::market_create(@_); };
  *market_update= sub { return Net::DRI::DRD::UniRegistry::UniRegistry::market_update(@_); };
 }

 my @custom = [];
 if ($bep eq 'unireg') {
    push @custom, 'UniRegistry::Market';
    push @custom, 'UniRegistry::Centric';
 }

 return {
     bep_type => 2, # shared registry
     tlds => ['audio','blackfriday','christmas','click','country','diet','flowers','game','gift','guitars','help','hiphop','hiv','home','hosting','juegos','link','lol','mom','photo','pics','property','sexy','tattoo','trust'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UniRegistry',{'custom' => @custom, 'brown_fee_version' => '0.7'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UniRegistry'],
     whois_server => 'whois.uniregistry.net',
   } if ($bep eq 'unireg' or $bep eq 'tucows');

=pod

=head3 TLDs

creditunion love

UNR no longer own any TLDs so from now on they plan to use a distinct server for some TLDs: .coop (epp.registry.coop:700), .love (epp.registry.love:700)

=head3 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head3 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=cut

 return {
     bep_type => 1, # dedicated (Since UNR no longer own any TLDs from now on and for some TLDs: "... most of our TLDs will be operated separately by their respective registry operators")
     tlds => ['creditunion','love'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UniRegistry',{'brown_fee_version' => '0.7'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UniRegistry'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'unireg_nonshared';

=pod

=head2 ICM

 $dri->add_registry('NGTLD',{provider=>'unireg_icm'});

=head3 Status: Working

=head3 TLDs

adult porn sex xxx

UniRegistry backend system to manage MMX ICM TLDs

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric> http://ns.uniregistry.net/centric-1.0

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market> http://ns.uniregistry.net/market-1.0

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::RegistryMessage> (poll parser suppliment)


=head3 Other extensions:

L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=cut

 if ($bep eq 'unireg_icm') {
  # These methods are in the DRD
  require Net::DRI::DRD::UniRegistry::Market;
  *market_check = sub { return Net::DRI::DRD::UniRegistry::Market::market_check(@_); };
  *market_info= sub { return Net::DRI::DRD::UniRegistry::Market::market_info(@_); };
  *market_create= sub { return Net::DRI::DRD::UniRegistry::Market::market_create(@_); };
  *market_update= sub { return Net::DRI::DRD::UniRegistry::Market::market_update(@_); };
 }

 return {
     bep_type => 2, # shared
     tlds => ['adult','porn','sex','xxx'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UniRegistry',{'brown_fee_version' => '0.7', 'default_product'=>'ICM'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UniRegistry'],
     whois_server => (defined $tld && $tld =~ m/\w+/ ? 'whois.nic.' . $tld : undef),
   } if $bep eq 'unireg_icm';

=pod

=head2 EPS

 $dri->add_registry('NGTLD',{provider=>'unireg_eps'});

=head3 Status: Work in progess

=head3 TLDs

adultblock adultblockplus (not really a TLD but profile used for mapping... for now)

UniRegistry EPS ICM adultblock/adultblockplus

=head3 Custom extensions:

L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::EPS> (Extended Protection Service)

=cut

 if ($bep eq 'unireg_eps') {
  # These methods are in the DRD
  require Net::DRI::DRD::UniRegistry::EPS;
 }

 return {
     bep_type => 2, # shared
     tlds => ['adultblock', 'adultblockplus'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UniRegistry::EPS',{'default_product'=>'ICM_EPS'}],
     factories => [ {'object'=>'contact','factory' => sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); } } ],
     requires => [ 'Net::DRI::Data::Contact::UniRegistry'],
   } if $bep eq 'unireg_eps';

=pod


=head2 Verisign

 $dri->add_registry('NGTLD',{provider=>'verisign'});

=head3 Status: Working

=head3 TLDs

xn--pssy2u xn--c1yn36f xn--11b4c3d xn--t60b56a xn--c2br7g xn--42c2d9a xn--j1aef xn--3pxu8k xn--hdb9cza1b xn--mk1bu44c xn--fhbei xn--tckwe xn--9dbq2a azure bing crs hotmail java maif microsoft oracle pictet sca shell sky xbox windows

Note: As VeriSign has started to use the RFC8748 Fee extension (fee-1.0), we are no longer supporting PremiumDomain and CentralNic::Fee to avoid conflicts

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
L<Net::DRI::Protocol::EPP::Extensions::VeriSign::PremiumDomain> (Not loaded by default)
L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.9 (Not loaded by default)
L<Net::DRI::Protocol::EPP::Extensions::Fee>

=cut

 return {
     bep_type => 2,
     contact_i18n => 7, # They accept LOC *or* INT, but only one of them.
     tlds => ['com','net','cc','tv','name','xn--pssy2u','xn--c1yn36f','xn--11b4c3d','xn--t60b56a','xn--c2br7g','xn--42c2d9a','xn--j1aef','xn--3pxu8k','xn--hdb9cza1b','xn--mk1bu44c','xn--fhbei','xn--tckwe','xn--9dbq2a','azure','bing','crs','hotmail','java','maif','microsoft','oracle','pictet','sca','shell','sky','xbox','windows'],
     transport_protocol_default => ['Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::NEWGTLD',{'disable_idn' => 1, custom => ['VeriSign::Sync', 'VeriSign::PollLowBalance', 'VeriSign::PollRGP', 'VeriSign::IDNLanguage', 'VeriSign::WhoWas', 'VeriSign::Suggestion', 'VeriSign::ClientAttributes', 'VeriSign::TwoFactorAuth', 'VeriSign::ZoneManagement', 'VeriSign::Balance', 'VeriSign::NameStore', 'Fee'], 'fee_version' => '1.0'}],
     whois_server => 'ccwhois.verisign-grs.com',
   } if $bep eq 'verisign';



=pod


=head2 ZACR (UniForum/ZA Central Registry)

 $dri->add_registry('NGTLD',{provider=>'zacr'});

=head3 Status: Working

=head3 TLDs

africa capetown cologne durban joburg koeln tirol wien

=head3 Custom extensions:

L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

The extensions are optional, so no need to do anything out of the ordinary if you don't want to.

L<Net::DRI::Protocol::EPP::Extensions::ZACR::Domain> http://co.za/epp/extensions/cozadomain-1-0
L<Net::DRI::Protocol::EPP::Extensions::ZACR::Contact> http://co.za/epp/extensions/cozacontact-1-0

=cut

 return {
     bep_type => 1, # dedicated
     tlds => ['africa','capetown','cologne','durban','joburg','koeln','tirol','wien'],
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
