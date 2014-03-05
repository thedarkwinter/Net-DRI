#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI::Protocol::EPP::Connection;
use Encode ();

use Test::More tests => 5;

can_ok('Net::DRI::Protocol::EPP::Connection',qw(read_data write_message));

TODO: {
        local $TODO="tests on read_data() write_message()";
        ok(0);
}

## This was basically in t/241epp_message.t before but needs to be moved
SKIP: {
	eval { require Net::DRI::Protocol::EPP::Message; };
	skip 'Unable to correctly load Net::DRI::Protocol::EPP::Message',3 if $@;
	
	my $msg=Net::DRI::Protocol::EPP::Message->new();
	$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
	$msg->command(['check','host:check','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);
	$msg->command_body([['host:name','ns1.example.com'],['host:name','ns2.example.com'],['host:name','ns3.example.com']]);
	$msg->cltrid('ABC-12345');

	my $s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <check>
      <host:check
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
        <host:name>ns2.example.com</host:name>
        <host:name>ns3.example.com</host:name>
      </host:check>
    </check>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

	$msg->version('1.0');
	my $m=Net::DRI::Protocol::EPP::Connection->write_message(undef,$msg);
	ok(!Encode::is_utf8($m),'Unicode : XML string sent on network is bytes not characters (version 1.0)');
	my $l=unpack('N',substr($m,0,4));
	$m=substr($m,4);
	is($l,4+length(_n($s)),'Unicode : XML string length (version 1.0)');
	is($m,_n($s),'Unicode : string is ok after removing length (version 1.0)');
}


exit 0;

sub _n
{
 my $in=shift;
 $in=~s/^\s+//gm;
 $in=~s/\n/ /g;
 $in=~s/>\s+</></g;
 $in=~s/\s+$//gm;
 return $in;
}
