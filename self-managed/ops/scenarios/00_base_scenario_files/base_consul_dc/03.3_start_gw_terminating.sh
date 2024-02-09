#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Start Consul on Terminating gateways nodes"

if [ "${term_gw_NUMBER}" == 0 ]; then
  log "No Terminating Gateway node configured. Skipping."
fi

for i in `seq ${term_gw_NUMBER}`; do

  NODE_NAME="gateway-terminating-$((i-1))"

  log "Starting Consul for ${NODE_NAME}"

  mkdir -p "${STEP_ASSETS}${NODE_NAME}"

  log_debug "Copy available configuration"

  cp -r ${STEP_ASSETS}secrets/*.hcl "${STEP_ASSETS}${NODE_NAME}/"
  cp "${STEP_ASSETS}secrets/consul-agent-ca.pem" "${STEP_ASSETS}${NODE_NAME}/"

  log_debug "Generating configuration for Consul agent "

  tee ${STEP_ASSETS}${NODE_NAME}/consul.hcl > /dev/null << EOF
# -----------------------------+
# consul.hcl                   |
# -----------------------------+

server = false
datacenter = "${CONSUL_DATACENTER}"
domain = "${CONSUL_DOMAIN}" 
node_name = "${NODE_NAME}"

# Logging
log_level = "${CONSUL_LOG_LEVEL}"
enable_syslog = false

# Data persistence
data_dir = "${CONSUL_DATA_DIR}"

## Networking 
client_addr = "127.0.0.1"
bind_addr   = "{{ GetInterfaceIP \"eth0\" }}"

# Join other Consul agents
retry_join = [ "${CONSUL_RETRY_JOIN}", "consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}" ]

# DNS recursors
recursors = ["1.1.1.1"]

# Ports
ports {
  http      = 8500
  https     = -1
  # https   = 443
  grpc      = 8502
  # grpc_tls  = 8503
  grpc_tls  = -1
  dns       = 8600
}

# Enable Consul service mesh
connect {
  enabled = true
}

## Disable script checks
enable_script_checks = false
## Enable local script checks
enable_local_script_checks = true
# Enable central service config
enable_central_service_config = true

## TLS Encryption
tls {
  # defaults { }
  https {
    ca_file   = "${CONSUL_CONFIG_DIR}consul-agent-ca.pem"
    verify_incoming        = false
    verify_outgoing        = true
  }
  internal_rpc {
    ca_file   = "${CONSUL_CONFIG_DIR}consul-agent-ca.pem"
    verify_incoming        = true
    verify_outgoing        = true
    verify_server_hostname = true
  }
}

auto_encrypt {
  tls = true
}

## ACL
acl {
  enabled        = true
  # default_policy = "allow"
  default_policy = "deny"
  enable_token_persistence = true
}
EOF

  log "Generate ACL tokens"

  AGENT_TOKEN=${CONSUL_HTTP_TOKEN}
  DNS_TOK=${CONSUL_HTTP_TOKEN}

  tee ${STEP_ASSETS}${NODE_NAME}/agent-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "${AGENT_TOKEN}"
    default  = "${DNS_TOK}"
    config_file_service_registration = "${AGENT_TOKEN}"
  }
}
EOF

  log "Start Consul"

  log_debug "Clean remote node"
  remote_exec -o ${NODE_NAME} "sudo rm -rf ${CONSUL_CONFIG_DIR}* && \
                            sudo rm -rf ${CONSUL_DATA_DIR}* && \
                            sudo chmod g+w ${CONSUL_DATA_DIR}"

  ## Stop already running Consul processes
  _CONSUL_PID=`remote_exec ${NODE_NAME} "pidof consul"`
  if [ ! -z "${_CONSUL_PID}" ]; then
    remote_exec ${NODE_NAME} "sudo kill -9 ${_CONSUL_PID}"
  fi

  ## Stop already running Envoy processes (helps idempotency)
  _ENVOY_PID=`remote_exec ${NODE_NAME} "pidof envoy"`
  if [ ! -z "${_ENVOY_PID}" ]; then
    remote_exec ${NODE_NAME} "sudo kill -9 ${_ENVOY_PID}"
  fi

  log_debug "Copy configuration on client nodes"
  remote_copy ${NODE_NAME} "${STEP_ASSETS}${NODE_NAME}/*" "${CONSUL_CONFIG_DIR}"

  log_debug "Start Consul agent"

  remote_exec ${NODE_NAME} \
      "/usr/bin/consul agent \
      -log-file=/tmp/consul-client \
      -config-dir=${CONSUL_CONFIG_DIR} > /tmp/consul-client.log 2>&1 &" 

done
