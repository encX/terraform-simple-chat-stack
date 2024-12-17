resource "google_service_account" "gke-sa" {
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE TF Service Account"
}

resource "google_container_cluster" "gke" {
  name                = var.cluster_name
  location            = var.zone
  initial_node_count  = 3
  deletion_protection = false
  datapath_provider   = "ADVANCED_DATAPATH"

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 40
    image_type   = "COS_CONTAINERD"
    disk_type    = "pd-balanced"
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
    service_account = google_service_account.gke-sa.email
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  logging_config {
    enable_components = ["WORKLOADS"]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "STORAGE",
      "POD",
      "DEPLOYMENT",
      "STATEFULSET",
      "DAEMONSET",
      "HPA",
      "CADVISOR",
      "KUBELET"
    ]
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  private_cluster_config {
    enable_private_nodes = true
  }

  default_snat_status {
    disabled = true
  }

  networking_mode = "VPC_NATIVE"

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

resource "kubernetes_namespace" "chat-stack" {
  depends_on = [google_container_cluster.gke]

  metadata {
    name = "chat-stack"
  }
}

resource "kubernetes_namespace" "nginx" {
  depends_on = [google_container_cluster.gke]

  metadata {
    name = "nginx"
  }
}

resource "kubernetes_storage_class" "filestore_vpc" {
  metadata {
    name = "standard-rwx-vpc"
  }

  storage_provisioner = "filestore.csi.storage.gke.io"

  parameters = {
    network = "projects/${var.project_id}/global/networks/${google_compute_network.vpc.name}"
    tier    = "standard"
  }

  allow_volume_expansion = true
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "chat-stack-pvc"
    namespace = kubernetes_namespace.chat-stack.metadata[0].name
  }

  timeouts {
    create = "5m"
  }

  wait_until_bound = false

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.filestore_vpc.metadata[0].name

    resources {
      requests = {
        storage = "200Gi"
      }
    }
  }
}

output "cluster_name" {
  value = google_container_cluster.gke.name
}
