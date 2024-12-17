variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "chat-stack"
}

variable "machine_type" {
  description = "The machine type for the node pool instances"
  type        = string
  default     = "e2-standard-2"
}

variable "openwebui_replicas" {
  description = "The number of replicas for the OpenWebUI deployment"
  type        = number
  default     = 2
}

variable "domain" {
  description = "Domain name to manage DNS records"
  type        = string
}

variable "subdomain" {
  description = "A subdomain to be used for the OpenWebUI"
  type        = string
}

variable "openai_api_key" {
  description = "The OpenAI API key"
  type        = string
}

variable "webui_name" {
  description = "The name displayed on the OpenWebUI"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token to manage DNS records"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}
