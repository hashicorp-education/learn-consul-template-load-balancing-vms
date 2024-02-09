#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# CONSUL_LOG_LEVEL="DEBUG"

# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Configure Listener for API Gateway"


if [ "${ENABLE_SERVICE_MESH}" == "true" ]; then

  if [ "${api_gw_NUMBER}" -gt "0" ]; then
    header2 "Generate Gateway API certificates"

    log "Generate API gateway certificate"

    pushd ${STEP_ASSETS}secrets

    # https://www.golinuxcloud.com/shell-script-to-generate-certificate-openssl/
    COMMON_NAME="hashicups.hashicorp.com"

    # Generate openssl config
    tee ./gateway-api-ca-config.cnf > /dev/null << EOT
[req]
default_bit = 4096
distinguished_name = req_distinguished_name
prompt = no

[req_distinguished_name]
countryName             = US
stateOrProvinceName     = California
localityName            = San Francisco
organizationName        = HashiCorp
commonName              = ${COMMON_NAME}
EOT

    openssl genrsa -out gateway-api-cert.key  4096 2>/dev/null
    openssl req -new -key gateway-api-cert.key -out gateway-api-cert.csr -config gateway-api-ca-config.cnf 2>/dev/null
    openssl x509 -req -days 3650 -in gateway-api-cert.csr -signkey gateway-api-cert.key -out gateway-api-cert.crt 2>/dev/null

    API_GW_KEY=`cat gateway-api-cert.key`
    API_GW_CERT=`cat gateway-api-cert.crt`

    popd

    tee ${STEP_ASSETS}config-gateway-api-certificate.hcl > /dev/null << EOT
Kind = "inline-certificate"
Name = "api-gw-certificate"

Certificate = <<EOF
${API_GW_CERT}
EOF

PrivateKey = <<EOF
${API_GW_KEY}
EOF
EOT

    consul config write ${STEP_ASSETS}config-gateway-api-certificate.hcl

    header2 "Generate API Gateway rules"

    ## todo Configuring only the first instance. Make it a cycle.
    NODE_NAME="gateway-api-0"

    PORT_NUM=8443

    tee ${STEP_ASSETS}config-gateway-api-0.hcl > /dev/null << EOF
Kind = "api-gateway"
Name = "gateway-api"

// Each listener configures a port which can be used to access the Consul cluster
Listeners = [
    {
        Port = ${PORT_NUM}
        Name = "api-gw-listener"
        Protocol = "http"
        TLS = {
            Certificates = [
                {
                    Kind = "inline-certificate"
                    Name = "api-gw-certificate"
                }
            ]
        }
    }
]
EOF

    consul config write ${STEP_ASSETS}config-gateway-api-0.hcl

    sleep 2

    tee ${STEP_ASSETS}config-gateway-api-0-http-route.hcl > /dev/null << EOF
Kind = "http-route"
Name = "hashicups-http-route"

Rules = [
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/"
        }
      }
    ]
    Services = [
      {
        Name = "hashicups-nginx"
        Weight = 100
      }
    ]
  }
]

Parents = [
  {
    Kind = "api-gateway"
    Name = "gateway-api"
    SectionName = "api-gw-listener"
  }
]
EOF

    consul config write ${STEP_ASSETS}config-gateway-api-0-http-route.hcl

    sleep 2

    header2 "Start Envoy sidecar for API GW"

    AGENT_TOKEN=${CONSUL_HTTP_TOKEN}

    log "Start new instance"
    remote_exec -o ${NODE_NAME} "/usr/bin/consul connect envoy \
                            -gateway api \
                            -register \
                            -service gateway-api \
                            -token=${AGENT_TOKEN} \
                            -envoy-binary /usr/bin/envoy \
                            ${ENVOY_EXTRA_OPT} -- -l ${ENVOY_LOG_LEVEL} > /tmp/api-gw-proxy.log 2>&1 &"

  else
    log_warn "Consul service mesh is enabled but no API Gateway is deployed."  
  fi

else

  log_warn "Consul service mesh is not configured. Skipping API Gateway configuration."

fi