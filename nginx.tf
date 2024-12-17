resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.nginx.metadata[0].name

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

data "kubernetes_service_v1" "nginx-ingress-controller" {
  depends_on = [helm_release.nginx]

  metadata {
    name      = "nginx-ingress-nginx-controller"
    namespace = kubernetes_namespace.nginx.metadata[0].name
  }
}
