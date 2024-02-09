#!/usr/bin/env bash

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

header1 "Monitor your application health with distributed checks"

# H1 ===========================================================================
md_log "
# Monitor your application health with distributed checks"
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
## Create ACL token for service registration"
# ------------------------------------------------------------------------------

md_log "
To register services in a Consul datacenter, when ACLs are enabled, you need a valid token with the proper permissions."

_RUN_CMD 'consul acl token create \
  -description="SVC HashiCups API token" \
  --format json \
  -service-identity="hashicups-api" | tee '${STEP_ASSETS}'secrets/acl-token-svc-hashicups-api-1.json'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error creating Token for hashicups-api service."
  exit 254
fi

md_log '
Retrieve the token from the `acl-token-svc-hashicups-api-1.json` file'


_RUN_CMD 'export CONSUL_AGENT_TOKEN=`cat '${STEP_ASSETS}'secrets/acl-token-svc-hashicups-api-1.json | jq -r ".SecretID"`'
## Exporting variables needs to be done also outside the _RUN_CMD commands. Otherwise environment will not pick them.
export CONSUL_AGENT_TOKEN=`cat ${STEP_ASSETS}secrets/acl-token-svc-hashicups-api-1.json | jq -r ".SecretID"`

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Token file not found."
  exit 254
fi

md_log "
The token will be used in the service definition file."

##  H2 -------------------------------------------------------------------------
md_log "
## Understand service configuration for Consul services"
# ------------------------------------------------------------------------------

md_log '
Service configuration is composed by two parts, service definitions and health checks definitions.'

### H3 .........................................................................
md_log '
### Service definition'
# ..............................................................................

md_log '
The service definition requires the following parameters to be defined:
- `name` - the service name to register. Multiple instances of the same service share the same service name.
- `id` - the service id. Multiple instances of the same service require a unambiguous id to be registered. 
- `tags` - [optional] - tags to assign to the service instance. Useful for blue-green deployment, canary deployment or to identify services inside Consul datacenter.
- `port` - the port your service is exposing.
- `token` - a token to be used during service registration. This is the token you created in the previous section.'

md_log '
Below an example configuration for the service definition.
'

md_log_cmd -s hcl -p '
service {
  name = "hashicups-api"
  id = "hashicups-api-1"
  tags = [ "inst_1" ]
  port = 8081
  token = "'${CONSUL_AGENT_TOKEN}'"
}'

md_log '
Read more on service definitions at [Services configuration reference](https://developer.hashicorp.com/consul/docs/services/configuration/services-configuration-reference)'

### H3 .........................................................................
md_log '
### Checks definition.'
# ..............................................................................

md_log '
Consul is able to provide distributed monitoring for your services with the use of health checks.'

md_log '
Health checks configurations are nested in the service block. They can be defined using the following parameters:
- `id` - unique string value that specifies an ID for the check.
- `name` - required string value that specifies the name of the check.
- `service_id` - specifies the ID of a service instance to associate with a service check.
- `interval` - specifies how frequently to run the check.
- `timeout` - specifies how long unsuccessful requests take to end with a timeout.'

md_log '
The other parameter required to define the check is the type.'

md_log '
Consul supports multiple check types, but for this tutorial you will use the *TCP* and *HTTP* check types.'

md_log '
A tcp check establishes connections to the specified IPs or hosts. If the check 
successfully establishes a connection, the service status is reported as `success`. 
If the IP or host does not accept the connection, the service status is reported as `critical`.'

md_log '
An example of tcp check for the hashicups-api service, listening on port `8081` is the following:'

md_log_cmd -s hcl -p '
{
  id =  "check-hashicups-api.public",
  name = "hashicups-api.public status check",
  service_id = "hashicups-api-1",
  tcp  = "localhost:8081",
  interval = "5s",
  timeout = "5s"
}'

md_log '
HTTP checks send an HTTP request to the specified URL and report the service health based on the HTTP response code.'

md_log '
An example of tcp check for the hashicups-api service, which exposes an `health` endpoint to test service status, is the following:'

md_log_cmd -s hcl -p '
{
  id =  "check-hashicups-api.public.http",
  name = "hashicups-api.public  HTTP status check",
  service_id = "hashicups-api-1",
  http  = "http://localhost:8081/health",
  interval = "5s",
  timeout = "5s"
}'

##  H2 -------------------------------------------------------------------------
md_log "
## Create service configuration for HashiCups API service"
# ------------------------------------------------------------------------------

md_log "
Create service configuration file."

_RUN_CMD 'tee /home/admin/assets/scenario/conf/hashicups-api-1/svc-hashicups-api.hcl > /dev/null << EOF
## -----------------------------
## svc-hashicups-api.hcl
## -----------------------------
service {
  name = "hashicups-api"
  id = "hashicups-api-1"
  tags = [ "inst_1" ]
  port = 8081
  token = "${CONSUL_AGENT_TOKEN}"

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

md_log '
> To distinguish the two instances you are adding the `inst_1` tag to the service definition.'


md_log '
Copy the configuration file on the `hashicups-api-1` node.'

_RUN_CMD 'scp -r -i '${SSH_CERT}' /home/admin/assets/scenario/conf/hashicups-api-1/svc-hashicups-api.hcl admin@hashicups-api-1:/etc/consul.d/svc-hashicups-api.hcl'

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error copying configuration file to the remote node."
  exit 254
fi

_CONNECT_TO hashicups-api-1

md_log '
Verify the file got copied correctly on the VM.'

_RUN_CMD -r hashicups-api-1 -o hcl "cat /etc/consul.d/svc-hashicups-api.hcl"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error. Configuration file not found on the remote node."
  exit 254
fi

md_log '
Reload Consul to apply the service configuration.'

_RUN_CMD -r hashicups-api-1 "consul reload"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error. Consul reload failed."
  exit 254
fi

md_log '
Start `hashicups-api` service.'

_RUN_CMD -r hashicups-api-1 "~/start_service.sh"

_STAT="$?"

if [ "${_STAT}" -ne 0 ];  then
  log_err "Error. HashiCups API failed to start."
  exit 254
fi

_EXIT_FROM hashicups-api-0

## Give time to the services to settle
sleep 10

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

##  H2 -------------------------------------------------------------------------
md_log '
## Verify Consul load balancing functionalities'
# ------------------------------------------------------------------------------

md_log '
When multiple instances of a service are defined, Consul DNS will automatically provide basic round-robin load balancing capabilities.'

_RUN_CMD 'for i in `seq 1 100` ; do dig @consul-server-0 '${_DNS_PORT}' hashicups-api.service.dc1.consul +short | head -1; done | sort | uniq -c'

## This tests all options, we still need to add UI checks and ideally, once public-api exposes and endpoint showing the instance we could change the test above to that one.
## Also another possible test is to stop the first instance and check HashiCups still works.
