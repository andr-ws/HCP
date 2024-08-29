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

  cp "${dir}/anat/${sub}_desc-min_proc_T1w.nii.gz" "${derivatives}/freesurfer/${sub}_T1w.nii.gz"
  cp "${dir}/anat/${sub}_desc-min_proc_T2w.nii.gz" "${derivatives}/freesurfer/${sub}_T2w.nii.gz"

  # Execute recon-all for 8 in paralell
  ls "${derivatives}/freesurfer/*T1w.nii.gz" | parallel --jobs 8 recon-all -s {.} -i {} \
  -all \
  -qcache

# Remove FreeSurfer input files
rm ${BASE}/FS/*.nii.gz

# Rename FreeSurfer directories
for DIR in ${BASE}/FS/m*.nii
do
SUB=$(basename ${DIR})
SUB=${SUB:0:8}
mv ${DIR} ${SUB}/
done
