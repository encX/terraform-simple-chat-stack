data "kubernetes_ingress_v1" "openwebui-ingress" {
  metadata {
    name = "open-webui"
    namespace  = kubernetes_namespace.chat-stack.metadata[0].name
  }
}

output "ip" {
  value = data.kubernetes_ingress_v1.openwebui-ingress.status.0.load_balancer.0.ingress.0.ip 
}

resource "cloudflare_record" "domain" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  content = data.kubernetes_ingress_v1.openwebui-ingress.status.0.load_balancer.0.ingress.0.ip
  type    = "A"
  proxied = true
}