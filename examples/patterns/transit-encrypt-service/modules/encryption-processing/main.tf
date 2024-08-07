resource "vault_transit_secret_backend_key" "this" {
  backend          = var.transit_path
  name             = var.test_id
  deletion_allowed = true
}

// create kubernetes resources on eks cluster

resource "kubernetes_namespace" "encrypt" {
  for_each = { for k, v in toset([var.test_id]) : k => v if strcontains(var.test_id, "0001") }

  metadata {
    name = "encrypt"
  }
}

resource "kubernetes_job" "this" {
  metadata {
    name = "transit-encrypt-${var.test_id}"
    namespace = "encrypt"
  }
  spec {
    template {
      metadata {
        labels = {
          app = "transit-encrypt"
        }
      }
      spec {
        container {
          name  = "transit-encrypt"
          image = "phantony/transit-encrypt-service:0.4"
          env {
            name = "VAULT_ADDR"
            value = var.vault_addr
          }
          env {
            name = "VAULT_TOKEN"
            value = var.vault_token
          }
          env {
            name = "VAULT_NAMESPACE"
            value = var.vault_namespace
          }
          env {
            name = "VAULT_KEY_NAME"
            value = var.test_id
          }
          env {
            name = "S3_BUCKET_NAME"
            value = var.deployment_id
          }
          env {
            name = "S3_UNENCRYPTED_FILE_PATH"
            value = "source/${var.test_file}"
          }
          resources {
            # limits = {
            #   cpu    = "0.5"
            #   memory = "4.0G"
            # }
            requests = {
              cpu    = "0.5"
              memory = "0.5G"
            }
          }
        }
      }
    }
  }
  wait_for_completion = false

  depends_on = [ 
    kubernetes_namespace.encrypt 
  ]
}