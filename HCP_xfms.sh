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

# Coregister T1p to b0 (Warped = b0 space / Inverse = T1 space)
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
-m ${BASE}/T1_preproc/${SUB}/${SUB}_T1p_brain.nii.gz \
-o ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_ \
-t r

# Generate T1p-b0 mask (T1-warped brain mask)
fslmaths \
${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-bin \
${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped_mask.nii.gz

# Generate T1p-b0-MNI xfm (warped T1 to MNI)
# Investigate this output i.r.t diffusion space!
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
-m ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-o ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_

# Convert T1p_b0-MNI (ANTs to FSL affine)
c3d_affine_tool \
-ref ${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
-src ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
-itk ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_0GenericAffine.mat \
-ras2fsl \
-o ${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat

# Convert T1p_b0-MNI (ANTs to FSL warp)
wb_command \
-convert-warpfield -from-itk \
${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1Warp.nii.gz \
-to-fnirt \
${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz

# Compose T1p_b0-MNI xfms (FSL affine + warp)
convertwarp \
--ref=${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
--premat=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat \
--warp1=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
--out=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz

# Invert MNI-T1p_b0 (FSL affine + warp)
invwarp \
--ref=${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
--warp=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz \
--out=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_05mm-T1p-b0_affwarp.nii.gz

##############

# FREESURFER #

##############

# Convert FreeSurfer files (.mgz to .nii.gz)
for IMG in aseg orig brainmask
do
mri_convert \
${BASE}/FS/${SUB}/${IMG}.mgz \
${BASE}/FS/${SUB}/${IMG}.nii.gz
done

# Create FreeSurfer exclusion masks (CSF + ventricles)
mri_binarize \
--i ${BASE}/FS/${SUB}/mri/aseg.nii.gz \
--match 4 43 14 15 24 31 63 \
--o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask.nii.gz 

# Create FreeSurfer'd brainmask (for FreeSurfer to b0 xfm)
fslmaths \
${BASE}/FS/${SUB}/brainmask.nii.gz \
-bin \
${BASE}/FS/${SUB}/brainmask.nii.gz

# Generate orig-T1p-b0 xfm (FreeSurfer space to b0 space)
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-m ${BASE}/FS/${SUB}/mri/orig.nii.gz \
-x ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped_mask.nii.gz,${BASE}/FS/${SUB}/brainmask.nii.gz
-o ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_
-t a

# Apply orig-T1p-b0 xfm (exclusion mask to b0 space)
antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/${SUB}/mri/ventricles_csf_mask.nii.gz \
-r ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_Warped.nii.gz \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-n NearestNeighbor \
-t ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_0GenericAffine.mat

# NOT SURE THIS IS NEEDED?

# Apply T1p-MNI warp (exclusion mask in MNI space)
antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-r ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_Warped.nii.gz \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_05mm.nii.gz \
-n Linear \
-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1Warp.nii.gz \
-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_0GenericAffine.mat

# Binarise exclusion masks

for mask in T1p-b0 05mm
do

fslmaths \
${BASE}/HCP/FS/${SUB}/mri/ventricles_csf_mask_${mask}.nii.gz \
-bin \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_${mask}.nii.gz

done

