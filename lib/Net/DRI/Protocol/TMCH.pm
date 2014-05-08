## Domain Registry Interface,  TMCH Protocol (Based on API 1.1.4)
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
## Copyright (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::Protocol::TMCH;

use utf8;
use strict;
use warnings;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::TMCH::Message;

=pod

=head1 NAME

Net::DRI::Protocol::TMCH - TMCH Protocol (Based on API 1.1.4) for Net::DRI

=head1 DESCRIPTION

TMCH Protocol for L<NET::DRI>

=head1 SYNOPSIS

The module inplements the TMCH protocol using namespace: urn:ietf:params:xml:ns:tmch-1.1

Mark data is build/parsed using L<Net::DRI::Protocol::EPP::Extensions::ICANN::MarkSignedMark> urn:ietf:params:xml:ns:mark-1.0, urn:ietf:params:xml:ns:signedMark-1.0

It is important to note the data differences between the TMCH Submission and the Mark data, as both items have their own date. $dri->get_info('crDate') will give you TMCH date, while $dri->get_info('mark / signedMark / encodedSignedMark') will get MARK data

Currently used by L<Net::DRI::DRD::Deloitte>

  $dri->add_registry('Deloitte');
  $dri->target('Deloitte')->add_current_profile('p1','tmch);

=head1 METHODS:

The TMCH methods are quite extensive. Here are some examples, but please see the test file (t/691_deloitte_tmch.t) for complete command coverage.

=head2 mark_check

  $rc=$dri->mark_check($mark_id);
  ...$dri->get_info('exist');

=head2 mark_info

  $rc=$dri->mark_info($mark_id);
  $dri->get_info('status');  # application status
  $dri->get_info('crDate'); # TMCH submitted date (not related to mark data)
  $dri->get_info('mark') # mark object
  $mark{'registration_date'}; # Mark date, not related to TMCH submission
  @labels = @{$dri->get_info('labels')}; # Note, while the mark namespace has aLabels, we are using the tmch namespace for labels here.
  @docs = @{$dri->get_info('documents')};
  @cases = @{$dri->get_info('cases')}; # cases have udrp/court as well as their own labels and documents
  
=head2 mark_info_smd

  $rc=$dri->mark_info_smd($mark_id);
  $dri->get_info('mark') # mark object
  $dri->get_info('signed_mark') # signedMark object
  $signedMark->{'issuer'}->{*} issuer details

=head2 mark_info_enc

  $rc=$dri->mark_info_smd($mark_id);
  $dri->get_info('mark') # mark object
  $dri->get_info('signed_mark') # signedMark object [decoded from the BASE64 string data]
  $dri->get_info('encoded_signed_mark') # encodedSignedMark BASE64 string

=head2 mark_info_file

  $rc=$dri->mark_info_smd($mark_id);
  $dri->get_info('mark') # mark object
  $dri->get_info('signed_mark') # signedMark object [decoded from the BASE64 string data]
  $dri->get_info('encoded_signed_mark') # encodedSignedMark BASE64 string - in this case with the file headers
  
=head2 mark_create

   # needs contacts
  $cs = $dri->local_object('contactset');
  $holder = $dri->local_object('contact');
  $cs->add($holder,'holder_owner'); # other types are holder_assignee, holder_licensee, contact_owner, contact_agent, contact_thirdparty

  # labels
  $l1 = { a_label => 'exampleone', smd_inclusion => 1, claims_notify => 1 };
  $l2 = { a_label => 'exampl-eone', smd_inclusion => 0, claims_notify => 1 };
  @labels = ($l1,$l2);

  #docs
  $d1 = { doc_type => 'tmOther', file_type => 'jpg', file_name => 'C:\\ddafs\\file.png', file_content => 'YnJvbAo='}; # file_content should be BASE64 encoded file content
  @docs = ($d1);

  # application durations:1,3,5 years
  $d = DateTime::Duration->new(years=>5);

  # mark objects
  $mark = { id => '0000061234-1', type => 'court', mark_name => 'Example One', court_name => 'P.R. supreme court', goods_services => 'Dirigendas et eiusmodi featuring infringo in airfare et cartam servicia.', cc => 'US', reference_number => '234235', protection_date => DateTime->new(year =>2009,month=>8,day=>16,hour=>9) };
  $mark->{contact} = $cs;
 
  # create
  $rc=$dri->mark_create($mark->{'id'}, { mark => $mark, duration=>$d, labels => \@labels, documents => \@docs});
  $rc->is_success();
  $dri->get_info('crDate');

=head2 mark_update

  # Mark & Contact data is all SET (not add/rem), so all data must be submitted
  $cs = $dri->local_object('contactset')->add($holder,'holder_owner');
  $mark = { id => '0000061234-1' ...
  $chg->set('mark',$mark);
  
  # labels can be Added and Removed, and since TMCHv2 can be changed as well (i.e. change flags)
  @addlabels = ({a_label=>'m-y-label',  smd_inclusion => 0, claims_notify => 0}, {a_label=>'m-y-l-a-b-e-l',  smd_inclusion => 0, claims_notify => 1} );
  $chg->add('labels',\@addlabels);
  @remlabels = ( {a_label=>'my-label', smd_inclusion => 0, claims_notify => 0} );
  @chglabels = ( {a_label=>'my-label', smd_inclusion => 1, claims_notify => 0} ); 
  
  # documents can only be added
  @adddocs = ( { doc_type => 'tmOther', file_type => 'pdf', file_name => 'test.pdf', file_contect => 'acdsdc' } );
  $chg->add('documents',\@adddocs);

  $rc = $dri->mark_update($mark->{'id'},$chg);
  $rc->is_success();
  
  # Adding a case (udrp)
  my $udrp={case_number=>'987654321', provider=>'National Arbitration Forum', language=>'Spanish'};
  my @labels=({a_label=>'a'},{a_label=>'b'});
  my @docs=({doc_type=>'courtCaseDocument', file_type=>'jpg', file_name=>'02-2013-TMCHdefect1.jpg', file_content=>'YnJvbAo='});
  my @cases=({id=>'case-00000123466989999999',udrp=>$udrp,documents=>\@docs,labels=>\@labels});
  $chg->add('cases',\@addcases);
  $rc=$dri->mark_update('000001132-1',$chg);

  # Adding a case (court)
  my $court={reference_number=>'987654321',cc=>'BE',name=>'Bla',language=>'Spanish'};
  @docs=({doc_type=>'courtCaseDocument', file_type=>'jpg', file_name=>'02-2013-TMCHdefect2.jpg', file_content=>'YnJvbAo='});
  @labels=({a_label=>'a'},{a_label=>'b'});
  @cases=({id=>'case-00000123466989979999',court=>$court,documents=>\@docs,labels=>\@labels});
  $chg->add('cases',\@cases);
  $rc=$dri->mark_update('000001132-1',$chg);

=head2 mark_renew

  $rc=$dri->mark_renew($mark_id, {duration=>DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2012,month=>10,day=>1)});
  my $new_exp = $dri->get_info('exDate');

=head2 mark_transfer_start

  $rc=$dri->mark_transfer_start('000001123456789876543211113333-1', {auth=>{pw=>'qwertyasdfgh'}});
  my $new_id = $dri->get_info('new_id'); # when transferring, a new id with the agents id is assigned

=head2 message_retrieve

  $rc=$dri->message_retrieve();
  $id = dri->get_info('last_id');
  $msg = $dri->get_info('action','message',$id);
  $action_code = $dri->get_info('action_code','message',$id); # these codes are in the manual, or see L<Net::DRI::Protocol::TMCH::Core::RegistryMessage> for examples
  $action_text = $dri->get_info('action_text','message',$id);


=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. 
                       (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($c,$ctx,$rp)=@_;
 my $drd=$ctx->{registry}->driver();
 my $self=$c->SUPER::new($ctx);
 $self->name('TMCH');
 my $version=Net::DRI::Util::check_equal($rp->{version},['1.1'],'1.1');
 $self->version($version);

 $self->ns({ _main   => ['urn:ietf:params:xml:ns:tmch-1.1','tmch-1.1'],
                         mark => ['urn:ietf:params:xml:ns:mark-1.0','mark-1.0'],
                         dignedMark => ['urn:ietf:params:xml:ns:signedMark-1.0','signedMark-1.0'],
                         'xmldsig-core-schema' => ['urn:ietf:params:xml:ns:xmldsig-core-schema-1.0','xmldsig-core-schema-1.0']
                        });
 $drd->set_factories($self) if $drd->can('set_factories');
 $self->factories('message',sub { my $m=Net::DRI::Protocol::TMCH::Message->new(@_); $m->ns($self->ns()); $m->version($version); return $m; });
 $self->_load($rp);
 $self->setup($rp);
 return $self;
}

sub _load
{
 my ($self,$rp)=@_;
 my $extramods=$rp->{extensions};
 my @class=$self->core_modules($rp);
 push @class,map { 'Net::DRI::Protocol::TMCH::Extensions::'.$_; } $self->default_extensions($rp) if $self->can('default_extensions');
 push @class,map { my $f=$_; $f='Net::DRI::Protocol::TMCH::Extensions::'.$f unless ($f=~s/^\+//); $f; } (ref $extramods ? @$extramods : ($extramods)) if defined $extramods && $extramods;
 $self->SUPER::_load(@class);
}

sub setup { } ## subclass as needed

sub parse_iso8601
{
 my ($self,$d)=@_;
 $d =~ s/ /T/; # they don't always sent back in  8601
 $self->{iso8601_parser}=DateTime::Format::ISO8601->new() unless exists $self->{iso8601_parser};
 return $self->{iso8601_parser}->parse_datetime($d);
}

sub core_modules
{
 my ($self,$rp)=@_;
 my @core=qw/Session Mark RegistryMessage/;
 return map { 'Net::DRI::Protocol::TMCH::Core::'.$_ } @core;
}

sub core_contact_types { return qw/agent owder thirdparty/; } # FIXME do i need this?

sub ns
{
 my ($self,$add)=@_;
 $self->{ns}={ ref $self->{ns} ? %{$self->{ns}} : (), %$add } if defined $add && ref $add eq 'HASH';
 return $self->{ns};
}

## Called during server greeting parse
sub switch_to_highest_namespace_version
{
 my ($self,$nsalias)=@_;

 my ($basens)=($self->message()->ns($nsalias)=~m/^(\S+)-[\d.]+$/);
 my $rs=$self->default_parameters()->{server};
 my @ns=grep { m/^${basens}-\S+$/ } @{$rs->{extensions_selected}};
 Net::DRI::Exception::err_invalid_parameters("No extension found under namespace ${basens}-*") unless @ns;

 my $version;
 foreach my $ns (@ns)
 {
  my ($v)=($ns=~m/^\S+-([\d.]+)$/);
  $version=0+$v if ! defined $version || 0+$v > $version;
 }

 my $fullns=$basens.'-'.$version;
 if (@ns > 1)
 {
  $self->log_output('info','protocol',{action=>'greeting',direction=>'in',trid=>$self->message()->cltrid(),message=>sprintf('More than one "%s" extension announced by server, selecting "%s"',$nsalias,$fullns)});
 } else
 {
  $self->log_output('info','protocol',{action=>'greeting',direction=>'in',trid=>$self->message()->cltrid(),message=>sprintf('For "%s" extension, using "%s"',$nsalias,$fullns)});
 }

 my $xsd=($self->message()->nsattrs($nsalias))[2];
 $xsd=~s/-([\d.]+)\.xsd$/-${version}.xsd/;
 $self->ns({ $nsalias => [ $fullns, $xsd ]});
 $self->message()->ns($self->ns()); ## not necessary, just to make sure
 ## remove all other versions of same namespace
 $rs->{extensions_selected}=[ grep { ! m/^${basens}-([\d.]+)$/ || $1 eq $version } @{$rs->{extensions_selected}} ];
}

sub transport_default
{
 my ($self)=@_;
 return (protocol_connection => 'Net::DRI::Protocol::TMCH::Connection', protocol_version => 1);
}

####################################################################################################
1;
