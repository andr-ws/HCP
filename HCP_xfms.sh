#! /bin/bash

# Code for computing ANTs 2 FSL warps for probtrackx2 (d 2 MNI_05mm / MNI_05mm 2 d) 

# Base directory
BASE=/Volumes/HD1/HCP

for DIR in /Volumes/HD1/HCP/xfms/m*
do
SUB=$(basename ${DIR})

# extract b0 brain
mri_synthstrip \
-i ${BASE}/b0_preproc/${SUB}/${SUB}_b0.nii.gz \
-o ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
-m ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain_mask.nii.gz

# T1p-b0
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
-m ${BASE}/T1_preproc/${SUB}/${SUB}_T1p_brain.nii.gz \
-o ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_ \
-t r

# T1p-b0 mask
fslmaths \
${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-bin \
${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped_mask.nii.gz

# T1p-b0-MNI
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
-m ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-o ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_

# T1p_b0-MNI ANTs to FSL affine
c3d_affine_tool \
                -ref ${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
                -src ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
                -itk ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_0GenericAffine.mat \
                -ras2fsl \
                -o ${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat

# T1p_b0-MNI ANTs to FSL warp
wb_command \
                -convert-warpfield -from-itk \
                ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1Warp.nii.gz \
                -to-fnirt \
                ${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
                ${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz

# T1p_b0-MNI FSL affine + warp
convertwarp \
                --ref=${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
                --premat=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat \
                --warp1=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
                --out=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz

# MNI-T1p_b0 FSL affine + warp
invwarp \
                --ref=${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
                --warp=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz \
                --out=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_05mm-T1p-b0_affwarp.nii.gz
done






probtrackx2 \
  -s /Users/neuro-239/Desktop/cerebellum_model/HCP/mgh_1003/mgh_1003.bedpostX/merged \
  -m /Users/neuro-239/Desktop/cerebellum_model/HCP/mgh_1003/mgh_1003.bedpostX/nodif_brain_mask.nii.gz \
  -x /Users/neuro-239/Desktop/cerebellum_model/VTA/sub-01/sub-01_lh_vta.nii.gz \
  -o vta_out --dir=/Users/neuro-239/Desktop/cerebellum_model/VTA/sub-01 \
  --xfm=/Users/neuro-239/Desktop/cerebellum_model/HCP/mgh_1003/mgh_1003_05mm_2_d_FSL_warp.nii.gz \
  --invxfm=/Users/neuro-239/Desktop/cerebellum_model/HCP/mgh_1003/mgh_1003_d_2_05mm_FSL_warp.nii.gz \
  --seedref=/Users/neuro-239/tremor/derivatives/Lead/standard/MNI152_05mm_T1.nii.gz \
  --modeuler \
  --opd \
  --loopcheck \
  --forcedir
