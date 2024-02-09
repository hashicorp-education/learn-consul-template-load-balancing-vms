#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"


# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Configure External Services"

if [ "${EMS_FOR_MONITORING}" == "true" ]; then

  if [ "${ENABLE_MONITORING}" == "true" ]; then

    header2 Registering Monitoring suite as external services

    mkdir -p "${STEP_ASSETS}external-services"

    log "Create external service definition"

    MONITORING_ARRAY=( "grafana:3000" "loki:3100" "mimir:8080" )

    for node in "${MONITORING_ARRAY[@]}"; do
      _svc_name=`echo ${node} | sed 's/:.*//'`
      _svc_port=`echo ${node} | sed 's/.*://'`
      _node_ip=`dig +short ${_svc_name}`

      tee ${STEP_ASSETS}external-services/${_svc_name}.json > /dev/null << EOF
{
  "Datacenter": "$CONSUL_DATACENTER",
  "Node": "${_svc_name}-node",
  "ID": "`cat /proc/sys/kernel/random/uuid`",
  "Address": "${_node_ip}",
  "NodeMeta": {
    "external-node": "true",
    "external-probe": "true"
  },
  "Service": {
    "ID": "${_svc_name}-1",
    "Service": "${_svc_name}",
    "Tags": [
      "monitoring"
    ],
    "Address": "${_node_ip}",
    "Port": ${_svc_port}
  }
}
EOF

    done

# ,
#   "Checks": [{
#     "CheckID": "service:${_svc_name}-1",
#     "Name": "${_svc_name} check",
#     "Status": "passing",
#     "ServiceID": "${_svc_name}-1",
#     "Definition": {
#       "TCP": "${_node_ip}:${_svc_port}",
#       "Interval": "5s",
#       "Timeout": "1s",
#       "DeregisterCriticalServiceAfter": "30s"
#      }
#   }]

    log "Register service"

    for i in `find ${STEP_ASSETS}external-services/*.json`; do

      curl --silent \
        --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
        --connect-to server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443:consul-server-0:8443 \
        --cacert ${CONSUL_CACERT} \
        --data @$i \
        --request PUT \
        https://server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443/v1/catalog/register

    done
  fi
fi

if [ "${consul_esm_NUMBER}" -gt "0" ]; then

  log_debug "Found ESM nodes, installing consul-esm on them."

  ## [cmd] [script] download_consul_esm.sh
  ## [ ] move service definition map outside
  log -l WARN -t '[SCRIPT]' "Download Consul-ESM on edge nodes"
  execute_supporting_script "download_consul_esm.sh"

  ## At this point we expect to have a consul-esm binary into /home/admin/bin

  BIN_FILE=`find /home/admin/bin | grep consul-esm | sort -r -V | head -1`

  if [ -f "${BIN_FILE}" ]; then
    log_debug "Consul-esm downloaded at ${BIN_FILE}"

    for i in `seq ${consul_esm_NUMBER}`; do
      
      NODE_NAME="consul-esm-$((i-1))"

      log "Installing ESM on ${NODE_NAME}"

    done

  else
    log_err "No file found, not installing."
  fi

else

  log_warn "No Consul ESM node found. No ESM available for scenario."

fi
