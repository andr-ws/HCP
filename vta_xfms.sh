BASE=/Volumes/HD1/dystonia/derivatives
VTA=${BASE}/lead_modelling/leaddbs

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
	    -ref ${BASE}/MNI/MNI152_T1_05mm.nii.gz \
	    -out ${DVTA}/sub-${ID}-${hemi}.nii.gz
  done
done
