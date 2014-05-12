### Net-DRI-0.96_06_tdw 

Based on Net-DRI-0.96_05 Patrick Mevzek, [Home Page](http://www.dotandco.com/services/software/Net-DRI/) and [CPAN](http://search.cpan.org/dist/Net-DRI/)

* * *
#### Overview
This version contains the following updates along with a few bug fixes and improvements

##### LaunchPhase extension 
Based on draft-ietf-eppext-launchphase-01

##### New gTLD backend providers (RO's)
Afilias, ARI, CentralNIC, CoreNIC, Charleston Road Registry, Donuts, Famous Four Media, GMO Registry, KSRegistry (Starting Dot), Minds And Machines, Neustar, Registry-in-a-Box from NicAT, Rightside, Tango from KNIPP, UniRegistry

##### Planned support for providers
CoCCA, KNET, Nic.br, Nominet, OpenRegistry, SIDN, TCI, Verisign, ZACR

##### Trademark services
TMCH (Deloitte)
TMDB (IBM): CNIS and SMDRL only

##### Added/Updated/Fixed support for ccTLDs
UK, IT, ES, NO, SE/NU (IIS module), BE, Eu, DE, CH, ZA


* * *
#### NGTLD Usage

The NGTLD "Super-DRD" is intended to work for all new gTLD providers with minimal fuss. In principle you can add the registry by selecting the provider and optionally customise the name and TLDs available.
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
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'nyc'}); # using name
$dri->target('nyc')->add_current_profile(....);
$dri->add_registry('NGTLD',{clid => 'ClientX',provider=>'neustar',name=>'whatever',tlds=['nyc']}); # using tld
```

* * *
