#! /bin/bash

# Code for computing xfms to perform putaminal tractography.

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

# Create directory for HMAT (b0 space)
mkdir -p ${BASE}/atlases/HMAT/segmentations/${SUB}

# Process hemispheres and handle MIST naming
for hemi in left right
do
if [ "$hemi" = "left" ]; then
h="L"
elif [ "$hemi" = "right" ]; then
h="R"
fi

# Apply T1p-b0 xfm (MIST segmentation to b0 space)
antsApplyTransforms \
-d 3 \
-i ${BASE}/MIST/tmp/${SUB}/mist_${hemi}_putamen_mask.nii.gz \
-r ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
-o ${BASE}/MIST/tmp/${SUB}/${SUB}_mist_${h}_putamen_mask_diff.nii.gz \
-n NearestNeighbor \
-t ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_0GenericAffine.mat

# Apply MNI-T1p-b0 xfm (HMAT parcellation to b0 space)
antsApplyTransforms \
-d 3 \
-i ${BASE}/atlases/HMAT/MNI/HMAT.nii.gz \
-r ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_InverseWarped.nii.gz \
-o ${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_diff.nii.gz \
-n NearestNeighbor \
-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1InverseWarp.nii.gz

# Handle HMAT label IDs
rois=("M1" "S1" "SMA" "PMd" "PMv")
if [ "$hemi" = "left" ]; then
nums=(1 3 5 9 11)
elif [ "$hemi" = "right" ]; then
nums=(2 4 6 10 12)
fi

# Generate individual HMAT cortical parcels
for i in ${!nums[@]}
do
roi=${rois[i]}
roi_n=${nums[i]}

# Threshold each mask
fslmaths \
${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_diff.nii.gz \
-thr ${roi_n} -uthr ${roi_n} \
${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_${h}_${roi}_mask_diff.nii.gz
done

# Write out target files (probtrackx2 classification)
find ${BASE}/atlases/HMAT/segmentations/${SUB} -name "m*${h}_*_mask_diff.nii.gz" \
> ${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_${h}_putamino-cortical_targets.txt
done

# Create subject probtrack2
mkdir -p ${BASE}/probtrackx2/putamino-cortical/${SUB}

# Initiate hemispheric putaminal-HMAT tractography
probtrackx2 \
-s ${BASE}/bedpost/${SUB}.bedpostX/merged \
-m ${BASE}/bedpost/${SUB}.bedpostX/nodif_brain_mask.nii.gz \
-x ${BASE}/MIST/tmp/${SUB}/mist_${h}_putamen_mask_diff.nii.gz \
--dir=${BASE}/probtrackx2/putaimno-cortical/${SUB} \
-o ${SUB}_${h}_putamen.nii.gz \
--seedref=${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
--avoid=${BASE}/FS/${SUB}/ventricles_csf_mask_T1p-b0.nii.gz \
--targetmasks=${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_${h}_putamino-cortical_targets.txt \
--modeuler \
--opd \
--forcedir \
--loopcheck \
--os2t

# Not sure what the outputs will look like yet! ^^^
find_the_biggest ${BASE}/probtrackx2/putamino-cortical/${SUB}/seeds_to_${hemi}_something ... 

done # Hemisphere loop
done # Subject loop
