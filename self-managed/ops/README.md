# Manage permissions with access control lists (ACLs)

This repository contains companion code for the following tutorial:

- [Automate reverse proxy configuration with consul-template](https://developer.hashicorp.com/consul/tutorials/developer-configuration/consul-template-load-balancing)

> **WARNING:** the script is currently under development. Some configurations might not work as expected. **Do not test on production environments.**

The code in this repository is derived from [hashicorp-education/learn-consul-get-started-vms](https://github.com/hashicorp-education/learn-consul-get-started-vms).


### Deploy

```
cd self-managed/infrastructure/aws
```

```
terraform apply --auto-approve -var-file=../../ops/conf/automate_configuration_with_consul_template.tfvars
```