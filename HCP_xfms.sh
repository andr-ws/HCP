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

for DIR in ${T1DIR}/m*
do
  SUB=$(basename ${DIR})
  MODS=("T1p" "T2p")
  mkdir ${XFMSDIR}${SUB}/coreg/
  mkdir -p ${XFMSDIR}${SUB}/norm/ANTs ${XFMSDIR}${SUB}/norm/FSL
  i=0
  # Process T1 and T2-weighted modalities
  for M in $T1DIR $T2DIR
  do
    fslreorient2std \
    ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz \
    ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz

    robustfov \
    -i ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz \
    -r ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz

    N4BiasFieldCorrection \
    -d 3 \
    -i ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz \
    -o ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz

    # Brain extract N4
    deepbet-cli \
    --input ${M}${SUB}/${SUB}_${MODS[i]}.nii.gz \
    --output ${M}${SUB}/${SUB}_${MODS[i]}_brain.nii.gz \
    --mask ${M}${SUB}/${SUB}_${MODS[i]}_brain_mask.nii.gz
    
    i=$((i+1))
  done

  # Coregister T1p & T2p
  antsRegistrationSyN.sh \
  -d 3 \
  -f ${T1DIR}${SUB}/${SUB}_T1p.nii.gz \
  -m ${T2DIR}${SUB}/${SUB}_T2p.nii.gz \
  -o ${XFMSDIR}${SUB}/coreg/${SUB}_T2p_coreg_T1p_ \
  -t r
  
  # Move warped image into T2
  mv ${XFMSDIR}${SUB}/coreg/${SUB}_T2p_coreg_T1p_Warped.nii.gz \
  ${T2DIR}${SUB}/

  # Compute structural to standard warps (MNI versions 05mm and 2mm) for probtrackx2 and MIST (respectively)
  for V in 05mm 2mm
  do

    antsRegistrationSyN.sh \
    -d 3 \
    -f ${MNIDIR}MNI152_T1_${V}_brain.nii.gz \
    -m ${T1DIR}${SUB}/${SUB}_T1p_brain.nii.gz \
    -x ${MNIDIR}MNI152_T1_${V}_brain_mask.nii.gz,${T1DIR}${SUB}/${SUB}_T1p_brain_mask.nii.gz \
    -o ${XFMSDIR}${SUB}/norm/ANTs/${SUB}_${V}_
    
    c3d_affine_tool \
    -ref ${MNIDIR}MNI152_T1_${V}_brain.nii.gz \
    -src ${T1DIR}${SUB}/${SUB}_T1p_brain.nii.gz \
    -itk ${XF?MSDIR}${SUB}/norm/ANTs/${SUB}_${V}_0GenericAffine.mat \
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

    # Remove intermediate nonlinear XFM (large)
    rm ${XFMSDIR}${SUB}/norm/FSL/${SUB}_T1_2_${V}_FSL_nonlinear.nii.gz
  done

# Compute a diffusion to structural mapping

  epi_reg \
  --epi=${B0DIR}${SUB}/${SUB}_b0.nii.gz \
  --t1=${T1DIR}${SUB}/${SUB}_T1p.nii.gz \
  --t1brain=${T1DIR}${SUB}/${SUB}_T1p_brain.nii.gz \
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
  --ref=${B0DIR}${SUB}/${SUB}_b0.nii.gz \
  --warp=${XFMSDIR}${SUB}/norm/FSL/${SUB}_d_2_05mm_FSL_warp.nii.gz \
  --out=${XFMSDIR}${SUB}/norm/FSL/${SUB}_05mm_2_d_FSL_warp.nii.gz
done




# Trial code for re-computing ANTs 2 FSL warps for probtrackx2 (MNI_05mm)

# I have run ANTs to obtain XFMS, and these are not provided in the below code.
# I am trying to run probtrackx2 to compute probablistic tractography in MNI space, example code for one subject is provided at the end.
# Can you help me work out why my probtrackx2 output is blank?
BASE=/Volumes/HD1/HCP
for DIR in /Volumes/HD1/HCP/xfms/m*
do
SUB=$(basename ${DIR})

epi_reg \
--epi=${BASE}/b0_preproc/${SUB}/${SUB}_b0.nii.gz \
--t1=${BASE}/T1_preproc/${SUB}/${SUB}_T1p.nii.gz \
--t1brain=${BASE}/T1_preproc/${SUB}/${SUB}_T1p_brain.nii.gz \
--out=${DIR}/coreg/${SUB}_d_2_T1

# Convert ANTs warps to FSL format
c3d_affine_tool \
                -ref ${BASE}/MNI/MNI152_05mm_brain.nii.gz \
                -src ${BASE}/T1_preproc/${SUB}/${SUB}_T1p_brain.nii.gz \
                -itk ${DIR}/norm/ANTs/${SUB}_05mm_0GenericAffine.mat \
                -ras2fsl \
                -o ${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_affine.mat

wb_command \
                -convert-warpfield -from-itk \
                ${DIR}/norm/ANTs/${SUB}_05mm_1Warp.nii.gz \
                -to-fnirt \
                ${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_warp.nii.gz \
                ${BASE}/MNI/MNI152_05mm_brain.nii.gz

convertwarp \
                --ref=${BASE}/MNI/MNI152_05mm_brain.nii.gz \
                --premat=${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_affine.mat \
                --warp1=${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_warp.nii.gz \
                --out=${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_warp.nii.gz

# Compute a diffusion to standard warp (and inverse; only required for 05mm as 2mm is shape analysis)
convertwarp \
                --ref=${BASE}/MNI/MNI152_05mm_brain.nii.gz \
                --premat=${DIR}/coreg/${SUB}_d_2_T1.mat \
                --warp1=${DIR}/norm/FSL/${SUB}_T1_2_05mm_FSL_warp.nii.gz \
                --out=${DIR}/norm/FSL/${SUB}_d_2_05mm_FSL_warp.nii.gz
  
invwarp \
                --ref=${BASE}/b0_preproc/${SUB}/${SUB}_b0.nii.gz \
                --warp=${DIR}/norm/FSL/${SUB}_d_2_05mm_FSL_warp.nii.gz \
                --out=${DIR}/norm/FSL/${SUB}_05mm_2_d_FSL_warp.nii.gz

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
