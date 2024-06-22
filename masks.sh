#! /bin/bash

# Code to create masks for tractography

BASE=/Users/neuro-239/Desktop/HCP/
T1DIR=${BASE}T1_preproc/
FSDIR=${BASE}/FS/
MNIDIR=${BASE}/MNI/
XFMSDIR=${BASE}/xfms/

for DIR in ${FSDIR}/s*
do
  SUB=$(basename ${DIR})

  for IMG in aseg filled
  do
  	mkdir ${DIR}/masks
   	mri_convert ${DIR}/mri/${IMG}.mgz ${FSDIR}/masks/${IMG}.nii.gz

	# Current issue is that when applying the XFM to the FS masks, does not
 	# align. This may be because FS used the unprocessed T1 as input, whereas
  	# the xfms are using the T1p - rerunning FS with the T1p_brain as input
   
     	antsApplyTransforms \
     	-d 3 \
      	-i ${FSDIR}masks/${IMG}.nii.gz \
       	-r ${MNIDIR}MNI152_T1_05mm.nii.gz \
	-t ${XFMDIR}${SUB}/norm/ANTs/${SUB}_05mm_1Warp.nii.gz \
 	-n NearestNeighbor \
 	-o ${FSDIR}masks/${IMG}_05mm.nii.gz
   		
  done

  # Ventricles
  for idx in 4 14 43
  do
	  fslmaths ${FSDIR}/masks/aseg_05mm.nii.gz \
	  -thr ${idx} -uthr ${idx} \
	  ${FSDIR}/masks/aseg_05mm_${idx}.nii.gz
  done

  # Combine ventricle masks
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
done
