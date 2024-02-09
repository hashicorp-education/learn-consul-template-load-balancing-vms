# Modular Consul scenarios for single datacenter installation on VMs

This repository contains code for Consul tutorials in the [HashiCorp Developer](https://developer.hashicorp.com/consul) website.

Scenarios are configurable environments that make it easy to test Consul datacenter configurations and Consul features.

This repository is currently focused on ***single datacenter cofigurations***.

This repository is based on code in [hashicorp-education/learn-consul-get-started-vms](https://github.com/hashicorp-education/learn-consul-get-started-vms) and extends the concepts used there.

<div style="background-color:#f8ebcf; color:#866d42; border:1px solid #f8ebcf; padding:1em; border-radius:3px; margin:24px 0;">
  <p> ⚠️ <strong>Warning:</strong> The code in this repository is currently under development and is not intended for production use. The scenarios in this repository are intended to provide a fast way to test Consul functionalities and voluntarily use not fully secured configuration to prove that Consul can be a valid tool to start introducing high grade of security even in an insecure environment. 
</p></div>

## Deployment Flow

The scenarios are deployed using Terraform so you can deploy a scenario with a single command without thinking too much on the configuration or the Consul configuration details. 

If you are interested in Consul manual configuration needed for the scenarios in this repository, refer to the [Consul Get Started on VMs](https://developer.hashicorp.com/consul/tutorials/get-started-vms) tutorial collection.


### AWS

Instructions for the AWS based scenario will be provided by the tutorials.

### Docker 

For local testing and development it is possible to use Docker to run the scenario locally.

The Docker code is used to speed up development (Docker scenario spins up in ~2 minutes as opposed to the ~15 minutes required by a public cloud scenario) and to make sure code is as cloud provider agnostic as possible.

To get more information on how to test scenario locally using Docker refer to [Test environment locally with Docker](./docs/Docker_Local_Environment.md).

## Available scenarios

### Self-managed scenario

A self-managed scenario is a scenario where Consul is deployed manually using VMs in the same private network of the other VMs hosting the services and the other Consul datacenter components.

Available self-managed scenarios are stored under the `self-managed` folder.

```
self-managed/
├── infrastructure
│   ├── aws/
│   └── docker/
└── ops
    ├── conf/
    ├── scenarios/
    ├── provision.sh
    └── README.md
```

#### Infrastructure

The `infrastructure` folder contains Terraform code for deploying the scenario infrastructure. It is divided in folders containing the specific code for the different cloud providers.

#### Ops

The `ops` folder contains the code to configure the infrastructure deployed by Terraform.

More information over the different content of the `ops` folder is present under the folder's [README.md](./self-managed/ops/README.md).