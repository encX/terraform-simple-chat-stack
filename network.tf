resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = "false"

}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_global_address" "vpc_ip" {
  name          = "${var.cluster_name}-vpc-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "vpc_psc" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.vpc_ip.name]
}

data "http" "cloudflare_ip" {
  url = "https://www.cloudflare.com/ips-v4"
}

resource "google_compute_firewall" "allow-cloudflare" {
  name   = "allow-cloudflare"
  network = google_compute_network.vpc.name

  priority = 1
  direction = "INGRESS"
  source_ranges = split("\n", data.http.cloudflare_ip.response_body)
  destination_ranges = [ data.kubernetes_ingress_v1.openwebui-ingress.status.0.load_balancer.0.ingress.0.ip ]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "deny-rest" {
  name   = "deny-rest"
  network = google_compute_network.vpc.name

  priority = 2
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  destination_ranges = [ data.kubernetes_ingress_v1.openwebui-ingress.status.0.load_balancer.0.ingress.0.ip ]
  
  deny {
    protocol = "all"
  }
}