#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Register Consul services for HashiCups"

# export NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )
NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

for node in "${NODES_ARRAY[@]}"; do

  ## Checking the number of configured instances for the scenario.
  NUM="${node/-/_}""_NUMBER"

  if [ "${!NUM}" -gt 0 ]; then
    
    header3 "Register Consul Service for ${node}"
    
    log "Found ${!NUM} instances of ${node}"

    for i in `seq ${!NUM}`; do

      export NODE_NAME="${node}-$((i-1))"

      log "Copy Configuration on ${NODE_NAME}"
    
      remote_copy ${NODE_NAME} "${STEP_ASSETS}${NODE_NAME}/svc" "${CONSUL_CONFIG_DIR}"

      if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
        remote_exec ${NODE_NAME} "cp ${CONSUL_CONFIG_DIR}svc/service_mesh/*.hcl ${CONSUL_CONFIG_DIR}"
      else
        remote_exec ${NODE_NAME} "cp ${CONSUL_CONFIG_DIR}svc/service_discovery/*.hcl ${CONSUL_CONFIG_DIR}"
      fi

      log "Reload Configuration for ${NODE_NAME}"

      _agent_token=`cat ${STEP_ASSETS}secrets/acl-token-bootstrap.json | jq -r ".SecretID"`

      remote_exec ${NODE_NAME} "/usr/bin/consul reload -token=${_agent_token}"

      if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
        log "Start Envoy sidecar-proxy for ${NODE_NAME}"
      
        log_debug "Stop existing instances"
        _ENVOY_PID=`remote_exec ${NODE_NAME} "pidof envoy"`
        if [ ! -z ${_ENVOY_PID} ]; then
          remote_exec ${NODE_NAME} "sudo kill -9 ${_ENVOY_PID}"
        fi

        log "Start Envoy instance"
        remote_exec ${NODE_NAME} "/usr/bin/consul connect envoy \
                                -token=${_agent_token} \
                                -envoy-binary /usr/bin/envoy \
                                -sidecar-for ${NODE_NAME} \
                                ${ENVOY_EXTRA_OPT} -- -l ${ENVOY_LOG_LEVEL} > /tmp/sidecar-proxy.log 2>&1 &"
      fi

    done

  else
    log_warn "No instance found for ${node}. Leaving unconfigured."
  fi

done


#   if [ "${!NUM}" -gt 0 ]; then
    
#     header3 "Register Consul Service for ${node}"
    
#     log "Found ${!NUM} instances of ${node}"

#     if [ "${!NUM}" -gt 1 ]; then
#       log_warn "Configuring only first instance of ${node}. Ignore other instances."
#     fi
  
#     ## Even if more instances are spawned for the service, only starts service on the first one. 
#     export NODE_NAME="${node}-0"

#     log "Copy Configuration on ${NODE_NAME}"
    
#     remote_copy ${NODE_NAME} "${STEP_ASSETS}${NODE_NAME}/svc" "${CONSUL_CONFIG_DIR}"

#     if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
#       remote_exec ${NODE_NAME} "cp ${CONSUL_CONFIG_DIR}svc/service_mesh/*.hcl ${CONSUL_CONFIG_DIR}"
#     else
#       remote_exec ${NODE_NAME} "cp ${CONSUL_CONFIG_DIR}svc/service_discovery/*.hcl ${CONSUL_CONFIG_DIR}"
#     fi

#     log "Reload Configuration for ${NODE_NAME}"

#     _agent_token=`cat ${STEP_ASSETS}secrets/acl-token-bootstrap.json | jq -r ".SecretID"`

#     remote_exec ${NODE_NAME} "/usr/bin/consul reload -token=${_agent_token}"

#     if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then
#       log "Start Envoy sidecar-proxy for ${NODE_NAME}"
      
#       log_debug "Stop existing instances"
#       _ENVOY_PID=`remote_exec ${NODE_NAME} "pidof envoy"`
#       if [ ! -z ${_ENVOY_PID} ]; then
#         remote_exec ${NODE_NAME} "sudo kill -9 ${_ENVOY_PID}"
#       fi

#       log "Start Envoy instance"
#       remote_exec ${NODE_NAME} "/usr/bin/consul connect envoy \
#                                 -token=${_agent_token} \
#                                 -envoy-binary /usr/bin/envoy \
#                                 -sidecar-for ${NODE_NAME} \
#                                 ${ENVOY_EXTRA_OPT} -- -l ${ENVOY_LOG_LEVEL} > /tmp/sidecar-proxy.log 2>&1 &"
#     fi

#   else
#     log_warn "No instance found for ${node}. Leaving unconfigured."
#   fi

# done

if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then

  header3 "Apply global configuration for Consul service mesh"

  for i in `find ${STEP_ASSETS}global -name "*.hcl"`; do
    consul config write $i
  done

fi


