// enable kv v2 secrets engine

resource "vault_mount" "kvv2" {
  provider = vault.hcp

  path        = "app"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_policy" "service-a" {
  provider = vault.hcp

  name = "service-a"

  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "auth/token/renew-self" {
    capabilities = ["update"]
}
EOT
}

resource "vault_token" "service-a" {
  provider = vault.hcp
  
  policies = ["service-a"]

  renewable = true
  ttl = "72h"

  # renew_min_lease = 43200
  # renew_increment = 86400
}