#! /bin/bash

BASE=/Volumes/HD1/HCP

for DIR in ${BASE}/xfms/m*
do
	SUB=$(basename ${DIR})

	mkdir -p ${BASE}/atlases/HMAT/segmentations/${SUB}

	for hemi in left right
	do

		if [ "$hemi" = "left" ]; then
    		h="L"
		elif [ "$hemi" = "right" ]; then
    		h="R"
		fi

		# MIST (T1p to b0)

		antsApplyTransforms \
		-d 3 \
		-i ${BASE}/MIST/tmp/${SUB}/mist_${hemi}_putamen_mask.nii.gz \
		-r ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
		-o ${BASE}/MIST/tmp/${SUB}/${SUB}_mist_${h}_putamen_mask_diff.nii.gz \
		-n NearestNeighbor \
		-t ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_0GenericAffine.mat

		# HMAT (MNI to b0)

		antsApplyTransforms \
		-d 3 \
		-i ${BASE}/atlases/HMAT/MNI/HMAT.nii.gz \
		-r ${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_InverseWarped.nii.gz \
		-o ${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_diff.nii.gz \
		-n NearestNeighbor \
		-t ${BASE}/xfms/${SUB}/norm/ANTs/${SUB}_T1p-b0-05mm_1InverseWarp.nii.gz

		if [ "$hemi" = "left" ]; then
    		nums=(1 3 5 9 11)
		elif [ "$hemi" = "right" ]; then
    		nums=(2 4 6 10 12)
		fi

		rois=("M1" "S1" "SMA" "PMd" "PMv")

		for i in ${!nums[@]}
		do

			roi=${rois[i]}
			roi_n=${nums[i]}

			fslmaths \
				${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_diff.nii.gz \
				-thr ${roi_n} -uthr ${roi_n} \
				${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_HMAT_${h}_${roi}_mask_diff.nii.gz
		done

		# Write out target files

		find ${BASE}/atlases/HMAT/segmentations/${SUB} -name "m*${h}_*_mask_diff.nii.gz" \
		> ${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_${h}_putamino-cortical_targets.txt
    done

		# Run probtrackx2

		mkdir -p ${BASE}/probtrackx2/putamino-cortical/${SUB}

		probtrackx2 \
		-s ${BASE}/bedpost/${SUB}.bedpostX/merged \
		-m ${BASE}/bedpost/${SUB}.bedpostX/nodif_brain_mask.nii.gz \
		-x ${BASE}/MIST/tmp/${SUB}/mist_${h}_putamen_mask_diff.nii.gz \
		--dir=${BASE}/probtrackx2/putaimno-cortical/${SUB} \
		-o ${SUB}_${h}_putamen.nii.gz \
		--seedref=${BASE}/xfms/${SUB}/coreg/${SUB}_T1p-b0_Warped.nii.gz \
		--avoid=${BASE}/FS/${SUB}/ventricles_csf_mask_T1p-b0.nii.gz \
		--targetmasks=${BASE}/atlases/HMAT/segmentations/${SUB}/${SUB}_${h}_putamino-cortical_targets.txt \
		--modeuler \
		--opd \
		--forcedir \
		--loopcheck \
		--os2t
done

	# Not sure what the outputs will look like yet! ^^^
	find_the_biggest 

