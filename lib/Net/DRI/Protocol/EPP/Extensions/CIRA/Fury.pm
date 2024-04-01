## EPP Mapping for CIRA Fury (Fury Platform Technical Test v1.3.pdf)
##
## Copyright (c) 2019 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CIRA::Fury;

use strict;
use warnings;
use feature 'state';

use Net::DRI::Util;
use Net::DRI::Exception;

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 state $cmds = {
    'contact' => {
        'create' => [ \&contact_create_build, undef ],
        'info'   => [ undef, \&contact_info_parse ],
        'update' => [ \&contact_update_build, undef ],
    },
    'domain' => {
        'create' => [ \&domain_create_build, undef ],
        'info'   => [ undef, \&domain_info_parse ],
        'update' => [ \&domain_update_build, undef ],
    },
    'agreement' => {
        'info' => [ \&agreement_info_build, \&agreement_info_parse ],
    },
 };

 return $cmds;
}

sub capabilities_add { return (['domain_update','privacy',['set']], ['contact_update', 'lang', ['add', 'del']]); }

sub setup
{
 my ($class,$po,$version)=@_;

 state $ns = {
    'fury' => [ 'urn:ietf:params:xml:ns:fury-2.0', 'fury-2.0.xsd' ],
    'fury-rgp' => [ 'urn:ietf:params:xml:ns:fury-rgp-1.0', 'fury-rgp-1.0.xsd' ],
 };
 $po->ns($ns);
 return;
}

sub implements { return 'Fury Platform Technical Test v1.3.pdf'; }

####################################################################################################
sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:fury="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('fury')));
}


sub build_properties
{
 my ($rprops) = @_;

 my @ps;
 foreach my $key (sort(keys(%$rprops)))
 {
  my @p;
  push @p, ['fury:key', $key];
  my $value = $rprops->{$key};
  if (not defined $value)
  {
   push @p, ['fury:remAll', 'true'];
  } else
  {
   $value = [ $value ] unless ref $value eq 'ARRAY';
   my %attributes;
   my $content = '';
   foreach my $data (ref $value eq 'ARRAY' ? @$value : [$value])
   {
    if (ref $data eq 'HASH')
    {
     %attributes = (%attributes, %$data);
    } else
    {
     $content = $data;
    }
   }
   push @p, ['fury:value', \%attributes, $content];
  }
  push @ps, ['fury:property', @p];
 }

 return @ps;
}

sub parse_value
{
 my ($po, $topnode) = @_;

 my $value = $topnode->textContent();
 if ($topnode->hasAttribute('remAll') && Net::DRI::Util::xml_parse_boolean($topnode->getAttribue('remAll')))
 {
  $value = undef;
 } elsif ($topnode->hasAttribute('default'))
 {
  $value = [ $value, {'default' => $topnode->getAttribute('default')} ];
 }

 return $value;
}

sub parse_property_value
{
 my ($po, $topnode) = @_;
 my %value;

 foreach my $el (Net::DRI::Util::xml_list_children($topnode))
 {
  my ($name, $node) = @$el;
  if ($name eq 'value')  # only mandatory element
  {
   $value{value} = parse_value($po, $node);
  } elsif ($name eq 'localizedValue')
  {
   $value{localized_value} = $node->textContent();
  } elsif ($name eq 'localizedDetail')
  {
   $value{localized_detail} = $node->textContent();
  } elsif ($name eq 'propertyValueAttributes')
  {
   $value{attributes} = {};
   foreach my $ell (Net::DRI::Util::xml_list_children($node, 'propertyValueAttribute'))
   {
    my ($key, $value) = parse_attribute($po, $ell);
    $value{attributes}->{$key} = $value;
   }
   delete $value{attributes} unless %{$value{attributes}};
  }
 }

 return \%value;
}

sub parse_attribute
{
 my ($po, $topnode) = @_;

 my ($key, $value);
 foreach my $el (Net::DRI::Util::xml_list_children($topnode))
 {
  my ($name, $node) = @$el;
  if ($name eq 'key')
  {
   $key = $node->textContent();
  } elsif ($name eq 'value')
  {
   $value = parse_value($po, $node);
  }
 }

 return ($key, $value);
}

sub parse_property
{
 my ($po, $topnode) = @_;

 my ($key, %value);
 foreach my $el (Net::DRI::Util::xml_list_children($topnode))
 {
  my ($name, $node) = @$el;

  if ($name eq 'key')
  {
   $key = $node->textContent();
  } elsif ($name eq 'localizedKey')
  {
   $value{localized_key} = $node->textContent();
  } elsif ($name eq 'propertyValues')
  {
   $value{'values'} = [];
   foreach my $ell (Net::DRI::Util::xml_list_children($node, 'propertyValue'))
   {
    push @{$value{'values'}}, parse_property_value($po, $ell)
   }
   delete $value{'values'} unless @{$value{'values'}};
  } elsif ($name eq 'propertyAttributes')
  {
   $value{attributes} = {};
   foreach my $ell (Net::DRI::Util::xml_list_children($node, 'propertyAttribute'))
   {
    my ($key, $value) = parse_attribute($po, $ell);
    $value{attributes}->{$key} = $value;
   }
   delete $value{attributes} unless %{$value{attributes}};
  }
 }

 return $key, \%value;
}

sub contact_create_build
{
 my ($epp, $contact)=@_;
 my $mes=$epp->message();

 ## $contact->validate() has been called
 my %props;
 $props{'LANGUAGE'} = uc $contact->lang();
 $props{'CPR'} = $contact->legal_form() if defined $contact->legal_form();

 my $ra = $contact->agreement();
 if (defined $ra and $ra->{signed})
 {
  $props{'AGREEMENT_VERSION'} = $ra->{version} eq 'default' ? {'default' => 'true'} : $ra->{version};
 }

 my $eid=build_command_extension($mes,$epp,'fury:create');
 $mes->command_extension($eid,['fury:properties',build_properties(\%props)]);

 return;
}

sub contact_info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('fury','info');
 return unless defined $infdata;

 my $contact = $rinfo->{contact}->{$oname}->{self};

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name, $node) = @$el;
  if ($name eq 'properties')
  {
   my %agreement;
   foreach my $ell (Net::DRI::Util::xml_list_children($node, 'property'))
   {
    my ($key, $value) = parse_attribute($po, $ell);
    if (uc $key eq 'LANGUAGE')
    {
     $contact->lang(lc $value);
    } elsif (uc $key eq 'CPR')
    {
     $contact->legal_form($value);
    } elsif (uc $key eq 'AGREEMENT_TIMESTAMP')
    {
     $agreement{timestamp} = $po->parse_iso8601($value);
    } elsif (uc $key eq 'AGREEMENT_VERSION')
    {
     $agreement{version} = $value;
     $agreement{signed} = 1;
    }
   }
   $contact->agreement(\%agreement) if %agreement;
  }
 }

 return;
}

sub contact_update_build
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 my $add = $todo->add('lang');
 my $del = $todo->del('lang');
 return unless defined $add && defined $del;

 my @d;
 push @d, ['fury:add', ['fury:properties', build_properties({'LANGUAGE' => uc $add})]];
 push @d, ['fury:rem', ['fury:properties', build_properties({'LANGUAGE' => uc $del})]];
 # What about CPR and AGREEMENT?
 my $eid=build_command_extension($mes,$epp,'fury:update');
 $mes->command_extension($eid,[@d]);

 return;
}


sub domain_create_build
{
 my ($epp, $domain, $rd)=@_;
 my $mes=$epp->message();

 my $privacy;

 # Backwards compatible way first, use data from registrant contact
 my $registrant = $rd->{contact}->get('registrant');
 if ($registrant && Net::DRI::Util::isa_contact($registrant))
 {
  my $wd = $registrant->whois_display();
  if (defined $wd)
  {
   if ($wd eq 'FULL')
   {
    $privacy = 0;
   } elsif ($wd eq 'PRIVATE')
   {
    $privacy = 1;
   }
  }
 }

 $privacy = $rd->{'privacy'} if Net::DRI::Util::has_key($rd, 'privacy');

 return unless $privacy;

 my %props = ('PRIVACY' => $privacy ? 'PRIVATE' : 'PUBLIC');

 my $eid=build_command_extension($mes,$epp,'fury:create');
 $mes->command_extension($eid,['fury:properties',build_properties(\%props)]);

 return;
}

sub domain_info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $infdata1=$mes->get_extension('fury', 'info');
 if ($infdata1)
 {
  foreach my $el (Net::DRI::Util::xml_list_children($infdata1))
  {
   my ($name, $node) = @$el;
   if ($name eq 'properties')
   {
    my %agreement;
    foreach my $ell (Net::DRI::Util::xml_list_children($node, 'property'))
    {
     my ($key, $value) = parse_attribute($po, $ell);
     if (uc $key eq 'PRIVACY')
     {
      $rinfo->{domain}->{$oname}->{privacy} = uc $value eq 'PRIVATE' ? 1 : 0;
      my $registrant = $rinfo->{domain}->{$oname}->{contact}->get('registrant');
      $registrant->whois_display(uc $value eq 'PRIVATE' ? 'PRIVATE' : 'FULL');
     }
    }
   } elsif ($name eq 'bundle')
   {
    my @v = Net::DRI::Util::xml_list_children($node, 'name');
    push @v, Net::DRI::Util::xml_list_children((Net::DRI::Util::xml_list_children($node, 'domains'))[0], 'name');
    $rinfo->{domain}->{$oname}->{variants} = [ map { $_->textContent() } @v ];
   }
  }
 }

 my $infdata2 = $mes->get_extension('fury-rgp', 'rgpInfo');
 if ($infdata2)
 {
  my $date = (Net::DRI::Util::xml_list_children($infdata2, 'rgpStatusEnd'))[0]->textContent();
  $date =~ s/^\s+//;
  $date =~ s/\s+$//;
  $rinfo->{domain}->{$oname}->{rgp_status_end} = $po->parse_iso8601($date);
 }

 return;
}

sub domain_update_build
{
 my ($epp, $domain, $todo)=@_;
 my $mes=$epp->message();

 if ($todo->{'rgp'}) {
  my @dd;
  push @dd, ['domain:name',$domain];
  push @dd, ['domain:chg',''];
  $mes->command_body(@dd);
 }

 # since there is only the privacy attribute, and it is binary,
 # we can emulate the silly add+rem from registry by a simple and logical set
 my $toset = $todo->set('privacy');

 return unless defined $toset;

 my %on = ('PRIVACY' => 'PRIVATE');
 my %off = ('PRIVACY' => 'PUBLIC');

 my @d;
 push @d, ['fury:add', ['fury:properties', build_properties($toset ? \%on : \%off)]];
 push @d, ['fury:rem', ['fury:properties', build_properties($toset ? \%off : \%on)]];

 my $eid=build_command_extension($mes,$epp,'fury:update');
 $mes->command_extension($eid,[@d]);

 return;
}

sub agreement_info_build
{
 my ($epp, $language) = @_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'fury:command');
 $mes->command_extension($eid,[['fury:info', ['fury:language', $language // 'en'],['fury:properties', build_properties({'AGREEMENT_VERSION' => {'default' => 'true'}})]]]);

 return;
}

sub agreement_info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $infdata = $mes->get_extension('fury', 'response');
 return unless defined $infdata;

 ($infdata) = Net::DRI::Util::xml_list_children($infdata, 'infData');
 return unless defined $infdata;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name, $node) = @$el;
  if ($name eq 'language')
  {
   $rinfo->{agreement}->{cira}->{language} = lc $node->textContent();
  } elsif ($name eq 'properties')
  {
   foreach my $ell (Net::DRI::Util::xml_list_children($node, 'property'))
   {
    my ($key, $value) = parse_property($po, $ell);

    if ($key eq 'AGREEMENT_VERSION')
    {
     $rinfo->{agreement}->{cira}->{version} = $value->{'values'}[0]{'localized_value'};
     $rinfo->{agreement}->{cira}->{content} = $value->{'values'}[0]{'localized_detail'};
    }
   }
  }
 }

 return;
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CIRA::Fury - EPP Mapping for CIRA Fury (Fury Platform Technical Test v1.3) for Net::DRI

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

Copyright (c) 2019 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut