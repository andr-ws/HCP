#! /bin/bash

# Code to create masks for tractography

BASE=/ /
FSDIR=${BASE}FS

for DIR in ${FSDIR}/s*
do
  SUB=$(basename ${DIR})

  for IMG in aseg filled
  do
	  mkdir ${DIR}/masks
	  mri_convert ${DIR}/mri/${IMG}.mgz ${FSDIR}/masks/${IMG}.nii.gz
  done

  # Ventricles
  for idx in 4 14 43
  do
	  fslmaths ${FSDIR}/masks/aseg.nii.gz \
	  -thr ${idx} -uthr ${idx} \
	  ${FSDIR}/masks/aseg_${idx}.nii.gz
  done

  fslmaths ${FSDIR}/masks/aseg_4.nii.gz \
          -add ${FSDIR}/masks/aseg_14.nii.gz \
          -add ${FSDIR}/masks/aseg_43.nii.gz \
          -bin ${FSDIR}/masks/ventricles.nii.gz

  # rh mask
  fslmaths ${FSDIR}/masks/filled.nii.gz \
          -thr 127 -uthr 127 \
          fslmaths ${FSDIR}/masks/rh.nii.gz
# lh mask
fslmaths ${FSDIR}/masks/filled.nii.gz \
          -thr 255 -uthr 255 fslmaths \
          ${FSDIR}/masks/rh.nii.gz
