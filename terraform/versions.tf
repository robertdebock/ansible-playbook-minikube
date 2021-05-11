terraform {
  required_version = ">= 0.14.6"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.13.2"
    }
  }
}
