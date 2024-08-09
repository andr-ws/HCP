#! /bin/bash

BASE=~/Desktop/HCP_tmp

for DIR in ${HOME}/bedpost/m*
do
SUB=$(basename ${DIR})

for SUB in mgh_1004 mgh_1005 mgh_1006
do
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
-t a

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


##############

# FREESURFER #

##############


# Convert FS files

for IMG in aseg orig brainmask

mri_convert \
	${BASE}/FS/${SUB}/${IMG}.mgz \
	${BASE}/FS/${SUB}/${IMG}.nii.gz

done

# Binarise and extract CSF and ventricle masks
mri_binarize \
	--i ${BASE}/FS/${SUB}/mri/aseg.nii.gz \
	--match 4 43 14 15 24 31 63 \
	--o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask.nii.gz 

# Binarise the FS brainmask to use in xfms
fslmaths \
${BASE}/FS/${SUB}/brainmask.nii.gz \
-bin \
${BASE}/FS/${SUB}/brainmask.nii.gz

# orig-T1p-b0
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-m ${BASE}/FS/${SUB}/orig.nii.gz \
-x ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped_mask.nii.gz,${BASE}/FS/${SUB}/brainmask.nii.gz
-o ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_
-t a

antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/${SUB}/mri/ventricles_csf_mask.nii.gz \
-r ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_Warped.nii.gz \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-n NearestNeighbor \
-t ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_0GenericAffine.mat

antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-r ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_Warped.nii.gz \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask_05mm.nii.gz \
-n Linear \
-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1Warp.nii.gz \
-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_0GenericAffine.mat

fslmaths \
${BASE}/HCP/FS/${SUB}/mri/ventricles_csf_mask-05mm.nii.gz \
-bin \
-o ${BASE}/FS/${SUB}/mri/ventricles_csf_mask-05mm.nii.gz

done
