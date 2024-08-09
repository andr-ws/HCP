#! /bin/bash

HOME=/Volumes/HD1/HCP

for DIR in ${HOME}/bedpost/m*
do
SUB=$(basename ${DIR})
for IMG in ${DIR}/*.nii.gz
do
echo $IMG

fslreorient2std ${IMG} ${IMG}

done
done

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
-f ${BASE}/MNI/MNI/MNI152_T1_05mm_brain.nii.gz \
-m ${BASE}/xfms/mgh_1003/coreg/mgh_1003_T1p-b0_Warped.nii.gz \
-o ${BASE}/xfms/mgh_1003/norm/ANTs/mgh_1003_T1p-b0-05mm_

# T1p_b0-MNI ANTs to FSL affine
c3d_affine_tool \
                -ref ${BASE}/MNI/MNI/MNI152_T1_05mm_brain.nii.gz \
                -src ${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
                -itk ${DIR}/norm/ANTs/${SUB}_T1p-b0-05mm_0GenericAffine.mat \
                -ras2fsl \
                -o ${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat

# T1p_b0-MNI ANTs to FSL warp
wb_command \
                -convert-warpfield -from-itk \
                ${DIR}/norm/ANTs/${SUB}_T1p-b0-05mm_1Warp.nii.gz \
                -to-fnirt \
                ${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
                ${FIXED}

# T1p_b0-MNI FSL affine + warp
convertwarp \
                --ref=${BASE}/MNI/MNI/MNI152_T1_05mm_brain.nii.gz\
                --premat=${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_affine.mat \
                --warp1=${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_warp.nii.gz \
                --out=${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz

# MNI-T1p_b0 FSL affine + warp
invwarp \
                --ref=${BASE}/b0_preproc/${SUB}/${SUB}_b0_brain.nii.gz \
                --warp=${DIR}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz \
                --out=${DIR}/norm/FSL/${SUB}_05mm-T1p-b0_affwarp.nii.gz


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
	--i ${BASE}/FS/mgh_1003/mri/aseg.nii.gz \
	--match 4 43 14 15 24 31 63 \
	--o ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask.nii.gz 

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
-x ${BASE}/xfms/mgh_1003/coreg/mgh_1003_T1p-b0_Warped_mask.nii.gz,${BASE}/FS/${SUB}/brainmask.nii.gz
-o ${BASE}/xfms/${SUB}/coreg/${SUB}_orig-T1p-b0_
-t a

antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask.nii.gz \
-r ${BASE}/xfms/mgh_1003/coreg/mgh_1003_orig-T1p-b0_Warped.nii.gz \
-o ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-n NearestNeighbor \
-t ${BASE}/xfms/mgh_1003/coreg/mgh_1003_orig-T1p-b0_0GenericAffine.mat

antsApplyTransforms \
-d 3 \
-i ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask_T1p-b0.nii.gz \
-r ${BASE}/xfms/mgh_1003/norm/ANTs/mgh_1003_T1p-b0-05mm_Warped.nii.gz \
-o ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask_05mm.nii.gz \
-n Linear \
-t ${BASE}/xfms/mgh_1003/norm/ANTs/mgh_1003_T1p-b0-05mm_1Warp.nii.gz \
-t ${BASE}/xfms/mgh_1003/norm/ANTs/mgh_1003_T1p-b0-05mm_0GenericAffine.mat

fslmaths \
${BASE}/HCP/FS/mgh_1003/mri/ventricles_csf_mask-05mm.nii.gz \
-bin \
-o ${BASE}/FS/mgh_1003/mri/ventricles_csf_mask-05mm.nii.gz




# initiate tractography using warps
probtrackx2 \
	-s ${BASE}/mgh_1003/mgh_1003.bedpostX/merged \
	-m ${BASE}/mgh_1003/mgh_1003.bedpostX/nodif_brain_mask.nii.gz \
	-x ${BASE}/VTA/sub-01/sub-01_lh_vta.nii.gz \
	-o vta_out \
	--dir=${BASE}/VTA/sub-01 \
	--xfm=${BASE}/xfms/${SUB}/norm/FSL/${SUB}_05mm-T1p-b0_affwarp.nii.gz \
	--invxfm={BASE}/xfms/${SUB}/norm/FSL/${SUB}_T1p-b0-05mm_affwarp.nii.gz \
	--seedref=${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
	--avoid=${BASE}/FS/${SUB}/ventricles_csf_mask_05mm.nii.gz \
	--targetmasks=point/2/targets.txt \
	--modeuler \
	--opd \
	--forcedir \
	--loopcheck \
	--os2t




