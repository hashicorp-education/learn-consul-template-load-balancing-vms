#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Start Grafana Agents for Consul server nodes"

if [ "${ENABLE_MONITORING}" == "true" ]; then

  ## Consul servers
  for i in `seq 0 "$((SERVER_NUMBER-1))"`; do
    log "Start monitoring for consul-server-$i"

    log_debug "Generate Grafana Agent configuration for consul-server-$i "

    tee ${STEP_ASSETS}monitoring/consul-server-$i.yaml > /dev/null << EOF
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
    - job_name: consul-server
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
     - job_name: consul-server
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: consul-server-$i
           __path__: /tmp/*.log
EOF
    log_debug "Stop pre-existing agent processes"
    ## Stop already running Envoy processes (helps idempotency)
    _G_AGENT_PID=`remote_exec consul-server-$i "pidof grafana-agent"`
    if [ ! -z "${_G_AGENT_PID}" ]; then
      remote_exec consul-server-$i "sudo kill -9 ${_G_AGENT_PID}"
    fi

    log_debug "Copy configuration"
    remote_copy consul-server-$i "${STEP_ASSETS}monitoring/consul-server-$i.yaml" "~/grafana-agent.yaml" 

    log_debug "Start Grafana agent"
    remote_exec consul-server-$i 'bash -c "grafana-agent -config.file ~/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1 &"'

  done
  
else
  log_warn "Monitoring not enabled. Not starting Grafana agent on nodes."
fi

