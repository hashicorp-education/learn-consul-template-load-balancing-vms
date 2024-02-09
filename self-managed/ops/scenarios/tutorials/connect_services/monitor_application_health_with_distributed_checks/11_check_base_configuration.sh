#!/usr/bin/env bash

# ++-----------------+
# || Functions       |
# ++-----------------+

_check_value_in_range() {
    _node_name=$1
    _value=$2
    _min_value=$3
    _max_value=$4

    if (( "${_min_value}" <= "${_max_value}")); then
        if (( "${_value}" >= "${_min_value}")); then
            if (( "${_value}" <= "${_max_value}")); then
                # Value in range
                log_ok "Number of ${_node_name} is in the required range."
            else
                # Value too big
                log_warn "Too many ${_node_name} instances found. Extra instances might not be configured."
            fi
        else
            # Value too small
            log_err "Not enough ${_node_name} instances found. Scenario cannot be demonstrated."
            exit 1
        fi
    else
        # Ranges are wrong MAX < MIN
        log_err "Unable to understand if enough hashicups-db instances are present. Exiting."
        exit 255
    fi
}

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Scenario: Monitor your application health with distributed checks"

# The scenario needed to test the functionality are the following:

#  INFRASTRUCTURE
# -------------------------------------------------------
# 7 Virtual Machines
#      - Bastion Host (Always needed for all scenarios)
#      - 1 <= Consul servers <=3 (If the script reached this point this is already verified)
#      - 0 API Gateways 
#      - 0 Terminating Gateways
#      - 0 Mesh Gateways
#      - 0 Consul ESM nodes
#      - 1 DB instance
#      - 2 API instances
#      - 1 FE instance
#      - 1 NGINX instance

_hashicups_db_MIN=1
_hashicups_db_MAX=1

_hashicups_api_MIN=2
_hashicups_api_MAX=2

_hashicups_frontend_MIN=1
_hashicups_frontend_MAX=1

_hashicups_nginx_MIN=1
_hashicups_nginx_MAX=1

# SCENARIO CONFIGURATION
# -------------------------------------------------------
# - Service Discovery
# - Monitoring Suite not needed
# - Monitoring suite not registered as external services in Consul

## The requirements listed above are the necessary nequirements to test the 
## functionality. If those requirements are not met the configuration will stop
## with an error.

## If more VMs/components than the required ones are configured, the scenario 
## will perform the configuration ignoring them. The check script should issue a 
## warning log messages when un-necessary instances are detected.

## i.e. If a Mesh Gateway VM instance is configured in the `.tfvar` scenario 
## configuration file, at this point in the flow, it will be configured as a 
## Consul client agent with node name `gateway-mesh-*.node.dc1.consul`.
## Since the scenario does not require a Mesh Gateway in the use-case, the Mesh
## gateway will be ignored in the scenario and will not be configured further.

## This script tests logical infrastructure configuration only. 
## The test is performed on environment variables only.
## It assumes the base scenario configuration was already tested.

## i.e. Using the `chack_prerequisites.sh` script present in the base scenario.

header2 "Testing Infrastructure"

## Gateway instances deployed in the infrastructure will be ignored in the configuration phase.
log "Testing gateway instances."

[ ! "${api_gw_NUMBER}" == '0' ] && log_warn "Found ${api_gw_NUMBER} API Gateways  - The instances will not be configured for Consul service mesh."
[ ! "${mesh_gw_NUMBER}" == '0' ] && log_warn "Found ${mesh_gw_NUMBER} MESH Gateways - The instances will not be configured for Consul service mesh."
[ ! "${term_gw_NUMBER}" == '0' ] && log_warn "Found ${term_gw_NUMBER} Terminating Gateways - The instances will not be configured for Consul service mesh."

## Consul ESM instances deployed in the infrastructure will be ignored in the configuration phase.
log "Testing Consul NIA instances."

[ ! "${consul_esm_NUMBER}" == '0' ] && log_warn "Found ${consul_esm_NUMBER} Consul ESM nodes - The instances will not be configured for Consul datacenter."

log "Testing HashiCups service instances."

_check_value_in_range "hashicups-db" "${hashicups_db_NUMBER}" "${_hashicups_db_MIN}" "${_hashicups_db_MAX}"
_check_value_in_range "hashicups-api" "${hashicups_api_NUMBER}" "${_hashicups_api_MIN}" "${_hashicups_api_MAX}"
_check_value_in_range "hashicups-frontend" "${hashicups_frontend_NUMBER}" "${_hashicups_frontend_MIN}" "${_hashicups_frontend_MAX}"
_check_value_in_range "hashicups-nginx" "${hashicups_nginx_NUMBER}" "${_hashicups_nginx_MIN}" "${_hashicups_nginx_MAX}"


log "Testing flow variables"

[ "${ENABLE_SERVICE_MESH}" == "true" ] && log_warn "enable_service_mesh = true - Scenario is service discovery only, variable will be ignored."
[ "${ENABLE_MONITORING}" == "true" ] && log_warn "start_monitoring_suite = true - Scenario does not include monitoring, variable will be ignored."
[ "${EMS_FOR_MONITORING}" == "true" ] && log_warn "register_monitoring_suite = true - Scenario does not include monitoring, variable will be ignored."

## The scenario is Service Discovery only and does not include monitoring.

ENABLE_SERVICE_MESH=false
ENABLE_MONITORING=false
EMS_FOR_MONITORING=false
