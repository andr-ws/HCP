#! /bin/bash

# Code to process HCP data using recon-all

BASE=/Users/neuro-239/Desktop/HCP/
T1DIR=${BASE}T1_preproc/
FSDIR=${BASE}/FS/

mkdir ${FSDIR}
export SUBJECTS_DIR=${FSDIR}

ls ${T1DIR} | grep ^mgh > ${FSDIR}/sub.txt

for SUB in `cat ${FSDIR}/sub.txt`
do
	cp ${T1DIR}${SUB}/${SUB}_T1p_brain.nii.gz ${FSDIR}/${SUB}_T1.nii.gz
done

# Execute 8 in paralell
ls ${FSDIR}*.nii.gz | parallel --jobs 8 recon-all -s {.} -i {} \
-motioncor \
-nonuintensitycor \
-talairach \
-normalization \
-noskullstrip \
-autorecon2 \
-autorecon3 \
-qcache

# Remove T1s
rm ${FSDIR}*.nii.gz

# Rename FS dirs
for DIR in ${FSDIR}m*.nii
do
	SUB=$(basename ${DIR})
	SUB=${SUB:0:8}
	mv ${DIR} ${SUB}/
done
