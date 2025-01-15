#! /bin/bash

# Code to organise and process preproc data from HCP
# Brain extract T1w MRI
# Reorient eddy_dwi data and create b0 files
base=~/imaging/datasets/hcp32
derivatives=${base}/derivatives
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12
export FREESURFER_HOME=/Applications/freesurfer/dev
source $FREESURFER_HOME/SetUpFreeSurfer.sh
mni_05mm_brain=~/imaging/datasets/mni/templates/T1/MNI152_T1_05mm_brain.nii.gz

for dir in ${derivatives}/sub-*; do
  sub=$(basename ${dir})
  
  # Reorient eddy corrected dwi
  mkdir ${dir}/dwi/reoriented
  mrconvert \
  ${dir}/dwi/${sub}_dwi.nii.gz \
  -fslgrad ${dir}/dwi/bvecs_fsl_moco_norm.txt \
  ${dir}/dwi/bvals.txt \
  -strides 1,2,3 \
  ${dir}/dwi/reoriented/${sub}_dwi.nii.gz \
  -export_grad_fsl \
  ${dir}/dwi/reoriented/${sub}_dwi.bvec \
  ${dir}/dwi/reoriented/${sub}_dwi.bval \
  -force

  # Obtain b0
  dwiextract \
  ${dir}/dwi/reoriented/${sub}_dwi.nii.gz - -bzero -fslgrad \
  ${dir}/dwi/reoriented/${sub}_dwi.bvec \
  ${dir}/dwi/reoriented/${sub}_dwi.bval | \
  mrmath - mean ${dir}/dwi/reoriented/${sub}_dwi_b0.nii.gz -axis 3

  # Obtain brain extracted and masked b0
  mri_synthstrip \
  -i ${dir}/dwi/reoriented/${sub}_dwi_b0.nii.gz \
  -o ${dir}/dwi/reoriented/${sub}_dwi_b0_brain.nii.gz \
  -m ${dir}/dwi/reoriented/${sub}_dwi_b0_brain_mask.nii.gz

  mri_synthstrip \
  -i ${dir}/anat/${sub}_T1w.nii.gz \
  -o ${dir}/anat/${sub}_T1w_brain.nii.gz \
  -m ${dir}/anat/${sub}_T1w_brain_mask.nii.gz

  mkdir ${dir}/xfms
  # Coregister T1w and b0
  antsRegistrationSyN.sh \
  -d 3 \
  -f ${dir}/anat/${sub}/${sub}_T1w_brain.nii.gz \
  -m ${dir}/dwi/reoriented/${sub}_dwi_b0_brain.nii.gz \
  -o ${dir}/xfms/${sub}_b0-T1w_ \
  -t r

  # Generate T1w-b0_MNI xfm
  antsRegistrationSyN.sh \
  -d 3 \
  -f ${mni_05mm_brain} \
  -m ${dir}/xfms/${sub}_b0-T1w_InverseWarped.nii.gz \
  -o ${dir}/anat/${sub}_T1w-b0_MNI_05mm_

  c3d_affine_tool \
  -ref ${mni_05mm_brain} \
  -src ${dir}/dwi/reoriented/${sub}_dwi_b0_brain.nii.gz \
  -itk ${dir}/anat/${sub}_T1w-b0_MNI_05mm_0GenericAffine.mat \
  -ras2fsl \
  -o ${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslaffine.mat

  # Convert T1p_b0-MNI xfm (ANTs to FSL warp)
  wb_command \
  -convert-warpfield -from-itk \
  ${dir}/anat/${sub}_T1w-b0_MNI_05mm_1Warp.nii.gz \
  -to-fnirt \
  ${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslwarp.nii.gz \
  ${mni_05mm_brain}

  # Compose fsl xfms
  convertwarp \
  --ref=${mni_05mm_brain} \
  --premat=${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslaffine.mat \
  --warp1=${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslwarp.nii.gz \
  --out=${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslaffwarp.nii.gz

  # Remove the intermediate warp
  rm ${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslwarp.nii.gz

  # Generate 05mm-T1p-b0 xfm (FSL affine + warp)
  invwarp \
  --ref=${dir}/dwi/reoriented/${sub}_dwi_b0_brain.nii.gz \
  --warp=${dir}/xfms/${sub}_T1w-b0_MNI_05mm_fslaffwarp.nii.gz \
  --out=${dir}/xfms/${sub}_MNI_05mm-T1w-b0_fslaffwarp.nii.gz

done
