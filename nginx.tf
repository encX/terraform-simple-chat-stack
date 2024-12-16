resource "helm_release" "nginx" {
  name = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace  = kubernetes_namespace.nginx-ns.metadata[0].name

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}