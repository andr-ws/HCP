#! /bin/bash

BASE=/Volumes/HD1
BASE_DYS=${BASE}/dystonia/derivatives
VTA=${BASE_DYS}/lead_modelling/leaddbs/derivatives/leaddbs
BASE_HCP=${BASE}/HCP

# directional VTAs
#DVTA=${BASE}/VTA/directional
#mkdir -p ${DVTA}

# Resample VTAs

for DIR in ${VTA}/s*
do
SUB=$(basename ${DIR})
for HEMI in L R
do

mkdir -p ${BASE_DYS}/probtrackx2/${SUB}

# Resample VTAs to full size
flirt \
-in ${VTA}/${SUB}/stimulations/MNI152NLin2009bAsym/Study/${SUB}_sim-binary_model-simbio_hemi-${HEMI}.nii \
-applyxfm \
-usesqform \
-ref ${BASE_DYS}/MNI/MNI152_T1_05mm.nii.gz \
-out ${BASE_DYS}/probtrackx2/${SUB}/${SUB}_${HEMI}.nii.gz \
-interp nearestneighbour

done # close hemi loop
done # close subject loop



# This will now require the segmented putamens


# Initiate tractography using warps
# Idea here is to loop through all HCP subjects for each DYT subjects VTA (L and R)
# Just need to think whether I should flip and combine for a single VTA, or run seperately and combine?

for DYT_SUB in ${BASE_DYS}/probtrackx2/s*
do
# Create probtrackx2 directory for dystonia patient
mkdir -p ${BASE}/probtrackx2/${DYT_SUB}
for HEMI in L R
do
# Seed each dystonia patients VTA for each HCP subject
for HCP_SUB in ${BASE_HCP}/xfms/m*
do
probtrackx2 \
-s ${BASE_HCP}/${HCP_SUB}/${HCP_SUB}.bedpostX/merged \
-m ${BASE_HCP}/${HCP_SUB}/${HCP_SUB}.bedpostX/nodif_brain_mask.nii.gz \
-x ${BASE_DYS}/probtrackx2/${DYT_SUB}/${DYT_SUB}_${HEMI}.nii.gz \
--dir=${BASE}/probtrackx2/${DYT_SUB} \
-o ${HCP_SUB}-${HEMI}.nii.gz \
--xfm=${BASE}/xfms/${NORM_SUB}/norm/FSL/${NORM_SUB}_05mm-T1p-b0_affwarp.nii.gz \
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
