#! /bin/bash

# Code to run MIST segmentation on HCP data
# Will likely use STN, Striatum and Pallidum segmentations

BASE=/Users/neuro-239/Desktop/HCP/
MISTDIR=${BASE}/MIST/
T1DIR=${BASE}/T1_preproc/
XFMSDIR=${BASE}/xfms/

mkdir -p ${MISTDIR}model
touch ${MISTDIR}model/mist_subjects
echo ${T1DIR}${SUB} >> ${MISTDIR}model/mist_subjects

echo -e "T1","T1","T1p.nii.gz",1.0\n"T2","T2","T2p.nii.gz",1.0\n"alternate_affine","${XFMSDIR}${SUB}/point2fslaffine.mat"\n"alternate_warp","${XFMSDIR}${SUB}/point2fslfnirt.nii.gz" >> ${MISTDIR}/mist_filenames

cd ${T1DIR}
mist_1_train
mist_2_fit

# RUN THIS ONCE XFMS DONE SO CAN ASSESS OUTPUT

# Example code for probablistic tracking

probtrackx2_gpu \
--samples=mgh_1002/mgh_1002.bedpostX/merged \
--mask=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--seed=mgh_1002/masks/l_ppn.nii.gz \
--out=ptx_out \
--targetmasks=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--xfm=mgh_1002/xfms/std2d.nii.gz \
--invxfm=mgh_1002/xfms/d2std.nii.gz \
--seedref=t1.nii.gz \
--modeuler \
--loopcheck \
--opd \
--dir=mgh_1002/probtrackx2/
