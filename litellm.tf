resource "kubernetes_config_map" "litellm_config" {
  metadata {
    name      = "litellm-config"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
  }

  data = {
    "proxy_config.yaml" = <<-EOT
      general_settings:
        disable_spend_logs: True
        database_connection_pool_limit: 20
        allow_requests_on_db_unavailable: True

      litellm_settings:
        request_timeout: 15
        set_verbose: False

      router_settings:
        redis_host: ${kubernetes_service.redis_service.metadata[0].name}.${kubernetes_service.redis_service.metadata[0].namespace}.svc.cluster.local
        redis_password: ""
        redis_port: 6379

      model_list:
        - model_name: gpt-4o-mini
          litellm_params:
            model: openai/gpt-4o-mini
            api_key: os.environ/OPENAI_API_KEY
            rpm: 500
            tpm: 200_000

        - model_name: gpt-4o
          litellm_params:
            model: openai/gpt-4o
            api_key: os.environ/OPENAI_API_KEY
            rpm: 500
            tpm: 30_000

        - model_name: o1-mini
          litellm_params:
            model: openai/o1-mini
            api_key: os.environ/OPENAI_API_KEY
            rpm: 500
            tpm: 200_000

        - model_name: o1-preview
          litellm_params:
            model: openai/o1-preview
            api_key: os.environ/OPENAI_API_KEY
            rpm: 500
            tpm: 30_000
    EOT
  }
}

resource "kubernetes_deployment" "litellm_deployment" {
  depends_on = [ kubernetes_service.redis_service ]
  metadata {
    name      = "litellm"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
    labels = {
      app = "litellm"
    }
  }

  timeouts {
    create = "5m"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "litellm"
      }
    }

    template {
      metadata {
        labels = {
          app = "litellm"
        }
      }

      spec {
        container {
          name  = "litellm-container"
          image = "ghcr.io/berriai/litellm:main-latest"

          image_pull_policy = "Always"

          env {
            name  = "OPENAI_API_KEY"
            value = var.openai_api_key
          }

          env {
            name  = "LITELLM_MASTER_KEY"
            value = local.litellm_master_key
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql://postgres:${google_sql_database_instance.pg.root_password}@${google_sql_database_instance.pg.private_ip_address}/litellm"
          }

          env {
            name  = "LITELLM_MODE"
            value = "PRODUCTION"
          }

          env {
            name  = "LITELLM_LOG"
            value = "ERROR"
          }

          args = [
            "--port",
            "4000",
            "--config",
            "/config/proxy_config.yaml"
          ]

          volume_mount {
            name       = "config-volume"
            mount_path = "/config"
            read_only  = true
          }

          resources {
            requests = {
              memory = "1.5Gi"
              cpu    = "1"
              ephemeral-storage = "100Mi"
            }

            limits = {
              memory = "2Gi"
              cpu    = "2"
              ephemeral-storage = "200Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health/liveliness"
              port = 4000
            }

            initial_delay_seconds = 120
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 3
            timeout_seconds       = 10
          }

          readiness_probe {
            http_get {
              path = "/health/readiness"
              port = 4000
            }

            initial_delay_seconds = 120
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 3
            timeout_seconds       = 10
          }
        }

        volume {
          name = "config-volume"

          config_map {
            name = kubernetes_config_map.litellm_config.metadata[0].name
          }
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "ScheduleAnyway"

          label_selector {
            match_labels = {
              app = "litellm"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "litellm_service" {
  metadata {
    name      = "litellm-service"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
  }

  spec {
    selector = {
      app = "litellm"
    }

    port {
      protocol   = "TCP"
      port       = 4000
      target_port = 4000
    }

    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata {
    name      = "redis-pvc"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "100Mi"
      }
    }

    storage_class_name = "standard-rwo"
  }

  wait_until_bound = false
}

resource "kubernetes_deployment" "redis_deployment" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
    labels = {
      app = "redis"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:latest"

          resources {
            limits = {
              memory            = "512Mi"
              cpu               = "500m"
              "ephemeral-storage" = "200Mi"
            }

            requests = {
              memory            = "256Mi"
              cpu               = "250m"
              "ephemeral-storage" = "100Mi"
            }
          }

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis_service" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}

resource "random_string" "litellm_master_key" {
  length  = 64
  special = false
}

locals {
  litellm_master_key = "sk-${random_string.litellm_master_key.result}"
}

output "litellm_master_key" {
  value     = local.litellm_master_key
}