#! /bin/bash

BASE=/Volumes/HD1/dystonia/derivatives
VTA=${BASE}/lead_modelling/leaddbs/derivatives/leaddbs

# directional VTAs

DVTA=${BASE}/VTA/directional
mkdir -p ${DVTA}

# Resample directional VTAs

for ID in 30 34 51 52 53 54 55 56 58 59 60 61
do
  for hemi in L R
  do
	  flirt \
	    -in ${VTA}/sub-${ID}/stimulations/MNI152NLin2009bAsym/Study/sub-${ID}_sim-binary_model-simbio_hemi-${hemi}.nii \
	    -applyxfm \
     	    -usesqform \
	    -ref ${BASE}/MNI/MNI152_T1_05mm.nii.gz \
	    -out ${DVTA}/sub-${ID}-${hemi}.nii.gz \
     	    -interp nearestneighbour
  done
done

# Initiate tractography using warps
# Idea here is to loop through all HCP subjects for each DYT subjects VTA (L and R)
# Just need to think whether I should flip and combine for a single VTA, or run seperately and combine?

for DYT_SUB in ${BASE}/VTA/s*
do
	mkdir -p ${BASE}/probtrackx2/${DYT_SUB}
	for hemi in L R
	do
		for NORM_SUB in ${BASE}/xfms/m*
		do
			probtrackx2 \
				-s ${BASE}/${NORM_SUB}/${NORM_SUB}.bedpostX/merged \
				-m ${BASE}/${NORM_SUB}/${NORM_SUB}.bedpostX/nodif_brain_mask.nii.gz \
				-x ${BASE}/VTA/${DYT_SUB}-${hemi}.nii.gz \
				--dir=${BASE}/probtrackx2/${DYT_SUB} \
				-o ${NORM_SUB}-${hemi}.nii.gz \
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
