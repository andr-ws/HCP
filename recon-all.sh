#! /bin/bash

# HCP recon-all

BASE=/Users/neuro-239/Desktop/HCP/

# Create and export FreeSurfer directory
mkdir ${BASE}/FS
export SUBJECTS_DIR=${BASE}/FS

# Generate subject list
ls ${BASE}/T1_preproc | grep ^mgh > ${BASE}/FS/sub.txt

# Create a T1 in the same space as the T1p (w/o bias correction)
for SUB in `cat ${BASE}/FS/sub.txt`
do
fslreorient2std \
${BASE}/T1_preproc/${SUB}/${SUB}_T1.nii.gz \
${BASE}/FS/${SUB}_T1.nii.gz
robustfov \
-i ${BASE}/FS/${SUB}_T1.nii.gz \
-r ${BASE}/FS/${SUB}_T1.nii.gz
done

# Execute recon-all for 8 in paralell
ls ${BASE}/FS/*.nii.gz | parallel --jobs 8 recon-all -s {.} -i {} \
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
