#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Start Grafana Agents for HashiCups nodes"

if [ "${ENABLE_MONITORING}" == "true" ]; then

  ## Service Nodes

  NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

  for node in "${NODES_ARRAY[@]}"; do

    NUM="${node/-/_}""_NUMBER"
    
    for i in `seq ${!NUM}`; do

      export NODE_NAME="${node}-$((i-1))"

      log "Start monitoring for ${NODE_NAME}"

      log_debug "Generate Grafana Agent configuration."

      tee ${STEP_ASSETS}monitoring/${NODE_NAME}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://${PROMETHEUS_URI}:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: ${NODE_NAME}
      metrics_path: '/stats/prometheus'
      static_configs:
        - targets: ['127.0.0.1:19000']
    - job_name: consul-agent
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://${LOKI_URI}:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: service-mesh-apps
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE_NAME}
           __path__: /tmp/*.log
EOF

      log_debug "Stop pre-existing agent processes"
      ## Stop already running Envoy processes (helps idempotency)
      _G_AGENT_PID=`remote_exec ${NODE_NAME} "pidof grafana-agent"`
      if [ ! -z "${_G_AGENT_PID}" ]; then
        remote_exec ${NODE_NAME} "sudo kill -9 ${_G_AGENT_PID}"
      fi

      log_debug "Copy configuration"
      remote_copy ${NODE_NAME} "${STEP_ASSETS}monitoring/${NODE_NAME}.yaml" "~/grafana-agent.yaml" 

      log_debug "Start Grafana agent"
      remote_exec ${NODE_NAME} 'bash -c "grafana-agent -config.file ~/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1 &"'

    done
  done

else
  log_warn "Monitoring not enabled. Not starting Grafana agent on nodes."
fi

