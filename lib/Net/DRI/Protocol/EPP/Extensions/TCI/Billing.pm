package Net::DRI::Protocol::EPP::Extensions::TCI::Billing;
use strict;
use warnings;
use utf8;
use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          info   => [ \&info, \&info_parse ],
         );

 return { 'billing' => \%tmp };
}

sub info
{
 my ($epp,$billing,$rd)=@_;

 my $mes=$epp->message();

 $mes->command(['info','billing:info',$mes->nsattrs('billing'),]);
 
 if ($rd && ref($rd) eq 'HASH')
 {
 	my @d;
	my %allowed_types = map {$_ => 1} qw(balance forecast billing);
	my $type = $rd->{type};
	unless (exists $allowed_types{$type})
	{
		Net::DRI::Exception::usererr_invalid_parameters("Wrong billing request type '$type'");
	}
	push @d, ['billing:type', $type];

	if (exists $rd->{params} && ref ($rd->{params}) eq 'HASH')
	{
		my @params;
		for my $key (qw(date period currency))
		{
			if (exists $rd->{params}->{$key})
			{
				push @params, ["billing:$key", $rd->{params}->{$key}];
			}
		}
		if (scalar @params)
		{
			push @d, ['billing:param', @params];
		}
	}

	$mes->command_body(\@d);
 }
 else
 {
 	$mes->command_body(['billing:type', 'balance'])
 }
}

sub info_parse
{
	my ($po,$otype,$oaction,$oname,$rinfo)=@_;
	my $mes=$po->message();
	return unless $mes->is_success();

	my $infdata=$mes->get_response("billing", "infData");
	return unless defined $infdata;

	foreach my $el (Net::DRI::Util::xml_list_children($infdata))
	{
		my ($name,$c)=@$el;

		if($name eq 'type')
		{
			$rinfo->{billing}->{info}->{type} = $c->textContent();
		}
		elsif (($name eq 'param') || ($name eq 'balance') || ($name eq 'forecast'))
		{
			foreach my $param (Net::DRI::Util::xml_list_children($el->[1]))
			{
				my ($name1,$c1)=@$param;
				if ($name1 eq 'calcDate')
				{
					$rinfo->{billing}->{info}->{$name}->{$name1} = 
						DateTime::Format::ISO8601->new()->parse_datetime($c1->textContent());
				}
				else
				{
					#XXX workaround for empty tag sum
					$rinfo->{billing}->{info}->{$name}->{$name1} = $c1->textContent() || 0;
				}
			}
		}
		else
		{
			warn "Unsupported name '$name'";
		}
	}
}

1;

