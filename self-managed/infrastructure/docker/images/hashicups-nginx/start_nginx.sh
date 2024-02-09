#!/bin/bash


# killall nginx 2>&1 &

if [ ! `pidof nginx | wc -w` -eq "0" ]; then kill -9 `pidof nginx`; fi

## NGINX will not start if it cannot resolve upstream DNS names.
## One of the services, hashicups-api, might take up to 10 seconds to be 
## healthy in Consul and to be resolved by Consul DNS. 
## For this reason, when running the service using service discovery and 
## Consul DNS to resolve the upstream name the script will try multiple times
## and wait between the different attemps a number of second to give Consul
## time to recognice the hashicups-api service as healthy. 
START_ATTEMPT=1
SLEEP_INTERVAL=1


## Check Parameters
if   [ "$1" == "local" ] || [ "$1" == "mesh" ]; then

    echo "Starting service on local interface."

    tee /etc/nginx/conf.d/def_upstreams.conf << EOF
upstream frontend_upstream {
    server localhost:3000;
}

upstream api_upstream {
    server localhost:8081;
}
EOF

else

    echo "Starting service on global interface."

    tee /etc/nginx/conf.d/def_upstreams.conf << EOF
upstream frontend_upstream {
    server hashicups-frontend:3000;
}

upstream api_upstream {
    server hashicups-api:8081;
}
EOF

START_ATTEMPT=5
SLEEP_INTERVAL=5

fi

for i in `seq ${START_ATTEMPT}`; do

    if [ `pidof nginx | wc -w` -eq "0" ]; then
        echo "Starting NGINX...attempt $i" 
        /usr/sbin/nginx >> /tmp/nginx.log 2>&1 &
        sleep ${SLEEP_INTERVAL}
    fi

done
