# Base Scenario

The base scenario deploys a Consul datacenter using Consul agents.

The flow to create a Consul datacenter is the following:

- Operator Environment
- Consul Servers [ `consul-server-*.node.dc1.consul`]
  - Generate secrets (gossip encryption key, CA, server certificates) 
  - Create Consul configuration (gossip encryption, TLS, ACL `default=deny`)
  - Start Consul server agents
  - Bootstrap ACLs
  - Create tokens
  - Assign tokens to Servers
- Consul clients
    - Generate secrets (ACL tokens)
    - Create Consul configuration
    - Start Consul client agents
- DNS Configuration
    - Configure DNS for VMs to use Consul


> ⚠️ The script for base scenario **does not start** Envoy sidecars, `consul-esm`, `consul-template`, HashiCups service instances. 

## Consul Clients

Consul client VMs can perform different roles in a Consul datacenter and are logically split in the following types:

- Gateways
  - API Gateways        [ `gateway-api-*.node.dc1.consul` ]
  - MESH Gateways       [ `gateway-mesh-*.node.dc1.consul` ]
  - Terminating Gateway [ `gateway-terminating-*.node.dc1.consul` ]
- Consul ESM nodes      [ `consul-esm-*.node.dc1.consul` ]
- HashiCups service nodes
  - DB       [ `hashicups-db-*.node.dc1.consul` ]
  - API      [ `hashicups-api-*.node.dc1.consul` ]
  - Frontend [ `hashicups-frontend-*.node.dc1.consul` ]    
  - NGINX    [ `hashicups-nginx-*.node.dc1.consul` ]    
    
## Prerequisite check

If a script named `check-prerequisites.sh` exists in the folder, it is added to the deployment script.

Check the script comments for more info on the prerequisites check for the scenario.
    