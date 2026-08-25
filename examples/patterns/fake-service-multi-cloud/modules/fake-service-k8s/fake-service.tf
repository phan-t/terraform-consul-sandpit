// create kubernetes resource

resource "kubernetes_service" "this" {
  metadata {
    name = var.service_name
    labels = {
        app = var.service_name
    }
  }
  spec {
    selector = {
      app = var.service_name
    }
    port {
      port        = 9090
      target_port = 9090
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name = var.service_name
  }
  automount_service_account_token = true
}

resource "kubernetes_deployment" "service-a" {
  metadata {
    name = var.service_name
  }
  spec {
    replicas = 2

    selector {
      match_labels = {
        service = var.service_name
        app = var.service_name
      }
    }
    template {
      metadata {
        labels = {
          service = var.service_name
          app = var.service_name
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = true           
        }
      }
      spec {
        container {
          name  = "fake-service"
          image = "nicholasjackson/fake-service:v0.25.2"
          port {
            container_port = 9090
          }
          env {
            name = "LISTEN_ADDR"
            value = "0.0.0.0:9090"
          }
          env {
            name = "NAME"
            value = var.service_name
          }
          env {
            name = "UPSTREAM_URIS"
            value = var.upstreams
          }
        }
        service_account_name = var.service_name
      }
    }
  }
  wait_for_rollout = false
}