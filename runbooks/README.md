# Runbooks for Consul scenarios


This folder contains the available runbooks for the scenarios present in the repository.

Runbooks are automatically generated using the `solve_scenario.sh` and `validate_scenario.sh` present in the scenario folder.


## Automatically Generate runbooks

Runbooks get automatically generated for scenarios having the `solve_scenario` option set.

```hcl
## Using `solve_scenario.sh` to solve the scenario and `validate_scenario.sh`
## to validate the solution.
solve_scenario = true
```

When this option is set the `solve_scenario.sh` and `validate_scenario.sh` are ran at the end of the provision and are saved in the `/home/admin/solve_runbook.md` file on the Bastion Host.


## Manually Generate Runbooks

Scenarios that have the `solve_scenario.sh` and `validate_scenario.sh` scripts present in the scenario folder, generate a `solve.sh` script that runs all the commands necessary to solve the scenario and produce the `/home/admin/solve_runbook.md` file on the Bastion Host.

This is useful to test is the runbooks are still valid.

* **AWS**

  ```shell-session
  ssh -i certs/id_rsa.pem admin@`terraform output -raw ip_bastion` 'assets/scenario/scripts/solve.sh'                 
  ```

* **Docker**

  ```shell-session
  ssh -i images/base/certs/id_rsa admin@localhost -p 2222 'assets/scenario/scripts/solve.sh'
  ```

## Retrieve Runbooks from Bastion Host

To retrieve a runbook from the Bastion Host you can use the `scp` command.

* **AWS**

  ```shell-session
  scp -i certs/id_rsa.pem admin@`terraform output -raw ip_bastion`:/home/admin/solve_runbook.md solve_runbook.md                    
  ```

* **Docker**

  ```shell-session
  scp -i images/base/certs/id_rsa -P 2222 admin@localhost:/home/admin/solve_runbook.md solve_runbook.md
  ```

> **Note:** the command copies the md file in the current folder. Change the file path to change its destination.
