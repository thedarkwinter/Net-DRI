#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 340;

use Net::DRI::Util;

ok(%Net::DRI::Util::CCA2,'%CCA2 defined');
isa_ok(\%Net::DRI::Util::CCA2,'HASH','%CCA2 hash');
is(keys(%Net::DRI::Util::CCA2),250,'%CCA2 number of elements');
is_deeply([grep { ! /^[A-Z]{2}$/ } keys(%Net::DRI::Util::CCA2)],[],'%CCA2 keys');
is(exists($Net::DRI::Util::CCA2{'FR'}),1,'%CCA2 FR exists');
is(!exists($Net::DRI::Util::CCA2{'ZZ'}),1,'%CCA2 ZZ not exists');

is(Net::DRI::Util::all_valid(undef,1,'A'),0,'all_valid() with one undef');
is(Net::DRI::Util::all_valid('B',undef,2,undef),0,'all_valid() with two undef');
is(Net::DRI::Util::all_valid(),1,'all_valid() empty');
is(Net::DRI::Util::all_valid(67,'AB'),1,'all_valid() not empty');

is(Net::DRI::Util::isint(-6),0,'isint(-6)');
is(Net::DRI::Util::isint(6),1,'isint(6)');
is(Net::DRI::Util::isint(67886),1,'isint(67886)');
is(Net::DRI::Util::isint('A'),0,'isint(A)');

is(Net::DRI::Util::check_equal(),undef,'check_equal()');
is(Net::DRI::Util::check_equal('A','A'),'A','check_equal(A,A)');
is(Net::DRI::Util::check_equal('A',['A']),'A','check_equal(A,[A])');
is(Net::DRI::Util::check_equal('A',['B','A']),'A','check_equal(A,[B,A])');
is(Net::DRI::Util::check_equal('A','C','def'),'def','check_equal(A,C,def)');
is(Net::DRI::Util::check_equal('A','C'),undef,'check_equal(A,C)');

eval { Net::DRI::Util::check_isa(bless({},'FooBar'),'FooBuz'); };
isa_ok($@,'Net::DRI::Exception','check_isa(FooBar,FooBuz)');
is(Net::DRI::Util::check_isa(bless({},'FooBar'),'FooBar'),1,'check_isa(FooBar,FooBuz)');

like(Net::DRI::Util::microtime(),qr/^\d{16}$/,'microtime()');
like(Net::DRI::Util::create_trid_1('name'),qr/^NAME-\d+-\d{16}$/,'create_trid_1(name)');


is(Net::DRI::Util::is_hostname(),0,'is_hostname()');
is(Net::DRI::Util::is_hostname('.'),0,'is_hostname(.)');
is(Net::DRI::Util::is_hostname('a.'),0,'is_hostname(a.)');
is(Net::DRI::Util::is_hostname('.a'),0,'is_hostname(.a)');
is(Net::DRI::Util::is_hostname('a..b'),0,'is_hostname(a..b)');
is(Net::DRI::Util::is_hostname('a.foo'),1,'is_hostname(a.foo)');
is(Net::DRI::Util::is_hostname('0.foo'),1,'is_hostname(0.foo)');
is(Net::DRI::Util::is_hostname('a.0.foo'),1,'is_hostname(a.0.foo)');
is(Net::DRI::Util::is_hostname('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.foo'),1,'is_hostname(abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyabcdefghijk.foo)');
is(Net::DRI::Util::is_hostname('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.foo'),0,'is_hostname(abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyabcdefghijkl.foo)');
is(Net::DRI::Util::is_hostname('-a.foo'),0,'is_hostname(-a.foo)');
is(Net::DRI::Util::is_hostname('a-.foo'),0,'is_hostname(a-.foo)');
is(Net::DRI::Util::is_hostname('a-b.foo'),1,'is_hostname(a-b.foo)');
is(Net::DRI::Util::is_hostname('a_b.foo'),0,'is_hostname(a_b.foo)');
is(Net::DRI::Util::is_hostname('a b.foo'),0,'is_hostname(a b.foo)');
foreach (0..255)
{
 next if ($_==45) || ($_==46) || (($_>=48) && ($_<=57)) || (($_>=65) && ($_<=90)) || (($_>=97) && ($_<=122));
 my $d='a'.chr($_).'b.foo';
 is(Net::DRI::Util::is_hostname($d),0,"is_hostname($d)");
}

is(Net::DRI::Util::is_ipv4(),0,'is_ipv4()');
is(Net::DRI::Util::is_ipv4('ab'),0,'is_ipv4(ab)');
is(Net::DRI::Util::is_ipv4('256.1.2.3'),0,'is_ipv4(256.1.2.3)');
is(Net::DRI::Util::is_ipv4('1.2.3'),0,'is_ipv4(1.2.3)');
is(Net::DRI::Util::is_ipv4('1.2.3.7.8'),0,'is_ipv4(1.2.3.7.8)');
is(Net::DRI::Util::is_ipv4('1.ab.6.7'),0,'is_ipv4(1.ab.6.7)');
is(Net::DRI::Util::is_ipv4('1.2.3.4'),1,'is_ipv4(1.2.3.4)');
is(Net::DRI::Util::is_ipv4('1.2.3.4',1),1,'is_ipv4(1.2.3.4,1)');
is(Net::DRI::Util::is_ipv4('0.1.2.3',1),0,'is_ipv4(0.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('10.1.2.3',1),0,'is_ipv4(10.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('127.1.2.3',1),0,'is_ipv4(127.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('169.254.6.7',1),0,'is_ipv4(169.254.6.7,1)');
is(Net::DRI::Util::is_ipv4('172.16.1.2',1),0,'is_ipv4(172.16.1.2,1)');
is(Net::DRI::Util::is_ipv4('172.33.1.2',1),1,'is_ipv4(172.33.1.2,1)');
is(Net::DRI::Util::is_ipv4('192.0.2.6',1),0,'is_ipv4(192.0.2.6,1)');
is(Net::DRI::Util::is_ipv4('192.168.1.3',1),0,'is_ipv4(192.168.1.3)');
is(Net::DRI::Util::is_ipv4('230.0.0.0',1),0,'is_ipv4(230.0.0.0,1)');

TODO: {
        local $TODO="tests on is_ipv6(), compare_duration()";
        ok(0);
}

is(Net::DRI::Util::xml_is_normalizedstring("A\tB"),0,'xml_is_normalizedstring()  1');
is(Net::DRI::Util::xml_is_normalizedstring("A",1),1,'xml_is_normalizedstring()  2');
is(Net::DRI::Util::xml_is_normalizedstring("A",2),0,'xml_is_normalizedstring()  3');
is(Net::DRI::Util::xml_is_normalizedstring("A",undef,1),1,'xml_is_normalizedstring()  4');
is(Net::DRI::Util::xml_is_normalizedstring("AB",undef,1),0,'xml_is_normalizedstring()  5');
is(Net::DRI::Util::xml_is_normalizedstring("A",1,2),1,'xml_is_normalizedstring()  6');
is(Net::DRI::Util::xml_is_normalizedstring("A",1,1),1,'xml_is_normalizedstring()  7');
is(Net::DRI::Util::xml_is_normalizedstring("AB",1,2),1,'xml_is_normalizedstring()  8');
is(Net::DRI::Util::xml_is_normalizedstring("ABC",1,2),0,'xml_is_normalizedstring()  9');
is(Net::DRI::Util::xml_is_normalizedstring(),0,'xml_is_normalizedstring() 10');

is(Net::DRI::Util::xml_is_token("A\tB"),0,'xml_is_token()  1');
is(Net::DRI::Util::xml_is_token(" AB"),0,'xml_is_token()  2');
is(Net::DRI::Util::xml_is_token("AB "),0,'xml_is_token()  3');
is(Net::DRI::Util::xml_is_token("A  B"),0,'xml_is_token()  4');
is(Net::DRI::Util::xml_is_token("A",1),1,'xml_is_token()  5');
is(Net::DRI::Util::xml_is_token("A",2),0,'xml_is_token()  6');
is(Net::DRI::Util::xml_is_token("A",undef,1),1,'xml_is_token()  7');
is(Net::DRI::Util::xml_is_token("AB",undef,1),0,'xml_is_token()  8');
is(Net::DRI::Util::xml_is_token("A",1,2),1,'xml_is_token()  9');
is(Net::DRI::Util::xml_is_token("A",1,1),1,'xml_is_token() 10');
is(Net::DRI::Util::xml_is_token("AB",1,2),1,'xml_is_token() 11');
is(Net::DRI::Util::xml_is_token("ABC",1,2),0,'xml_is_token() 12');
is(Net::DRI::Util::xml_is_token(),0,'xml_is_token() 13');

is(Net::DRI::Util::verify_ushort(),0,'verify_ushort() 1');
is(Net::DRI::Util::verify_ushort("A"),0,'verify_ushort() 2');
is(Net::DRI::Util::verify_ushort(123),1,'verify_ushort() 3');
is(Net::DRI::Util::verify_ushort(1000000),0,'verify_ushort() 4');
is(Net::DRI::Util::verify_ushort(-1000),0,'verify_ushort() 5');

is(Net::DRI::Util::verify_ubyte(),0,'verify_ubyte() 1');
is(Net::DRI::Util::verify_ubyte("A"),0,'verify_ubyte() 2');
is(Net::DRI::Util::verify_ubyte(123),1,'verify_ubyte() 3');
is(Net::DRI::Util::verify_ubyte(1000),0,'verify_ubyte() 4');
is(Net::DRI::Util::verify_ubyte(-1000),0,'verify_ubyte() 5');

is(Net::DRI::Util::verify_hex(),0,'verify_hex() 1');
is(Net::DRI::Util::verify_hex("G"),0,'verify_hex() 2');
is(Net::DRI::Util::verify_hex("AF65"),1,'verify_hex() 3');
is(Net::DRI::Util::verify_hex("af65"),1,'verify_hex() 4');

is(Net::DRI::Util::verify_int(),0,'verify_int()  1');
is(Net::DRI::Util::verify_int("A"),0,'verify_int()  2');
is(Net::DRI::Util::verify_int(1000),1,'verify_int()  3');
is(Net::DRI::Util::verify_int(-1000),1,'verify_int()  4');
is(Net::DRI::Util::verify_int(-2147483649),0,'verify_int()  5');
is(Net::DRI::Util::verify_int(2147483648),0,'verify_int()  6');
is(Net::DRI::Util::verify_int(-1000,-999),0,'verify_int()  7');
is(Net::DRI::Util::verify_int(-1000,-1001),1,'verify_int()  8');
is(Net::DRI::Util::verify_int(1000,undef,1001),1,'verify_int()  9');
is(Net::DRI::Util::verify_int(1000,undef,999),0,'verify_int() 10');
is(Net::DRI::Util::verify_int(1000,999,1001),1,'verify_int() 11');
is(Net::DRI::Util::verify_int(1000,1002,1004),0,'verify_int() 12');
is(Net::DRI::Util::verify_int(1000,996,998),0,'verify_int() 13');

is(Net::DRI::Util::verify_base64('Z'),0,'verify_base64()  1');
is(Net::DRI::Util::verify_base64('AAAA'),1,'verify_base64()  2');
is(Net::DRI::Util::verify_base64('A AAA'),1,'verify_base64()  3');
is(Net::DRI::Util::verify_base64('A A AA'),1,'verify_base64()  4');
is(Net::DRI::Util::verify_base64('A A A A'),1,'verify_base64()  5');
is(Net::DRI::Util::verify_base64('A A A A '),0,'verify_base64()  6');
is(Net::DRI::Util::verify_base64('BBE='),1,'verify_base64()  7');
is(Net::DRI::Util::verify_base64('BBB='),0,'verify_base64()  8');
is(Net::DRI::Util::verify_base64('B BE='),1,'verify_base64()  9');
is(Net::DRI::Util::verify_base64('B B E='),1,'verify_base64() 10');
is(Net::DRI::Util::verify_base64('B B E ='),1,'verify_base64() 11');
is(Net::DRI::Util::verify_base64('CA=='),1,'verify_base64() 12');
is(Net::DRI::Util::verify_base64('CC=='),0,'verify_base64() 13');
is(Net::DRI::Util::verify_base64('C A=='),1,'verify_base64() 14');
is(Net::DRI::Util::verify_base64('C A =='),1,'verify_base64() 15');
is(Net::DRI::Util::verify_base64('C A = ='),1,'verify_base64() 16');
is(Net::DRI::Util::verify_base64('AAAABBBB'),1,'verify_base64() 17');
is(Net::DRI::Util::verify_base64('A AAABBBB'),1,'verify_base64() 18');
is(Net::DRI::Util::verify_base64('A A AABBBB'),1,'verify_base64() 19');
is(Net::DRI::Util::verify_base64('A A A ABBBB'),1,'verify_base64() 20');
is(Net::DRI::Util::verify_base64('A A A A BBBB'),1,'verify_base64() 21');
is(Net::DRI::Util::verify_base64('FPucA9l+'),1,'verify_base64() 22'); ## From RFC3548
is(Net::DRI::Util::verify_base64('FPucA9k='),1,'verify_base64() 23');
is(Net::DRI::Util::verify_base64('FPucAw=='),1,'verify_base64() 24');
is(Net::DRI::Util::verify_base64('AAAABBBB',4),1,'verify_base64() 25');
is(Net::DRI::Util::verify_base64('AAAABBBB',10),0,'verify_base64() 26');
is(Net::DRI::Util::verify_base64('AAAABBBB',undef,4),0,'verify_base64() 27');
is(Net::DRI::Util::verify_base64('AAAABBBB',undef,10),1,'verify_base64() 28');
is(Net::DRI::Util::verify_base64('AAAABBBB',10,12),0,'verify_base64() 29');
is(Net::DRI::Util::verify_base64('AAAABBBB',4,13),1,'verify_base64() 30');
is(Net::DRI::Util::verify_base64('AAAABBBB',15,20),0,'verify_base64() 31');

is(Net::DRI::Util::xml_is_boolean('0'),1,'xml_is_boolean() 1');
is(Net::DRI::Util::xml_is_boolean('1'),1,'xml_is_boolean() 2');
is(Net::DRI::Util::xml_is_boolean('true'),1,'xml_is_boolean() 3');
is(Net::DRI::Util::xml_is_boolean('false'),1,'xml_is_boolean() 4');
is(Net::DRI::Util::xml_is_boolean('t'),0,'xml_is_boolean() 5');
is(Net::DRI::Util::xml_is_boolean('f'),0,'xml_is_boolean() 6');

is(Net::DRI::Util::xml_is_language('fr'),1,'xml_is_language() 1');
is(Net::DRI::Util::xml_is_language('0fr'),0,'xml_is_language() 2');
is(Net::DRI::Util::xml_is_language('fr-FR'),1,'xml_is_language() 3');


TODO: {
        local $TODO="tests on hash_merge()";
        ok(0);
}

exit 0;
