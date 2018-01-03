### Net-DRI-0.12-tdw

* * *
#### Overview

Net-DRI-0.X-tdw is a fork of Net-DRI from Patrick Mevzek [Home Page](http://www.dotandco.com/services/software/Net-DRI/), [CPAN](http://search.cpan.org/dist/Net-DRI/) based on Net-DRI-0.96_09 that includes support for new gTLDs, as well as a few other experimental changes. While some of these changes might be merged into the main release, there is no guarantee that they will be, or that they will be exactly the same if they do, so please consider this fork "mostly stable", but experimental.

* * *
#### Warning!

!! Since 0.12-tdw (2017-06-28),this fork contains the restructure of DRDs from Net-DRI-0.96_09, meaning that you will need to change your scripts. See http://cpansearch.perl.org/src/PMEVZEK/Net-DRI-0.96_09/Changes, along with the note:

"_This version changes almost all DRD module names, you will need to change your scripts.
  This is a consequence of an old design decision that no DRD module should have a TLD as name.
  Now, by default a DRD of a TLD registry will have the sponsor name as listed on IANA website._"
* While the upstream favours the Registry name for DRD, I favour the BackendOperator::Platform Naming
  * So instead of (.travel) Tralliance, I use Neustar::Tralliance, though there is variation in here I am still working on!
  * Its sometimes more clean to use Backend::TLD when the platform is for a single TLD and the operator is the backend.
  * For instance, GMORegistry::GMORegistry, and GMORegistry::BRRegistry, and GMORegistry::SHOP
  * Note, using old DRD names will probably still work as they will be automaticaly remapped. Probably.

* * *
##### LaunchPhase extension
Based on draft-ietf-eppext-launchphase-07 / draft-ietf-regext-launchphase-00

##### Fee extension
Based on draft-ietf-regext-epp-fees-06 (fee-0.23)

##### New gTLD backend providers (RO's)
Afnic, Afilias, Amazon (Neustar), ARI (now Neustar), CoCCA, CentralNIC, CoreNIC, Charleston Road Registry, CNNIC, Donuts, Famous Four Media (Nominet), Fury Registry (CIRA), GMO Registry, KNET, KSRegistry, Minds And Machines (Nominet-MMX), Neustar, Nic.BR, Nic.MX, Nominet, OpenRegistry, Registry-in-a-Box from NicAT, Rightside, SIDN, Tango from KNIPP, TCI, TeleInfo, UniRegistry, Verisign, ZACR

##### Planned/Possible support for providers
None

##### Trademark services
TMCH (Deloitte)
TMDB (IBM): CNIS and SMDRL only

##### Added/Updated/Fixed support for ccTLDs
UK, IT, ES, NO, SE/NU (IIS module), BE, EU, DE, CH, ZA, CO, MX, LV, DK, US, PH, CN, AE, NZ, EC, UA, EC, IN, RU, UA, RF, SU, CZ, MW, RO, CR, Afilias (IO AC SH), AfiliasGRS (AG BZ LC MN SC VC), CentralNic-Gateway (AM CX FM LA), CL, FI, ID, SK

* * *
#### NGTLD Usage

The NGTLD "Super-DRD" is intended to work for all new gTLD providers with minimal fuss. In principle you can add the registry by selecting the provider and optionally customise the name and TLDs available. In some cases, traditional DRD's are in still availalble, but they are likely to be outdated.
```perl
$dri->add_registry('NGTLD',{clid => '...',provider=>'...',name=>'...', tlds=>[]});
```

##### Selecting a back end provider

```perl
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'Neustar'});
$dri->target('Neustar')->add_current_profile(....);
```

##### Backend providers with shared environments

Donuts is an example of a backend that provides a single platform for all their TLDs. Normally only specifying the provider will suite your needs

```perl
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'donuts'});
$dri->target('donuts')->add_current_profile(....);
````

##### Backend providers with dedicated environments

Neustar is an example of a backend provider that provides a dedicated environment per TLD, so you may like to use the TLD as the target name.
e.g: add a custom target name, by default this is the back end provider name, but in this instance we select buzz
Note, if the name you specified matches one of the TLD's and you have not manually specified the tld list, if will use only this TLD. If the name doesn't match a TLD, it will make all TLD's by the prover available in the DRD

```perl
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'buzz'});
$dri->target('buzz')->add_current_profile(....);
```

Some TLDs have specific extensions that need to be loaded. In the case of NYC it is required to either set name or tlds parameter in order to load the Nexus extension

```perl
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'ari',name=>'nyc'}); # using name
$dri->target('nyc')->add_current_profile(....);
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'ari',name=>'whatever',tlds=['nyc']}); # using tld
```

##### Some experimental ngTLD functions
```perl
$rc = $dri->domain_check_claims('test.tld',{phase=>'landrush'});
$lp = $dri->get_info('lp');
$claim_key = ($lp->{'exist'}) ? $lp->{'claim_key'} : undef;

$rc = $dri->domain_check_price('test.tld');
$dri->get_info('is_premium');
$dri->get_info('create_price');
```

* * *
