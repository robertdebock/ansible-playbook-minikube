resource "digitalocean_project" "default" {
  name        = "minikube"
  description = "Many minikubes"
  purpose     = "Demo"
  environment = "development"
}

resource "digitalocean_project_resources" "default" {
  project   = digitalocean_project.default.id
  resources = digitalocean_droplet.default.*.urn
}

resource "digitalocean_ssh_key" "default" {
  name       = "minikube"
  public_key = file("../ssh_keys/id_rsa.pub")
}

resource "digitalocean_droplet" "default" {
  image    = "ubuntu-20-10-x64"
  name     = "minikube-${count.index}"
  region   = "ams3"
  size     = "8gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
  count    = var.amount
}

data "cloudflare_zones" "default" {
  filter {
    name = "meinit.nl"
  }
}

resource "cloudflare_record" "default" {
  zone_id = data.cloudflare_zones.default.zones[0].id
  name    = "minikube-${count.index}"
  value   = digitalocean_droplet.default[count.index].ipv4_address
  type    = "A"
  count   = var.amount
}
