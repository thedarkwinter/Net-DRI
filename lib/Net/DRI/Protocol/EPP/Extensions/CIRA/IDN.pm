## Domain Registry Interface, CIRA IDN handling (draft-wilcox-cira-idn-eppext-00)
##
## Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::CIRA::IDN;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 state $ops = { 'domain' => { check       => [ \&domain_check_build, undef ],
                              check_multi => [ \&domain_check_build, undef ],
                              info        => [ undef, \&domain_info_parse ],
                              create      => [ \&domain_create_build, undef ],
                            },
                'bundle' => { info => [ \&bundle_info_build, \&bundle_info_parse ],
                            },
              };

 return $ops;
}

sub setup
{
 my ($class,$po,$version)=@_;
 state $ns={ 'cira-idn'        => [ 'urn:ietf:params:xml:ns:cira-idn-1.0','cira-idn-1.0.xsd' ],
             'cira-idn-bundle' => [ 'urn:ietf:params:xml:ns:cira-idn-bundle-1.0','cira-idn-bundle-1.0.xsd' ],
           };
 $po->ns($ns);
 return;
}

sub implements { return 'https://tools.ietf.org/html/draft-wilcox-cira-idn-eppext-00'; }

####################################################################################################

sub _validate_repertoire
{
 my ($rp)=@_;
 ## This set is called a repertoire throughout the document, as a synonym with idn_table.
 return 0 unless Net::DRI::Util::has_key($rp,'idn_table');
 Net::DRI::Exception::usererr_invalid_parameters('idn_table must be of type XML schema token with 2 characters') unless Net::DRI::Util::xml_is_token($rp->{idn_table},2,2);
 return 1;
}

sub domain_check_build
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();
 return unless _validate_repertoire($rp);
 my $eid=$mes->command_extension_register('cira-idn','ciraIdnCheck');
 $mes->command_extension($eid,['cira-idn:repertoire',$rp->{idn_table}]);
 return;
}

sub domain_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('cira-idn','ciraIdnInfo');
 return unless defined $data;

 my @v=map { $_->textContent() } Net::DRI::Util::xml_traverse($data,$mes->ns('cira-idn'),qw/domainVariants name/);
 $rinfo->{domain}->{$oname}->{variants}=\@v;
 return;
}

sub bundle_info_build
{
 my ($epp,$bundle,$rp)=@_;
 my $mes=$epp->message();

 my @d;
 Net::DRI::Exception::usererr_invalid_parameters('bundle name must be of type eppcom:labelType') unless Net::DRI::Util::xml_is_token($bundle,1,255);
 push @d,['cira-idn-bundle:name',$bundle];
 if (_validate_repertoire($rp))
 {
  push @d,['cira-idn-bundle:repertoire',$rp->{idn_table}];
 }

 $mes->command(['info','cira-idn-bundle:info',sprintf('xmlns:cira-idn-bundle="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('cira-idn-bundle'))]);
 $mes->command_body(\@d);
 return;
}

sub bundle_info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $data=$mes->get_extension('cira-idn-bundle','infData');
 return unless defined $data;

 my %r;
 my $cs=$po->create_local_object('contactset');
 foreach my $el (Net::DRI::Util::xml_list_children($data))
 {
  my ($name,$c)=@$el;
  if ($name eq 'canonicalDomainName' || $name eq 'roid')
  {
   $r{Net::DRI::Util::remcam($name)}=$c->textContent();
  } elsif ($name eq 'registrant')
  {
   $cs->set($po->create_local_object('contact')->srid($c->textContent()),'registrant');
   $r{contact}=$cs;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $r{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $r{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'bundleDomains')
  {
   $r{variants}=[ map { $_->textContent() } Net::DRI::Util::xml_traverse($c,$mes->ns('cira-idn'),qw/name/) ];
  }
 }

 foreach my $domain (@{$r{variants}}, $r{canonical_domain_name}) ## $oname is among $r{variants}
 {
  $rinfo->{bundle}->{$domain}=\%r;
 }

 return;
}

sub domain_create_build
{
 my ($epp,$domain,$rp)=@_;
 my $mes=$epp->message();

 return unless _validate_repertoire($rp);

 my @d;
 push @d,['cira-idn:repertoire',$rp->{idn_table}];
 if (Net::DRI::Util::has_key($rp,'ulabel')) ## TODO: compute u-label directly from $domain
 {
  Net::DRI::Exception::usererr_invalid_parameters('ulabel must be of type eppcom:labelType') unless Net::DRI::Util::xml_is_token($rp->{ulabel},1,255);
  push @d,['cira-idn:u-label',$rp->{ulabel}];
 }

 my $eid=$mes->command_extension_register('cira-idn','ciraIdnCreate');
 $mes->command_extension($eid,\@d);
 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::IDN - CIRA IDN EPP (draft-wilcox-cira-idn-eppext-00) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2015 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

