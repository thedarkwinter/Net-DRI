package Net::DRI::Protocol::OpenSRS::XCP::Host;
#===============================================================================
#
#         FILE:  Host.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  04/27/2012 04:10:40 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
#               info  => [\&info,  \&info_parse ],
#               create => [ \&create, \&create_parse ], 
#               delete => [ \&delete, ],
#               update => [\&update, undef],
#
                registry_add   => [\&registry_add,   ],
                registry_check => [\&registry_check, \&registry_check_parse],
                );

 return { 'nameserver' => \%tmp };
}

####################################################################################################
########### Query commands

sub registry_check
{
       my ($xcp, $hostname, $registry) = @_;
       my $msg=$xcp->message();
       my %r = (action => 'registry_check_nameserver', object => 'nameserver');

 $msg->command(\%r);
 Net::DRI::Exception::usererr_insufficient_parameters('Missing or bad registry') unless ($registry && $registry =~ /^\./);
 my $attr = {fqdn => $hostname, tld => $registry};
 $msg->command_attributes($attr);
 return;
}

sub registry_check_parse
{
 my ($xcp,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$xcp->message();
 return if($mes->response_code() >= 400);

 $rinfo->{nameserver}->{$oname}->{action}='registry_check_nameserver';
 my $ra=$mes->response_attributes();

 $rinfo->{nameserver}->{$oname}->{exists} = $ra->{is_success} ? 1 : 0;
 return;
}

############ Transform commands

sub registry_add
{
       my ($xcp, $hostname, $rd) = @_;
       my $msg=$xcp->message();
       my %r = (action => 'registry_add_ns', object => 'nameserver');

 $msg->command(\%r);
 Net::DRI::Exception::usererr_insufficient_parameters('Missing or bad registry') unless ($rd->{tld} && $rd->{tld} =~ /^\./);
 my $attr = {fqdn => $hostname, tld => $rd->{tld}, all => $rd->{all} || 0};
 $msg->command_attributes($attr);
 return;
}

1;
