#!/bin/bash

JOB_ID=$(aws amplify start-job --app-id ${APP_ID} --branch-name main --job-type RELEASE | jq -r '.jobSummary.jobId')
echo "JOB_ID: $JOB_ID"

CTR=0

for (( ; ; ))
do
	sleep 15
	JOB_STATUS=$(aws amplify get-job --app-id ${APP_ID} --branch-name main --job-id ${JOB_ID} | jq -r '.job.summary.status')
  echo "JOB_STATUS: $JOB_STATUS"
	if [[ "$JOB_STATUS" = "SUCCEED"  ]]
	then
		break
	fi
	if [[ "$CTR" -gt "20" ]]
	then
		exit 1
	fi
	CTR=$(($CTR+1))
	echo $CTR
done
