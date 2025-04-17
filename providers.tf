# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
  }
}


# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}