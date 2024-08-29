#! /bin/bash

# recon-all

# Base directory structure
rawdata="${base}/rawdata"
derivatives="${base}/derivatives"

# Create and export FreeSurfer directory
mkdir "${derivatives}/freesurfer"
export SUBJECTS_DIR="${derivatives}/freesurfer"

# Generate subject list
ls ${derivatives}/data/sub-* > "${derivatives}/freesurfer/participants.txt"

# Copy a minimally pre-proc T1w MRI into the directory

find "${derivatives}/data" -type d -name 'sub-*' | sort -V | while read -r dir; do
  # extract subject-id and create directory
  sub=$(basename "${dir}")

  for modality in T1w T2w; do
    cp "${dir}/anat/${sub}_desc-min_proc_${modality}.nii.gz" "${derivatives}/freesurfer/${sub}_${modality}.nii.gz"
    gunzip "${derivatives}/freesurfer/${sub}_${modality}.nii.gz"
  done
done

# Execute recon-all for 8 in paralell (with T2w)
ls "${derivatives}/freesurfer/*T1w.nii" | parallel --jobs 8 recon-all -s {.} -i {} \
-T2 {}/T2w.nii \
-T2pial \
-all \
-qcache

# Remove freesurfer input files
rm ${BASE}/FS/*.nii.gz

# Rename freesurfer directories
find "${derivatives}/data/freesurfer" -type d -name 'sub-*' | sort -V | while read -r dir; do
  sub=$(basename ${dir})

  # remove the freesurfer extension!
  not sure how this looks yet!

  mv ${dir} ${sub}/
done
