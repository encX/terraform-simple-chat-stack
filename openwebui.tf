resource "helm_release" "openwebui" {
  name       = "openwebui"
  repository = "https://helm.openwebui.com/"
  chart      = "open-webui"
  namespace  = kubernetes_namespace.chat-stack.metadata[0].name

  values = [
    yamlencode({
      ollama    = { enabled = false }
      pipelines = { enabled = false }
      tika      = { enabled = false }

      clusterDomain = "cluster.local"

      annotations    = {}
      podAnnotations = {}
      replicaCount   = var.openwebui_replicas

      image = {
        repository = "ghcr.io/open-webui/open-webui"
        tag        = "main"
        pullPolicy = "IfNotPresent"
      }

      resources = {
        requests = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      ingress = {
        enabled = true
        class   = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/affinity"               = "cookie"
          "nginx.ingress.kubernetes.io/session-cookie-name"    = "podmap"
          "nginx.ingress.kubernetes.io/session-cookie-expires" = "10800"
          "nginx.ingress.kubernetes.io/session-cookie-max-age" = "10800"
        }
        host = "${var.subdomain}.${var.domain}"
        tls  = false
      }

      persistence = {
        enabled       = true
        existingClaim = kubernetes_persistent_volume_claim.pvc.metadata[0].name
      }

      topologySpreadConstraints = [
        {
          maxSkew           = 1
          topologyKey       = "kubernetes.io/hostname"
          whenUnsatisfiable = "ScheduleAnyway"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/component" = "open-webui"
            }
          }
        }
      ]

      service = {
        type              = "NodePort"
        annotations       = {}
        port              = 80
        containerPort     = 8080
        nodePort          = ""
        labels            = {}
        loadBalancerClass = ""
      }

      openaiBaseApiUrl = "http://${kubernetes_service.litellm_service.metadata.0.name}.${kubernetes_service.litellm_service.metadata.0.namespace}.svc.cluster.local:4000"

      extraEnvVars = [
        {
          name  = "OPENAI_API_KEY"
          value = local.litellm_master_key
        },
        {
          name  = "WEBUI_NAME"
          value = var.webui_name
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://postgres:${google_sql_database_instance.pg.root_password}@${google_sql_database_instance.pg.private_ip_address}/openwebui"
        },
        {
          name  = "JWT_EXPIRES_IN"
          value = "1d"
        },
        {
          name  = "AIOHTTP_CLIENT_TIMEOUT"
          value = "60"
        }
      ]
    })
  ]
}
