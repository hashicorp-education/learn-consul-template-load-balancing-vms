# Defines Consul version to install on agents
consul_version = "latest"

# Name of the Consul datacenter to deploy
consul_datacenter = "dc1"

# Name of the Consul domain
consul_domain   = "consul"

# Number of Consul servers to deploy for Consul control plane
server_number   = 1

# Number of instances for each service of Hashicups
# Scenarios will configure and start Consul in ALL service instances.
## Different scenarios will have different behaviors in the service landscape.
hc_db_number    = 1
hc_api_number   = 1
hc_fe_number    = 2
hc_lb_number    = 1

# Number of instances for each Gateway type
api_gw_number   = 0
term_gw_number  = 0
mesh_gw_number  = 0

# Number of instances for Consul ESM nodes
consul_esm_number = 0

# Decide if the datacenter has Consul service mesh enabled for services
enable_service_mesh = false

# Start instances for monitoring suite
start_monitoring_suite = false

# Register monitoring suite as external services
register_monitoring_suite = false

## Scenario configuration
scenario = "network_automation/automate_configuration_with_consul_template"

## Using `solve_scenario.sh` to solve the scenario and `validate_scenario.sh`
## to validate the solution.
solve_scenario = false

## Log level for the scenario operate scripts.
log_level = 2

