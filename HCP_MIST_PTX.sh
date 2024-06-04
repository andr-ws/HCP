# Example code for MIST segmentation on HCP data

mkdir ${BASE}/MIST

touch ${BASE}/MIST/mist_subjects
echo ${BASE}/t1_preproc/${SUB} >> ${BASE}/MIST/mist_subjects

echo -e "T1","T1","T1p.nii.gz",1.0\n"T2","T2","T2p.nii.gz",1.0\n"alternate_affine","point2fslaffine.mat"\n"alternate_warp","point2fslfnirt.nii.gz" >> ${BASE}/MIST/mist_filenames

cd ${BASE}/t1_preproc
mist_1_train
mist_2_fit

# Example code for probablistic tracking

probtrackx2_gpu \
--samples=mgh_1002/mgh_1002.bedpostX/merged \
--mask=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--seed=mgh_1002/masks/l_ppn.nii.gz \
--out=ptx_out \
--targetmasks=mgh_1002/mgh_1002.bedpostX/nodif_brain_mask.nii.gz \
--xfm=mgh_1002/xfms/std2d.nii.gz \
--invxfm=mgh_1002/xfms/d2std.nii.gz \
--seedref=t1.nii.gz \
--modeuler \
--loopcheck \
--opd \
--dir=mgh_1002/probtrackx2/
