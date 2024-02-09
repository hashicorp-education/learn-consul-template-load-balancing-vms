#! /bin/bash

# ++-----------------+
# || Functions       |
# ++-----------------+

## [feat] clean_env() a function to clean environment config
## Cleans entire environment. Removes Infrastructure.
clean_env() {

  ########## ------------------------------------------------
  header1     "CLEANING PREVIOUS SCENARIO"
  ###### -----------------------------------------------

  #   # ## Remove custom scripts
  # rm -rf ${ASSETS}scripts/*

  # ## Remove certificates 
  # rm -rf ${ASSETS}secrets/*

  # ## Remove data 
  # rm -rf ${ASSETS}data/*

  # ## Remove logs
  # # rm -rf ${LOGS}/*
  
  # ## Unset variables
  # unset CONSUL_HTTP_ADDR
  # unset CONSUL_HTTP_TOKEN
  # unset CONSUL_HTTP_SSL
  # unset CONSUL_CACERT
  # unset CONSUL_CLIENT_CERT
  # unset CONSUL_CLIENT_KEY
}

# ++-----------------+
# || Variables       |
# ++-----------------+

## Scenario Library

## [core] FLOW CRITICAL POINT !!! - Scenario PATHS configuration
## The ASSETS variable is overwritten several times during execution
## todo: Find a more elegant way to get out of this bottleneck.

## This ends up being replaced by the scenario variable when the scenario 
## file `scenario_env.env` is present.
## The new values is: `ASSETS="../assets/"`
## This is intended (and necessary) when running the `provision.sh` directly on
## the Bastion Host but it breaks the flow when running the `provision.sh`
## locally and then trying to copy the generated files on the remote bastion host. 

## Using @ASSETS_flow tag to indicate points in the code where the variable is 
## overwritten.

## Refers to the workbench folder used by the script itself.
## In this folder are kept all the dynamic files created explicitly for this 
## scenario.

if [ -z "${BASTION_HOST}" ]; then
    ## If BASTION_HOST is not set it means we are running the script locally
    # log_debug "Bastion Host is not defined. The script is going to be executed on this node."
    ASSETS="../assets/"
else 
    # log_debug "Bastion Host is ${BASTION_HOST}. The script is going to be executed remotely."
    ASSETS="../../assets/"
fi


## The assets folder should contain a scenario specific asset collection. This 
## at the moment counts as default state detection (possibly not the only factor)
## [warn] This could break flow in some cases. (Check inside/outside flows)
export SCENARIO_OUTPUT_FOLDER="${ASSETS}scenario/"

## Refers to the scenario library where the script looks for scenario files and 
## for the
SCENARIOS_FOLDER="./scenarios"

# --- GLOBAL VARS AND FUNCTIONS ---
# log_trace Importing functions from env files.
## Logging, OS checks, networking. Imported into provision.sh.
source ${SCENARIOS_FOLDER}/00_shared_functions.env
## Scenario related functions. Depends on 00_*.env. Not imported into provision.sh
source ${SCENARIOS_FOLDER}/10_scenario_functions.env
## Infrastructure related functions. Depends on 00_*.env. Not imported into provision.sh
source ${SCENARIOS_FOLDER}/20_infrastructure_functions.env
## Random functions. Mostly scenarios files and folders tools
source ${SCENARIOS_FOLDER}/30_utility_functions.env

## Scenario specific environment. Generated dynamically.
## UNCHARTED: Currently the tool supports only single scenario running.
##              Only single scenario use cases are tested at this time of 
##              development. 
## If scenario file does not exist the final script might not work.
## If this file does not exist we should fallback to local execution and print a 
## warning because the resulting scripts might not work as-is.

########## ------------------------------------------------
header0 "CONSUL SCENARIO DEPLOYMENT TOOL"
###### -----------------------------------------------

header2 "Testing environment variables for scenario"

## Infrastructure creation creates a "state file", named `scenario_env.env` with 
## variables required to locate and connect to the remote scenario. If the state 
## file is not present you are either trying to create one (via creating infra)
## or you are testing the content creation. When possible will reverse to 
## dry_run version of the function (produce output but don't apply scripts).
if [ -f "${SCENARIO_OUTPUT_FOLDER}scenario_env.env" ]; then

  ## @ASSETS_flow
  ## [warn] This operation overwrites the ASSETS variable
  ## This is intended only when BASTION_HOST is undefined.
  log_debug Importing scenario environment variables.
  source ${SCENARIO_OUTPUT_FOLDER}scenario_env.env

  export SCENARIO_OUTPUT_FOLDER="${ASSETS}scenario/"
  log_trace "export SCENARIO_OUTPUT_FOLDER=${SCENARIO_OUTPUT_FOLDER}"

else
  _NO_ENV="true"
fi

if [ "${_NO_ENV}" == "true" ]; then

  ## If there is no environment definition the scenario files might be faulty
  ## Therefore it is better to not run them but just generate them for checks.
  log_warn "No environment definition file found at ${SCENARIO_OUTPUT_FOLDER}scenario_env.env"
  _DRY_RUN="true"

else
  ## If the scenario is defined we need to determine wether the provision.sh
  ## script is being executed locally or needs a remote Bastion Host for running

  ## We made this flow automatic by checking on the BASTION_HOST env variable.
  ## The variable needs to be populated prior to the script execution to make 
  ## this choice valid.

  if [ -z "${BASTION_HOST}" ]; then
    ## If BASTION_HOST is not set it means we are running the script locally
    ## This is the case when the provision.sh script is being executed on
    ## the bastion host at the end of the infrastructure provision.
    log "Bastion Host is not defined. The script is going to be executed on this node."
    _RUN_LOCAL="true"
  else 
    log "Bastion Host is ${BASTION_HOST}. The script is going to be executed remotely."
    _RUN_LOCAL="false"
    ## In this case we also SSH based options to permit SSH connection to the
    ## Bastion Host.

    ## [core] FLOW CRITICAL POINT !!! if this breaks, connections will not work.
    ## This overrides the SSH_OPTS and SSH_CERT that were loaded from
    ## ${ASSETS}/scenario/scenario_env.env for the provision.sh workflow. 
    ## This only affects the certificate used to connect to the Bastion Host. 
    ## The SSH_CERT defined in ../assets/scenario/scenario_env.env will still be
    ## used when running the operate.sh script on BASTION_HOST.

    ## Automatically accept certificates of remote nodes and tries to connect 
    ## for 10 seconds.
    ## todo: Move this on global variables since it should be used in any case
    SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"

    ## This is how to locate SSH certificate on the Bastion Host
    ## todo: Parametrize cloud provider (or move tf_home one level up)
    ## [ux-diff] [cloud provider] UX differs across different Cloud providers
    if [ "${SCENARIO_CLOUD_PROVIDER}" == "docker" ]; then

      SSH_CERT="../infrastructure/docker/images/base/certs/id_rsa"

    elif [ "${SCENARIO_CLOUD_PROVIDER}" == "aws" ]; then
    ## [ ] [test] check if still works in AWS
    
      SSH_CERT="../infrastructure/aws/certs/id_rsa.pem"

    else 
      log_err "Cloud provider $SCENARIO_CLOUD_PROVIDER is unsupported...exiting."
      exit 245
    fi

    ## @ASSETS_flow
    ## [warn]: This operation overwrites the ASSETS variable
    ## This is intended only when BASTION_HOST is defined.

    ## If running the script from a remote machine we need to redefine the 
    ## working paths to make the scenario generation work properly.
    WORKDIR="../../"
    ASSETS="${WORKDIR}assets/"
    export SCENARIO_OUTPUT_FOLDER="${ASSETS}scenario/"
    log_trace "export SCENARIO_OUTPUT_FOLDER=${SCENARIO_OUTPUT_FOLDER}"
  fi
fi

# --------------------
# --- ENVIRONMENT ----
# --------------------

## Comma separates string of prerequisites
PREREQUISITES="docker,wget,jq,grep,sed,tail,awk"

# ++-----------------+
# || Begin           |
# ++-----------------+

## Flow control
## Check parameters
if   [ "$1" == "operate" ]; then
  ########## ------------------------------------------------
  header2     "OPERATE SCENARIO"
  log "Scenario: $2"
  ###### -----------------------------------------------
  ## Generates scenario operate file and runs it on bastion host. 
  ## Scenario file is composed from the scenario folder and is going to be 
  ## located at ${SCENARIO_OUTPUT_FOLDER}scripts/operate.sh
  ## Uses functions defined at ${SCENARIOS}/10_scenario_functions.env

  ## todo:  Clean existing environment
  ## todo:  check here for sw_clean or hw_clean
  ## For now the scenario should be safe enough to be ran multiple times on the 
  ## same host with similar output.
 
  ## Removing previous run scripts
  rm -rf ${SCENARIO_OUTPUT_FOLDER}scripts 

  ## Generate operate.sh script
  operate_dry "$2"

  ## Generate solve.sh script
  solve_dry "$2"

  ## Copy solve.sh on Bastion Host
  execute_scenario_step -copy "solve"

  ## Copy operate.sh script on Bastion Host
  ## Copy supporting scripts on Bastion Host
  ## Execute operate.sh script
  execute_scenario_step "operate"

fi

