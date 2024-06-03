# Code to compute HCP warps to MNI152nlin2009b space

BASE=/Users/neuro-239/Desktop/HCP

for DIR in ${BASE}/T1_preproc/m*; do

SUB=$(basename ${DIR})

mkdir -p ${BASE}/xfms/${SUB}

# Process T1 and T2-weighted MRI

for M in T1 T2; do

# T1p is processed T1
fslreorient2std \
${BASE}/${M}_preproc/${SUB}/${M}.nii.gz \
${BASE}/${M}_preproc/${SUB}/${M}p.nii.gz

robustfov \
-i ${BASE}/${M}_preproc/${SUB}/${M}.nii.gz \
-r ${BASE}/${M}_preproc/${SUB}/${M}p.nii.gz

N4BiasFieldCorrection \
-d 3 \
-i ${BASE}/${M}_preproc/${SUB}/${M}p.nii.gz \
-o ${BASE}/${M}_preproc/${SUB}/${M}p.nii.gz

# Brain extract N4
deepbet-cli \
--input ${BASE}/${M}_preproc/${SUB}/${M}p.nii.gz \
--output ${BASE}/${M}_preproc/${SUB}/${M}p_brain.nii.gz \
--mask ${BASE}/${M}_preproc/${SUB}/${M}p_brain_mask.nii.gz

done

# Coregister T1p & T2p
antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/T1_preproc/${SUB}/T1p.nii.gz \
-m ${BASE}/T2_preproc/${SUB}/T2p.nii.gz \
-o ${BASE}/xfms/${SUB}/${SUB}_T2p_coreg_T1p_ \
-t r

mv ${BASE}/xfms/${SUB}/${SUB}_T2p_coreg_T1p_Warped.nii.gz \
${BASE}/T2_preproc/${SUB}/

# Compute structural to standard (mni2009asym - 05mm and 2mm) warp for probtrackx2 and MIST (respectively)
for V in 05mm 2mm; do

antsRegistrationSyN.sh \
-d 3 \
-f ${BASE}/MNI/MNI152_T1_${V}_brain.nii.gz \
-m ${BASE}/T1_preproc/${SUB}/T1p_brain.nii.gz \
-x ${BASE}/MNI/MNI152_T1_${V}_brain_mask.nii.gz,${BASE}/T1_preproc/${SUB}/T1p_brain_mask.nii.gz \
-o ${BASE}/xfms/${SUB}/${SUB}_${V}_

c3d_affine_tool \
-ref ${BASE}/MNI/MNI152_T1_${V}_brain.nii.gz \
-src ${BASE}/t1_preproc/${SUB}/T1p_brain.nii.gz \
-itk ${BASE}/xfms/${SUB}/${SUB}_${V}_0GenericAffine.mat \
-ras2fsl \
-o ${BASE}/xfms/${SUB}/T1_2_${V}_FSL_affine.mat

c3d \
-mcs ${BASE}/xfms/${SUB}/${SUB}_${V}_1Warp.nii.gz \
-oo \
${BASE}/xfms/${SUB}/t_wx.nii.gz \
${BASE}/xfms/${SUB}/t_wy.nii.gz \
${BASE}/xfms/${SUB}/t_wz.nii.gz

fslmaths \
${BASE}/xfms/${SUB}/t_wy.nii.gz \
-mul -1 \
${BASE}/xfms/${SUB}/t_wiy.nii.gz

fslmerge \
-t \
${BASE}/xfms/${SUB}/T1_2_${V}_FSL_nonlinear.nii.gz \
${BASE}/xfms/${SUB}/t_wx.nii.gz \
${BASE}/xfms/${SUB}/t_wiy.nii.gz \
${BASE}/xfms/${SUB}/t_wz.nii.gz

# warp_c for concatenated affine and warp (not sure how this affects things - may be able to use the fnirt warp)
convertwarp \
--ref=${BASE}/MNI/MNI152_T1_${V}_brain.nii.gz \
--premat=${BASE}/xfms/${SUB}/T1_2_${V}_FSL_affine.mat \
--warp1=${BASE}/xfms/${SUB}/T1_2_${V}_FSL_nonlinear.nii.gz \
--out=${BASE}/xfms/${SUB}/T1_2_${V}_FSL_warp.nii.gz

# Remove tmp files
rm ${BASE}/xfms/${SUB}/t_*.nii.gz \
${BASE}/xfms/t1_2_std_mni_${V}_f*.nii.gz

done

# Compute a diffusion to structural mapping

epi_reg \
--epi=${BASE}/b0_preproc/${SUB}/b0.nii.gz \
--t1=${BASE}/T1_preproc/${SUB}/T1p.nii.gz \
--t1brain=${BASE}/T1_preproc/${SUB}/T1p_brain.nii.gz \
--out=${BASE}/xfms/${SUB}/d_2_T1

# Compute a diffusion to standard warp (and inverse; only required for 05mm as 2mm is shape analysis)

convertwarp \
--ref=${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \
--premat=${BASE}/xfms/${SUB}/d_2_T1.mat \
--warp1=${BASE}/xfms/${SUB}/T1_2_05mm_FSL_warp.nii.gz \
--out=${BASE}/xfms/${SUB}/d_2_05mm_FSL_warp.nii.gz

invwarp \
--ref=${BASE}/b0_preproc/${SUB}/b0.nii.gz \
--warp=${BASE}/xfms/${SUB}/d_2_05mm_FSL_warp.nii.gz \
--out=${BASE}/xfms/${SUB}/05mm_2_d_FSL_warp.nii.gz

rm ${BASE}/xfms/${SUB}/*fast*

done

# Example code for MIST segmentation on HCP data

mkdir ${BASE}/MIST

touch ${BASE}/MIST/mist_subjects
echo ${BASE}/t1_preproc/${SUB} >> ${BASE}/MIST/mist_subjects

echo -e "T1","T1","T1p.nii.gz",1.0\n"T2","T2","T2p.nii.gz",1.0\n"alternate_affine","point2fslaffine.mat"\n"alternate_warp","point2fslfnirt.nii.gz" >> ${BASE}/MIST/mist_filenames

cd ${BASE}/t1_preproc
mist_1_train
mist_2_fit

# Example code for probablistic tracking

probtrackx2_gpu \
--samples=mgh_1002/mgh_1002.bedpostX/merged \
--mask=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--seed=mgh_1002/masks/l_ppn.nii.gz \
--out=ptx_out \
--targetmasks=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--xfm=mgh_1002/xfms/std2d.nii.gz \
--invxfm=mgh_1002/xfms/d2std.nii.gz \
--seedref=t1.nii.gz \
--modeuler \
--loopcheck \
--opd \
--dir=mgh_1002/probtrackx2/



