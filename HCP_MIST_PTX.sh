#! /bin/bash

# Code to run MIST segmentation on HCP data
# Will likely use STN, Striatum and Pallidum segmentations

BASE=/Users/neuro-239/Desktop/HCP/
MISTDIR=${BASE}MIST/
T1DIR=${BASE}T1_preproc/
XFMSDIR=${BASE}xfms/
mkdir -p ${MISTDIR}
touch ${MISTDIR}/mist_subjects

# FSL affine and warp xfms for T1 to 2mm MNI space
A="T1_2_2mm_FSL_affine.mat"
W="T1_2_2mm_FSL_warp.nii.gz"

# Create a temporary directory to run MIST in
TMPDIR=${MISTDIR}tmp/

for DIR in ${XFMSDIR}*
do
  SUB=$(basename ${DIR})
  mkdir -p ${TMPDIR}${SUB}
  ln -s ${XFMSDIR}${SUB}/norm/FSL/${SUB}_${A} ${TMPDIR}${SUB}/${A}
  ln -s ${XFMSDIR}${SUB}/norm/FSL/${SUB}_${W} ${TMPDIR}${SUB}/${W}
  ln -s ${T1DIR}${SUB}/T1p.nii.gz ${TMPDIR}${SUB}/
  ln -s ${T1DIR}${SUB}/T1p_brain.nii.gz ${TMPDIR}${SUB}/
  ln -s ${T2DIR}${SUB}/T2p.nii.gz ${TMPDIR}${SUB}/
  echo ${TMPDIR}${SUB} >> ${MISTDIR}mist_subjects
done

echo -e '"T1","T1","T1p.nii.gz",1.0\n"T2","T2","T2p.nii.gz",1.0\n"alternate_affine","T1_2_2mm_FSL_affine.mat"\n"alternate_warp","T1_2_2mm_FSL_warp.nii.gz"' >> ${MISTDIR}/mist_filenames

# If MIST works, then ammend the above for using the brain extracted...

cd ${MISTDIR}
mist_1_train
mist_2_fit
cd ${BASE}

# 

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
