#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

## Input taken from http://langtag.net/test-suites.html
my @wellformed1=qw/fr
fr-Latn
fr-fra
fr-Latn-FR
fr-Latn-419
fr-FR
ax-TZ
fr-shadok
fr-y-myext-myext2
fra-Latn
fra
fra-FX
i-klingon
I-kLINgon
no-bok
fr-Lat
mn-Cyrl-MN
mN-cYrL-Mn
fr-Latn-CA
en-US
fr-Latn-CA
i-enochian
x-fr-CH
sr-Latn-CS
es-419
sl-nedis
de-CH-1996
de-Latg-1996
sl-IT-nedis
en-a-bbb-x-a-ccc
de-a-value
en-Latn-GB-boont-r-extended-sequence-x-private
en-x-US
az-Arab-x-AZE-derbend
es-Latn-CO-x-private
en-US-boont
ab-x-abc-x-abc
ab-x-abc-a-a
i-default
i-klingon
abcd-Latn
AaBbCcDd-x-y-any-x
en
de-AT
es-419
de-CH-1901
sr-Cyrl
sr-Cyrl-CS
sl-Latn-IT-rozaj
en-US-x-twain
zh-cmn
zh-cmn-Hant
zh-cmn-Hant-HK
zh-gan
zh-yue-Hant-HK
xr-lxs-qut
xr-lqt-qu
xr-p-lze
/;

my @notwellformed1=qw/f
f-Latn
fr-Latn-F
a-value
en-a-bbb-a-ccc
tlh-a-b-foo
i-notexist
abcdefghi-012345678
ab-abc-abc-abc-abc
ab-abcd-abc
ab-ab-abc
ab-123-abc
a-Hant-ZH
a1-Hant-ZH
ab-abcde-abc
ab-1abc-abc
ab-ab-abcd
ab-123-abcd
ab-abcde-abcd
ab-1abc-abcd
ab-a-b
ab-a-x
ab--ab
ab-abc-
-ab-abc
ab-c-abc-r-toto-c-abc
abcd-efg
aabbccddE
/;

## Unicode vector tests, with corrections
my @wellformed2=qw/
en-GB-oed
zh-cmn-Hans
no-bok
AaBbCcDd
AaBbCcDd-x-y-any-x
abcd-Latn
ab-x-abc-a-a
ab-x-abc-x-abc
ax-TZ
az-Arab-x-AZE-derbend
de-a-value
de-CH-1996
de-Latg-1996
en
en-a-bbb-x-a-ccc
en-gb-oed
en-Latn
en-Latn-001
en-Latn-GB-boont-r-extended-sequence-x-private
en-Latn-US
en-Latn-US-lojban-gaulish
en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH
en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH-x-a-b-c-12345678
en-US
en-US
en-US-boont
en-x-US
es-419
es-Latn-CO-x-private
fr
fra
fra-FX
fra-Latn
fr-FR
fr-Latn
fr-Latn-419
fr-Latn-CA
fr-Latn-CA
fr-Latn-FR
fr-shadok
fr-y-myext-myext2
i-default
i-enochian
i-klingon
mn-Cyrl-MN
mN-cYrL-Mn
no-bok
sl-IT-nedis
sl-nedis
sr-Latn-CS
x-12345678-a
x-fr-CH
En-Gb-Oed
I-Ami
I-Bnn
I-Default
I-Enochian
I-Hak
I-Klingon
I-Lux
I-Mingo
I-Navajo
I-Pwn
I-Tao
I-Tay
I-Tsu
Sgn-Be-Fr
Sgn-Be-Nl
Sgn-Ch-De
art-lojban
cel-gaulish
en-boont
en-scouse
no-bok
no-nyn
zh-cmn
zh-cmn-Hans
zh-cmn-Hant
zh-gan
zh-guoyu
zh-hakka
zh-min
zh-min-nan
zh-wuu
zh-xiang
zh-yue
zszLDm-sCVS-es-x-gn762vG-83-S-mlL
IIJdFI-cfZv
kbAxSgJ-685
tbutP
hDL-595
dUf-iUjq-0hJ4P-5YkF-WD8fk
FZAABA-FH
xZ-lh-4QfM5z9J-1eG4-x-K-R6VPr2z
Fyi
SeI-DbaG
ch-xwFn
OeC-GPVI
JLzvUSi
Fxh-hLAs
pKHzCP-sgaO-554
eytqeW-hfgH-uQ
ydn-zeOP-PR
uoWmBM-yHCf-JE
xwYem
zie
Re-wjSv-Ey-i-XE-E-JjWTEB8-f-DLSH-NVzLH-AtnFGWoH-SIDE
ji
IM-487
EPZ-zwcB
GauwEcwo
kDEP
FwDYt-TNvo
ottqP-KLES-x-9-i9
fcflR-grQQ
TvFwdu-kYhs
WE-336
MgxQa-ywEp-8lcW-7bvT-h-dP1Md-0h7-0Z3ir-K-Srkm-kA-7LXM-Z-whb2MiO-2mNsvbLm-W3O-4r-U-KceIxHdI-gvMVgUBV-2uRUni-J0-7C8yTK2
Hyr-B-evMtVoB1-mtsVZf-vQMV-gM-I-rr-kvLzg-f-lAUK-Qb36Ne-Z-7eFzOD-mv6kKf-l-miZ7U3-k-XDGtNQG
ybrlCpzy
ih-DlPR-PE
Krf-362
WzaD
EPaOnB-gHHn
XYta
NZ-RgOO-tR
at-FE
Tpc-693
YFp
gRQrQULo
pVomZ-585
laSu-ZcAq-338
gCW
PydSwHRI-TYfF
zKmWDD
X-bCrL5RL
HK
YMKGcLY
LwDux
Zl-072
Ri-Ar
vocMSwo-cJnr-288
kUWq-gWfQ-794
YyzqKL-273
Xrw-ZHwH-841-9foT-ESSZF-6OqO-0knk-991U-9p3m-b-JhiV-0Kq7Y-h-cxphLb-cDlXUBOQ-X-4Ti-jty94yPp
en-GB-oed
LEuZl-so
HyvBvFi-cCAl-X-irMQA-Pzt-H
uDbsrAA-304
wTS
IWXS
XvDqNkSn-jRDR
gX-Ycbb-iLphEks-AQ1aJ5
FbSBz-VLcR-VL
JYoVQOP-Iytp
gDSoDGD-lq-v-7aFec-ag-k-Z4-0kgNxXC-7h
Bjvoayy-029
qSDJd
qpbQov
fYIll-516
GfgLyfWE-EHtB
Wc-ZMtk
cgh-VEYK
WRZs-AaFd-yQ
eSb-CpsZ-788
YVwFU
JSsHiQhr-MpjT-381
LuhtJIQi-JKYt
vVTvS-RHcP
SY
fSf-EgvQfI-ktWoG-8X5z-63PW
NOKcy
OjJb-550
KB
qzKBv-zDKk-589
Jr
Acw-GPXf-088
WAFSbos
HkgnmerM-x-e5-zf-VdDjcpz-1V6
UAfYflJU-uXDc-YV
x-CHsHx-VDcOUAur-FqagDTx-H-V0e74R
uZIAZ-Xmbh-pd
GDJ-nHYa-bw-X-ke-rohH5GfS-LdJKsGVe
en-enx
en-enx-eny-enz-latn-us
fr-fra
fr-Lat
/;


my @notwellformed2=qw/
PTow-w-cAQ51-8Xd6E-cumicgt-WpkZv3NY-q-ORYPRy-v-A4jL4A-iNEqQZZ-sjKn-W-N1F-pzyc-xP5eWz-LmsCiCcZ
Ri-063-c-u6v-ZfhkToTB-C-IFfmv-XT-j-rdyYFMhK-h-pY-D5-Oh6FqBhL-hcXt-v-WdpNx71-K-c74m4-eBTT7-JdH7Q1Z
tfOxdau-yjge-489-a-oB-I8Csb-1ESaK1v-VFNz-N-FT-ZQyn-On2-I-hu-vaW3-jIQb-vg0U-hUl-h-dO6KuJqB-U-tde2L-P3gHUY-vnl5c-RyO-H-gK1-zDPu-VF1oeh8W-kGzzvBbW-yuAJZ
ab-a-abc-a-abc
en-a-bbb-a-ccc
ab-c-abc-r-toto-c-abc
-a
a-
a1-Hant-ZH
aabbccddE
a--b
ab-123-abc
ab-123-abc
ab-123-abcd
ab-123-abcd
ab-1abc-abc
ab-1abc-abc
ab-1abc-abcd
ab-1abc-abcd
ab--ab
ab--ab
ab-a-b
ab-a-b
ab-ab-abc
ab-ab-abc
ab-ab-abcd
ab-ab-abcd
-ab-abc
-ab-abc
ab-abc-
ab-abc-
ab-abc-abc-abc-abc
ab-abc-abc-abc-abc
ab-abcd-abc
ab-abcd-abc
ab-abcde-abc
ab-abcde-abc
ab-abcde-abcd
ab-abcde-abcd
ab-a-x
ab-a-x
abcd-efg
abcdefghi-012345678
abcdefghi-012345678
a-foo
a-Hant-ZH
a-value
a-x
b-fish
en-enx-eny-enz-enw
en-UK-oed
en-US-Latn
f
f-Latn
fr-Latn-F
overlongone
tlh-a-b-foo
i-notexist
EdY-z_H791Xx6_m_kj
qWt85_8S0-L_rbBDq0gl_m_O_zsAx_nRS
VzyL2
T_VFJq-L-0JWuH_u2_VW-hK-kbE
u-t
Q-f_ZVJXyc-doj_k-i
JWB7gNa_K-5GB-25t_W-s-ZbGVwDu1-H3E
b-2T-Qob_L-C9v_2CZxK86
fQTpX_0_4Vg_L3L_g7VtALh2
S-Z-E_J
f6wsq-02_i-F
9_GcUPq_G
QjsIy_9-0-7_Dv2yPV09_D-JXWXM
D_se-f-k
ON47Wv1_2_W
f-z-R_s-ha
N3APeiw_195_Bx2-mM-pf-Z-Ip5lXWa-5r
IRjxU-E_6kS_D_b1b_H
NB-3-5-AyW_FQ-9hB-TrRJg3JV_3C
yF-3a_V_FoJQAHeL_Z-Mc-u
n_w_bbunOG_1-s-tJMT5je
Q-AEWE_X
57b1O_k_R6MU_sb
hK_65J_i-o_SI-Y
wB4B7u_5I2_I_NZPI
J24Nb_q_d-zE
v6-dHjJmvPS_IEb-x_A-O-i
8_8_dl-ZgBr84u-P-E
nIn-xD7EVhe_C
5_N-6P_x7Of_Lo_6_YX_R
0_46Oo0sZ-YNwiU8Wr_d-M-pg1OriV
laiY-5
K-8Mdd-j_ila0sSpo_aO8_J
wNATtSL-Cp4_gPa_fD41_9z
H_FGz5V8_n6rrcoz0_1O6d-kH-7-N
wDOrnHU-odqJ_vWl
gP_qO-I-jH
h
dJ0hX-o_csBykEhU-F
L-Vf7_BV_eRJ5goSF_Kp
y-oF-chnavU-H
9FkG-8Q-8_v
W_l_NDQqI-O_SFSAOVq
kDG3fzXw
t-nsSp-7-t-mUK2
Yw-F
1-S_3_l
u-v_brn-Y
4_ft_3ZPZC5lA_D
n_dR-QodsqJnh_e
Hwvt-bSwZwj_KL-hxg0m-3_hUG
mQHzvcV-UL-o2O_1KhUJQo_G2_uryk3-a
b-UTn33HF
r-Ep-jY-aFM_N_H
K-k-krEZ0gwD_k_ua-9dm3Oy-s_v
XS_oS-p
EIx_h-zf5
p_z-0_i-omQCo3B
1_q0N_jo_9
0Ai-6-S
L-LZEp_HtW
Zj-A4JD_2A5Aj7_b-m3
x
p-qPuXQpp_d-jeKifB-c-7_G-X
X94cvJ_A
F2D25R_qk_W-w_Okf_kx
rc-f
D
gD_WrDfxmF-wu-E-U4t
Z_BN9O4_D9-D_0E_KnCwZF-84b-19
T-8_g-u-0_E
lXTtys9j_X_A_m-vtNiNMw_X_b-C6Nr
V_Ps-4Y-S
X5wGEA
mIbHFf_ALu4_Jo1Z1
ET-TacYx_c
Z-Lm5cAP_ri88-d_q_fi8-x
rTi2ah-4j_j_4AlxTs6m_8-g9zqncIf-N5
FBaLB85_u-0NxhAy-ZU_9c
x_j_l-5_aV95_s_tY_jp4
PL768_D-m7jNWjfD-Nl_7qvb_bs_8_Vg
9-yOc-gbh
6DYxZ_SL-S_Ye
ZCa-U-muib-6-d-f_oEh_O
Qt-S-o8340F_f_aGax-c-jbV0gfK_p
WE_SzOI_OGuoBDk-gDp
cs-Y_9
m1_uj
Y-ob_PT
li-B
f-2-7-9m_f8den_J_T_d
p-Os0dua-H_o-u
L
rby-w
/;

my %wellformed1 = map { $_ => $_ } @wellformed1;
## canonicalization rules
$wellformed1{'AaBbCcDd-x-y-any-x'}='aabbccdd-x-y-any-x';
$wellformed1{'I-kLINgon'}='i-klingon';
$wellformed1{'az-Arab-x-AZE-derbend'}='az-Arab-x-aze-derbend';
$wellformed1{'en-x-US'}='en-x-us';
$wellformed1{'fr-Lat'}='fr-lat';
$wellformed1{'mN-cYrL-Mn'}='mn-Cyrl-MN';
$wellformed1{'xr-lqt-qu'}='xr-lqt-QU';

my %wellformed2 = map { $_ => $_ } @wellformed2;
$wellformed2{'AaBbCcDd'}='aabbccdd';
$wellformed2{'AaBbCcDd-x-y-any-x'}='aabbccdd-x-y-any-x';
$wellformed2{'Acw-GPXf-088'}='acw-Gpxf-088';
$wellformed2{'Bjvoayy-029'}='bjvoayy-029';
$wellformed2{'EPaOnB-gHHn'}='epaonb-Ghhn';
$wellformed2{'EPZ-zwcB'}='epz-Zwcb';
$wellformed2{'En-Gb-Oed'}='en-GB-oed';
$wellformed2{'FZAABA-FH'}='fzaaba-FH';
$wellformed2{'FbSBz-VLcR-VL'}='fbsbz-Vlcr-VL';
$wellformed2{'FwDYt-TNvo'}='fwdyt-Tnvo';
$wellformed2{'Fxh-hLAs'}='fxh-Hlas';
$wellformed2{'Fyi'}='fyi';
$wellformed2{'GDJ-nHYa-bw-X-ke-rohH5GfS-LdJKsGVe'}='gdj-Nhya-BW-x-ke-rohh5gfs-ldjksgve';
$wellformed2{'GauwEcwo'}='gauwecwo';
$wellformed2{'GfgLyfWE-EHtB'}='gfglyfwe-Ehtb';
$wellformed2{'HK'}='hk';
$wellformed2{'HkgnmerM-x-e5-zf-VdDjcpz-1V6'}='hkgnmerm-x-e5-ZF-vddjcpz-1v6';
$wellformed2{'Hyr-B-evMtVoB1-mtsVZf-vQMV-gM-I-rr-kvLzg-f-lAUK-Qb36Ne-Z-7eFzOD-mv6kKf-l-miZ7U3-k-XDGtNQG'}='hyr-b-evmtvob1-mtsvzf-Vqmv-GM-f-lauk-qb36ne-i-rr-kvlzg-k-xdgtnqg-l-miz7u3-z-7efzod-mv6kkf';
$wellformed2{'HyvBvFi-cCAl-X-irMQA-Pzt-H'}='hyvbvfi-Ccal-x-irmqa-pzt-h';
$wellformed2{'I-Ami'}='i-ami';
$wellformed2{'I-Bnn'}='i-bnn';
$wellformed2{'I-Default'}='i-default';
$wellformed2{'I-Enochian'}='i-enochian';
$wellformed2{'I-Hak'}='i-hak';
$wellformed2{'I-Klingon'}='i-klingon';
$wellformed2{'I-Lux'}='i-lux';
$wellformed2{'I-Mingo'}='i-mingo';
$wellformed2{'I-Navajo'}='i-navajo';
$wellformed2{'I-Pwn'}='i-pwn';
$wellformed2{'I-Tao'}='i-tao';
$wellformed2{'I-Tay'}='i-tay';
$wellformed2{'I-Tsu'}='i-tsu';
$wellformed2{'IIJdFI-cfZv'}='iijdfi-Cfzv';
$wellformed2{'IM-487'}='im-487';
$wellformed2{'IWXS'}='iwxs';
$wellformed2{'JLzvUSi'}='jlzvusi';
$wellformed2{'JSsHiQhr-MpjT-381'}='jsshiqhr-Mpjt-381';
$wellformed2{'JYoVQOP-Iytp'}='jyovqop-Iytp';
$wellformed2{'Jr'}='jr';
$wellformed2{'Krf-362'}='krf-362';
$wellformed2{'KB'}='kb';
$wellformed2{'LEuZl-so'}='leuzl-SO';
$wellformed2{'LuhtJIQi-JKYt'}='luhtjiqi-Jkyt';
$wellformed2{'LwDux'}='lwdux';
$wellformed2{'MgxQa-ywEp-8lcW-7bvT-h-dP1Md-0h7-0Z3ir-K-Srkm-kA-7LXM-Z-whb2MiO-2mNsvbLm-W3O-4r-U-KceIxHdI-gvMVgUBV-2uRUni-J0-7C8yTK2'}='mgxqa-Ywep-8lcw-7bvt-h-dp1md-0h7-0z3ir-k-srkm-KA-7lxm-u-kceixhdi-gvmvgubv-2uruni-J0-7c8ytk2-z-whb2mio-2mnsvblm-w3o-4R';
$wellformed2{'NZ-RgOO-tR'}='nz-Rgoo-TR';
$wellformed2{'NOKcy'}='nokcy';
$wellformed2{'OeC-GPVI'}='oec-Gpvi';
$wellformed2{'OjJb-550'}='ojjb-550';
$wellformed2{'PydSwHRI-TYfF'}='pydswhri-Tyff';
$wellformed2{'Re-wjSv-Ey-i-XE-E-JjWTEB8-f-DLSH-NVzLH-AtnFGWoH-SIDE'}='re-Wjsv-EY-e-jjwteb8-f-dlsh-nvzlh-atnfgwoh-Side-i-xe';
$wellformed2{'Ri-Ar'}='ri-AR';
$wellformed2{'SY'}='sy';
$wellformed2{'SeI-DbaG'}='sei-Dbag';
$wellformed2{'Sgn-Be-Fr'}='sgn-BE-FR';
$wellformed2{'Sgn-Be-Nl'}='sgn-BE-NL';
$wellformed2{'Sgn-Ch-De'}='sgn-CH-DE';
$wellformed2{'Tpc-693'}='tpc-693';
$wellformed2{'TvFwdu-kYhs'}='tvfwdu-Kyhs';
$wellformed2{'UAfYflJU-uXDc-YV'}='uafyflju-Uxdc-YV';
$wellformed2{'WAFSbos'}='wafsbos';
$wellformed2{'WE-336'}='we-336';
$wellformed2{'WRZs-AaFd-yQ'}='wrzs-Aafd-YQ';
$wellformed2{'Wc-ZMtk'}='wc-Zmtk';
$wellformed2{'WzaD'}='wzad';
$wellformed2{'X-bCrL5RL'}='x-bcrl5rl';
$wellformed2{'Xrw-ZHwH-841-9foT-ESSZF-6OqO-0knk-991U-9p3m-b-JhiV-0Kq7Y-h-cxphLb-cDlXUBOQ-X-4Ti-jty94yPp'}='xrw-Zhwh-841-9fot-esszf-6oqo-0knk-991u-9p3m-b-jhiv-0kq7y-h-cxphlb-cdlxuboq-x-4ti-jty94ypp';
$wellformed2{'XYta'}='xyta';
$wellformed2{'XvDqNkSn-jRDR'}='xvdqnksn-Jrdr';
$wellformed2{'YFp'}='yfp';
$wellformed2{'YMKGcLY'}='ymkgcly';
$wellformed2{'YVwFU'}='yvwfu';
$wellformed2{'YyzqKL-273'}='yyzqkl-273';
$wellformed2{'Zl-072'}='zl-072';

$wellformed2{'az-Arab-x-AZE-derbend'}='az-Arab-x-aze-derbend';
$wellformed2{'cgh-VEYK'}='cgh-Veyk';
$wellformed2{'ch-xwFn'}='ch-Xwfn';
$wellformed2{'dUf-iUjq-0hJ4P-5YkF-WD8fk'}='duf-Iujq-0hj4p-5ykf-wd8fk';
$wellformed2{'eSb-CpsZ-788'}='esb-Cpsz-788';
$wellformed2{'en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH'}='en-Latn-US-lojban-gaulish-a-12345678-Abcd-b-abcdefgh';
$wellformed2{'en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH-x-a-b-c-12345678'}='en-Latn-US-lojban-gaulish-a-12345678-Abcd-b-abcdefgh-x-a-b-c-12345678';
$wellformed2{'en-enx-eny-enz-latn-us'}='en-enx-eny-enz-Latn-US';
$wellformed2{'en-gb-oed'}='en-GB-oed';
$wellformed2{'en-x-US'}='en-x-us';
$wellformed2{'eytqeW-hfgH-uQ'}='eytqew-Hfgh-UQ';
$wellformed2{'fSf-EgvQfI-ktWoG-8X5z-63PW'}='fsf-egvqfi-ktwog-8x5z-63pw';
$wellformed2{'fYIll-516'}='fyill-516';
$wellformed2{'fcflR-grQQ'}='fcflr-Grqq';
$wellformed2{'fr-Lat'}='fr-lat';
$wellformed2{'gCW'}='gcw';
$wellformed2{'gDSoDGD-lq-v-7aFec-ag-k-Z4-0kgNxXC-7h'}='gdsodgd-LQ-k-z4-0kgnxxc-7H-v-7afec-AG';
$wellformed2{'gRQrQULo'}='grqrqulo';
$wellformed2{'gX-Ycbb-iLphEks-AQ1aJ5'}='gx-Ycbb-ilpheks-aq1aj5';
$wellformed2{'hDL-595'}='hdl-595';
$wellformed2{'hkgnmerm-x-e5-zf-vddjcpz-1v6'}='hkgnmerm-x-e5-ZF-vddjcpz-1v6';
$wellformed2{'ih-DlPR-PE'}='ih-Dlpr-PE';
$wellformed2{'kDEP'}='kdep';
$wellformed2{'kUWq-gWfQ-794'}='kuwq-Gwfq-794';
$wellformed2{'kbAxSgJ-685'}='kbaxsgj-685';
$wellformed2{'laSu-ZcAq-338'}='lasu-Zcaq-338';
$wellformed2{'mN-cYrL-Mn'}='mn-Cyrl-MN';
$wellformed2{'ottqP-KLES-x-9-i9'}='ottqp-Kles-x-9-i9';
$wellformed2{'pKHzCP-sgaO-554'}='pkhzcp-Sgao-554';
$wellformed2{'pVomZ-585'}='pvomz-585';
$wellformed2{'qSDJd'}='qsdjd';
$wellformed2{'qpbQov'}='qpbqov';
$wellformed2{'qzKBv-zDKk-589'}='qzkbv-Zdkk-589';
$wellformed2{'tbutP'}='tbutp';
$wellformed2{'tvfwdu-kyhs'}='tvfwdu-Kyhs';
$wellformed2{'uDbsrAA-304'}='udbsraa-304';
$wellformed2{'uZIAZ-Xmbh-pd'}='uziaz-Xmbh-PD';
$wellformed2{'uoWmBM-yHCf-JE'}='uowmbm-Yhcf-JE';
$wellformed2{'vVTvS-RHcP'}='vvtvs-Rhcp';
$wellformed2{'vocMSwo-cJnr-288'}='vocmswo-Cjnr-288';
$wellformed2{'wTS'}='wts';
$wellformed2{'x-CHsHx-VDcOUAur-FqagDTx-H-V0e74R'}='x-chshx-vdcouaur-fqagdtx-h-v0e74r';
$wellformed2{'xZ-lh-4QfM5z9J-1eG4-x-K-R6VPr2z'}='xz-LH-4qfm5z9j-1eg4-x-k-r6vpr2z';
$wellformed2{'xwYem'}='xwyem';
$wellformed2{'ybrlCpzy'}='ybrlcpzy';
$wellformed2{'ydn-zeOP-PR'}='ydn-Zeop-PR';
$wellformed2{'zszLDm-sCVS-es-x-gn762vG-83-S-mlL'}='zszldm-Scvs-ES-x-gn762vg-83-s-mll';
$wellformed2{'zKmWDD'}='zkmwdd';



require_ok('Net::DRI::Data::LanguageTag');

subtest 'wellformed' => sub {
 plan tests => (scalar(keys(%wellformed1)) + scalar(keys(%wellformed2)));

 foreach my $tag (sort { $a cmp $b } keys %wellformed1)
 {
  my $ctag=eval { Net::DRI::Data::LanguageTag->new($tag)->as_string(); };
  is($ctag,$wellformed1{$tag},qq{Tag "${tag}" is parsed correctly});
 }

 foreach my $tag (sort { $a cmp $b } keys %wellformed2)
 {
  my $ctag=eval { Net::DRI::Data::LanguageTag->new($tag)->as_string(); };
  is($ctag,$wellformed2{$tag},qq{Tag "${tag}" is parsed correctly});
 }
};

subtest 'notwellformed' => sub {
 plan tests => (@notwellformed1 + @notwellformed2);

 foreach my $tag (@notwellformed1)
 {
  my $ctag=eval { Net::DRI::Data::LanguageTag->new($tag)->as_string(); };
  ok(! defined $ctag,qq{Tag "${tag}" is rejected as expected});
 }

 foreach my $tag (@notwellformed2)
 {
  my $ctag=eval { Net::DRI::Data::LanguageTag->new($tag)->as_string(); };
  ok(! defined $ctag,qq{Tag "${tag}" is rejected as expected});
 }
};

subtest 'accessors' => sub {
 plan tests => 46;

 my $s='en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH-x-a-b-c-12345678';
 my $sn='en-Latn-US-lojban-gaulish-a-12345678-Abcd-b-abcdefgh-x-a-b-c-12345678';
 my $ltag=Net::DRI::Data::LanguageTag->new($s);

 is($ltag->type(),'langtag','type()');
 is($ltag->language(),'en','language() scalar');
 is(''.$ltag->script(),'Latn','script() scalar');
 is(''.$ltag->region(),'US','region() scalar');
 is(''.$ltag->variant(),'lojban-gaulish','variant() scalar');
 is(''.$ltag->extension(),'a-12345678-Abcd-b-abcdefgh','extension() scalar');
 is(''.$ltag->privateuse(),'x-a-b-c-12345678','privateuse() scalar');
 is_deeply([$ltag->language()],['en'],'language() array');
 is_deeply([$ltag->script()],['Latn'],'script() array');
 is_deeply([$ltag->region()],['US'],'region() array');
 is_deeply([$ltag->variant()],[qw/lojban gaulish/],'variant() array');
 is_deeply([$ltag->extension()],[qw/a 12345678 Abcd b abcdefgh/],'extension() array');
 is_deeply([$ltag->privateuse()],[qw/x a b c 12345678/],'privateuse() array');

 is_deeply([$ltag->subtags()],[qw/en Latn US lojban gaulish a 12345678 Abcd b abcdefgh x a b c 12345678/],'subtags() array');
 is_deeply(scalar $ltag->subtags(),{type=>'langtag',language=>['en'],script=>['Latn'],region=>['US'],variant=>[qw/lojban gaulish/],extension=>[qw/a 12345678 Abcd b abcdefgh/],privateuse=>[qw/x a b c 12345678/]},'subtags() scalar');

 is($ltag->as_string(),$sn,'as_string()');

 $ltag=Net::DRI::Data::LanguageTag->new('x-whatever');
 is($ltag->type(),'privateuse','type() privateuse');
 ok(! defined $ltag->language(),'language() privateuse');
 ok(! defined $ltag->script(),'script() privateuse');
 ok(! defined $ltag->region(),'region() privateuse');
 ok(! defined $ltag->variant(),'variant() privateuse');
 ok(! defined $ltag->extension(),'extension() privateuse');
 ok(! defined $ltag->privateuse(),'privateuse() privateuse');
 is_deeply([$ltag->subtags()],[qw/x whatever/],'subtags() privateuse');
 is_deeply(scalar $ltag->subtags(),{type=>'privateuse',language=>undef,script=>undef,region=>undef,variant=>undef,extension=>undef,privateuse=>undef},'subtags() array privateuse');
 is($ltag->as_string(),'x-whatever','as_string() privateuse');

 $ltag=Net::DRI::Data::LanguageTag->new('i-default');
 is($ltag->type(),'grandfathered','type() grandfathered irregular');
 ok(! defined $ltag->language(),'language() grandfathered irregular');
 ok(! defined $ltag->script(),'script() grandfathered irregular');
 ok(! defined $ltag->region(),'region() grandfathered irregular');
 ok(! defined $ltag->variant(),'variant() grandfathered irregular');
 ok(! defined $ltag->extension(),'extension() grandfathered irregular');
 ok(! defined $ltag->privateuse(),'privateuse() grandfathered irregular');
 is_deeply([$ltag->subtags()],[qw/i default/],'subtags() grandfathered irregular');
 is_deeply(scalar $ltag->subtags(),{type=>'grandfathered',language=>undef,script=>undef,region=>undef,variant=>undef,extension=>undef,privateuse=>undef},'subtags() array grandfathered irregular');
 is($ltag->as_string(),'i-default','as_string() grandfathered irregular');

 $ltag=Net::DRI::Data::LanguageTag->new('zh-min-nan');
 is($ltag->type(),'langtag','type() grandfathered regular'); ## they are parsed as normal tag, based on the regex order
 is(''.$ltag->language(),'zh-min-nan','language() grandfathered regular');
 is(''.$ltag->script(),'','script() grandfathered regular');
 is(''.$ltag->region(),'','region() grandfathered regular');
 is(''.$ltag->variant(),'','variant() grandfathered regular');
 is(''.$ltag->extension(),'','extension() grandfathered regular');
 is(''.$ltag->privateuse(),'','privateuse() grandfathered regular');
 is_deeply([$ltag->subtags()],[qw/zh min nan/],'subtags() grandfathered regular');
 is_deeply(scalar $ltag->subtags(),{type=>'langtag',language=>[qw/zh min nan/],script=>[],region=>[],variant=>[],extension=>[],privateuse=>[]},'subtags() array grandfathered regular');
 is($ltag->as_string(),'zh-min-nan','as_string() grandfathered regular');
};

subtest 'overload' => sub {
 plan tests => 5;

 my $s='en-Latn-US-lojban-gaulish-a-12345678-ABCD-b-ABCDEFGH-x-a-b-c-12345678';
 my $sn='en-Latn-US-lojban-gaulish-a-12345678-Abcd-b-abcdefgh-x-a-b-c-12345678';
 my $ltag=Net::DRI::Data::LanguageTag->new($s);
 is("${ltag}",$sn,'overload in string');
 is_deeply([@$ltag],[qw/en Latn US lojban gaulish a 12345678 Abcd b abcdefgh x a b c 12345678/],'overload as ref array');
 my $other=Net::DRI::Data::LanguageTag->new('fr');
 is($ltag cmp $other,-1,'cmp between 2 objects');
 is($ltag cmp 'de',1,'cmp between object and scalar 1');
 is('it' cmp $ltag,1,'cmp between object and scalar 2');
 ## with cmp overloading, we get the whole gt, lt, eq, etc… as bonus
};

subtest 'add_subtag' => sub {
 plan tests => 8;

 my $ltag=Net::DRI::Data::LanguageTag->new('fr');
 is($ltag->as_string(),'fr','add_subtag step 1');
 eval { $ltag = ''.$ltag; };
 like($@,qr/^Left adding subtags is not implemented/,'overload in string concatenation 1');
 is($ltag.'','fr','overload in string concatenation 2');
 $ltag->add_subtag('FR');
 is($ltag->as_string(),'fr-FR','add_subtag step 2');
 $ltag->add_subtag('latin');
 is($ltag->as_string(),'fr-FR-latin','add_subtag step 3');
 eval { $ltag->add_subtag('x'); };
 like($@,qr/does not validate as a "Language Tag"/,'add_subtag step 4 invalid');
 is($ltag->as_string(),'fr-FR-latin','add_subtag step 4 previous value');

 $ltag=$ltag.'x-whatever';
 is($ltag->as_string(),'fr-FR-latin-x-whatever','add_subtag overloaded');
};

subtest 'die' => sub {
 plan tests => 9;

 my $ltag;
 eval { $ltag = Net::DRI::Data::LanguageTag->new(undef); };
 like($@, qr/^No tag to parse at/, 'new undef');
 eval { $ltag = Net::DRI::Data::LanguageTag->new(''); };
 like($@, qr/^No tag to parse at/, 'new empty');
 eval { $ltag = Net::DRI::Data::LanguageTag->new('fr-1aaa-1aaa'); };
 like($@, qr/^Variant element "1aaa" can not appear more than once in language tag/, 'not twice same variant');
 is(Net::DRI::Data::LanguageTag->new('fr-X-11-X-12')->as_string(),'fr-x-11-x-12','2 extensions');
 eval { Net::DRI::Data::LanguageTag::_format_subtags(0, '0123456789'); };
 like($@, qr/^Subtag "0123456789" is too long at /, 'length < 8 chars'); ## can not happen anyway due to regex
 is_deeply([Net::DRI::Data::LanguageTag::_format_subtags(1,'99')],['99'],'_format_subtags up');
 $ltag = Net::DRI::Data::LanguageTag->new('fr');
 eval { $ltag->add_subtag(); };
 like($@, qr/^Undefined subtag to add at /, 'add_subtag undef');

 ## two variants of mydie
 eval { Net::DRI::Data::LanguageTag::mydie('TEST'); };
 like($@, qr/^TEST /, 'mydie variant (outside Net::DRI framework)');
 $INC{'Net/DRI.pm'}=1;
 delete $INC{'Net/DRI/Data/LanguageTag.pm'};
 {
  package Net::DRI::Exception;
 }
 eval { local $SIG{__WARN__} = sub {};  require Net::DRI::Data::LanguageTag; }; ## silence all "Subroutine X redefined"
 eval { Net::DRI::Data::LanguageTag::mydie('TEST'); };
 isa_ok($@, 'Net::DRI::Exception');

};

exit 0;
