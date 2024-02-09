#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Start services for HashiCups"

# export NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )
NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

for node in "${NODES_ARRAY[@]}"; do

  header2 "Start Service for ${node}"

  NUM="${node/-/_}""_NUMBER"
  
  for i in `seq ${!NUM}`; do

    export NODE_NAME="${node}-$((i-1))"
    
    ## [ux-diff] [cloud provider] UX differs across different Cloud providers
    if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

      log_debug "Application pre-installed. Starting."

    elif [ "${SCENARIO_CLOUD_PROVIDER}" == "aws" ]; then
      ## [ ] [test] check if still works in AWS

      log_debug "Cleaning existing version."

      ## Example:
      ## NODE_NAME        = hashicups-db-3
      ## SERVICE_NAME     = hashicups-db
      ## SERVICE_ID       = 3
      ## SCRIPT_SVC_NAME  = hashicups_db

      SCRIPT_SVC_NAME=`echo ${NODE_NAME} | awk '{split($0,a,"-"); print a[1]"_"a[2]}'`

      remote_exec ${NODE_NAME} "rm -f ~/start_service.sh" > /dev/null 2>&1
      log_debug "Deployment state cleaned"

      log_debug "Installing new version."
      remote_copy ${NODE_NAME}        ${SCENARIO_OUTPUT_FOLDER}start_${SCRIPT_SVC_NAME}.sh ~/start_service.sh

    else 
        log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."
        exit 245
    fi

    remote_exec ${NODE_NAME} "chmod +x ~/start_service.sh" > /dev/null 2>&1

    if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
      remote_exec ${NODE_NAME} "bash ~/start_service.sh local" > /dev/null 2>&1
    else
      remote_exec ${NODE_NAME} "bash ~/start_service.sh" > /dev/null 2>&1
    fi
  done
done

