// set consul default partition cluster peering through mesh gateways

resource "consul_config_entry" "eks-mesh" {
  count = var.cloud == "aws" ? 1 : 0

  name      = "mesh"
  kind      = "mesh"

  config_json = jsonencode({
      Peering = {
          PeerThroughMeshGateways = true
      }
  })
}

resource "consul_config_entry" "gke-mesh" {
  count = var.cloud == "gcp" ? 1 : 0

  name      = "mesh"
  kind      = "mesh"

  config_json = jsonencode({
    Peering = {
      PeerThroughMeshGateways = true
    }
  })
}

// create default partition cluster peering token for aws and gcp

resource "consul_peering_token" "aws-gcp-default" {
  count = var.cloud == "aws" ? 1 : 0

  peer_name = "aws-gcp-default"

  depends_on = [
    consul_config_entry.eks-mesh
  ]
}

// create default partition cluster peering connection between aws and gcp

resource "consul_peering" "aws-gcp-default" {
  count = var.cloud == "gcp" ? 1 : 0

  peer_name     = "aws-gcp-default"
  peering_token = var.peering_token
}