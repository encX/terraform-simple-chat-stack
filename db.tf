resource "google_sql_database_instance" "pg" {
  name             = "${var.cluster_name}-pg-${random_id.db_name_suffix.hex}"
  region           = var.region
  database_version = "POSTGRES_17"
  root_password    = random_password.db_password.result

  depends_on = [google_service_networking_connection.vpc_psc]

  settings {
    tier              = "db-custom-4-16384"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_size         = 100
    disk_type         = "PD_SSD"
    disk_autoresize   = false

    location_preference {
      zone = var.zone
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "db-openwebui" {
  name     = "openwebui"
  instance = google_sql_database_instance.pg.name
}

resource "google_sql_database" "db-litellm" {
  name     = "litellm"
  instance = google_sql_database_instance.pg.name
}

resource "random_id" "db_name_suffix" {
  byte_length = 2
}

resource "random_password" "db_password" {
  length  = 48
  special = false
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
