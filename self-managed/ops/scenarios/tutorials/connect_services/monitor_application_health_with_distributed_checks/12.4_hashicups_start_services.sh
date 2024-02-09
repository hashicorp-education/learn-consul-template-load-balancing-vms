#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Start services for HashiCups"

# export NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )
NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

for node in "${NODES_ARRAY[@]}"; do

## Checking the number of configured instances for the scenario.
  NUM="${node/-/_}""_NUMBER"

  if [ "${!NUM}" -gt 0 ]; then
    
    header3 "Starting ${node} service"
    
    log "Found ${!NUM} instances of ${node}"

    if [ "${!NUM}" -gt 1 ]; then
      log_warn "Configuring only first instance of ${node}. Ignore other instances."
    fi

    ## Even if more instances are spawned for the service, only starts service on the first one. 
    export NODE_NAME="${node}-0"

    _OUTPUT=""

    if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
      _OUTPUT=`remote_exec ${NODE_NAME} "bash ~/start_service.sh local 2>&1"`
      _STAT="$?"
    else
      _OUTPUT=`remote_exec ${NODE_NAME} "bash ~/start_service.sh start --consul 2>&1"`
      _STAT="$?"
    fi

    if [ "${_STAT}" -ne 0 ];  then
      log_warn "Service ${node} on ${NODE_NAME} failed to start."
    fi

  else
    log_warn "No instance found for ${node}. Leaving unconfigured."
  fi

done


