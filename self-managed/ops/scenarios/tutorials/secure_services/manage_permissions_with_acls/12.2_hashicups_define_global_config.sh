#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

header2 "Create Global Config for HashiCups"

# ++-----------------+
# || Begin           |
# ++-----------------+

OUTPUT_FOLDER=${STEP_ASSETS}global/hashicups

rm -rf ${OUTPUT_FOLDER}

mkdir -p "${OUTPUT_FOLDER}"


##################
## Intentions
##################

log "Create intention configuration files"

## HASHICUPS DB

tee ${OUTPUT_FOLDER}/intention-db.hcl > /dev/null << EOF
Kind = "service-intentions"
Name = "hashicups-db"
Sources = [
  {
    Name   = "hashicups-api"
    Action = "allow"
  }
]
EOF

tee ${OUTPUT_FOLDER}/intention-db.json > /dev/null << EOF
{
  "Kind": "service-intentions",
  "Name": "hashicups-db",
  "Sources": [
    {
      "Action": "allow",
      "Name": "hashicups-api"
    }
  ]
}
EOF

## HASHICUPS API

tee ${OUTPUT_FOLDER}/intention-api.hcl > /dev/null << EOF
Kind = "service-intentions"
Name = "hashicups-api"
Sources = [
  {
    Name   = "hashicups-nginx"
    Action = "allow"
  }
]
EOF

tee ${OUTPUT_FOLDER}/intention-api.json > /dev/null << EOF
{
  "Kind": "service-intentions",
  "Name": "hashicups-api",
  "Sources": [
    {
      "Action": "allow",
      "Name": "hashicups-nginx"
    }
  ]
}
EOF

## HASHICUPS FRONTEND

tee ${OUTPUT_FOLDER}/intention-frontend.hcl > /dev/null << EOF
Kind = "service-intentions"
Name = "hashicups-frontend"
Sources = [
  {
    Name   = "hashicups-nginx"
    Action = "allow"
  }
]
EOF

tee ${OUTPUT_FOLDER}/intention-frontend.json > /dev/null << EOF
{
  "Kind": "service-intentions",
  "Name": "hashicups-frontend",
  "Sources": [
    {
      "Action": "allow",
      "Name": "hashicups-nginx"
    }
  ]
}
EOF

## HASHICUPS NGINX

tee ${OUTPUT_FOLDER}/intention-nginx.hcl > /dev/null << EOF
Kind = "service-intentions"
Name = "hashicups-nginx"
Sources = [
  {
    Name   = "gateway-api"
    Action = "allow"
  }
]
EOF

tee ${OUTPUT_FOLDER}/intention-nginx.json > /dev/null << EOF
{
  "Kind": "service-intentions",
  "Name": "hashicups-nginx",
  "Sources": [
    {
      "Action": "allow",
      "Name": "gateway-api"
    }
  ]
}
EOF


##################
## Global Config
##################

log "Create global configuration files"

tee ${OUTPUT_FOLDER}/config-global-default-hashicups-api.json > /dev/null << EOF
{
  "Kind": "service-defaults",
  "Name": "hashicups-api",
  "Protocol": "http"
}
EOF

tee ${OUTPUT_FOLDER}/config-global-default-hashicups-api.hcl > /dev/null << EOF
Kind      = "service-defaults"
Name      = "hashicups-api"
Protocol  = "http"
EOF


tee ${OUTPUT_FOLDER}/config-global-default-hashicups-nginx.json > /dev/null << EOF
{
  "Kind": "service-defaults",
  "Name": "hashicups-nginx",
  "Protocol": "http"
}
EOF

tee ${OUTPUT_FOLDER}/config-global-default-hashicups-nginx.hcl > /dev/null << EOF
Kind      = "service-defaults"
Name      = "hashicups-nginx"
Protocol  = "http"
EOF


for i in `find ${OUTPUT_FOLDER} -name "*.hcl"`; do
  consul config write $i
done
