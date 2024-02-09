#!/usr/bin/env bash

#   H1 =========================================================================
##  H2 =========================================================================
### H3 =========================================================================

#   H1 =========================================================================
##  H2 -------------------------------------------------------------------------
### H3 .........................................................................

# ==============================================================================
# ------------------------------------------------------------------------------
# ..............................................................................

# ++-----------------+
# || Functions       |
# ++-----------------+

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

export MD_RUNBOOK_FILE=/home/admin/solve_runbook.md

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Manage permissions with Access Control Lists (ACLs)"

# H1 ===========================================================================
md_log "
# Manage permissions with Access Control Lists (ACLs)"
# ==============================================================================


md_log "
This is a solution runbook for the scenario deployed.
"

##  H2 -------------------------------------------------------------------------
md_log "
## Prerequisites"
# ------------------------------------------------------------------------------

md_log "
Login to the Bastion Host"

## [ux-diff] [cloud provider] UX differs across different Cloud providers 
if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

  md_log_cmd 'ssh -i images/base/certs/id_rsa admin@localhost -p 2222`
#...
admin@bastion:~$'

elif [ "${SCENARIO_CLOUD_PROVIDER}" == "aws" ]; then
  
  md_log_cmd 'ssh -i certs/id_rsa.pem admin@`terraform output -raw ip_bastion`
#...
admin@bastion:~$'

else

  log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."

  exit 245
fi

### H3 .........................................................................
md_log "
### Configure CLI to interact with Consul" 
# ..............................................................................


md_log "
Configure your bastion host to communicate with your Consul environment using the two dynamically generated environment variable files."

_RUN_CMD 'source "'${ASSETS}'scenario/env-scenario.env" && \
  source "'${ASSETS}'scenario/env-consul.env"'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error reading variables"
  exit 254
fi

## Running the source command locally for variable visibility reasons
source "${ASSETS}scenario/env-scenario.env" && \
source "${ASSETS}scenario/env-consul.env"

md_log "
After loading the needed variables, verify you can connect to your Consul 
datacenter."

_RUN_CMD 'consul members'    

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error connecting to Consul."
  exit 254
fi

##  H2 -------------------------------------------------------------------------
md_log "
## Create ACL token for ACL management"
# ------------------------------------------------------------------------------

md_log "
To manage ACL a management token is required. It is recommended to create a new Consul management token instead of reusing the bootstrap token."

_RUN_CMD -o json 'consul acl token create \
  -description="SVC HashiCups API token" \
  --format json \
  -policy-name="global-management" | tee '${STEP_ASSETS}'secrets/acl-token-management.json'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating Token for hashicups-api service."
  exit 254
fi

md_log "
Use the newly generated token to perform the remaining operations."

_RUN_CMD 'export CONSUL_HTTP_TOKEN=`cat '${STEP_ASSETS}'secrets/acl-token-management.json | jq -r ".SecretID"`'
## Exporting variables needs to be done also outside the _RUN_CMD commands. Otherwise environment will not pick them.
export CONSUL_HTTP_TOKEN=`cat ${STEP_ASSETS}secrets/acl-token-management.json | jq -r ".SecretID"`

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Token file not found."
  exit 254
fi

##  H2 -------------------------------------------------------------------------
md_log "
## Create ACL configuration for Consul agent"
# ------------------------------------------------------------------------------

md_log "
Consul provides a fine grained set of permissions to manage your Consul nodes and services. 
In this scenario you are going to create ACLs tokens to 
register a new Consul client node in a Consul datacenter and to 
register a service in Consul service mesh."

md_log '
For this purpose the scenario comes with an empty VM, named `hashicups-api-1` that will be used for the test.'


md_log '
When configuring a Consul agent, there is a section in the configuration that permits you to specify ACL tokens to be used by the agent.'

md_log_cmd -s hcl -p '
...
acl {
  tokens {
    agent  = "<Consul agent token>"
    default  = "<Consul default token>"
    config_file_service_registration = "<Consul service registration token>"
  }
}
...'

md_log '
The different tokens are used for different operation performed by the Consul agent:
- `agent` - Used for clients and servers to perform internal operations. This token must at least have write access to the node name it will register as in order to set any of the node-level information in the catalog.
- `default` - Used for the default operations when `agent` token is not provided and for the endpoints that do not permit a token being passed. This will be used for the DNS interface of the Consul agent.
- `config_file_service_registration` - Specifies the ACL token the agent uses to register services and checks. This token needs write permission to register all services and checks defined in this agent'"'"'s configuration.'

### H3 .........................................................................
md_log '
### Generate `default` token' 
# ..............................................................................

md_log '
The scenario already contains a policy used to generate the default token for the other nodes that is already suitable for the node default token.
The policy is named `acl-policy-dns`.
'


_RUN_CMD -o hcl "consul acl policy read -name acl-policy-dns"

md_log '
The policy guarantees read access to all services and nodes to permit DNS query to work. It also includes read permissions for prepared queries and agent metrics endpoints.'

md_log '
Generate a new token using the `acl-policy-dns` policy.'

_RUN_CMD -o json 'consul acl token create \
  -description="hashicups-api-1 default token" \
  --format json \
  -policy-name="acl-policy-dns" | tee '${STEP_ASSETS}'secrets/acl-token-default-hashicups-api-1.json'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating default token for hashicups-api-1"
  exit 254
fi

### H3 .........................................................................
md_log '
### Generate `agent` token' 
# ..............................................................................

md_log '
This token must at least have write access to the node name it will register as in order to set any of the node-level information in the catalog.
'

md_log '
Consul provides a convenient shortcut to generate `agent` tokens for Consul nodes. You can use a `node-identity`.
Node identities enable you to quickly construct policies for nodes, rather than manually creating identical polices for each node.'

md_log_cmd -s hcl -p '
# Allow the agent to register its own node in the Catalog and update its network coordinates
node "<node name>" {
  policy = "write"
}

# Allows the agent to detect and diff services registered to itself. This is used during
# anti-entropy to reconcile difference between the agents knowledge of registered
# services and checks in comparison with what is known in the Catalog.
service_prefix "" {
  policy = "read"
}'

md_log '
Generate a new token for `hashicups-api-1` using `node-identity`'

_RUN_CMD -o json 'consul acl token create \
  -description="hashicups-api-1 agent token" \
  --format json \
  -node-identity="hashicups-api-1:'${CONSUL_DATACENTER}'" | tee '${STEP_ASSETS}'secrets/acl-token-agent-hashicups-api-1.json'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating agent token for hashicups-api-1."
  exit 254
fi

### H3 .........................................................................
md_log '
### Generate `config_file_service_registration` token' 
# ..............................................................................

md_log '
This token needs write permission to register all services and checks defined in this agent'"'"'s configuration.'

md_log '
Consul provides a convenient shortcut to generate `config_file_service_registration` tokens for Consul nodes. You can use a `service-identity`.
Service identities enable you to quickly construct policies for services, rather than creating identical polices for each service.'

md_log_cmd -s hcl -p '
# Allow the service and its sidecar proxy to register into the catalog.
service "<service name>" {
    policy = "write"
}
service "<service name>-sidecar-proxy" {
    policy = "write"
}

# Allow for any potential upstreams to be resolved.
service_prefix "" {
    policy = "read"
}
node_prefix "" {
    policy = "read"
}
'

md_log '
Generate a new token for `hashicups-api-1` using `node-identity`.'

_RUN_CMD -o json 'consul acl token create \
  -description="hashicups-api-1 config_file_service_registration token" \
  --format json \
  -service-identity="hashicups-api:'${CONSUL_DATACENTER}'" | tee '${STEP_ASSETS}'secrets/acl-token-svc-hashicups-api-1.json'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating config_file_service_registration token for hashicups-api-1."
  exit 254
fi

md_log '
Verify all tokens are now created and the files are present in the `assets/` folder.'

_RUN_CMD -o plaintext 'ls ~/assets/scenario/conf/secrets/ | grep hashicups-api-1'

### H3 .........................................................................
md_log '
### Generate Consul agent ACL configuration section'
# ..............................................................................

md_log '
With the three tokens you created, generate the Consul agent ACL configuration.'

_RUN_CMD 'tee /home/admin/assets/scenario/conf/hashicups-api-1/agent-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "`cat '${STEP_ASSETS}'secrets/acl-token-agent-hashicups-api-1.json | jq -r ".SecretID"`"
    default  = "`cat '${STEP_ASSETS}'secrets/acl-token-default-hashicups-api-1.json | jq -r ".SecretID"`"
    config_file_service_registration = "`cat '${STEP_ASSETS}'secrets/acl-token-svc-hashicups-api-1.json | jq -r ".SecretID"`"
  }
}
EOF
'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating configuration file."
  exit 254
fi

##  H2 -------------------------------------------------------------------------
md_log "
## Generate hashicups-api service configuration"
# ------------------------------------------------------------------------------

md_log '
Generate `hashicups-api` service configuration.'

_RUN_CMD 'tee /home/admin/assets/scenario/conf/hashicups-api-1/svc-hashicups-api.hcl > /dev/null << EOF
## -----------------------------
## svc-hashicups-api.hcl
## -----------------------------
service {
  name = "hashicups-api"
  id = "hashicups-api-1"
  tags = [ "inst_1" ]
  port = 8081

  token = "`cat '${STEP_ASSETS}'secrets/acl-token-svc-hashicups-api-1.json | jq -r ".SecretID"`"

  connect {
    sidecar_service {
        proxy {
          upstreams = [
            {
              destination_name = "hashicups-db"
              local_bind_port = 5432
            }
          ]
        }
     }
  }

  checks =[
  {
  id =  "check-hashicups-api.public.http",
  name = "hashicups-api.public  HTTP status check",
  service_id = "hashicups-api-1",
  http  = "http://localhost:8081/health",
  interval = "5s",
  timeout = "5s"
  },
  {
    id =  "check-hashicups-api.public",
    name = "hashicups-api.public status check",
    service_id = "hashicups-api-1",
    tcp  = "localhost:8081",
    interval = "5s",
    timeout = "5s"
  },
  {
    id =  "check-hashicups-api.product",
    name = "hashicups-api.product status check",
    service_id = "hashicups-api-1",
    tcp  = "localhost:9090",
    interval = "5s",
    timeout = "5s"
  },
  {
    id =  "check-hashicups-api.payments",
    name = "hashicups-api.payments status check",
    service_id = "hashicups-api-1",
    tcp  = "localhost:8080",
    interval = "5s",
    timeout = "5s"
  }]
}
EOF
'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating configuration file."
  exit 254
fi

##  H2 -------------------------------------------------------------------------
md_log '
## Start Consul on hashicups-api-1'
# ------------------------------------------------------------------------------

md_log '
The scenario contains a basic Consul configuration for the node.'

_RUN_CMD -o plaintext 'ls /home/admin/assets/scenario/conf/hashicups-api-1'

md_log '
Copy the configuration on the remote node.'

_RUN_CMD 'scp -r -i '${SSH_CERT}' /home/admin/assets/scenario/conf/hashicups-api-1/* admin@hashicups-api-1:/etc/consul.d/'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error copying configuration file to the remote node."
  exit 254
fi

_CONNECT_TO hashicups-api-1

md_log '
Verify the files got copied correctly on the VM.'

_RUN_CMD -r hashicups-api-1 -o hcl "ls /etc/consul.d"

## =========== xxx =========== xxx =========== xxx =========== xxx =========== #
md_log '
Start Consul agent.'

# _RUN_CMD -b -r hashicups-api-1 '
#   /usr/bin/consul agent \
#   -retry-join=consul \
#   -log-file=/tmp/consul-client \
#   -config-dir=/etc/consul.d > /tmp/consul-client.log 2>&1 &'

## [bug] Running commands with output redirect seems to fail
## Running using remote_exec to workaround the runbook.
## Investigate why process hangs (check output redirect and ssh session)
_command='/usr/bin/consul agent \
  -retry-join=consul \
  -log-file=/tmp/consul-client \
  -config-dir=/etc/consul.d > /tmp/consul-client.log 2>&1 &'

md_log_cmd "
${_command}"

remote_exec -o hashicups-api-1 "${_command}"

# _RUN_CMD -b -r hashicups-api-1 '
#   nohup \
#   /usr/bin/consul agent \
#   -retry-join=consul \
#   -log-file=/tmp/consul-client \
#   -config-dir=/etc/consul.d > /tmp/consul-client.log 2>&1 &'

# _RUN_CMD -b -r hashicups-api-1 '
#   nohup \
#   /usr/bin/consul agent \
#   -retry-join=consul \
#   -log-file=/tmp/consul-client \
#   -config-dir=/etc/consul.d > /tmp/consul-client.log &>/dev/null &'


## =========== xxx =========== xxx =========== xxx =========== xxx =========== #

## [bug] Running remote commands that require output redirect and 
## variables set on the remote node require some convoluted steps.

_RUN_CMD -b -r hashicups-api-1 'export _agent_token=`cat /etc/consul.d/agent-acl-tokens.hcl | grep -Po "(?<=registration = \")[^\"]+(?=\")"` && echo ${_agent_token}'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error. Token not found."
  exit 254
fi

## Exporting variables needs to be done also outside the _RUN_CMD commands. Otherwise environment will not pick them.
export _agent_token=`cat ${STEP_ASSETS}secrets/acl-token-svc-hashicups-api-1.json | jq -r ".SecretID"`

md_log '
Start Envoy sidecar proxy for hashicups-api service.'

_command='/usr/bin/consul connect envoy \
  -token=${_agent_token} \
  -envoy-binary /usr/bin/envoy \
  -sidecar-for hashicups-api-1 > /tmp/sidecar-proxy.log 2>&1 &'

echo $_command

md_log_cmd "
${_command}"

_command='/usr/bin/consul connect envoy \
  -token='${_agent_token}' \
  -envoy-binary /usr/bin/envoy \
  -sidecar-for hashicups-api-1 > /tmp/sidecar-proxy.log 2>&1 &'

remote_exec -o hashicups-api-1 "${_command}"


## =========== xxx =========== xxx =========== xxx =========== xxx =========== #

md_log '
Start `hashicups-api` service.'

_RUN_CMD -r hashicups-api-1 "~/start_service.sh local"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error. HashiCups API failed to start."
  exit 254
fi

_EXIT_FROM hashicups-api-1

## Give time to the services to settle
## [ux-diff] [cloud provider] UX differs across different Cloud providers 
if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

  sleep 10

elif [ "${SCENARIO_CLOUD_PROVIDER}" == "aws" ]; then
  
  sleep 60

else

  log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."

  exit 245
fi

##  H2 -------------------------------------------------------------------------
md_log '
## Verify service registration'
# ------------------------------------------------------------------------------

md_log '
Consul CLI'

_RUN_CMD "consul catalog services -tags"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error connecting to Consul."
  exit 254
fi

md_log '
Consul API'

_RUN_CMD -o json 'curl --silent \
   --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
   --connect-to server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443:consul-server-0:8443 \
   --cacert ${CONSUL_CACERT} \
   https://server.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}:8443/v1/catalog/service/hashicups-api | jq -r .'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error connecting to Consul."
  exit 254
fi

md_log '
Using `dig` command'

## [ux-diff] [cloud provider] UX differs across different Cloud providers 
if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

  _DNS_PORT=""

elif [ "${SCENARIO_CLOUD_PROVIDER}" == "aws" ]; then
  
  _DNS_PORT="-p 8600"

else

  log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."

  exit 245
fi

_RUN_CMD "dig @consul-server-0 ${_DNS_PORT} hashicups-api.service.${CONSUL_DATACENTER}.${CONSUL_DOMAIN}"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error connecting to Consul."
  exit 254
fi

md_log '
Notice the output reports two instances for the service.'

