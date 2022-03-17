## Domain Registry Interface, NameAction Registry Driver
##
## Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::NameAction;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::DRD::NameAction - NameAction Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>paulo.s.castanheira@gmail.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Castanheira, E<lt>paulo.s.castanheira@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'NameAction'; }
sub tlds         { 
 my @tlds = qw/ae aero ag ai al am app ar art as asia at attorney aw az ba bb be bg bh bi bike biz bo bs by bz ca cam cc cd ch ci cl cloud club cm cn co com company coop cr cu cv cz de diamonds digital dj dk dm do domains dz ec edu ee equipment es eu farm fashion fi film fit fm fo fr futbol ga gd ge gf gg gi gl global gp gq gr group gs gt guru gy hk hn hr ht hu id in info international investments io ir is it jewelry jo jobs jp ki kn kr kz la lat law lawyer lc legal li life link lk love lt ltda lu lv ly ma madrid market marketing md me mg mk mn mobi moda mp mq ms mt museum mx my name net network ni nl no online org pa pe pet ph pk pl pr pro pt pw qa racing ro rocks rs ru rw sc sd se services sg shop si site sk ski sm sn solutions soy sr st store su support sv sx systems tc tech technology tel tg tienda tj tk tl tn to tools top trade travel tt tv tw ua uk uno us uy vacations vc vg vi vin vn watch website wedding win wine ws xxx/;

 my @ag = map {"$_.ag"} qw/co com net/;
 my @ai = map {"$_.ai"} qw/com net/;
 my @al = map {"$_.al"} qw/com/;
 my @ao = map {"$_.ao"} qw/co it/;
 my @ar = map {"$_.ar"} qw/com int net org tur/;
 my @at = map {"$_.at"} qw/co/;
 my @au = map {"$_.au"} qw/com/;
 my @aw = map {"$_.aw"} qw/com/;
 my @az = map {"$_.az"} qw/com/;
 my @ba = map {"$_.ba"} qw/co/;
 my @bd = map {"$_.bd"} qw/com/;
 my @bh = map {"$_.bh"} qw/com/;
 my @bo = map {"$_.bo"} qw/com int net org/;
 my @br = map {"$_.br"} qw/abc adm adv agr aju am aparecida app arq art b belem bhz bib blog boavista bsb campinas caxias cim cnt com contagem coz cuiaba curitiba des det dev eco emp enf eng esp etc far flog floripa fm fortal foz geo goiania gru imb ind inf jab jampa jdf joinville log londrina macapa maceio manaus maringa med natal net niteroi odo ong org osasco palmas poa ppg pro psi radio rec recife rep ribeirao rio riobranco salvador sampa saobernardo seg sjc slz sorocaba srv tec teo the tmp tur tv udi vix vlog wiki/;
 my @bs = map {"$_.bs"} qw/com net org/;
 my @bw = map {"$_.bw"} qw/co/;
 my @bz = map {"$_.bz"} qw/com net/;
 my @ci = map {"$_.ci"} qw/co/;
 my @cn = map {"$_.cn"} qw/bj com net org/;
 my @co = map {"$_.co"} qw/com edu net nom org/;
 my @com = map {"$_.com"} qw/br cn us/;
 my @cr = map {"$_.cr"} qw/co fi or/;
 my @cu = map {"$_.cu"} qw/com net/;
 my @cv = map {"$_.cv"} qw/com/;
 my @cw = map {"$_.cw"} qw/com/;
 my @cy = map {"$_.cy"} qw/com/;
 my @de = map {"$_.de"} qw/com/;
 my @dk = map {"$_.dk"} qw/co/;
 my @dm = map {"$_.dm"} qw/co/;
 my @do = map {"$_.do"} qw/com net org web/;
 my @dz = map {"$_.dz"} qw/com/;
 my @ec = map {"$_.ec"} qw/com fin info net org/;
 my @ee = map {"$_.ee"} qw/co/;
 my @eg = map {"$_.eg"} qw/com/;
 my @es = map {"$_.es"} qw/com/;
 my @fj = map {"$_.fj"} qw/com/;
 my @ge = map {"$_.ge"} qw/com/;
 my @gh = map {"$_.gh"} qw/com/;
 my @gn = map {"$_.gn"} qw/com/;
 my @gp = map {"$_.gp"} qw/com/;
 my @gr = map {"$_.gr"} qw/com/;
 my @gt = map {"$_.gt"} qw/com ind net org/;
 my @gy = map {"$_.gy"} qw/co com net/;
 my @hk = map {"$_.hk"} qw/com/;
 my @hn = map {"$_.hn"} qw/com net org/;
 my @hr = map {"$_.hr"} qw/com/;
 my @hu = map {"$_.hu"} qw/co/;
 my @id = map {"$_.id"} qw/co web/;
 my @il = map {"$_.il"} qw/co/;
 my @in = map {"$_.in"} qw/co net/;
 my @ir = map {"$_.ir"} qw/co/;
 my @it = map {"$_.it"} qw/co/;
 my @jm = map {"$_.jm"} qw/com net org/;
 my @jo = map {"$_.jo"} qw/com/;
 my @jp = map {"$_.jp"} qw/co gr ne/;
 my @ke = map {"$_.ke"} qw/co info/;
 my @ki = map {"$_.ki"} qw/com/;
 my @kn = map {"$_.kn"} qw/co com net org/;
 my @kr = map {"$_.kr"} qw/co ne or/;
 my @kw = map {"$_.kw"} qw/com/;
 my @ly = map {"$_.ly"} qw/com/;
 my @ma = map {"$_.ma"} qw/co/;
 my @mk = map {"$_.mk"} qw/com/;
 my @mt = map {"$_.mt"} qw/com/;
 my @mx = map {"$_.mx"} qw/com org/;
 my @my = map {"$_.my"} qw/com/;
 my @mz = map {"$_.mz"} qw/co/;
 my @na = map {"$_.na"} qw/com/;
 my @ng = map {"$_.ng"} qw/com/;
 my @ni = map {"$_.ni"} qw/ac biz co com edu in info int net nom org pp web/;
 my @nl = map {"$_.nl"} qw/co/;
 my @no = map {"$_.no"} qw/co/;
 my @nz = map {"$_.nz"} qw/co/;
 my @om = map {"$_.om"} qw/co com/;
 my @pa = map {"$_.pa"} qw/com org/;
 my @pe = map {"$_.pe"} qw/com net nom org/;
 my @pk = map {"$_.pk"} qw/com/;
 my @pl = map {"$_.pl"} qw/com/;
 my @pr = map {"$_.pr"} qw/com net org/;
 my @pt = map {"$_.pt"} qw/co com/;
 my @py = map {"$_.py"} qw/com coop net org/;
 my @qa = map {"$_.qa"} qw/com/;
 my @ro = map {"$_.ro"} qw/co com/;
 my @ru = map {"$_.ru"} qw/com net org/;
 my @sg = map {"$_.sg"} qw/com/;
 my @sn = map {"$_.sn"} qw/com/;
 my @sv = map {"$_.sv"} qw/com org/;
 my @th = map {"$_.th"} qw/co/;
 my @tr = map {"$_.tr"} qw/com/;
 my @tt = map {"$_.tt"} qw/biz co com info name net org pro/;
 my @tw = map {"$_.tw"} qw/com/;
 my @ua = map {"$_.ua"} qw/co com/;
 my @uk = map {"$_.uk"} qw/co org/;
 my @uy = map {"$_.uy"} qw/com edu net org/;
 my @uz = map {"$_.uz"} qw/co/;
 my @ve = map {"$_.ve"} qw/arts co com firm info int net nom org rec store web/;
 my @vi = map {"$_.vi"} qw/co com net/;
 my @vn = map {"$_.vn"} qw/com/;
 my @za = map {"$_.za"} qw/co/;

 return @tlds,@ag,@ai,@al,@ao,@ar,@at,@au,@aw,@az,@ba,@bd,@bh,@bo,@br,@bs,@bw,@bz,@ci,@cn,@co,@com,@cr,@cu,@cv,@cw,@cy,@de,@dk,@dm,@do,@dz,@ec,@ee,@eg,@es,@fj,@ge,@gh,@gn,@gp,@gr,@gt,@gy,@hk,@hn,@hr,@hu,@id,@il,@in,@ir,@it,@jm,@jo,@jp,@ke,@ki,@kn,@kr,@kw,@ly,@ma,@mk,@mt,@mx,@my,@mz,@na,@ng,@ni,@nl,@no,@nz,@om,@pa,@pe,@pk,@pl,@pr,@pt,@py,@qa,@ro,@ru,@sg,@sn,@sv,@th,@tr,@tt,@tw,@ua,@uk,@uy,@uz,@ve,@vi,@vn,@za;
}
sub object_types { return ('domain'); }
sub profile_types { return qw/nameaction/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::HTTP',{},'Net::DRI::Protocol::NameAction',{}) if $type eq 'nameaction';
 return;
}

####################################################################################################
1;
