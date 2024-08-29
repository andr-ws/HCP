#! /bin/bash

# Code to organise and process preproc data from HCP

# Renaming scheme: example for dwi (anat is just for rawdata)

# [1]
# hcp/
# └── mgh_1001/
#     └── diff/
#         └── raw/
#     	  └── preproc/

# [2]
# hcp/
# └── rawdata/
# 	  └── sub-1001/
#         └── dwi/
#         └── raw/
# └── derivatives/
# 	  └── data/
# 	  	  └── sub-1001/
#             └── dwi/
#             └── eddy_files

# rawdata contains anat folder (T1w and T2w MRI) and dwi folder (bvals.txt/bvecs.txt/bvecs_fsl.txt/dwi.nii.gz)
# derivatives/data contains:
# 1) dwi folder (bvecs_fsl_mono_norm.txt/bvecs_mono_norm.txt/eddy_dwi.nii.gz)

# sub-1001 sub-1002 sub-1003 sub-1005 sub-1006 sub-1007 sub-1008 sub-1009 sub-1010 sub-1011
# renaming of HCP files:

base=./imaging/datasets/hcp
sourcedata=${base}/sourcedata
rawdata=${base}/rawdata
derivatives=${base}/derivatives

export FREESURFER_HOME=/Applications/freesurfer/dev
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Reorient eddy_dwi data and create b0 files

# [2]
# hcp/
# └── derivatives/
# 	  └── data/
# 	  	  └── sub-1001/
#             └── dwi/
#				  └── reoriented/
#				  └── eddy_files

for dir in ${derivatives}/data/sub-*; do

  sub=$(basename ${dir})
  
  # Reorient eddy corrected dwi
  mrconvert \
  "${derivatives}/data/${sub}/dwi/${sub}_dwi_eddy.nii.gz" \
  -fslgrad "${derivatives}/data/${sub}/dwi/${sub}_bvecs_fsl_moco_norm.txt" \
  "${raw}/${sub}/dwi/${sub}_bvals.txt" \
  -strides 1,2,3 \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.nii.gz" \
  -export_grad_fsl \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.bvec" \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.bval" \
  -force

  # Obtain b0
  dwiextract \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.nii.gz" - -bzero -fslgrad \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.bvec" \
  "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy.bval" | \
  mrmath - mean "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy_b0.nii.gz" -axis 3

  # Obtain brain extracted and masked b0
  mri_synthstrip \
  -i "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy_b0.nii.gz" \
  -o "${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy_b0_brain.nii.gz" \
  -m ".${derivatives}/data/${sub}/dwi/reoriented/${sub}_dwi_eddy_b0_brain_mask.nii.gz"

done

# Process anatomical files using global anat_processing.sh script
