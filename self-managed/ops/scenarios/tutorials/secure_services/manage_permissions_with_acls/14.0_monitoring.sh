#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Monitor Consul datacenter with Grafana"

if [ "${ENABLE_MONITORING}" == "true" ]; then
    log_debug "Create monitoring folder."
    mkdir -p ${STEP_ASSETS}monitoring
fi