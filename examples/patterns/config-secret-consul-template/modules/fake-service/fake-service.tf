// create kv on consul cluster

resource "consul_keys" "service-a" {
  provider = consul.hcp

  key {
    path   = "app/service-a/logging/loglevel"
    value  = "info"
    delete = true
  }
}

// create secret on vault cluster

resource "vault_kv_secret_v2" "service-a" {
  provider = vault.hcp

  mount                      = "app"
  name                       = "service-a/database"
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    username  = "admin",
    password  = "Passw0rd1!"
  }
  )
}


// create kubernetes resources on eks cluster

resource "kubernetes_namespace" "fake-service" {
  provider = kubernetes.eks

  metadata {
    name = "fake-service"
  }
}

resource "kubernetes_service" "service-a" {
  provider = kubernetes.eks

  metadata {
    name = "service-a"
    namespace = "fake-service"
    labels = {
        app = "service-a"
    }
  }
  spec {
    selector = {
      app = "service-a"
    }
    port {
      port        = 9090
      target_port = 9090
    }
    type = "ClusterIP"
  }

  depends_on = [
    kubernetes_namespace.fake-service
  ]
}

resource "kubernetes_config_map" "service-a" {
  provider = kubernetes.eks

  metadata {
    name = "app-settings"
    namespace = "fake-service"
  }

  data = {
    "app-settings.json" = "${file("${path.module}/config-maps/app-settings.json.tmp")}"
  }

  depends_on = [
    kubernetes_namespace.fake-service
  ]
}

resource "kubernetes_service_account" "service-a" {
  provider = kubernetes.eks

  metadata {
    name = "service-a"
    namespace = "fake-service"
  }
  automount_service_account_token = true

  depends_on = [
    kubernetes_namespace.fake-service
  ]
}

resource "kubernetes_deployment" "service-a" {
  provider = kubernetes.eks

  metadata {
    name = "service-a"
    namespace = "fake-service"
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        service = "service-a"
        app = "service-a"
      }
    }
    template {
      metadata {
        labels = {
          service = "service-a"
          app = "service-a"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = true           
        }
      }
      spec {
        init_container {
          name  = "consul-template-init"
          image = "phantony/consul-template:0.33.0"
          volume_mount {
            name = "app-settings"
            mount_path = "/etc/app-settings"
          }
          volume_mount {
            name = "app-settings-result"
            mount_path = "/app/config"
          }
          env {
            name = "TEMPLATE_PATH"
            value = "/etc/app-settings/app-settings.json"
          }
          env {
            name = "RESULT_PATH"
            value = "/app/config/app-settings.json"
          }
          env {
            name = "EXTRA_ARGS"
            value = "-once"
          }
          env {
            name = "CONSUL_HTTP_ADDR"
            value = var.consul_addr
          }
          env {
            name = "CONSUL_HTTP_TOKEN"
            value = var.consul_token
          }
          env {
            name = "CONSUL_HTTP_SSL"
            value = true
          }
          env {
            name = "CONSUL_HTTP_SSL_VERIFY"
            value = false
          }
          env {
            name = "VAULT_ADDR"
            value = var.vault_addr
          }
          env {
            name = "VAULT_NAMESPACE" // required for hcp vault
            value = "admin"
          }
          env {
            name = "VAULT_TOKEN"
            value = var.vault_token
          }
        }
        container {
          name  = "fake-service"
          image = "nicholasjackson/fake-service:v0.25.2"
          port {
            container_port = 9090
          }
          volume_mount {
            name = "app-settings-result"
            mount_path = "/app/config"
          }
          env {
            name = "LISTEN_ADDR"
            value = "0.0.0.0:9090"
          }
          env {
            name = "NAME"
            value = "service-a"
          }
        }
        container {
          name  = "consul-template-sidecar"
          image = "phantony/consul-template:0.33.0"
          volume_mount {
            name = "app-settings"
            mount_path = "/etc/app-settings"
          }
          volume_mount {
            name = "app-settings-result"
            mount_path = "/app/config"
          }
          env {
            name = "TEMPLATE_PATH"
            value = "/etc/app-settings/app-settings.json"
          }
          env {
            name = "RESULT_PATH"
            value = "/app/config/app-settings.json"
          }
          env {
            name = "CONSUL_HTTP_ADDR"
            value = var.consul_addr
          }
          env {
            name = "CONSUL_HTTP_TOKEN"
            value = var.consul_token
          }
          env {
            name = "CONSUL_HTTP_SSL"
            value = true
          }
          env {
            name = "CONSUL_HTTP_SSL_VERIFY"
            value = false
          }
          env {
            name = "VAULT_ADDR"
            value = var.vault_addr
          }
          env {
            name = "VAULT_NAMESPACE" // required for hcp vault
            value = "admin"
          }
          env {
            name = "VAULT_TOKEN"
            value = var.vault_token
          }
        }
        service_account_name = "service-a"
        volume {
          name  = "app-settings"
          config_map {
            name = "app-settings"
            items {
              key = "app-settings.json"
              path = "app-settings.json"
            }
          }
        }
        volume {
          name  = "app-settings-result"
          empty_dir {
            medium = "Memory"
          }
        }
      }
    }
  }
  wait_for_rollout = false

  depends_on = [
    kubernetes_namespace.fake-service
  ]
}