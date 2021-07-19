use Net::DRI;
use Net::DRI::Data::Raw;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

package Net::DRI::Test;

my $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">';
my $E2='</epp>';
my $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

sub new_epp
{
 my ($class, $rexts, $registry) = @_;
 my $dri=Net::DRI::TrapExceptions->new({cache_ttl => -1});
 $dri->{trid_factory}=sub { return 'ABC-12345'; };
 $dri->add_current_registry($registry // 'Example');

 my ($output, $input);

 my $send = sub { my ($transport,$count,$msg)=@_; $input=$msg->as_string(); return 1;};
 my $recv = sub { return Net::DRI::Data::Raw->new_from_string($output? $output : $E1.'<response>'.r().$TRID.'</response>'.$E2); };

 $dri->add_current_profile('p1','epp',{f_send=>$send,f_recv=>$recv},{extensions=>$rexts});

 my %self = ( dri    => $dri,
              input  => \$input,
              output => \$output,
            );
 bless \%self, $class;
 return \%self;
}

sub dri { return $_[0]->{dri}; }

sub set_response
{
 my ($self, $response) = @_;
 ${$self->{output}} = $E1.'<response>'.r().($response // '').$TRID.'</response>'.$E2;
}

sub get_command
{
 my ($self) = @_;
 my $cmd = ${$self->{input}};
 $cmd =~s/^\Q$E1\E//;
 $cmd =~s/\Q$E2\E$//;
 return $cmd;
}

sub format_xml
{
 my ($self, $xml) = @_;
 $xml =~ s/\n\s*//g;
 return $xml;
}

1;
