#!/bin/bash

#!/usr/bin/env bash

## Service file to start HashiCups services in the different VM based scenarios.
## For production environments it is recommended to use systemd service files, 
## this file is more complex than needed in order to take into account all possible
## situation an HashiCups service might get started in the different use-cases.

## Possible uses:
## -----------------------------------------------------------------------------
## service.sh                       -   [Compatibility mode] Starts the service on all available interfaces  
## service.sh local                 -   [Compatibility mode] Starts the service on localhost interface
## service.sh start                 -   Starts the service using hostnames for upstream services
## service.sh start --local         -   Starts the service on localhost interface
## service.sh start --hostname      -   Starts the service using hostnames for upstream services
## service.sh start --consul        -   Starts the service using Consul service name for upstream services (using LB functionality)
## service.sh start --consul-node   -   Starts the service using Consul node name for upstream services
## service.sh stop                  -   Stops the service
## service.sh reload                -   Reload the service without changing the configuration files
## service.sh reload --local        -   Reload the service without changing the configuration files. If variables need to be set, are set on localhost.

## ----------
## Variables
## -----------------------------------------------------------------------------

SERVICE_MESH=false

LOGFILE="/tmp/database.log"

export PGDATA="/var/lib/postgresql/data"
export POSTGRES_DB="products"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="p05tgr35"
# Get latest Postgres version installed
PSQL_VERSION=`ls /usr/lib/postgresql -1 | sort -r | head`

PATH=$PATH:/usr/lib/postgresql/${PSQL_VERSION}/bin

## ----------
## Stop pre-existing instances.
## -----------------------------------------------------------------------------
echo "Stop pre-existing instances."

killall postgres >> ${LOGFILE} 2>&1 &
rm -rf ${PGDATA}/*

## -----------------------------------------------------------------------------



## ----------
## Check script command
## -----------------------------------------------------------------------------
case "$1" in
    "")
        echo "EMPTY - Start services on all interfaces."
        ;;
    "local")
        echo "LOCAL - Start services on local interface."
        SERVICE_MESH=true
        ;;
    "start")
        echo "START - Start services on all interfaces."
        case "$2" in
        ""|"--hostname")
            echo "START - Start services on all interfaces using hostnames for upstream services."
            echo "NOT APPLICABLE FOR THIS SERVICE - No Upstreams to define."
            ;;
        "--local")
            echo "START LOCAL - Start services on local interface."
            SERVICE_MESH=true
            ;;
        "--consul")
            echo "START CONSUL - Starts the service using Consul service name for upstream services (using LB functionality)."
            echo "NOT APPLICABLE FOR THIS SERVICE - No Upstreams to define."
            ;;
        "--consul-node")
            echo "START CONSUL - Starts the service using Consul node name for upstream services."
            echo "NOT APPLICABLE FOR THIS SERVICE - No Upstreams to define."
            ;;
        *) echo "$0 $1: error - unrecognized option $2" 1>&2; exit 2;;
        esac 
        ;;
    "stop")
        echo "Service instance stopped." 
        exit 0
        ;;
    "reload")
        echo "RELOAD - Start services on all interfaces."
        case "$2" in
            "")
                echo "RELOAD - Reload the service without changing the configuration files"
                echo "NOT APPLICABLE FOR THIS SERVICE - A full restart is going to be performed."
                ;;
            "--local")
                echo "RELOAD LOCAL - Reload the service without changing the configuration files. If variables need to be set, are set on localhost."
                echo "NOT APPLICABLE FOR THIS SERVICE - A full restart, on local interface, is going to be performed."
                SERVICE_MESH=true
                ;;
        
            *) echo "$0 $1: error - unrecognized option $2" 1>&2; exit 2;;
        esac
        ;;
    *) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
esac

## -----------------------------------------------------------------------------


## ----------
## Start instances.
## -----------------------------------------------------------------------------
echo "Start service instance."

## Start PostgreSQL instance (by default on loacalhost)
/usr/local/bin/docker-entrypoint.sh postgres >> ${LOGFILE} 2>&1 &

## Wait for process to startup
sleep 1

if test -f "${LOGFILE}"; then
    until grep -q "PostgreSQL init process complete; ready for start up." ${LOGFILE}; do
        echo "Postgres is still starting - sleeping ..."
        sleep 2
    done
else
    echo "Something went wrong - exiting"
    exit 1
fi

if [ "${SERVICE_MESH}" == true ]; then
    echo "DB started on local insteface"
else
    echo "Reloading config to listen on all available interfaces."

    ## Stop PostgreSQL process
    killall postgres >> ${LOGFILE} 2>&1 &
    rm ${PGDATA}/postmaster.pid >> ${LOGFILE} 2>&1 &

    sleep 2

    ## Copy correct configuration to data folder
    cp /home/admin/pg_hba.conf ${PGDATA}/pg_hba.conf

    printf "\n listen_addresses = '*' \n" >> ${PGDATA}/postgresql.conf

    ## Start PostgreSQL process
    /usr/local/bin/docker-entrypoint.sh postgres >> ${LOGFILE} 2>&1 &
fi

## -----------------------------------------------------------------------------