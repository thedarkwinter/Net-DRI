#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 9;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }


my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv},{extensions=>['VeriSign::Suggestion']});

$R2='';
my $rc=$dri->domain_suggest('mimisflowershop.com',{language=>'ENG',contentfilter=>'false',customfilter=>'false',forsale=>'off',maxlength=>30,maxresults=>20,usehyphens=>1,usenumbers=>1,view=>'grid',action=>{basic=>'medium',related=>'high',similar=>'off',topical=>'high'},tld=>['COM','Net']});
is_string($R1,$E1.'<command><info><suggestion:info xmlns:suggestion="http://www.verisign-grs.com/epp/suggestion-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/suggestion-1.1 suggestion-1.1.xsd"><suggestion:key>mimisflowershop.com</suggestion:key><suggestion:language>ENG</suggestion:language><suggestion:filter contentfilter="false" customfilter="false" forsale="off" maxlength="30" maxresults="20" usehyphens="1" usenumbers="1" view="grid"><suggestion:action name="basic" weight="medium"/><suggestion:action name="related" weight="high"/><suggestion:action name="similar" weight="off"/><suggestion:action name="topical" weight="high"/><suggestion:tld>COM</suggestion:tld><suggestion:tld>Net</suggestion:tld></suggestion:filter></suggestion:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_suggest build');



$R2=$E1.'<response>'.r().'<resData><suggestion:infData xmlns:suggestion="http://www.verisign-grs.com/epp/suggestion-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/suggestion-1.1 suggestion-1.1.xsd"><suggestion:key>harrypotterquidditchgame.com</suggestion:key><suggestion:language>ENG</suggestion:language><suggestion:token name="harrypotter"><suggestion:related>wizard</suggestion:related></suggestion:token><suggestion:token name="quidditch"/><suggestion:token name="game"><suggestion:related>videogame</suggestion:related><suggestion:related>contest</suggestion:related></suggestion:token><suggestion:answer><suggestion:table><suggestion:row name="HarrypotterQuidditchGame.com" score="1000" status="registered"/><suggestion:row name="HarryPotterVideoGame.com" score="952" status="available"/><suggestion:row name="TheHarryPotterMovie.com" score="945" status="available"/><suggestion:row name="HarryPotterTehMovie.com" score="923" status="available"/><suggestion:row name="MovieAboutHarryPotter.com" score="919" status="forsale"/><suggestion:row name="HarryPotterChatter.com" score="899" status="available"/></suggestion:table></suggestion:answer></suggestion:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_suggest('harrypotterquidditchgame.com');
my $rs=$rc->get_data('suggestions');
is($rs->{language},'ENG','domain_suggest language');
is_deeply($rs->{tokens},{ 'harrypotter' => ['wizard'], 'quidditch' => [], 'game' => ['videogame','contest']},'domain_suggest tokens');
is($rs->{result_type},'table','domain_suggest result_type');
is_deeply($rs->{answer},
{
'HarrypotterQuidditchGame.com'=>{score=>1000,status=>'registered'},
'HarryPotterVideoGame.com'=>{score=>952,status=>'available'},
'TheHarryPotterMovie.com'=>{score=>945,status=>'available'},
'HarryPotterTehMovie.com'=>{score=>923,status=>'available'},
'MovieAboutHarryPotter.com'=>{score=>919,status=>'forsale'},
'HarryPotterChatter.com'=>{score=>899,status=>'available'}
},'domain_suggest answer');


$R2=$E1.'<response>'.r().'<resData><suggestion:infData xmlns:suggestion="http://www.verisign-grs.com/epp/suggestion-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/suggestion-1.1 suggestion-1.1.xsd"><suggestion:key>harrypotterquidditchgame.com</suggestion:key><suggestion:language>ENG</suggestion:language><suggestion:token name="harrypotter"><suggestion:related>wizard</suggestion:related></suggestion:token><suggestion:token name="quidditch"/><suggestion:token name="game"><suggestion:related>videogame</suggestion:related><suggestion:related>contest</suggestion:related></suggestion:token><suggestion:answer><suggestion:grid><suggestion:record name="HarrypotterQuidditchGame"><suggestion:cell tld="com" score="1000" status="registered"/><suggestion:cell tld="net" score="543" status="available"/></suggestion:record><suggestion:record name="HarryPotterVideoGame"><suggestion:cell tld="com" score="952" status="available"/><suggestion:cell tld="net" score="521" status="available"/></suggestion:record><suggestion:record name="TheHarryPotterMovie"><suggestion:cell tld="com" score="945" status="forsale"/><suggestion:cell tld="net" score="432" status="available"/></suggestion:record><suggestion:record name="HarryPotterTehMovie"><suggestion:cell tld="com" score="923" status="available"/><suggestion:cell tld="net" score="412" status="registered"/></suggestion:record><suggestion:record name="MovieAboutHarryPotter"><suggestion:cell tld="com" score="919" status="available"/><suggestion:cell tld="net" score="367" status="available"/></suggestion:record><suggestion:record name="HarryPotterChatter"><suggestion:cell tld="com" score="899" status="available"/><suggestion:cell tld="net" score="734" status="unknown"/></suggestion:record></suggestion:grid></suggestion:answer></suggestion:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_suggest('harrypotterquidditchgame.com');
$rs=$rc->get_data('suggestions');
is($rs->{language},'ENG','domain_suggest language');
is_deeply($rs->{tokens},{ 'harrypotter' => ['wizard'], 'quidditch' => [], 'game' => ['videogame','contest']},'domain_suggest tokens');
is($rs->{result_type},'grid','domain_suggest result_type');
is_deeply($rs->{answer},
{
'HarrypotterQuidditchGame'=>{'com'=>{score=>1000,status=>'registered'},'net'=>{score=>543,status=>'available'}},
'HarryPotterVideoGame'=>{'com'=>{score=>952,status=>'available'},'net'=>{score=>521,status=>'available'}},
'TheHarryPotterMovie'=>{'com'=>{score=>945,status=>'forsale'},'net'=>{score=>432,status=>'available'}},
'HarryPotterTehMovie'=>{'com'=>{score=>923,status=>'available'},'net'=>{score=>412,status=>'registered'}},
'MovieAboutHarryPotter'=>{'com'=>{score=>919,status=>'available'},'net'=>{score=>367,status=>'available'}},
'HarryPotterChatter'=>{'com'=>{score=>899,status=>'available'},'net'=>{score=>734,status=>'unknown'}},
},'domain_suggest answer');


exit 0;

