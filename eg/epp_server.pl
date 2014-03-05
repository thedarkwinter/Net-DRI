#!/usr/bin/perl -w
#
# A minimalistic server to send back EPP frame with correct length

use IO::Socket;

our $PORT=5555;

die "File to send must be provided on command line !!!" unless @ARGV;

my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                    LocalPort => $PORT,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1);

die "can't setup server" unless $server;
print "[Server $0 accepting clients on $PORT]\n";

my $client = $server->accept();
$client->autoflush(1);
print "Got a new client\n";

my ($c,$length,$content);
while(my $file=shift(@ARGV))
{
 open my $fh, "< ${file}" or die $!;
 local $/; # enable localized slurp mode
 $content=<$fh>;
 close $fh;
 print "Sending content of file $file [".length($content)." bytes]\n";
 $client->print(pack('N',length($content)+4).$content);

 next unless @ARGV;

 print "Waiting for client data\n";
 $c='';
 $client->read($c,4);
 $length=unpack('N',$c)-4;
 print "Got length=${length} bytes\n";
 $c='';
 $client->read($c,$length);
 print "Got from client: $c\n";
}

print "Closing connection to client\n";
close $client;

exit 0;
