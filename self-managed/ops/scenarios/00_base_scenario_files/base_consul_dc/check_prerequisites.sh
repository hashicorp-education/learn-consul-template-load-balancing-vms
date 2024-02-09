#!/usr/bin/env bash

## This script checks conditions for the prerequisites scenario before moving to 
## the specific scenario deployment.

## Uses Consul `/v1/agent/members` API endpoint to retrieve available nodes in 
## the datacenter. The filter used is based on node names convention used in the 
## datacenter.
## Usage Example: `get_node_number_by_name gateway-api-`
get_node_number_by_name() {

  NODE_NUM=`curl --silent \
  --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
  --connect-to server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443:consul-server-0:8443 \
  --cacert ${CONSUL_CACERT} \
  --get \
  --data-urlencode filter="Name contains \"$1\"" \
  https://server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443/v1/agent/members | jq -r '. | length'`

  echo $NODE_NUM

}


## Script Prerequisites:
## Scenario environment configued in environment files.
## Consul datacenter deployed with one or more servers and all VMs configured as clients.
header "Checking prerequisites for base scenario"

## Check if environment files are available
for i in "scenario" "consul"; do
    if [[ -f "${ASSETS}scenario/env-$i.env" ]] && [[ -s "${ASSETS}scenario/env-$i.env" ]] ;  then
        log_ok "Found ${ASSETS}scenario/env-$i.env"
        source "${ASSETS}scenario/env-$i.env"
    fi
done

## Check if Consul datacenter is up
consul info > /dev/null

OUTP=$?

if [ ! "${OUTP}" -eq "0" ]; then
    # Consul info is not responding
    # Either Consul is down or ACL is not bootstrapped
    log_err "Consul info is not responding. Consul server might be down."
    exit 1
fi

## Check number of Consul servers
PEERS_NUM=`curl --silent \
  --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
  --connect-to server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443:consul-server-0:8443 \
  --cacert ${CONSUL_CACERT} \
  https://server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443/v1/status/peers | jq -r ". | length"`

log_ok "Found ${PEERS_NUM} Consul servers."


if [ ! "${PEERS_NUM}" -eq "${CONSUL_SERVER_NUMBER}" ]; then
    log_err "Not all Consul server are correctly initialized."
    exit 2
fi

## Check number of API Gateways nodes
GW_API_NUM=`get_node_number_by_name gateway-api-`
log_ok "Found ${GW_API_NUM} API Gateway nodes."

if [ ! "${GW_API_NUM}" -eq "${api_gw_NUMBER}" ]; then
    log_err "Not all API gateway nodes are correctly initialized."
    exit 3
fi

## Check number of Mesh Gateways nodes
GW_MESH_NUM=`get_node_number_by_name gateway-mesh-`
log_ok "Found ${GW_MESH_NUM} Mesh Gateway nodes."

if [ ! "${GW_MESH_NUM}" -eq "${mesh_gw_NUMBER}" ]; then
    log_err "Not all Mesh gateway nodes are correctly initialized."
    exit 4
fi

## Check number of Terminating Gateways nodes
GW_TERM_NUM=`get_node_number_by_name gateway-terminating-`
log_ok "Found ${GW_TERM_NUM} Terminating Gateway nodes."

if [ ! "${GW_TERM_NUM}" -eq "${term_gw_NUMBER}" ]; then
    log_err "Not all Terminating gateway nodes are correctly initialized."
    exit 5
fi

## Check number of Consul-ESM nodes
ESM_NUM=`get_node_number_by_name consul-esm-`
log_ok "Found ${ESM_NUM} Consul ESM nodes."

if [ ! "${ESM_NUM}" -eq "${consul_esm_NUMBER}" ]; then
    log_err "Not all Consul ESM nodes are correctly initialized."
    exit 6
fi

## CHECK HASHICUPS NODES

## Check number of hashicxups-db nodes
DB_NUM=`get_node_number_by_name hashicups-db-`
log_ok "Found ${DB_NUM} HashiCups DB nodes."

if [ ! "${DB_NUM}" -eq "${hashicups_db_NUMBER}" ]; then
    log_err "Not all HashiCups DB nodes are correctly initialized."
    exit 7
fi

## Check number of hashicxups-api nodes
API_NUM=`get_node_number_by_name hashicups-api-`
log_ok "Found ${API_NUM} HashiCups API nodes."

if [ ! "${API_NUM}" -eq "${hashicups_api_NUMBER}" ]; then
    log_err "Not all HashiCups API nodes are correctly initialized."
    exit 7
fi

## Check number of hashicxups-frontend nodes
FE_NUM=`get_node_number_by_name hashicups-frontend-`
log_ok "Found ${FE_NUM} HashiCups Frontend nodes."

if [ ! "${FE_NUM}" -eq "${hashicups_frontend_NUMBER}" ]; then
    log_err "Not all HashiCups Frontend nodes are correctly initialized."
    exit 7
fi

## Check number of hashicxups-nginx nodes
LB_NUM=`get_node_number_by_name hashicups-nginx-`
log_ok "Found ${LB_NUM} HashiCups NGINX nodes."

if [ ! "${LB_NUM}" -eq "${hashicups_nginx_NUMBER}" ]; then
    log_err "Not all HashiCups NGINX nodes are correctly initialized."
    exit 7
fi


## Dig does not work, it returns 0 even if no results are found.
## todo think of a better test for DNS configuration check.

# ## Check DNS for Nodes
# log "Check DNS for Consul client nodes."

# log_debug "Check DNS for API Gateways"
# for i in `seq ${api_gw_NUMBER}`; do
#   NODE_NAME="gateway-api-$((i-1))"

#   remote_exec -s ${NODE_NAME} "dig consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}" 
  
#   _STAT="$?"

#   if [ "${_STAT}" -ne 0 ];  then
#     log_error "DNS Error."
#     exit 254
#   fi

# done 

# log_debug "Change DNS for Mesh Gateways"

# for i in `seq ${mesh_gw_NUMBER}`; do
#   NODE_NAME="gateway-mesh-$((i-1))"
  
#   remote_exec -s ${NODE_NAME} "dig consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}"

#   _STAT="$?"

#   if [ "${_STAT}" -ne 0 ];  then
#     log_error "DNS Error."
#     exit 254
#   fi
# done 

# log_debug "Change DNS for Terminating Gateways"

# for i in `seq ${term_gw_NUMBER}`; do
#   NODE_NAME="gateway-terminating-$((i-1))"
  
#   remote_exec -s ${NODE_NAME} "dig consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}"

#   _STAT="$?"

#   if [ "${_STAT}" -ne 0 ];  then
#     log_error "DNS Error."
#     exit 254
#   fi
# done 

# log_debug "Change DNS for Consul ESM nodes"

# for i in `seq ${consul_esm_NUMBER}`; do
#   NODE_NAME="consul-esm-$((i-1))"
  
#   remote_exec -s ${NODE_NAME} "dig consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}"

#   _STAT="$?"

#   if [ "${_STAT}" -ne 0 ];  then
#     log_error "DNS Error."
#     exit 254
#   fi
# done 

# # export NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )
# NODES_ARRAY=( "hashicups-db" "hashicups-api" "hashicups-frontend" "hashicups-nginx" )

# log_debug "Change DNS for Consul Service Nodes"

# for node in "${NODES_ARRAY[@]}"; do

#   NUM="${node/-/_}""_NUMBER"
  
#   for i in `seq ${!NUM}`; do

#     NODE_NAME="${node}-$((i-1))"
    
#     remote_exec -s ${NODE_NAME} "dig consul.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}"

#     _STAT="$?"

#     if [ "${_STAT}" -ne 0 ];  then
#       log_error "DNS Error."
#       exit 254
#     fi
#   done
# done

# log_ok "DNS working for all client nodes."

log_ok "All prerequisites check passed correctly."