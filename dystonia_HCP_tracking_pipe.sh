#! /bin/bash

base=./imaging/datasets/cd
derivatives=${BASE}/derivatives
mni=MNI152NLin2009bAsym

# Anatomical landmark:


# directional VTAs
#DVTA=${BASE}/VTA/directional
#mkdir -p ${DVTA}

# Resample VTAs

for dir in ${derivatives}/leaddbs/s*; do
sub=$(basename ${dir})
mkdir -p ${dir}/stimulations/${mni}/study/resampled

for hemisphere in L R; do
# Resample VTAs to full size
flirt \
-in ${dir}/stimulations/${mni}/study/${sub}_sim-binary_model-simbio_hemi-${hemisphere}.nii \
-applyxfm \
-usesqform \
-ref ${BASE_DYS}/MNI/MNI152_T1_05mm.nii.gz \
-out ${dir}/stimulations/${mni}/study/resampled/${sub}_sim-binary_model-simbio_hemi-${hemisphere}.nii.gz \
-interp nearestneighbour

done # close hemi loop
done # close subject loop



# This will now require the segmented putamens


# Initiate tractography using warps
# Idea here is to loop through all HCP subjects for each DYT subjects VTA (L and R)
# Just need to think whether I should flip and combine for a single VTA, or run seperately and combine?

for DYS_SUB in ${BASE_DYS}/probtrackx2/s*
do
# Create probtrackx2 directory for dystonia patient
mkdir -p ${BASE}/probtrackx2/${DYS_SUB}
for HEMI in L R
do
# Seed each dystonia patients VTA for each HCP subject
for HCP_SUB in ${BASE_HCP}/xfms/m*
do

for each seed_region in ${BASE_HCP}/probtrackx2/putamino-cortical/${HCP_SUB}/seed XYZ
SEED=$(basename ${seed_region})
SEED=remove extension here

probtrackx2 \
-s ${BASE_HCP}/${HCP_SUB}/${HCP_SUB}.bedpostX/merged \
-m ${BASE_HCP}/${HCP_SUB}/${HCP_SUB}.bedpostX/nodif_brain_mask.nii.gz \
-x ${seed_region} \

-o ${SEED}_${HEMI}_05mm.nii.gz \


--dir=${BASE_DYS}/probtrackx2/${DYS_SUB} \
--xfm=${BASE_HCP}/xfms/${HCP_SUB}/norm/FSL/${HCP_SUB}_05mm-T1p-b0_affwarp.nii.gz \
--invxfm={BASE}/xfms/${NORM_SUB}/norm/FSL/${NORM_SUB}_T1p-b0-05mm_affwarp.nii.gz \

--seedref=${BASE}/MNI/MNI152_T1_05mm_brain.nii.gz \

--avoid=${BASE}/FS/${NORM_SUB}/ventricles_csf_mask_05mm.nii.gz \
--targetmasks=point/2/targets.txt \
--modeuler \
--opd \
--forcedir \
--loopcheck \
--os2t
done
	done
done
