#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Installing services for HashiCups"

# export NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )
NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

for node in "${NODES_ARRAY[@]}"; do

  log "Install Service for ${node} nodes"

  NUM="${node/-/_}""_NUMBER"
  
  for i in `seq ${!NUM}`; do

    export NODE_NAME="${node}-$((i-1))"
    
    ## [ux-diff] [cloud provider] UX differs across different Cloud providers
    if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

      log_debug "Application pre-installed."

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
      remote_copy ${NODE_NAME} ${SCENARIO_OUTPUT_FOLDER}start_${SCRIPT_SVC_NAME}.sh ~/start_service.sh
      remote_exec ${NODE_NAME} "chmod +x ~/start_service.sh > /dev/null 2>&1"

    else 
        log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."
        exit 245
    fi

  done
done

