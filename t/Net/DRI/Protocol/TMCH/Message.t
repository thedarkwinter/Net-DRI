#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Net::DRI::Protocol::TMCH::Message;
use Net::DRI::Data::Raw;

use Test::More tests=> 12;

my $msg;
my $s;

###################################################################################

$msg=Net::DRI::Protocol::TMCH::Message->new();
$msg->ns({ _main   => ['urn:ietf:params:xml:ns:tmch-1.0','tmch-1.0']});
$s=Net::DRI::Data::Raw->new_from_string(<<EOF);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:tmch-1.0
     tmch-1.0.xsd">
  <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54321-XYZ</svTRID>
    </trID>
  </response>
</tmch>
EOF

$msg->parse($s);
is($msg->result_code(),1000,'parse (result,trid) result_code');
is($msg->result_message(),'Command completed successfully','parse (result,trid) result_message');
is($msg->result_lang(),'en','parse (result,trid) result_lang');
is($msg->cltrid(),'ABC-12345','parse (result,trid) cltrid');
is($msg->svtrid(),'54321-XYZ','parse (result,trid) svtrid');

$msg=Net::DRI::Protocol::TMCH::Message->new();
$msg->ns({ _main   => ['urn:ietf:params:xml:ns:tmch-1.0','tmch-1.0']});
$s=Net::DRI::Data::Raw->new_from_string(<<EOF);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<tmch xmlns="urn:ietf:params:xml:ns:tmch-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:tmch-1.0
     tmch-1.0.xsd">
  <response>
    <result code="2004">
      <msg>Parameter value range error</msg>
      <value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem1>2525</obj:elem1></value>
    </result>
    <result code="2005">
      <msg>Parameter value syntax error</msg>
      <value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem2>ex(ample</obj:elem2></value>
      <extValue><value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem3>abc.ex(ample</obj:elem3></value><reason>Invalid character found.</reason></extValue>
    </result>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54321-XYZ</svTRID>
    </trID>
  </response>
</tmch>
EOF

$msg->parse($s);

is($msg->result_code(0),2004,'parse (result,2 errors) result_code(0)');
is($msg->result_code(1),2005,'parse (result,2 errors) result_code(1)');
my $ri=$msg->result_extra_info(0);
is_deeply($ri,[{type=>'rawxml',from=>'eppcom:value',message=>'<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem1>2525</obj:elem1></value>'}],'parse (result,2 errors) result_extra_info(0)');
$ri=$msg->result_extra_info(1);
is_deeply($ri,[{type=>'rawxml',from=>'eppcom:value',message=>'<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem2>ex(ample</obj:elem2></value>'},{type=>'rawxml',from=>'eppcom:extValue',message=>'<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem3>abc.ex(ample</obj:elem3></value>',reason=>'Invalid character found.',lang=>'en'}],'parse (result,2 errors) result_extra_info(1)');
is_deeply([$msg->results_code()],[2004,2005],'parse (result,2 errors) results_code');
is_deeply([$msg->results_message()],['Parameter value range error','Parameter value syntax error'],'parse (result,2 errors) results_message');
is_deeply([$msg->results_lang()],['en','en'],'parse (result,2 errors) results_lang');

#################################################################################


exit 0;