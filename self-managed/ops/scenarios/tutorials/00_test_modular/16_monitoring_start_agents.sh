#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Start Grafana Agents for Consul Nodes"

if [ "${ENABLE_MONITORING}" == "true" ]; then

  ## Consul servers

  for i in `seq 0 "$((SERVER_NUMBER-1))"`; do
    log "Start monitoring for consul-server-$i"
  done

  ## Gateways

  ### API Gateways

  for i in `seq ${api_gw_NUMBER}`; do

    # log_warn "gateway-api-$((i-1))"
    NODE_NAME="gateway-api-$((i-1))"

    log "Start monitoring for ${NODE_NAME}"
  done

  ### Mesh Gateways

  for i in `seq ${mesh_gw_NUMBER}`; do

    # log_warn "gateway-api-$((i-1))"
    NODE_NAME="gateway-mesh-$((i-1))"

    log "Start monitoring for ${NODE_NAME}"
  done

  ### Terminating Gateways

  for i in `seq ${term_gw_NUMBER}`; do

    # log_warn "gateway-api-$((i-1))"
    NODE_NAME="gateway-terminating-$((i-1))"

    log "Start monitoring for ${NODE_NAME}"
  done

  ## Consul ESM

  for i in `seq ${consul_esm_NUMBER}`; do

    # log_warn "gateway-api-$((i-1))"
    NODE_NAME="consul-esm-$((i-1))"

    log "Start monitoring for ${NODE_NAME}"
  done

  ## Service Nodes

  NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

  for node in "${NODES_ARRAY[@]}"; do

    NUM="${node/-/_}""_NUMBER"
    
    for i in `seq ${!NUM}`; do

      export NODE_NAME="${node}-$((i-1))"

      log "Start monitoring for ${NODE_NAME}"
    done
  done

else
  log_warn "Monitoring not enabled. Not starting Grafana agent on nodes."
fi

