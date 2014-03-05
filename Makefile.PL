use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DRI',
    AUTHOR              => 'Patrick Mevzek <netdri@dotandco.com>',
    VERSION_FROM        => 'lib/Net/DRI.pm',
    ABSTRACT            => 'Interface to Domain Name Registries/Registrars/Resellers',
    PL_FILES            => {},
    LICENSE             => 'gpl',
    PREREQ_PM => {
        'DateTime' => 0,
        'DateTime::Duration' => 0,
        'DateTime::Format::Strptime' => 0,
        'DateTime::TimeZone' => 0,
        'DateTime::Format::ISO8601' => '0.06', ## version 0.0403 is also ok, version 0.05 IS NOT OK !
        'Class::Accessor' => 0,
        'Class::Accessor::Chained' => 0,
        'IO::Socket::SSL' => '1.31',
        'Email::Valid' => 0,
        'XML::LibXML' => '1.61',
        'Module::Load' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::LongString' => 0,

    },
    EXE_FILES => [ 'bin/drish' ],
    MIN_PERL_VERSION    => '5.8.0', ## as reported by perlver from Perl::MinimumVersion
    META_ADD            => { optional_features => {
                                                   webservices => { description => 'Support of webservices for the following registry drivers: Gandi, BookMyName, OVH',
                                                                    requires => {
                                                                                 'XMLRPC::Lite' => 0,
                                                                                 'SOAP::Lite' => 0,
                                                                                 'SOAP::WSDL' => 0,
                                                                                },
                                                                  },
                                                   http => { description => 'Support of HTTP(S) transport for OpenSRS, .IT and .PL',
                                                             requires => {
                                                                          'LWP::UserAgent' => '6.02',
                                                                          'HTTP::Request' => 0,
                                                                         },
                                                           },
                                                   digest => { description => 'Support of MD5 digest for OpenSRS',
                                                               requires => {
                                                                            'Digest::MD5' => 0,
                                                                           },
                                                             },
                                                   iris => { description => 'Support of IRIS inflation/deflation & DNS SRV records for .DE and .FR IRIS DCHK service',
                                                             requires => {
                                                                          'IO::Uncompress::RawInflate' => 0,
                                                                          'IO::Compress::RawDeflate' => 0,
                                                                          'Net::DNS' => 0,
                                                                         },
                                                           },
                                                   smd => { description => 'Support for ICANN TMCH signed mark content (new gTLDs)',
                                                            requires => {
                                                                         'Net::SAML2' => 0,
                                                                         'MIME::Base64' => 0,
                                                                        },
                                                          },
                                                  },
                             keywords => [qw/DNS EPP RRP DAS ENUM IRIS DCHK Whois gTLD ccTLD domain ICANN TMCH SMD/],
                             resources => { homepage => 'http://www.dotandco.com/services/software/Net-DRI/index.en',
                                            license  => 'http://www.dotandco.com/services/software/Net-DRI/index.en#license',
                                            bugtracker => 'nntp://news.dotandco.net/dotandco.discuss'},
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DRI-*' },
);
