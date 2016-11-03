package Net::DRI::DRD::RF;
#===============================================================================
#
#         FILE:  RF.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  13/10/2016 03:30:58 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use base qw/Net::DRI::DRD::TCI/;

#sub tlds     { return ('xn--p1ai', 'su', 'ru'); }
sub tlds     { return ('xn--p1ai'); }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP'},'Net::DRI::Protocol::EPP::Extensions::RF',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

1;

