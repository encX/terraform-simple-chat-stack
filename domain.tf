resource "cloudflare_record" "domain" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  content = data.kubernetes_service_v1.nginx-ingress-controller.status.0.load_balancer.0.ingress.0.ip
  type    = "A"
  proxied = true
}
