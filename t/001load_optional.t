#!/usr/bin/perl
#
# Here we test the presence of optional modules,
# needed for some registries in Net::DRI but not all of them,
# and we warn the user if they are not present

use strict;
use warnings;

use Test::More tests => 10;

#SKIP: {
#	eval { require Net::SMTP; };
#	skip 'Module Net::SMTP is not installed, you need it if you want to use Net::DRI for: AFNIC (emails)',1 if $@;
#	require_ok('Net::DRI::Transport::SMTP');
#}

SKIP: {
	eval { require XMLRPC::Lite; };
	skip 'Module XMLRPC::Lite is not installed, you need it if you want to use Net::DRI for: Gandi (WebServices)',2 if $@;
	require_ok('Net::DRI::Transport::HTTP::XMLRPCLite');
        require_ok('Net::DRI::Protocol::Gandi::WS::Connection'); ## depends on XMLRPC::Data
}

SKIP: {
	eval { require SOAP::Lite; };
	skip 'Module SOAP::Lite is not installed, you need it if you want to use Net::DRI for: BookMyName (WebServices)',1 if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPLite');
}

SKIP: {
	eval { require SOAP::WSDL; }; ## also needs SOAP::Lite
	skip('Module SOAP::WSDL is not installed, you need it if you want to use Net::DRI for: OVH (WebServices)',1) if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPWSDL');
}

SKIP: {
	eval { require LWP::UserAgent; LWP::UserAgent->VERSION('6.02'); };
	skip('Module LWP::UserAgent is not installed or not at least version 6.02, you need it if you want to use Net::DRI for: OpenSRS (XCP), .PL (EPP over HTTPS), .IT (EPP over HTTPS)',1) if $@;
	require_ok('Net::DRI::Transport::HTTP');
}

SKIP: {
	eval { require HTTP::Request; };
	skip('Module HTTP::Request is not installed, you need it if you want to use Net::DRI for: .PL (EPP over HTTPS), .IT (EPP over HTTPS)',1) if $@;
	require_ok('Net::DRI::Protocol::EPP::Extensions::HTTP');
}

SKIP: {
	eval { require Digest::MD5; };
	skip('Module Digest::MD5 is not installed, you need it if you want to use Net::DRI for: OpenSRS (XCP)',1) if $@;
        eval { require HTTP::Request; };
        skip('Module HTTP::Request is not installed, you need it if you want to use Net::DRI for: OpenSRS (XCP)',1) if $@;
	require_ok('Net::DRI::Protocol::OpenSRS::XCP::Connection');
}

SKIP: {
	eval { require IO::Uncompress::RawInflate; };
	skip('Module IO::Uncompress::RawInflate is not installed, you need it if you want to use Net::DRI for: .DE (IRIS DCHK over LWZ) .FR (IRIS DCHK over LWZ)',1) if $@;
	eval { require IO::Compress::RawDeflate; };
	skip('Module IO::Compress::RawDeflate is not installed, you need it if you want to use Net::DRI for: .DE (IRIS DCHK over LWZ) .FR (IRIS DCHK over LWZ)',1) if $@;
	eval { require Net::DNS; };
	skip('Module Net::DNS is not installed, you need it if you want to use Net::DRI for: .DE (IRIS DCHK over LWZ) .FR (IRIS DCHK over LWZ)',1) if $@;
	require_ok('Net::DRI::Protocol::IRIS::LWZ');
}

SKIP: {
	eval { require Sys::Syslog; }; ## this is in Perl core, but necessarily here on Windows !
	skip('Module Sys::Syslog is not installed, you need it if you want to use Net::DRI logging over syslog',1) if $@;
	require_ok('Net::DRI::Logging::Syslog');
}

SKIP: {
	eval { require Net::SAML2; };
	skip('Module Net::SAML2 is not installed, you need it to verify signatures of marks (ICANN TMCH)',1) if $@;
	eval { require MIME::Base64; };
	skip('Module MIME::Base64 is not installed, you need it to manipulate encoded signed marks (ICANN TMCH)',1) if $@;
	require_ok('Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark');
}

exit 0;
