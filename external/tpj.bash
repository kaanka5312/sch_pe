#!/bin/bash
#The	superior	premotor	subdivisions	include	areas	6d (54),	6a(96),	and	the	frontal	eye	field (FEF,10),
#whereas the inferior premotor subdivisions include	6v (56) ,	6r (78),	and	the	premotor eye field(PEF,11).
#AFNI - 1-180 sol + 1000 eklendiğinde sağ'da yer alıyor. 

#All subregions 
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<139,140,141,1139,1140,1141>" \
-expr 'step(a)' \
-prefix r_l_tpj.nii

#Left TPJ
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<139,140,141>" \
-expr 'step(a)' \
-prefix l_tpj.nii

# Left TPJ Subunits
# Left TPOJ1
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<139>" \
-expr 'step(a)' \
-prefix l_tpoj1.nii

# Left TPOJ2
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<140>" \
-expr 'step(a)' \
-prefix l_tpoj2.nii

# Left TPOJ3
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<141>" \
-expr 'step(a)' \
-prefix l_tpoj3.nii

#Right TPJ 
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<1139,1140,1141>" \
-expr 'step(a)' \
-prefix r_tpj.nii

# Right TPJ Subunits
# Right TPOJ1
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<1139>" \
-expr 'step(a)' \
-prefix r_tpoj1.nii

# Right TPOJ2
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<1140>" \
-expr 'step(a)' \
-prefix r_tpoj2.nii

# Right TPOJ3
3dcalc \
-a MNI_Glasser_HCP_v1.0_LPI_2009c.nii.gz"<1141>" \
-expr 'step(a)' \
-prefix r_tpoj3.nii

