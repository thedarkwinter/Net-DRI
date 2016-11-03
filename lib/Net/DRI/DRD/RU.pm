package Net::DRI::DRD::RU;
#===============================================================================
#
#         FILE:  RU.pm
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

sub tlds     { return ('ru'); }

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1, 
 						check_name_dots => [1], 
						my_tld => 1
            });                                              
}

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{protocol_connection=>'Net::DRI::Protocol::EPP::Extensions::HTTP'},'Net::DRI::Protocol::EPP::Extensions::RU',{}) if $type eq 'epp'; ## EPP is over HTTPS here
 return;
}

1;

