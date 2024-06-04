# Code to compute HCP warps to MNI152nlin2009b space
# Performs initial pre-processing steps on raw images
# ANTs XFM's followed by c3d based conversion to FSL format

# Base directory
BASE=/Users/neuro-239/Desktop/HCP/
T1DIR=${BASE}T1_preproc/
T2DIR=${BASE}T2_preproc/
B0DIR=${BASE}b0_preproc/
XFMSDIR=${BASE}xfms/
MNIDIR=${BASE}MNI/

for DIR in ${T1DIR}/T1_preproc/m*
do
  SUB=$(basename ${DIR})
  MODS=("T1p" "T2p")
  mkdir -p ${XFMSDIR}${SUB}/coreg
  i=0
  # Process T1 and T2-weighted modalities
  for M in $T1DIR $T2DIR
  do
    fslreorient2std \
    ${M}${SUB}/${MODS[i]}.nii.gz \
    ${M}${SUB}/${MODS[i]}.nii.gz

    robustfov \
    -i ${M}${SUB}/${MODS[i]}.nii.gz \
    -r ${M}${SUB}/${MODS[i]}.nii.gz

    N4BiasFieldCorrection \
    -d 3 \
    -i ${M}${SUB}/${MODS[i]}.nii.gz \
    -o ${M}${SUB}/${MODS[i]}.nii.gz

    # Brain extract N4
    deepbet-cli \
    --input ${M}${SUB}/${MODS[i]}.nii.gz \
    --output ${M}${SUB}/${MODS[i]}_brain.nii.gz \
    --mask ${M}${SUB}/${MODS[i]}_brain_mask.nii.gz
    
    i=$((i+1))
  done

  # Coregister T1p & T2p
  antsRegistrationSyN.sh \
  -d 3 \
  -f ${T1DIR}${SUB}/T1p.nii.gz \
  -m ${T2DIR}${SUB}/T2p.nii.gz \
  -o ${XFMSDIR}${SUB}/coreg/${SUB}_T2p_coreg_T1p_ \
  -t r
  
  # Move warped image into T2
  mv ${XFMSDIR}${SUB}/coreg/${SUB}_T2p_coreg_T1p_Warped.nii.gz \
  ${T2DIR}${SUB}/

  # Compute structural to standard warps (MNI versions 05mm and 2mm) for probtrackx2 and MIST (respectively)
  for V in 05mm 2mm
  do
    mkdir -p ${XFMSDIR}${SUB}/norm/ANTs ${XFMSDIR}${SUB}/norm/FSL

    antsRegistrationSyN.sh \
    -d 3 \
    -f ${MNIDIR}MNI152_T1_${V}_brain.nii.gz \
    -m ${T1DIR}${SUB}/T1p_brain.nii.gz \
    -x ${MNIDIR}MNI152_T1_${V}_brain_mask.nii.gz,${T1DIR}${SUB}/T1p_brain_mask.nii.gz \
    -o ${XFMSDIR}${SUB}/norm/ANTs/${SUB}_${V}_
    
    c3d_affine_tool \
    -ref ${MNIDIR}MNI152_T1_${V}_brain.nii.gz \
    -src ${T1DIR}${SUB}/T1p_brain.nii.gz \
    -itk ${XFMSDIR}${SUB}/norm/ANTs/${SUB}_${V}_0GenericAffine.mat \
    -ras2fsl \
    -o ${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_affine.mat
    
    c3d \
    -mcs ${XFMSDIR}${SUB}/norm/ANTs/${SUB}_${V}_1Warp.nii.gz \
    -oo \
    ${XFMSDIR}${SUB}/norm/FSL/t_wx.nii.gz \
    ${XFMSDIR}${SUB}/norm/FSL/t_wy.nii.gz \
    ${XFMSDIR}${SUB}/norm/FSL/t_wz.nii.gz
    
    fslmaths \
    ${XFMSDIR}${SUB}/norm/FSL/t_wy.nii.gz \
    -mul -1 \
    ${XFMSDIR}${SUB}/norm/FSL/t_wiy.nii.gz
   
    fslmerge \
    -t \
    ${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_nonlinear.nii.gz \
    ${XFMSDIR}${SUB}/norm/FSL/t_wx.nii.gz \
    ${XFMSDIR}${SUB}/norm/FSL/t_wiy.nii.gz \
    ${XFMSDIR}${SUB}/norm/FSL/t_wz.nii.gz

    # Remove temporary xfms
    rm ${XFMSDIR}${SUB}/norm/FSL/t_*.nii.gz

    # Concatenate affine and warp xfms
    convertwarp \
    --ref=${MNIDIR}MNI152_T1_${V}_brain.nii.gz \
    --premat=${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_affine.mat \
    --warp1=${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_nonlinear.nii.gz \
    --out=${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_warp.nii.gz
  done

# Compute a diffusion to structural mapping

  epi_reg \
  --epi=${B0DIR}${SUB}/b0.nii.gz \
  --t1=${T1DIR}${SUB}/T1p.nii.gz \
  --t1brain=${T1DIR}${SUB}/T1p_brain.nii.gz \
  --out=${XFMSDIR}${SUB}/coreg/${SUB}_d_2_T1

    # Remove temporary xfms
  rm ${XFMSDIR}${SUB}/coreg/*fast*

# Compute a diffusion to standard warp (and inverse; only required for 05mm as 2mm is shape analysis)
  convertwarp \
  --ref=${MNIDIR}MNI152_T1_05mm_brain.nii.gz \
  --premat=${XFMSDIR}${SUB}/coreg/${SUB}_d_2_T1.mat \
  --warp1=${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_05mm_FSL_warp.nii.gz \
  --out=${XFMSDIR}${SUB}/norm/FSL/${SUB}_d_2_05mm_FSL_warp.nii.gz
  
  invwarp \
  --ref=${B0DIR}${SUB}/b0.nii.gz \
  --warp=${XFMSDIR}${SUB}/norm/FSL/${SUB}_d_2_05mm_FSL_warp.nii.gz \
  --out=${XFMSDIR}${SUB}/norm/FSL/${SUB}_05mm_2_d_FSL_warp.nii.gz
done
