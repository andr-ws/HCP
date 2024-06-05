#! /bin/bash

# Code to run MIST segmentation on HCP data
# Will likely use STN, Striatum and Pallidum segmentations

BASE=/Users/neuro-239/Desktop/HCP/
MISTDIR=${BASE}/MIST/
T1DIR=${BASE}/T1_preproc/
XFMSDIR=${BASE}/xfms/
mkdir -p ${MISTDIR}model
touch ${MISTDIR}model/mist_subjects

# FSL affine and warp xfms for T1 to 2mm MNI space
A="_T1_2_2mm_FSL_affine.mat"
W="_T1_2_2mm_FSL_warp.nii.gz"

for DIR in ${T1DIR}*
do
  echo ${DIR} >> ${MISTDIR}model/mist_subjects
  echo -e "T1","T1","T1p.nii.gz",1.0\n"T2","T2","T2p.nii.gz",1.0\n"alternate_affine","${XFMSDIR}${SUB}/norm/FSL/${SUB}${A}"\n"alternate_warp","${XFMSDIR}${SUB}/norm/FSL/${SUB}${W}" >> ${MISTDIR}/mist_filenames
done

cd ${T1DIR}
mist_1_train
mist_2_fit
cd ${BASE}

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
