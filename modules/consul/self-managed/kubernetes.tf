data "kubernetes_service" "consul-ui" {
  metadata {
    name = "consul-ui"
    namespace = "consul"
  }
  
  depends_on = [
    helm_release.consul-server
  ]
}

data "kubernetes_secret" "consul-bootstrap-token" {
  metadata {
    name = "consul-bootstrap-acl-token"
    namespace = "consul"
  }

  depends_on = [
  helm_release.consul-server
  ]
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name      = "consul"
  }
}

resource "kubernetes_secret" "consul-ent-license" {
  metadata {
    name = "consul-ent-license"
    namespace = "consul"
  }

  data = {
    key = var.consul_ent_license
  }
}

// create gp3 as the default storage class
resource "kubernetes_annotations" "gp2" {  
  count = var.cloud == "aws" ? 1 : 0

  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }

  force = true
}

resource "kubernetes_storage_class" "ebs_csi_encrypted_gp3" {
  count = var.cloud == "aws" ? 1 : 0

  metadata {
    name = "ebs-csi-encrypted-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }
}