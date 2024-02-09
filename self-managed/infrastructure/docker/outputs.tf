
output "connection_string" {
  value = "ssh -i images/base/certs/id_rsa admin@localhost -p 2222"
}

output "consul_bootstrap_token" {
  value = "ssh -i images/base/certs/id_rsa admin@localhost -p 2222 'cat assets/scenario/conf/secrets/acl-token-bootstrap.json | jq -r .SecretID'"
}

output "ui_hashicups" {
  value = "http://localhost"
}

output "ui_hashicups_api_gw" {
  value = "https://localhost:9443"
}

output "ui_consul" {
  value = "https://localhost:8443"
}

output "ui_grafana" {
  value = "http://localhost:3001/d/hashicups/hashicups"
}

output "remote_ops" {
  value = "export BASTION_HOST=127.0.0.1:2222"
}
