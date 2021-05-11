output "minikubes" {
  value = cloudflare_record.default.*.hostname
}
