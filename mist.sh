#! /bin/bash

# Code to run MIST segmentation on HCP data
# Will likely use STN, Striatum and Pallidum segmentations

base=./Users/neuro-239/Desktop/HCP/




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

# Iterate over each xfm directory
for dir in ${derivatives}/data/sub-*; do
  sub=$(basename ${dir})
  
  mkdir -p ${TMPDIR}${SUB}
  ln -s ${XFMSDIR}${SUB}/norm/FSL/${SUB}_${A} ${TMPDIR}${SUB}/${A}
  ln -s ${XFMSDIR}${SUB}/norm/FSL/${SUB}_${W} ${TMPDIR}${SUB}/${W}
  ln -s ${T1DIR}${SUB}/${SUB}_T1p.nii.gz ${TMPDIR}${SUB}/T1.nii.gz
  ln -s ${T1DIR}${SUB}/${SUB}_T1p_brain.nii.gz ${TMPDIR}${SUB}/T1_brain.nii.gz
  ln -s ${T2DIR}${SUB}/${SUB}_T2p_coreg_T1p_Warped.nii.gz ${TMPDIR}${SUB}/T2.nii.gz
  echo ${TMPDIR}${SUB} >> ${MISTDIR}mist_subjects
done

# If MIST works, then ammend for using the brain extracted...
echo -e '"T1","T1","T1.nii.gz",1.0\n"T2","T2","T2.nii.gz",1.0\n"alternate_affine","T1_2_2mm_FSL_affine.mat"\n"alternate_warp","T1_2_2mm_FSL_warp.nii.gz"' >> ${MISTDIR}/mist_filenames

cd ${MISTDIR}
mist_1_train
mist_2_fit
cd ${BASE}
