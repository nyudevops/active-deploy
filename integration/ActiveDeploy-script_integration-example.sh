#!/bin/bash

#********************************************************************************
# Copyright 2016 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#********************************************************************************
# Purpose: This script shows you how to call Active Deploy from a script. For 
# example, you are doing build and deployment work and you want to call 
# Active Deploy instead of the direct CF or Container commands you are using now.
# Maybe you are using Jenkins and want to call out to Active Deploy.
#
# Usage: This is no a finalized script - you will need to potentially modify 
# it to suit your own purpose: change time outs, set variables, handle conditions.
# Use it as a starting point and modify as you see fit.
#
# Questions: Please use the normal support channels
#
#********************************************************************************


# This finds what the current execution directory is
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Sets up tracing
set -x # trace steps

# Setup for Active Deploy phase times - you may or may not use these, although you probably should control how long you want it to run.

### Very fast deploy
# rampup="1m"
# test="1s"
# rampdown="1m"
# TIMEOUT_IN_MINUTES=6

### Moderate speed deploy
rampup="10m"
test="10m"
rampdown="5m"
TIMEOUT_IN_MINUTES=40

if [[ -z ${rampup} ]]; then echo "You must set rampup"; exit 1; fi
if [[ -z ${test} ]]; then echo "You must set test"; exit 1; fi
if [[ -z ${rampdown} ]]; then echo "You must set rampdown"; exit 1; fi
if [[ -z ${TIMEOUT_IN_MINUTES} ]]; then echo "You must set TIMEOUT_IN_MINUTES"; exit 1; fi

# Start the active deploy - record back the Active Deploy identification
id=$(cf active-deploy-create $old_app_name $new_app_name -u $rampup -t $test -w $rampdown --quiet)

# Get the status of deploy using id
status=$(cf active-deploy-check-status "$id" --quiet)

#Status values are listed here => https://www.ng.bluemix.net/docs/services/ActiveDeploy/index.html - Basically they are:
# Status - Description
# in_progress - The deployment is running
# paused - The deployment is paused
# completed - The deployment is completed
# rolling_back - The deployment is being rolled back to the initial phase
# rolled_back - The deployment is rolled back to the initial phase
# failed - The deployment failed; and an error message is displayed

# Loop while active deploy is in progress

# You can use the the specific Active Deploy -check-phase subcommand or poll from the script to wait for specfic phase
# This is a specific use-case probably
# cf active-deploy-check-phase "$id" --phase final --wait $(TIMEOUT_IN_MINUTES)m

# $SECONDS is a Bash built-in from the start f script execution
while [ $status = "in_progress" ] && [ $SECONDS -lt $(( TIMEOUT_IN_MINUTES*60 )) ]
do
	sleep 60
 	status=$(cf active-deploy-check-status "$id" --quiet)
done

if [[ "${update_status}" == 'paused' ]]; then
  echo "Deployment is in paused"
  # Do something here if you need to

elif [[ "${update_status}" == 'completed' ]]; then
  echo "Deployment is in completed"
  # Do something here if you need to - the deployment is completed at this point
  
elif [[ "${update_status}" == 'rolling_back' ]]; then
  echo "Deployment is in rolling_back"
  # Do something here if you need to - the deployment is being rolled back
  
elif [[ "${update_status}" == 'rolled_back' ]]; then
  echo "Deployment is in rolled_back"
  # Do something here if you need to - the deployment is now rolled back
  
elif [[ "${update_status}" == 'failed' ]]; then
  echo "Deployment failed"
  # Do something here if you need to - the deployment as failed
  
else
  echo "Deployment status is $update_status"
  # This shouldn't be a status you see because it should be one of the above

fi

# At this point use `cf delete` or `cf ic group rm` to remove the old v1 1 instance group.
