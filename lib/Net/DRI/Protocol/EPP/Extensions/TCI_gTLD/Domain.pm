package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Domain;
#===============================================================================
#
#         FILE:  Domain.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  06/24/2013 04:24:53 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          create => [ \&create, undef ],
          info   => [ undef, \&info_parse ],
          update => [ \&update ],
         );

 return { 'domain' => \%tmp };
}

sub create
{
 my ($epp,$domain,$rd)=@_;

 if (exists $rd->{description})
 {
#	 Net::DRI::Exception::usererr_insufficient_parameters('description attribute is mandatory') 
#		 unless (exists($rd->{description}));

	 my @n;
	 push @n,['domain:description',$rd->{description}];

	 $epp->message()->command_extension('domain', ['create', @n, {'xmlns:domain'=>$epp->message()->ns('tci-domain-ext')}]);
 }
}

sub update
{
 my ($epp,$domain,$toc,$rd)=@_;
 my @chg;
 my $chg = $toc->set('description');
 if ($chg)
 {
	for my $str (@$chg)
	{
		push @chg, ['domain:description', $str];
	}

	 $epp->message()->command_extension('domain', ['update', ['chg', @chg], {'xmlns:domain'=>$epp->message()->ns('tci-domain-ext')}]);
 }
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('domain','infData');
 return unless $infdata;

 my %ens;
 my $c=$infdata->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'description')
  {
   $ens{description}=$c->getFirstChild()->getData();
  }

 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ens}=\%ens;
}


1;

