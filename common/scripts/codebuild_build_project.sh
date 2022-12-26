#!/bin/bash

BUILD_ID=$(aws codebuild start-build --project-name $1 | jq -r '.build.id')
echo $BUILD_ID

CTR=0

for (( ; ; ))
do
	sleep 15
	BUILD_STATUS=$(aws codebuild batch-get-builds --ids $BUILD_ID | jq -r '.builds[0].buildStatus')

	echo "Attempt: $(($CTR+1))"
	echo "BUILD STATUS: $BUILD_STATUS"

	if [[ "$BUILD_STATUS" = "SUCCEEDED"  ]]
	then
		break
	fi
	if [[ "$BUILD_STATUS" = "FAILED" ]]
	then
		exit 1
	fi
	if [[ "$CTR" -gt "20" ]]
	then
		exit 1
	fi
	CTR=$(($CTR+1))
done
